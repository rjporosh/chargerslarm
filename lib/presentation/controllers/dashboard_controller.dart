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
  bool _targetNotifiedThisSession = false;
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

    _subscription = _batteryMonitor.watch().listen(_onReading, onError: (Object e) {
      _lastError = e;
      notifyListeners();
    });

    if (_settings.alarmEnabled) {
      await _batteryMonitor.startBackgroundMonitoring();
    }
  }

  void _onReading(BatteryReading reading) {
    _reading = reading;

    final event = _stateMachine.process(
      reading,
      targetPercentage: _settings.targetPercentage,
      targetAlreadyNotified: _targetNotifiedThisSession,
    );

    if (event is ChargerConnected) {
      _targetNotifiedThisSession = false;
    }
    if (event is TargetReached) {
      _targetNotifiedThisSession = true;
    }

    final decision = _alarmLogic.decide(
      event: event,
      settings: _settings,
      currentStatus: _status,
    );
    _applyDecision(decision, reachedPercentage: reading.percentage);

    notifyListeners();
  }

  void _applyDecision(AlarmDecision decision, {required int reachedPercentage}) {
    final wasSounding = _status == AlarmStatus.sounding;
    _status = decision.status;

    if (decision.shouldPlay && !wasSounding) {
      unawaited(_alarmPlayer.start(settings: _settings, reachedPercentage: reachedPercentage));
    } else if (!decision.shouldPlay && wasSounding) {
      unawaited(_alarmPlayer.stop());
    }
  }

  /// User-initiated dismiss/stop of a currently sounding alarm.
  Future<void> dismissAlarm() async {
    await _alarmPlayer.stop();
    _status = _alarmLogic.dismiss().status;
    notifyListeners();
  }

  /// Applies a new target percentage, validating it first. Returns true if
  /// the value was valid and applied. Resets the "already notified"
  /// bookkeeping so a newly raised target can still fire this session, per
  /// the "target changed while charging" edge case.
  Future<bool> setTarget(int candidate) async {
    final result = _validator.validate(candidate);
    if (!result.isValid) return false;

    _settings = _settings.copyWith(targetPercentage: candidate);
    await _settingsRepository.save(_settings);

    final current = _reading;
    _targetNotifiedThisSession =
        current != null && current.isCharging && current.percentage < candidate ? false : _targetNotifiedThisSession;
    if (current != null && current.percentage < candidate) {
      _targetNotifiedThisSession = false;
    }

    notifyListeners();
    return true;
  }

  /// Called by the settings controller when alarm-relevant settings change,
  /// so the dashboard reflects them without a full re-initialize.
  void applySettings(AlarmSettings updated) {
    _settings = updated;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
