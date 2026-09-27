import '../models/battery_reading.dart';

/// Discrete, semantically meaningful events derived by comparing two
/// consecutive [BatteryReading]s. The state machine emits these; the alarm
/// trigger logic and UI layer react to them. Keeping this as its own
/// vocabulary (rather than reacting to raw readings everywhere) is what
/// makes edge cases like "launched mid-charge" or "target changed while
/// charging" tractable and testable.
sealed class ChargingEvent {
  const ChargingEvent(this.reading);

  final BatteryReading reading;
}

/// Charger was just connected (previously disconnected).
class ChargerConnected extends ChargingEvent {
  const ChargerConnected(super.reading);
}

/// Charger was just disconnected (previously connected/charging).
class ChargerDisconnected extends ChargingEvent {
  const ChargerDisconnected(super.reading);
}

/// Battery percentage changed while charging, but no target was crossed.
class ChargingProgressed extends ChargingEvent {
  const ChargingProgressed(super.reading);
}

/// The configured target percentage was reached or exceeded while
/// charging. Carries the target that was reached so the alarm logic and UI
/// don't need to re-read settings to know what happened.
class TargetReached extends ChargingEvent {
  const TargetReached(super.reading, this.targetPercentage);

  final int targetPercentage;
}

/// No meaningful change since the last reading (deduplicated no-op).
class NoChange extends ChargingEvent {
  const NoChange(super.reading);
}
