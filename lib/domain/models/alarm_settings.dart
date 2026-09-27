import 'package:equatable/equatable.dart';

import 'alarm_sound.dart';
import 'app_language.dart';

/// All user-configurable preferences for the charge alarm, persisted as a
/// single unit. Immutable — use [copyWith] to produce updated instances.
class AlarmSettings extends Equatable {
  const AlarmSettings({
    required this.alarmEnabled,
    required this.targetPercentage,
    required this.soundId,
    required this.vibrationEnabled,
    required this.autoStopOnUnplug,
    required this.language,
  });

  factory AlarmSettings.defaults() => const AlarmSettings(
        alarmEnabled: true,
        targetPercentage: 80,
        soundId: 'default_alarm',
        vibrationEnabled: true,
        autoStopOnUnplug: true,
        language: AppLanguage.english,
      );

  final bool alarmEnabled;
  final int targetPercentage;
  final String soundId;
  final bool vibrationEnabled;

  /// When true, an active alarm is automatically silenced the moment the
  /// charger is unplugged, rather than requiring manual dismissal.
  final bool autoStopOnUnplug;
  final AppLanguage language;

  AlarmSound get sound => AlarmSound.fromId(soundId);

  AlarmSettings copyWith({
    bool? alarmEnabled,
    int? targetPercentage,
    String? soundId,
    bool? vibrationEnabled,
    bool? autoStopOnUnplug,
    AppLanguage? language,
  }) {
    return AlarmSettings(
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      soundId: soundId ?? this.soundId,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoStopOnUnplug: autoStopOnUnplug ?? this.autoStopOnUnplug,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        alarmEnabled,
        targetPercentage,
        soundId,
        vibrationEnabled,
        autoStopOnUnplug,
        language,
      ];
}
