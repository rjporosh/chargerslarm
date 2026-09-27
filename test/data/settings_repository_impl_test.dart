import 'package:chargealarm/data/repositories/settings_repository_impl.dart';
import 'package:chargealarm/domain/models/alarm_settings.dart';
import 'package:chargealarm/domain/models/app_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepositoryImpl', () {
    test('load() returns defaults when nothing has been persisted yet', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final loaded = await repo.load();

      expect(loaded, AlarmSettings.defaults());
    });

    test('save() then load() round-trips every field', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final settings = const AlarmSettings(
        alarmEnabled: false,
        targetPercentage: 65,
        soundId: 'classic_bell',
        vibrationEnabled: false,
        autoStopOnUnplug: false,
        language: AppLanguage.bengali,
      );

      await repo.save(settings);
      final loaded = await repo.load();

      expect(loaded, settings);
    });

    test('load() clamps a corrupted out-of-range stored target percentage', () async {
      SharedPreferences.setMockInitialValues({'target_percentage': 250});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final loaded = await repo.load();

      expect(loaded.targetPercentage, 100);
    });

    test('load() falls back to English for an unrecognized language code', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'xx'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final loaded = await repo.load();

      expect(loaded.language, AppLanguage.english);
    });
  });
}
