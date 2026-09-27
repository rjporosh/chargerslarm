import 'package:chargealarm/domain/logic/alarm_trigger_logic.dart';
import 'package:chargealarm/domain/logic/charging_events.dart';
import 'package:chargealarm/domain/models/alarm_settings.dart';
import 'package:chargealarm/domain/models/alarm_status.dart';
import 'package:chargealarm/domain/models/battery_reading.dart';
import 'package:chargealarm/domain/models/charging_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

BatteryReading _reading(int percent, ChargingConnectionState state) {
  return BatteryReading(percentage: percent, connectionState: state, timestamp: DateTime(2026));
}

void main() {
  final logic = AlarmTriggerLogic();
  final enabledSettings = AlarmSettings.defaults();
  final disabledSettings = enabledSettings.copyWith(alarmEnabled: false);

  group('AlarmTriggerLogic.decide', () {
    test('disabled settings always produce AlarmStatus.disabled and no playback', () {
      final decision = logic.decide(
        event: TargetReached(_reading(80, ChargingConnectionState.charging), 80),
        settings: disabledSettings,
        currentStatus: AlarmStatus.idle,
      );
      expect(decision.status, AlarmStatus.disabled);
      expect(decision.shouldPlay, isFalse);
    });

    test('TargetReached starts sounding', () {
      final decision = logic.decide(
        event: TargetReached(_reading(80, ChargingConnectionState.charging), 80),
        settings: enabledSettings,
        currentStatus: AlarmStatus.idle,
      );
      expect(decision.status, AlarmStatus.sounding);
      expect(decision.shouldPlay, isTrue);
    });

    test('ChargerDisconnected with autoStopOnUnplug stops a sounding alarm', () {
      final decision = logic.decide(
        event: ChargerDisconnected(_reading(85, ChargingConnectionState.disconnected)),
        settings: enabledSettings.copyWith(autoStopOnUnplug: true),
        currentStatus: AlarmStatus.sounding,
      );
      expect(decision.status, AlarmStatus.idle);
      expect(decision.shouldPlay, isFalse);
    });

    test('ChargerDisconnected without autoStopOnUnplug keeps a sounding alarm going', () {
      final decision = logic.decide(
        event: ChargerDisconnected(_reading(85, ChargingConnectionState.disconnected)),
        settings: enabledSettings.copyWith(autoStopOnUnplug: false),
        currentStatus: AlarmStatus.sounding,
      );
      expect(decision.status, AlarmStatus.sounding);
      expect(decision.shouldPlay, isTrue);
    });

    test('ChargerConnected resets to idle even after a prior dismissed session', () {
      final decision = logic.decide(
        event: ChargerConnected(_reading(10, ChargingConnectionState.charging)),
        settings: enabledSettings,
        currentStatus: AlarmStatus.dismissed,
      );
      expect(decision.status, AlarmStatus.idle);
    });

    test('ChargingProgressed while already sounding keeps sounding until dismissed', () {
      final decision = logic.decide(
        event: ChargingProgressed(_reading(90, ChargingConnectionState.charging)),
        settings: enabledSettings,
        currentStatus: AlarmStatus.sounding,
      );
      expect(decision.status, AlarmStatus.sounding);
      expect(decision.shouldPlay, isTrue);
    });

    test('ChargingProgressed while idle stays idle', () {
      final decision = logic.decide(
        event: ChargingProgressed(_reading(40, ChargingConnectionState.charging)),
        settings: enabledSettings,
        currentStatus: AlarmStatus.idle,
      );
      expect(decision.status, AlarmStatus.idle);
      expect(decision.shouldPlay, isFalse);
    });
  });

  group('AlarmTriggerLogic.dismiss', () {
    test('always returns dismissed with no playback', () {
      final decision = logic.dismiss();
      expect(decision.status, AlarmStatus.dismissed);
      expect(decision.shouldPlay, isFalse);
    });
  });
}
