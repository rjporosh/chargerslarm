import 'package:flutter/foundation.dart';

import '../../domain/logic/target_validator.dart';
import '../../domain/models/alarm_settings.dart';
import '../../domain/models/app_language.dart';
import '../../domain/services/battery_monitor_service.dart';
import '../../domain/services/settings_repository.dart';

/// Owns persisted [AlarmSettings] for the Settings screen and notifies a
/// registered listener (the [DashboardController]) whenever they change,
/// so both screens stay in sync without a heavier global state solution.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsRepository settingsRepository,
    required BatteryMonitorService batteryMonitor,
    TargetValidator? validator,
    this.onSettingsChanged,
  })  : _settingsRepository = settingsRepository,
        _batteryMonitor = batteryMonitor,
        _validator = validator ?? const TargetValidator();

  final SettingsRepository _settingsRepository;
  final BatteryMonitorService _batteryMonitor;
  final TargetValidator _validator;

  /// Invoked after every successful save, e.g. wired to
  /// [DashboardController.applySettings] from the composition root.
  void Function(AlarmSettings updated)? onSettingsChanged;

  AlarmSettings _settings = AlarmSettings.defaults();
  bool _loaded = false;
  String? _targetErrorKey;

  AlarmSettings get settings => _settings;
  bool get loaded => _loaded;
  String? get targetErrorKey => _targetErrorKey;

  Future<void> load() async {
    _settings = await _settingsRepository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist(AlarmSettings updated) async {
    _settings = updated;
    await _settingsRepository.save(updated);
    onSettingsChanged?.call(updated);
    notifyListeners();
  }

  Future<void> setAlarmEnabled(bool enabled) async {
    await _persist(_settings.copyWith(alarmEnabled: enabled));
    if (enabled) {
      await _batteryMonitor.startBackgroundMonitoring();
    } else {
      await _batteryMonitor.stopBackgroundMonitoring();
    }
  }

  /// Validates and applies a candidate target percentage. Returns true on
  /// success; on failure, [targetErrorKey] is populated for the UI to show.
  Future<bool> setTargetPercentage(int candidate) async {
    final result = _validator.validate(candidate);
    if (!result.isValid) {
      _targetErrorKey = result.errorKey;
      notifyListeners();
      return false;
    }
    _targetErrorKey = null;
    await _persist(_settings.copyWith(targetPercentage: candidate));
    return true;
  }

  Future<void> setSoundId(String soundId) async {
    await _persist(_settings.copyWith(soundId: soundId));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _persist(_settings.copyWith(vibrationEnabled: enabled));
  }

  Future<void> setAutoStopOnUnplug(bool enabled) async {
    await _persist(_settings.copyWith(autoStopOnUnplug: enabled));
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _persist(_settings.copyWith(language: language));
  }
}
