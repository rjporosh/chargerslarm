// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChargeAlarm';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get batteryPercentageLabel => 'Battery';

  @override
  String get chargerStatusLabel => 'Charger';

  @override
  String get chargerStatusConnected => 'Connected';

  @override
  String get chargerStatusCharging => 'Charging';

  @override
  String get chargerStatusDisconnected => 'Disconnected';

  @override
  String get chargerStatusFull => 'Full';

  @override
  String get alarmStatusLabel => 'Alarm';

  @override
  String get alarmStatusIdle => 'Armed';

  @override
  String get alarmStatusSounding => 'Sounding';

  @override
  String get alarmStatusDismissed => 'Dismissed';

  @override
  String get alarmStatusDisabled => 'Disabled';

  @override
  String get currentTargetLabel => 'Current target';

  @override
  String get quickTargetsTitle => 'Quick targets';

  @override
  String targetOptionPercent(int value) {
    return '$value%';
  }

  @override
  String get targetOptionCustom => 'Custom';

  @override
  String get customTargetTitle => 'Custom target';

  @override
  String get customTargetDescription =>
      'Choose any percentage between 1% and 100%.';

  @override
  String get customTargetFieldLabel => 'Target percentage';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorTargetRequired => 'Enter a target percentage.';

  @override
  String get errorTargetOutOfRange => 'Target must be between 1% and 100%.';

  @override
  String get batteryFullTitle => 'Battery Full';

  @override
  String get batteryFullMessage => 'Battery Full — Please Unplug the Charger';

  @override
  String get targetReachedTitle => 'Target Reached';

  @override
  String targetReachedMessage(int value) {
    return 'Your battery reached $value%.';
  }

  @override
  String get dismissAlarm => 'Stop Alarm';

  @override
  String get settingsAlarmSection => 'Alarm';

  @override
  String get settingsAlarmEnabled => 'Enable charge alarm';

  @override
  String get settingsAlarmEnabledDescription =>
      'Turn off to stop all monitoring and notifications.';

  @override
  String get settingsSoundSection => 'Sound';

  @override
  String get settingsSoundLabel => 'Alarm sound';

  @override
  String get settingsVibrationLabel => 'Vibrate';

  @override
  String get settingsVibrationDescription =>
      'Vibrate the device when the alarm sounds, where supported.';

  @override
  String get settingsAutoStopLabel => 'Auto-stop on unplug';

  @override
  String get settingsAutoStopDescription =>
      'Automatically silence the alarm when the charger is disconnected.';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPlatformNote => 'Platform behavior';

  @override
  String get settingsIosLimitation =>
      'On iOS, alerts fire while ChargeAlarm is open or recently backgrounded. Apple does not allow apps to run unrestricted alarms while fully closed.';

  @override
  String get settingsAndroidNote =>
      'On Android, ChargeAlarm keeps monitoring in the background using a persistent notification, subject to your device manufacturer\'s battery-saving restrictions.';

  @override
  String get soundDefault => 'Default Alarm';

  @override
  String get soundGentleChime => 'Gentle Chime';

  @override
  String get soundUrgentAlert => 'Urgent Alert';

  @override
  String get soundClassicBell => 'Classic Bell';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get emptyStateNoReading => 'Waiting for battery data…';

  @override
  String get errorStateTitle => 'Couldn\'t read battery status';

  @override
  String get errorStateRetry => 'Retry';

  @override
  String get permissionNotificationTitle => 'Allow notifications';

  @override
  String get permissionNotificationRationale =>
      'ChargeAlarm needs notification permission to alert you when your target charge level is reached.';

  @override
  String get permissionBatteryOptimizationTitle => 'Allow background activity';

  @override
  String get permissionBatteryOptimizationRationale =>
      'To detect your target charge level while the screen is locked, allow ChargeAlarm to run in the background and disable battery optimization for it.';
}
