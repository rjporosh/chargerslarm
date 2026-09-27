import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'platform/alarm/native_alarm_channel.dart';
import 'platform/battery/battery_monitor_channel.dart';
import 'presentation/controllers/dashboard_controller.dart';
import 'presentation/controllers/settings_controller.dart';

/// Composition root. Concrete platform/data implementations are
/// constructed exactly once, here, and injected into the controllers via
/// their constructors — the rest of the app only ever depends on the
/// domain-layer interfaces, which is what keeps business logic testable
/// without Flutter or platform-channel bootstrapping.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepositoryImpl(prefs);
  final batteryMonitor = BatteryMonitorChannel();
  final alarmPlayer = NativeAlarmChannel();

  final dashboardController = DashboardController(
    batteryMonitor: batteryMonitor,
    alarmPlayer: alarmPlayer,
    settingsRepository: settingsRepository,
  );

  final settingsController = SettingsController(
    settingsRepository: settingsRepository,
    batteryMonitor: batteryMonitor,
    onSettingsChanged: dashboardController.applySettings,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dashboardController),
        ChangeNotifierProvider.value(value: settingsController),
      ],
      child: const ChargeAlarmApp(),
    ),
  );
}
