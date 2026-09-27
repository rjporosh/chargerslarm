import '../models/alarm_settings.dart';

/// Abstraction over persisted user settings. The concrete implementation
/// uses `shared_preferences`; domain/presentation code never touches
/// persistence APIs directly.
abstract class SettingsRepository {
  Future<AlarmSettings> load();
  Future<void> save(AlarmSettings settings);
}
