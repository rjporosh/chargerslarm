import 'dart:async';

import 'package:chargealarm/domain/models/alarm_settings.dart';
import 'package:chargealarm/domain/models/battery_reading.dart';
import 'package:chargealarm/domain/services/alarm_player_service.dart';
import 'package:chargealarm/domain/services/battery_monitor_service.dart';
import 'package:chargealarm/domain/services/settings_repository.dart';

/// Test double for [BatteryMonitorService] that lets a test push arbitrary
/// readings on demand via [emit], rather than depending on real platform
/// channels — this is what keeps [DashboardController] unit testable.
class FakeBatteryMonitorService implements BatteryMonitorService {
  FakeBatteryMonitorService(this._initial);

  final BatteryReading _initial;
  final _controller = StreamController<BatteryReading>.broadcast();
  bool backgroundMonitoringActive = false;

  void emit(BatteryReading reading) => _controller.add(reading);

  @override
  Stream<BatteryReading> watch() => _controller.stream;

  @override
  Future<BatteryReading> current() async => _initial;

  @override
  Future<void> startBackgroundMonitoring() async {
    backgroundMonitoringActive = true;
  }

  @override
  Future<void> stopBackgroundMonitoring() async {
    backgroundMonitoringActive = false;
  }

  void dispose() => _controller.close();
}

class FakeAlarmPlayerService implements AlarmPlayerService {
  int startCount = 0;
  int stopCount = 0;
  int? lastReachedPercentage;
  bool _playing = false;

  @override
  Future<void> start({required AlarmSettings settings, required int reachedPercentage}) async {
    startCount++;
    lastReachedPercentage = reachedPercentage;
    _playing = true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _playing = false;
  }

  @override
  Future<bool> isPlaying() async => _playing;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AlarmSettings? initial]) : _settings = initial ?? AlarmSettings.defaults();

  AlarmSettings _settings;
  int saveCount = 0;

  @override
  Future<AlarmSettings> load() async => _settings;

  @override
  Future<void> save(AlarmSettings settings) async {
    _settings = settings;
    saveCount++;
  }
}
