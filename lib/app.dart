import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/dashboard_screen.dart';

/// Root widget: wires the persisted language preference to [MaterialApp]'s
/// locale and applies the shared light/dark theme. Controllers themselves
/// are provided above this widget in `main.dart`'s composition root.
class ChargeAlarmApp extends StatelessWidget {
  const ChargeAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settingsController, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          locale: settingsController.loaded
              ? Locale(settingsController.settings.language.code)
              : null,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
