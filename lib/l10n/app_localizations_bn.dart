// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'চার্জঅ্যালার্ম';

  @override
  String get dashboardTitle => 'ড্যাশবোর্ড';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get batteryPercentageLabel => 'ব্যাটারি';

  @override
  String get chargerStatusLabel => 'চার্জার';

  @override
  String get chargerStatusConnected => 'সংযুক্ত';

  @override
  String get chargerStatusCharging => 'চার্জ হচ্ছে';

  @override
  String get chargerStatusDisconnected => 'সংযোগ বিচ্ছিন্ন';

  @override
  String get chargerStatusFull => 'পূর্ণ';

  @override
  String get alarmStatusLabel => 'অ্যালার্ম';

  @override
  String get alarmStatusIdle => 'প্রস্তুত';

  @override
  String get alarmStatusSounding => 'বাজছে';

  @override
  String get alarmStatusDismissed => 'বন্ধ করা হয়েছে';

  @override
  String get alarmStatusDisabled => 'নিষ্ক্রিয়';

  @override
  String get currentTargetLabel => 'বর্তমান লক্ষ্যমাত্রা';

  @override
  String get quickTargetsTitle => 'দ্রুত লক্ষ্যমাত্রা';

  @override
  String targetOptionPercent(int value) {
    return '$value%';
  }

  @override
  String get targetOptionCustom => 'কাস্টম';

  @override
  String get customTargetTitle => 'কাস্টম লক্ষ্যমাত্রা';

  @override
  String get customTargetDescription =>
      '১% থেকে ১০০%-এর মধ্যে যেকোনো শতাংশ নির্বাচন করুন।';

  @override
  String get customTargetFieldLabel => 'লক্ষ্যমাত্রা শতাংশ';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get errorTargetRequired => 'একটি লক্ষ্যমাত্রা শতাংশ লিখুন।';

  @override
  String get errorTargetOutOfRange =>
      'লক্ষ্যমাত্রা অবশ্যই ১% থেকে ১০০%-এর মধ্যে হতে হবে।';

  @override
  String get batteryFullTitle => 'ব্যাটারি পূর্ণ';

  @override
  String get batteryFullMessage =>
      'ব্যাটারি পূর্ণ হয়েছে — অনুগ্রহ করে চার্জার খুলে ফেলুন';

  @override
  String get targetReachedTitle => 'লক্ষ্যমাত্রা অর্জিত';

  @override
  String targetReachedMessage(int value) {
    return 'আপনার ব্যাটারি $value% পৌঁছেছে।';
  }

  @override
  String get dismissAlarm => 'অ্যালার্ম বন্ধ করুন';

  @override
  String get settingsAlarmSection => 'অ্যালার্ম';

  @override
  String get settingsAlarmEnabled => 'চার্জ অ্যালার্ম চালু করুন';

  @override
  String get settingsAlarmEnabledDescription =>
      'বন্ধ করলে সব পর্যবেক্ষণ ও বিজ্ঞপ্তি বন্ধ হয়ে যাবে।';

  @override
  String get settingsSoundSection => 'শব্দ';

  @override
  String get settingsSoundLabel => 'অ্যালার্মের শব্দ';

  @override
  String get settingsVibrationLabel => 'কম্পন';

  @override
  String get settingsVibrationDescription =>
      'সমর্থিত হলে অ্যালার্ম বাজার সময় ডিভাইস কাঁপবে।';

  @override
  String get settingsAutoStopLabel => 'চার্জার খোলার সাথে সাথে বন্ধ';

  @override
  String get settingsAutoStopDescription =>
      'চার্জার সংযোগ বিচ্ছিন্ন হলে অ্যালার্ম স্বয়ংক্রিয়ভাবে বন্ধ হয়ে যাবে।';

  @override
  String get settingsLanguageSection => 'ভাষা';

  @override
  String get settingsAbout => 'সম্পর্কে';

  @override
  String get settingsPlatformNote => 'প্ল্যাটফর্ম আচরণ';

  @override
  String get settingsIosLimitation =>
      'iOS-এ, চার্জঅ্যালার্ম চালু থাকা বা সম্প্রতি ব্যাকগ্রাউন্ডে যাওয়া অবস্থায় সতর্কতা কাজ করে। অ্যাপল সম্পূর্ণ বন্ধ থাকা অ্যাপে সীমাহীন অ্যালার্ম চালানোর অনুমতি দেয় না।';

  @override
  String get settingsAndroidNote =>
      'অ্যান্ড্রয়েডে, চার্জঅ্যালার্ম একটি স্থায়ী বিজ্ঞপ্তির মাধ্যমে ব্যাকগ্রাউন্ডে পর্যবেক্ষণ চালিয়ে যায়, যা আপনার ডিভাইস প্রস্তুতকারকের ব্যাটারি সাশ্রয় নিয়ন্ত্রণ সাপেক্ষে।';

  @override
  String get soundDefault => 'ডিফল্ট অ্যালার্ম';

  @override
  String get soundGentleChime => 'মৃদু ঘণ্টাধ্বনি';

  @override
  String get soundUrgentAlert => 'জরুরি সতর্কতা';

  @override
  String get soundClassicBell => 'ক্লাসিক বেল';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get emptyStateNoReading => 'ব্যাটারির তথ্যের জন্য অপেক্ষা করা হচ্ছে…';

  @override
  String get errorStateTitle => 'ব্যাটারির অবস্থা পড়া যায়নি';

  @override
  String get errorStateRetry => 'আবার চেষ্টা করুন';

  @override
  String get permissionNotificationTitle => 'বিজ্ঞপ্তির অনুমতি দিন';

  @override
  String get permissionNotificationRationale =>
      'আপনার লক্ষ্যমাত্রা চার্জ স্তরে পৌঁছালে সতর্ক করতে চার্জঅ্যালার্মের বিজ্ঞপ্তির অনুমতি প্রয়োজন।';

  @override
  String get permissionBatteryOptimizationTitle =>
      'ব্যাকগ্রাউন্ড কার্যকলাপের অনুমতি দিন';

  @override
  String get permissionBatteryOptimizationRationale =>
      'স্ক্রিন লক থাকা অবস্থায় লক্ষ্যমাত্রা শনাক্ত করতে, চার্জঅ্যালার্মকে ব্যাকগ্রাউন্ডে চলার অনুমতি দিন এবং এর জন্য ব্যাটারি অপ্টিমাইজেশন বন্ধ করুন।';
}
