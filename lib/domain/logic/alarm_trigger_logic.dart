import '../models/alarm_settings.dart';
import '../models/alarm_status.dart';
import 'charging_events.dart';

/// The outcome the alarm trigger logic wants the rest of the app to act
/// on: whether to (start playing / keep playing / stop) native alarm
/// playback, and what [AlarmStatus] the UI should reflect.
class AlarmDecision {
  const AlarmDecision({required this.status, required this.shouldPlay});

  final AlarmStatus status;

  /// True if native alarm playback (sound/vibration/notification) should
  /// be actively triggered or kept alive as a result of this decision.
  final bool shouldPlay;

  static const AlarmDecision idle = AlarmDecision(status: AlarmStatus.idle, shouldPlay: false);
  static const AlarmDecision disabled =
      AlarmDecision(status: AlarmStatus.disabled, shouldPlay: false);
}

/// Pure decision logic mapping a [ChargingEvent] plus the current
/// [AlarmSettings] and alarm lifecycle state to an [AlarmDecision].
///
/// Deliberately has no knowledge of platform channels, notifications, or
/// audio — it only decides *what should happen*, so it is fully unit
/// testable and the platform layer stays a thin, dumb executor of its
/// decisions.
class AlarmTriggerLogic {
  const AlarmTriggerLogic();

  AlarmDecision decide({
    required ChargingEvent event,
    required AlarmSettings settings,
    required AlarmStatus currentStatus,
  }) {
    if (!settings.alarmEnabled) {
      return AlarmDecision.disabled;
    }

    if (event is TargetReached) {
      return const AlarmDecision(status: AlarmStatus.sounding, shouldPlay: true);
    }

    if (event is ChargerDisconnected) {
      if (settings.autoStopOnUnplug) {
        return const AlarmDecision(status: AlarmStatus.idle, shouldPlay: false);
      }
      // Auto-stop disabled: keep sounding if it already was, otherwise
      // stay idle. We never *start* a new alarm on disconnect.
      if (currentStatus == AlarmStatus.sounding) {
        return const AlarmDecision(status: AlarmStatus.sounding, shouldPlay: true);
      }
      return AlarmDecision.idle;
    }

    if (event is ChargerConnected) {
      // A fresh charging session below target clears any previous
      // dismissed/sounding state from an earlier session.
      return AlarmDecision.idle;
    }

    // ChargingProgressed / NoChange: preserve whatever is already true,
    // e.g. a sounding alarm keeps sounding until explicitly stopped.
    if (currentStatus == AlarmStatus.sounding) {
      return const AlarmDecision(status: AlarmStatus.sounding, shouldPlay: true);
    }
    return AlarmDecision(status: currentStatus, shouldPlay: false);
  }

  /// Decision for an explicit user "stop/dismiss" action.
  AlarmDecision dismiss() => const AlarmDecision(status: AlarmStatus.dismissed, shouldPlay: false);
}
