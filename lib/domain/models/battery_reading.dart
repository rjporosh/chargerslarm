import 'package:equatable/equatable.dart';

import 'charging_connection_state.dart';

/// A single, immutable snapshot of the device's battery/charging state,
/// as reported by the platform layer at a point in time.
class BatteryReading extends Equatable {
  const BatteryReading({
    required this.percentage,
    required this.connectionState,
    required this.timestamp,
  }) : assert(
          percentage >= 0 && percentage <= 100,
          'percentage must be within 0-100',
        );

  /// Battery charge level, 0-100 inclusive.
  final int percentage;

  /// Charger connection/charging state as reported by the OS.
  final ChargingConnectionState connectionState;

  /// When this reading was captured. Useful for debouncing and logging.
  final DateTime timestamp;

  bool get isCharging => connectionState != ChargingConnectionState.disconnected;

  BatteryReading copyWith({
    int? percentage,
    ChargingConnectionState? connectionState,
    DateTime? timestamp,
  }) {
    return BatteryReading(
      percentage: percentage ?? this.percentage,
      connectionState: connectionState ?? this.connectionState,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [percentage, connectionState, timestamp];
}
