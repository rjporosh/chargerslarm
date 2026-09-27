import '../models/battery_reading.dart';
import '../models/charging_connection_state.dart';
import 'charging_events.dart';

/// Pure state machine that turns a stream of raw [BatteryReading]s into
/// discrete [ChargingEvent]s.
///
/// This is intentionally the single source of truth for "what just
/// happened" so that every edge case in the specification (app launched
/// mid-charge, already above target, reconnect, target changed while
/// charging, etc.) reduces to a table of (previous, current, target)
/// comparisons that can be unit tested without any platform or UI code.
class ChargingStateMachine {
  ChargingStateMachine({BatteryReading? initialReading})
      : _previous = initialReading;

  BatteryReading? _previous;

  /// The last reading processed, or null if no reading has been seen yet
  /// (e.g. immediately after app launch, before the first platform
  /// callback arrives).
  BatteryReading? get previous => _previous;

  /// Feeds a new raw reading into the machine and returns the event that
  /// best describes the transition from the previous reading, given the
  /// currently configured [targetPercentage].
  ///
  /// [targetAlreadyNotified] should be true if an alarm for the *current*
  /// charging session has already fired for this target, so the machine
  /// does not repeatedly emit [TargetReached] on every subsequent reading
  /// while still above target (this satisfies "do not repeatedly trigger
  /// the same alarm").
  ChargingEvent process(
    BatteryReading reading, {
    required int targetPercentage,
    required bool targetAlreadyNotified,
  }) {
    final prev = _previous;
    _previous = reading;

    final wasConnected =
        prev != null && prev.connectionState != ChargingConnectionState.disconnected;
    final isConnected = reading.connectionState != ChargingConnectionState.disconnected;

    if (!wasConnected && isConnected) {
      // Handles both "app launched while already charging" (prev == null,
      // isConnected == true) and a genuine reconnect.
      if (reading.percentage >= targetPercentage && !targetAlreadyNotified) {
        return TargetReached(reading, targetPercentage);
      }
      return ChargerConnected(reading);
    }

    if (wasConnected && !isConnected) {
      return ChargerDisconnected(reading);
    }

    if (isConnected) {
      if (reading.percentage >= targetPercentage && !targetAlreadyNotified) {
        return TargetReached(reading, targetPercentage);
      }
      if (prev != null && prev.percentage == reading.percentage) {
        return NoChange(reading);
      }
      return ChargingProgressed(reading);
    }

    return NoChange(reading);
  }

  /// Resets tracked history, e.g. when the alarm target changes while
  /// charging and the "already notified" bookkeeping (held by the caller)
  /// is reset alongside it so a higher new target can still fire.
  void reset({BatteryReading? seedWith}) {
    _previous = seedWith;
  }
}
