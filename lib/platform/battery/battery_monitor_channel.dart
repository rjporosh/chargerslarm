import 'package:flutter/services.dart';

import '../../domain/models/battery_reading.dart';
import '../../domain/models/charging_connection_state.dart';
import '../../domain/services/battery_monitor_service.dart';

/// [BatteryMonitorService] implementation backed by a platform
/// MethodChannel (for one-shot reads and start/stop control) and an
/// EventChannel (for the push stream of battery/charging updates from the
/// native Android/iOS side).
///
/// The wire format on the EventChannel is a `Map` with:
///   - `percentage`: int, 0-100
///   - `connectionState`: String, one of "disconnected" | "charging" | "connectedFull"
///   - `timestampMs`: int, epoch milliseconds
///
/// Keeping the channel/message-shape parsing isolated here means the rest
/// of the app never deals with platform-channel primitives directly.
class BatteryMonitorChannel implements BatteryMonitorService {
  BatteryMonitorChannel({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method = methodChannel ?? const MethodChannel('chargealarm/battery_control'),
        _events = eventChannel ?? const EventChannel('chargealarm/battery_stream');

  final MethodChannel _method;
  final EventChannel _events;

  Stream<BatteryReading>? _cachedStream;

  @override
  Stream<BatteryReading> watch() {
    return _cachedStream ??= _events.receiveBroadcastStream().map(_parseReading);
  }

  @override
  Future<BatteryReading> current() async {
    final result = await _method.invokeMapMethod<String, dynamic>('getCurrentReading');
    if (result == null) {
      throw PlatformException(
        code: 'no_reading',
        message: 'Native battery layer returned no reading.',
      );
    }
    return _parseReading(result);
  }

  @override
  Future<void> startBackgroundMonitoring() {
    return _method.invokeMethod('startBackgroundMonitoring');
  }

  @override
  Future<void> stopBackgroundMonitoring() {
    return _method.invokeMethod('stopBackgroundMonitoring');
  }

  BatteryReading _parseReading(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final percentage = (map['percentage'] as num).toInt().clamp(0, 100);
    final stateString = map['connectionState'] as String? ?? 'disconnected';
    final timestampMs = map['timestampMs'] as int? ??
        DateTime.now().millisecondsSinceEpoch;

    return BatteryReading(
      percentage: percentage,
      connectionState: _parseConnectionState(stateString),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  ChargingConnectionState _parseConnectionState(String value) {
    switch (value) {
      case 'charging':
        return ChargingConnectionState.charging;
      case 'connectedFull':
        return ChargingConnectionState.connectedFull;
      case 'disconnected':
      default:
        return ChargingConnectionState.disconnected;
    }
  }
}
