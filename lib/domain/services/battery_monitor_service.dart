import '../models/battery_reading.dart';

/// Abstraction over platform-specific battery/charging monitoring.
///
/// Concrete implementations live in the `platform/` layer (backed by
/// MethodChannel/EventChannel to native Android/iOS code). Domain and
/// presentation code depend only on this interface, so business logic can
/// be unit tested with a fake implementation with no platform channels
/// involved.
abstract class BatteryMonitorService {
  /// Emits a new [BatteryReading] whenever the OS reports a battery level
  /// or charging-state change. Implementations should emit an initial
  /// reading immediately on subscription so the app never shows a blank
  /// state while waiting for the first OS callback (handles "app launched
  /// while already charging").
  Stream<BatteryReading> watch();

  /// Reads the current battery/charging state once, without subscribing.
  Future<BatteryReading> current();

  /// Starts any platform-side background monitoring required to keep
  /// receiving updates while the app is not in the foreground (Android
  /// foreground service / iOS background battery monitoring, subject to
  /// each platform's real capabilities).
  Future<void> startBackgroundMonitoring();

  /// Stops platform-side background monitoring, e.g. when the alarm is
  /// disabled in settings.
  Future<void> stopBackgroundMonitoring();
}
