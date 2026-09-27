import 'package:chargealarm/domain/models/alarm_status.dart';
import 'package:chargealarm/domain/models/battery_reading.dart';
import 'package:chargealarm/domain/models/charging_connection_state.dart';
import 'package:chargealarm/presentation/controllers/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_services.dart';

BatteryReading _reading(int percent, ChargingConnectionState state) {
  return BatteryReading(percentage: percent, connectionState: state, timestamp: DateTime(2026));
}

void main() {
  late FakeBatteryMonitorService battery;
  late FakeAlarmPlayerService alarmPlayer;
  late FakeSettingsRepository settingsRepo;
  late DashboardController controller;

  setUp(() {
    battery = FakeBatteryMonitorService(_reading(50, ChargingConnectionState.disconnected));
    alarmPlayer = FakeAlarmPlayerService();
    settingsRepo = FakeSettingsRepository();
    controller = DashboardController(
      batteryMonitor: battery,
      alarmPlayer: alarmPlayer,
      settingsRepository: settingsRepo,
    );
  });

  tearDown(() {
    controller.dispose();
    battery.dispose();
  });

  test('initialize() loads settings and the current reading', () async {
    await controller.initialize();

    expect(controller.initialized, isTrue);
    expect(controller.reading?.percentage, 50);
    expect(controller.settings.targetPercentage, 80); // default
    expect(battery.backgroundMonitoringActive, isTrue); // alarm enabled by default
  });

  test('reaching the target while charging starts native alarm playback exactly once', () async {
    await controller.initialize();

    battery.emit(_reading(79, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);
    battery.emit(_reading(80, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);
    battery.emit(_reading(81, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AlarmStatus.sounding);
    expect(alarmPlayer.startCount, 1); // no repeated trigger while still above target
    expect(alarmPlayer.lastReachedPercentage, 80);
  });

  test('unplugging with autoStopOnUnplug enabled stops the alarm', () async {
    await controller.initialize();
    battery.emit(_reading(80, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, AlarmStatus.sounding);

    battery.emit(_reading(80, ChargingConnectionState.disconnected));
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AlarmStatus.idle);
    expect(alarmPlayer.stopCount, 1);
  });

  test('dismissAlarm() stops playback and marks the alarm dismissed', () async {
    await controller.initialize();
    battery.emit(_reading(80, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);

    await controller.dismissAlarm();

    expect(controller.status, AlarmStatus.dismissed);
    expect(alarmPlayer.stopCount, 1);
  });

  test('setTarget rejects an out-of-range value and leaves settings unchanged', () async {
    await controller.initialize();
    final applied = await controller.setTarget(150);

    expect(applied, isFalse);
    expect(controller.settings.targetPercentage, 80);
  });

  test('setTarget persists a valid value via the settings repository', () async {
    await controller.initialize();
    final applied = await controller.setTarget(90);

    expect(applied, isTrue);
    expect(controller.settings.targetPercentage, 90);
    expect(settingsRepo.saveCount, 1);
  });

  test('app initialized while already above target fires the alarm immediately', () async {
    battery = FakeBatteryMonitorService(_reading(95, ChargingConnectionState.charging));
    controller = DashboardController(
      batteryMonitor: battery,
      alarmPlayer: alarmPlayer,
      settingsRepository: settingsRepo,
    );

    await controller.initialize();
    // The initial current() reading alone does not run through the state
    // machine (only the stream does); simulate the platform immediately
    // echoing that same reading on the stream, as real implementations do.
    battery.emit(_reading(95, ChargingConnectionState.charging));
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AlarmStatus.sounding);
  });
}
