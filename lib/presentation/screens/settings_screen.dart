import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/alarm_sound.dart';
import '../../domain/models/app_language.dart';
import '../../l10n/app_localizations.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().load();
    });
  }

  String _soundLabel(AppLocalizations l10n, AlarmSound sound) {
    return switch (sound.id) {
      'gentle_chime' => l10n.soundGentleChime,
      'urgent_alert' => l10n.soundUrgentAlert,
      'classic_bell' => l10n.soundClassicBell,
      _ => l10n.soundDefault,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: Consumer<SettingsController>(
          builder: (context, controller, _) {
            if (!controller.loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final settings = controller.settings;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _SectionHeader(l10n.settingsAlarmSection),
                SwitchListTile.adaptive(
                  title: Text(l10n.settingsAlarmEnabled),
                  subtitle: Text(l10n.settingsAlarmEnabledDescription),
                  value: settings.alarmEnabled,
                  onChanged: controller.setAlarmEnabled,
                ),
                const Divider(height: 1),
                _SectionHeader(l10n.settingsSoundSection),
                ...AlarmSound.all.map(
                  (sound) => RadioListTile<String>(
                    title: Text(_soundLabel(l10n, sound)),
                    value: sound.id,
                    groupValue: settings.soundId,
                    onChanged: settings.alarmEnabled
                        ? (value) {
                            if (value != null) controller.setSoundId(value);
                          }
                        : null,
                  ),
                ),
                SwitchListTile.adaptive(
                  title: Text(l10n.settingsVibrationLabel),
                  subtitle: Text(l10n.settingsVibrationDescription),
                  value: settings.vibrationEnabled,
                  onChanged: settings.alarmEnabled ? controller.setVibrationEnabled : null,
                ),
                SwitchListTile.adaptive(
                  title: Text(l10n.settingsAutoStopLabel),
                  subtitle: Text(l10n.settingsAutoStopDescription),
                  value: settings.autoStopOnUnplug,
                  onChanged: settings.alarmEnabled ? controller.setAutoStopOnUnplug : null,
                ),
                const Divider(height: 1),
                _SectionHeader(l10n.settingsLanguageSection),
                RadioListTile<AppLanguage>(
                  title: Text(l10n.languageEnglish),
                  value: AppLanguage.english,
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) controller.setLanguage(value);
                  },
                ),
                RadioListTile<AppLanguage>(
                  title: Text(l10n.languageBengali),
                  value: AppLanguage.bengali,
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) controller.setLanguage(value);
                  },
                ),
                const Divider(height: 1),
                _SectionHeader(l10n.settingsAbout),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.settingsPlatformNote,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    Theme.of(context).platform == TargetPlatform.iOS
                        ? l10n.settingsIosLimitation
                        : l10n.settingsAndroidNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
