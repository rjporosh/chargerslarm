import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChargeAlarm'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @batteryPercentageLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get batteryPercentageLabel;

  /// No description provided for @chargerStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Charger'**
  String get chargerStatusLabel;

  /// No description provided for @chargerStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get chargerStatusConnected;

  /// No description provided for @chargerStatusCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get chargerStatusCharging;

  /// No description provided for @chargerStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get chargerStatusDisconnected;

  /// No description provided for @chargerStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get chargerStatusFull;

  /// No description provided for @alarmStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmStatusLabel;

  /// No description provided for @alarmStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Armed'**
  String get alarmStatusIdle;

  /// No description provided for @alarmStatusSounding.
  ///
  /// In en, this message translates to:
  /// **'Sounding'**
  String get alarmStatusSounding;

  /// No description provided for @alarmStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get alarmStatusDismissed;

  /// No description provided for @alarmStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get alarmStatusDisabled;

  /// No description provided for @currentTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Current target'**
  String get currentTargetLabel;

  /// No description provided for @quickTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick targets'**
  String get quickTargetsTitle;

  /// No description provided for @targetOptionPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String targetOptionPercent(int value);

  /// No description provided for @targetOptionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get targetOptionCustom;

  /// No description provided for @customTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom target'**
  String get customTargetTitle;

  /// No description provided for @customTargetDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose any percentage between 1% and 100%.'**
  String get customTargetDescription;

  /// No description provided for @customTargetFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Target percentage'**
  String get customTargetFieldLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a target percentage.'**
  String get errorTargetRequired;

  /// No description provided for @errorTargetOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Target must be between 1% and 100%.'**
  String get errorTargetOutOfRange;

  /// No description provided for @batteryFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery Full'**
  String get batteryFullTitle;

  /// No description provided for @batteryFullMessage.
  ///
  /// In en, this message translates to:
  /// **'Battery Full — Please Unplug the Charger'**
  String get batteryFullMessage;

  /// No description provided for @targetReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Reached'**
  String get targetReachedTitle;

  /// No description provided for @targetReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your battery reached {value}%.'**
  String targetReachedMessage(int value);

  /// No description provided for @dismissAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get dismissAlarm;

  /// No description provided for @settingsAlarmSection.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get settingsAlarmSection;

  /// No description provided for @settingsAlarmEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable charge alarm'**
  String get settingsAlarmEnabled;

  /// No description provided for @settingsAlarmEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn off to stop all monitoring and notifications.'**
  String get settingsAlarmEnabledDescription;

  /// No description provided for @settingsSoundSection.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSoundSection;

  /// No description provided for @settingsSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get settingsSoundLabel;

  /// No description provided for @settingsVibrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get settingsVibrationLabel;

  /// No description provided for @settingsVibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate the device when the alarm sounds, where supported.'**
  String get settingsVibrationDescription;

  /// No description provided for @settingsAutoStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-stop on unplug'**
  String get settingsAutoStopLabel;

  /// No description provided for @settingsAutoStopDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically silence the alarm when the charger is disconnected.'**
  String get settingsAutoStopDescription;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPlatformNote.
  ///
  /// In en, this message translates to:
  /// **'Platform behavior'**
  String get settingsPlatformNote;

  /// No description provided for @settingsIosLimitation.
  ///
  /// In en, this message translates to:
  /// **'On iOS, alerts fire while ChargeAlarm is open or recently backgrounded. Apple does not allow apps to run unrestricted alarms while fully closed.'**
  String get settingsIosLimitation;

  /// No description provided for @settingsAndroidNote.
  ///
  /// In en, this message translates to:
  /// **'On Android, ChargeAlarm keeps monitoring in the background using a persistent notification, subject to your device manufacturer\'s battery-saving restrictions.'**
  String get settingsAndroidNote;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default Alarm'**
  String get soundDefault;

  /// No description provided for @soundGentleChime.
  ///
  /// In en, this message translates to:
  /// **'Gentle Chime'**
  String get soundGentleChime;

  /// No description provided for @soundUrgentAlert.
  ///
  /// In en, this message translates to:
  /// **'Urgent Alert'**
  String get soundUrgentAlert;

  /// No description provided for @soundClassicBell.
  ///
  /// In en, this message translates to:
  /// **'Classic Bell'**
  String get soundClassicBell;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// No description provided for @emptyStateNoReading.
  ///
  /// In en, this message translates to:
  /// **'Waiting for battery data…'**
  String get emptyStateNoReading;

  /// No description provided for @errorStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read battery status'**
  String get errorStateTitle;

  /// No description provided for @errorStateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorStateRetry;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationRationale.
  ///
  /// In en, this message translates to:
  /// **'ChargeAlarm needs notification permission to alert you when your target charge level is reached.'**
  String get permissionNotificationRationale;

  /// No description provided for @permissionBatteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow background activity'**
  String get permissionBatteryOptimizationTitle;

  /// No description provided for @permissionBatteryOptimizationRationale.
  ///
  /// In en, this message translates to:
  /// **'To detect your target charge level while the screen is locked, allow ChargeAlarm to run in the background and disable battery optimization for it.'**
  String get permissionBatteryOptimizationRationale;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
