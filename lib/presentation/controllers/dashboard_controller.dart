import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/logic/alarm_trigger_logic.dart';
import '../../domain/logic/charging_events.dart';
import '../../domain/logic/charging_state_machine.dart';
import '../../domain/logic/target_validator.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/models/alarm_status.dart';
import '../../domain/models/battery_reading.dart';
import '../../domain/services/alarm_player_service.dart';
import '../../domain/services/battery_monitor_service.dart';
import '../../domain/services/settings_repository.dart';

/// Drives the dashboard screen: owns the live battery subscription, feeds
/// readings through the pure [ChargingStateMachine] / [AlarmTriggerLogic],
/// and executes the resulting decisions against the native
/// [AlarmPlayerService]. This is the only place in the app where the pure
/// domain logic is wired to real platform side effects, which keeps that
/// logic itself trivially unit testable in isolation.
///
/// A single session-level flag, [targetNotifiedThisSession], records whether
/// the alarm has already fired for the current target in the current
/// charging session. It is cleared on both disconnect and connect so that
/// unplugging and plugging back in while still at or above target sounds
/// again, and cleared whenever the target or the alarm toggle changes so a
/// newly raised target / re-enabled alarm can still fire.
class DashboardController extends ChangeNotifier {
  DashboardController({
    required BatteryMonitorService batteryMonitor,
    required AlarmPlayerService alarmPlayer,
    required SettingsRepository settingsRepository,
    ChargingStateMachine? stateMachine,
    AlarmTriggerLogic? alarmLogic,
    TargetValidator? validator,
  })  : _batteryMonitor = batteryMonitor,
        _alarmPlayer = alarmPlayer,
        _settingsRepository = settingsRepository,
        _stateMachine = stateMachine ?? ChargingStateMachine(),
        _alarmLogic = alarmLogic ?? const AlarmTriggerLogic(),
        _validator = validator ?? const TargetValidator();

  final BatteryMonitorService _batteryMonitor;
  final AlarmPlayerService _alarmPlayer;
  final SettingsRepository _settingsRepository;
  final ChargingStateMachine _stateMachine;
  final AlarmTriggerLogic _alarmLogic;
  final TargetValidator _validator;

  StreamSubscription<BatteryReading>? _subscription;

  BatteryReading? _reading;
  AlarmSettings _settings = AlarmSettings.defaults();
  AlarmStatus _status = AlarmStatus.idle;
  bool targetNotifiedThisSession = false;
  bool _initialized = false;
  Object? _lastError;

  BatteryReading? get reading => _reading;
  AlarmSettings get settings => _settings;
  AlarmStatus get status => _status;
  bool get initialized => _initialized;
  Object? get lastError => _lastError;

  /// Progress toward the current target, clamped to [0, 1], for progress
  /// indicators. Returns 0 if there is no reading yet.
  double get progressToTarget {
    final r = _reading;
    if (r == null || _settings.targetPercentage == 0) return 0;
    return (r.percentage / _settings.targetPercentage).clamp(0.0, 1.0);
  }

  Future<void> initialize() async {
    _settings = await _settingsRepository.load();
    try {
      _reading = await _batteryMonitor.current();
    } catch (error) {
      _lastError = error;
    }
    _initialized = true;
    notifyListeners();

    _subscription = _batteryMonitor.watch().listen(
      _onReading,
      onError: (Object e) {
        _lastError = e;
        notifyListeners();
      },
    );

    if (_settings.alarmEnabled) {
      await _batteryMonitor.startBackgroundMonitoring();
    }
  }

  void _onReading(BatteryReading reading) {
    _reading = reading;

    final event = _stateMachine.process(
      reading,
      targetPercentage: _settings.targetPercentage,
      targetAlreadyNotified: targetNotifiedThisSession,
    );

    if (event is ChargerDisconnected) {
      // Close out the charging session. Clearing the flag *here* (and not
      // only on connect) is what allows plugging back in while still at or
      // above target to be treated as a fresh session and alarm again.
      targetNotifiedThisSession = false;
    }
    if (event is ChargerConnected) {
      targetNotifiedThisSession = false;
    }
    if (event is TargetReached) {
      targetNotifiedThisSession = true;
    }

    final decision = _alarmLogic.decide(
      event: event,
      settings: _settings,
      currentStatus: _status,
    );
    _applyDecision(decision, reachedPercentage: reading.percentage);

    notifyListeners();
  }

