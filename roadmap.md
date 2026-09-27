# Roadmap

## Completed milestones
1. Project scaffolding, tooling config (`analysis_options.yaml`, `l10n.yaml`, `.gitignore`), master specification committed.
2. Domain layer: models, `TargetValidator`, `ChargingStateMachine`, `AlarmTriggerLogic` — pure Dart, no Flutter dependency.
3. Data + platform layer: `SettingsRepositoryImpl` (SharedPreferences), `BatteryMonitorChannel` / `NativeAlarmChannel` (MethodChannel/EventChannel bridges).
4. Complete English + Bengali localization resources.
5. Theming, responsive layout helpers, `DashboardController` / `SettingsController`.
6. Dashboard and Settings screens with adaptive portrait/landscape layouts; composition root in `main.dart`.
7. Android native implementation: foreground service, charging broadcast receivers, boot-recovery, native alarm playback.
8. iOS native implementation: `UIDevice` battery monitoring, local-notification + in-app audio alarm, documented platform limitation.
9. Generated brand icon, configured for both platforms' launcher/app-icon slots.
10. Unit test suite: validation, state machine, alarm logic, persistence, controller-level integration tests against fakes.

## Current milestone
**Toolchain verification.** The next required step is running the project through an actual Flutter installation: `flutter pub get`, `flutter analyze`, `flutter test`, and a real device/emulator run on both platforms. This repository has not yet had that pass — see `README.md` → Verification status and `ai-handover.md` for exactly where to look first.

## Remaining milestones
- Run and fix `flutter analyze` / `flutter test` results.
- Generate `Runner.xcodeproj`/`Runner.xcworkspace` via `flutter create --platforms=ios .` and confirm the custom Swift plugins wire in cleanly.
- Manual QA pass on a real Android device (screen-locked charging, OEM battery-optimization prompt flow, reboot-while-charging) and a real iOS device (foreground/backgrounded alarm behavior).
- Replace the generated icon with a designer-produced asset if this app is published to a store.
- Add real bundled alarm sound files (`assets/sounds/*.mp3` for Android via `RingtoneManager`-independent playback, `Runner/alarm_default.caf` for iOS) instead of relying on system ringtones.
- Capture real device screenshots for the README's screenshots section.
- Add a widget-test smoke suite for `DashboardScreen`/`SettingsScreen` once `flutter gen-l10n`'s generated `AppLocalizations` class exists locally (requires the Flutter toolchain to generate).

## Known technical debt
- Native Android/iOS alarm notification copy is hardcoded in English rather than sourced from the shared ARB files (native code has no access to Flutter's `gen-l10n` output). A future pass could mirror the handful of alarm-related strings into `strings.xml` (per `values-bn/`) and an iOS `Localizable.strings` file so even background-triggered native alerts are localized.
- `shared_preferences`'s Android implementation has, in some plugin versions, stored integers as 64-bit longs under the hood; `BatteryReadingUtils.targetPercentage` in the native Android code assumes a plain `Int` read. If `flutter test`/manual QA surfaces a type-mismatch reading `flutter.target_percentage` from native code, switch that read to a `Long`-safe helper.
- No CI workflow (`.github/workflows/`) has been added yet; recommended before treating `main` as protected.

## Future improvements
- Home-screen widget (Android) / Lock Screen widget (iOS 16+) showing live progress toward target without opening the app.
- Charging-history log (opt-in, local-only) so users can see typical charge-to-target durations.
- Wear OS / watchOS companion alert.
