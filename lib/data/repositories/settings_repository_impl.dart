import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/logic/target_validator.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/models/app_language.dart';
import '../../domain/services/settings_repository.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].
///
/// Every read is sanitized through [TargetValidator.clamp] so a corrupted
/// or platform-migration-related bad value in storage can never put the
/// app into an invalid/impossible target state (defence in depth beyond
/// the settings-screen validation).
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs, {TargetValidator? validator})
      : _validator = validator ?? const TargetValidator();

  final SharedPreferences _prefs;
  final TargetValidator _validator;

  static const _keyAlarmEnabled = 'alarm_enabled';
  static const _keyTargetPercentage = 'target_percentage';
  static const _keySoundId = 'sound_id';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyAutoStopOnUnplug = 'auto_stop_on_unplug';
  static const _keyLanguage = 'language_code';

  @override
  Future<AlarmSettings> load() async {
    final defaults = AlarmSettings.defaults();
    final rawTarget = _prefs.getInt(_keyTargetPercentage) ?? defaults.targetPercentage;

    return AlarmSettings(
      alarmEnabled: _prefs.getBool(_keyAlarmEnabled) ?? defaults.alarmEnabled,
      targetPercentage: _validator.clamp(rawTarget),
      soundId: _prefs.getString(_keySoundId) ?? defaults.soundId,
      vibrationEnabled: _prefs.getBool(_keyVibrationEnabled) ?? defaults.vibrationEnabled,
      autoStopOnUnplug: _prefs.getBool(_keyAutoStopOnUnplug) ?? defaults.autoStopOnUnplug,
      language: AppLanguage.fromCode(
        _prefs.getString(_keyLanguage) ?? defaults.language.code,
      ),
    );
  }

  @override
  Future<void> save(AlarmSettings settings) async {
    await Future.wait([
      _prefs.setBool(_keyAlarmEnabled, settings.alarmEnabled),
      _prefs.setInt(_keyTargetPercentage, _validator.clamp(settings.targetPercentage)),
      _prefs.setString(_keySoundId, settings.soundId),
      _prefs.setBool(_keyVibrationEnabled, settings.vibrationEnabled),
      _prefs.setBool(_keyAutoStopOnUnplug, settings.autoStopOnUnplug),
      _prefs.setString(_keyLanguage, settings.language.code),
    ]);
  }
}