  void _applyDecision(
    AlarmDecision decision, {
    required int reachedPercentage,
    bool forceRestart = false,
  }) {
    final wasSounding = _status == AlarmStatus.sounding;
    _status = decision.status;

    if (decision.shouldPlay && (!wasSounding || forceRestart)) {
      // The native side releases any previous player before starting a new
      // one, so a restart is simply another start() — no stop/start pair,
      // which would otherwise race on the platform channel.
      unawaited(
        _alarmPlayer.start(
          settings: _settings,
          reachedPercentage: reachedPercentage,
        ),
      );
    } else if (!decision.shouldPlay && wasSounding) {
      unawaited(_alarmPlayer.stop());
    }
  }

  /// Re-runs the alarm decision against the latest reading and the current
  /// settings without waiting for the next battery callback.
  ///
  /// Settings changes are not battery changes, so nothing would otherwise
  /// re-evaluate them. Without this, turning the charge alarm off while it
  /// was sounding would leave it playing until the next 1% tick, re-enabling
  /// it while already at or above target would never start it, and raising
  /// the target above the current level would leave a stale alarm ringing.
  ///
  /// [restartPlayback] is set when a playback-relevant option (sound or
  /// vibration) changed, so the already-sounding alarm is restarted with the
  /// new cue instead of continuing with the old one.
  void _reEvaluate({bool restartPlayback = false}) {
    final current = _reading;
    if (current == null) {
      if (!_settings.alarmEnabled) {
        _applyDecision(AlarmDecision.disabled, reachedPercentage: 0);
      }
      return;
    }

    final reachedPercentage = current.percentage;

    // Silencing the alarm is unconditional and immediate: a disabled alarm
    // must not ring no matter what the battery is doing.
    if (!_settings.alarmEnabled) {
      targetNotifiedThisSession = false;
      _applyDecision(
        AlarmDecision.disabled,
        reachedPercentage: reachedPercentage,
      );
      return;
    }

    final atTarget =
        current.isCharging && current.percentage >= _settings.targetPercentage;

    if (atTarget) {
      targetNotifiedThisSession = true;
      _applyDecision(
        const AlarmDecision(status: AlarmStatus.sounding, shouldPlay: true),
        reachedPercentage: reachedPercentage,
        forceRestart: restartPlayback,
      );
      return;
    }

    targetNotifiedThisSession = false;

    if (!current.isCharging) {
      // Unplugged: delegate to the pure logic so the auto-stop-on-unplug
      // setting keeps deciding whether it silences now or rings on.
      _applyDecision(
        _alarmLogic.decide(
          event: ChargerDisconnected(current),
          settings: _settings,
          currentStatus: _status,
        ),
        reachedPercentage: reachedPercentage,
      );
      return;
    }

    if (_status == AlarmStatus.sounding) {
      // Still connected but now below target: the target was raised above
      // the current level, so what is ringing no longer matches settings.
      _applyDecision(
        AlarmDecision.idle,
        reachedPercentage: reachedPercentage,
      );
      return;
    }

    _applyDecision(
      _alarmLogic.decide(
        event: ChargingProgressed(current),
        settings: _settings,
        currentStatus: _status,
      ),
      reachedPercentage: reachedPercentage,
    );
  }

  /// User-initiated dismiss/stop of a currently sounding alarm.
  Future<void> dismissAlarm() async {
    await _alarmPlayer.stop();
    _status = _alarmLogic.dismiss().status;
    notifyListeners();
  }

  /// Applies a new target percentage, validating it first. Returns true if
  /// the value was valid and applied.
  ///
  /// The "already notified" bookkeeping is reset and the decision re-run
  /// immediately: lowering the target below the current level must start the
  /// alarm at once, and raising it above the current level must stop the
  /// now-obsolete alarm and re-arm for the new target.
  Future<bool> setTarget(int candidate) async {
    final result = _validator.validate(candidate);
    if (!result.isValid) return false;

    _settings = _settings.copyWith(targetPercentage: candidate);
    await _settingsRepository.save(_settings);

    targetNotifiedThisSession = false;
    _reEvaluate();

    notifyListeners();
    return true;
  }

  /// Called by the settings controller whenever alarm-relevant settings
  /// change, so the dashboard reflects them — and acts on them — without a
  /// full re-initialize.
  void applySettings(AlarmSettings updated) {
    final previous = _settings;
    final playbackChanged = previous.soundId != updated.soundId ||
        previous.vibrationEnabled != updated.vibrationEnabled;
    final targetChanged =
        previous.targetPercentage != updated.targetPercentage;
    final enabledChanged = previous.alarmEnabled != updated.alarmEnabled;

    _settings = updated;
    if (targetChanged || enabledChanged) {
      targetNotifiedThisSession = false;
    }

    _reEvaluate(restartPlayback: playbackChanged);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
