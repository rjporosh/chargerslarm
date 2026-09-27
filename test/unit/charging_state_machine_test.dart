import 'package:chargealarm/domain/logic/charging_events.dart';
import 'package:chargealarm/domain/logic/charging_state_machine.dart';
import 'package:chargealarm/domain/models/battery_reading.dart';
import 'package:chargealarm/domain/models/charging_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

BatteryReading _reading(int percent, ChargingConnectionState state) {
  return BatteryReading(percentage: percent, connectionState: state, timestamp: DateTime(2026));
}

void main() {
  group('ChargingStateMachine', () {
    test('app launched while already charging below target emits ChargerConnected', () {
      final machine = ChargingStateMachine(); // no initial reading: fresh launch
      final event = machine.process(
        _reading(40, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<ChargerConnected>());
    });

    test('app launched when already above target emits TargetReached immediately', () {
      final machine = ChargingStateMachine();
      final event = machine.process(
        _reading(85, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<TargetReached>());
      expect((event as TargetReached).targetPercentage, 80);
    });

    test('charger connected below target does not fire the alarm', () {
      final machine = ChargingStateMachine(initialReading: _reading(10, ChargingConnectionState.disconnected));
      final event = machine.process(
        _reading(10, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<ChargerConnected>());
    });

    test('battery progressing while charging, target not yet reached', () {
      final machine = ChargingStateMachine(initialReading: _reading(50, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(55, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<ChargingProgressed>());
    });

    test('reaching exactly the target fires TargetReached', () {
      final machine = ChargingStateMachine(initialReading: _reading(79, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(80, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<TargetReached>());
    });

    test('does not repeatedly fire TargetReached once already notified this session', () {
      final machine = ChargingStateMachine(initialReading: _reading(80, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(81, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: true,
      );
      expect(event, isNot(isA<TargetReached>()));
    });

    test('reaching 100% fires TargetReached when target is 100', () {
      final machine = ChargingStateMachine(initialReading: _reading(99, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(100, ChargingConnectionState.connectedFull),
        targetPercentage: 100,
        targetAlreadyNotified: false,
      );
      expect(event, isA<TargetReached>());
    });

    test('unplugging before target emits ChargerDisconnected', () {
      final machine = ChargingStateMachine(initialReading: _reading(50, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(50, ChargingConnectionState.disconnected),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<ChargerDisconnected>());
    });

    test('unplugging after target emits ChargerDisconnected, not another TargetReached', () {
      final machine = ChargingStateMachine(initialReading: _reading(85, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(85, ChargingConnectionState.disconnected),
        targetPercentage: 80,
        targetAlreadyNotified: true,
      );
      expect(event, isA<ChargerDisconnected>());
    });

    test('reconnecting after a full disconnect/reconnect cycle can re-fire once below target again', () {
      final machine = ChargingStateMachine(initialReading: _reading(85, ChargingConnectionState.disconnected));
      final event = machine.process(
        _reading(30, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false, // caller resets this on ChargerConnected/new session
      );
      expect(event, isA<ChargerConnected>());
    });

    test('target changed while charging (raised) can fire again since caller resets notified flag', () {
      // Simulates: was charging at 85 with target 80 (already notified), user
      // raises target to 90 -> caller resets targetAlreadyNotified to false.
      final machine = ChargingStateMachine(initialReading: _reading(85, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(90, ChargingConnectionState.charging),
        targetPercentage: 90,
        targetAlreadyNotified: false,
      );
      expect(event, isA<TargetReached>());
    });

    test('identical consecutive readings while charging are a no-op', () {
      final machine = ChargingStateMachine(initialReading: _reading(50, ChargingConnectionState.charging));
      final event = machine.process(
        _reading(50, ChargingConnectionState.charging),
        targetPercentage: 80,
        targetAlreadyNotified: false,
      );
      expect(event, isA<NoChange>());
    });
  });
}
