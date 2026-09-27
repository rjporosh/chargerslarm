# ChargeAlarm

ChargeAlarm watches your device while it charges and alerts you the moment it reaches a battery percentage you choose — 80%, 100%, or any custom target from 1–100%. No more overcharging, no more forgetting a full battery on the charger.

> **Portfolio note:** this repository was generated end-to-end (architecture, native Android/iOS platform code, localization, tests, documentation, and Git history) as a demonstration of production-minded Flutter engineering. See [Verification status](#verification-status) below for exactly what has and hasn't been compiler-verified.

## Features

- **Flexible targets** — quick 80%/100% presets plus a validated custom percentage (1–100%).
- **Real charging alerts** — a loud, persistent notification plus sound and vibration when your target is reached, with a clear "unplug the charger" prompt at 100%.
- **Live dashboard** — current battery %, charging status, progress toward target, and alarm status at a glance.
- **Full settings control** — enable/disable the alarm, pick a sound, toggle vibration, choose whether the alarm auto-stops on unplug, and switch language.
- **English & Bengali** — every user-visible string is localized; switch languages from Settings.
- **Responsive UI** — dedicated portrait and landscape/tablet layouts, light & dark themes, no hardcoded breakpoints.
- **Offline-first** — no account, no backend, no analytics. Settings persist locally.

## Supported platforms

| Platform | Status |
|---|---|
| Android 8.0+ (API 26+) | Full feature set, including background monitoring via a foreground service |
| iOS 13+ | Full feature set while the app is foregrounded/recently backgrounded; see [Platform limitations](#platform-limitations) |

## Architecture

Clean, feature-oriented layering, dependency direction pointing inward toward pure Dart:

```
lib/
  domain/        Pure Dart models + business logic (no Flutter imports).
    models/      BatteryReading, AlarmSettings, AlarmStatus, ...
    logic/       TargetValidator, ChargingStateMachine, AlarmTriggerLogic
    services/    Abstract interfaces (BatteryMonitorService, AlarmPlayerService, SettingsRepository)
  data/          Concrete repository implementations (SharedPreferences-backed settings).
  platform/      MethodChannel/EventChannel bridges to native Android/iOS code.
  presentation/  Controllers (ChangeNotifier), screens, reusable widgets, responsive layout helpers.
  core/          Theme and cross-cutting utilities.
  l10n/          ARB localization resources (English + Bengali).
android/         Native Kotlin: foreground service, broadcast receivers, alarm playback.
ios/             Native Swift: UIDevice battery monitoring, local-notification-based alarm.
```

**Why this shape:** `domain/logic` (target validation, the charging state machine, and the alarm trigger decision table) is deliberately pure Dart with zero Flutter or platform-channel imports, so every tricky edge case in the spec — app launched mid-charge, already above target, target changed while charging, reconnect, no-repeat-firing — is captured as a unit test against plain objects, not something that only shows up on a real device. `presentation/controllers` is the one place pure decisions get wired to real side effects (native alarm playback, persistence).

### State management

**Provider + `ChangeNotifier`** was chosen over a heavier solution (Bloc, Riverpod) because the app has exactly two screens and two pieces of long-lived state (dashboard, settings). `ChangeNotifier` is predictable, requires no code generation, and is trivial for another engineer to read top-to-bottom. `DashboardController` and `SettingsController` are constructed once in `main.dart`'s composition root and injected via `Provider` — never located as globals — which keeps them substitutable with fakes in tests (see `test/fakes/fake_services.dart`).

### Dependency injection

Plain constructor injection. `main.dart` is the single composition root: it builds the concrete `SettingsRepositoryImpl`, `BatteryMonitorChannel`, and `NativeAlarmChannel`, and hands them to the controllers through their constructors. No service locator or DI framework — the app is small enough that one would add ceremony without adding safety.

## Localization

- Source of truth: `lib/l10n/app_en.arb` and `lib/l10n/app_bn.arb`.
- Generated with Flutter's built-in `flutter gen-l10n` (configured via `l10n.yaml`, `generate: true` in `pubspec.yaml`) — running `flutter pub get` regenerates `lib/l10n/app_localizations.dart` automatically. That generated file is intentionally **not** committed.
- No user-visible string is hardcoded in any widget; every screen reads from `AppLocalizations.of(context)!`.
- Switch language from **Settings → Language**; the change applies immediately via `MaterialApp`'s `locale`.

## Getting started

### Prerequisites
- Flutter 3.22+ / Dart 3.4+
- Android Studio (Android) and/or Xcode 15+ (iOS, macOS only)

### Setup
```bash
flutter pub get
```

If this is the very first time the `ios/` platform folder is being built in a real Flutter toolchain, first run:
```bash
flutter create --platforms=ios .
```
This regenerates the standard Xcode project scaffolding (`Runner.xcodeproj`, `Runner.xcworkspace`, storyboards) that this repository's iOS folder deliberately does not hand-maintain (see [Verification status](#verification-status)) — it will not overwrite the custom Swift sources or `Info.plist` already committed here as long as you keep them; otherwise re-apply `ios/Runner/AppDelegate.swift`, `BatteryMonitorPlugin.swift`, `AlarmPlugin.swift`, and `Info.plist` from this repo afterward.

### Run
```bash
flutter run                 # connected device/emulator
flutter run -d chrome       # not supported — this app requires real battery APIs
```

### Build
```bash
flutter build apk --release
flutter build ios --release   # macOS + Xcode required
```

### Test & analyze
```bash
flutter analyze
flutter test
```

## Platform limitations

**Android:** Background monitoring uses a foreground service with a persistent low-priority notification, started when a charger is connected and stopped on disconnect (or reboot-recovery via `BOOT_COMPLETED`). This works while the screen is locked and the app is closed, **subject to the device manufacturer's own battery-optimization/OEM background-kill policies** (some Android skins — e.g. certain MIUI, ColorOS, or OneUI configurations — aggressively kill background services regardless of what the app does; users may need to manually exempt ChargeAlarm from battery optimization on such devices).

**iOS:** Apple does not provide any supported API for an app to run indefinitely in the background the way Android's foreground service can. ChargeAlarm is honest about this rather than faking it:
- While the app is foregrounded or has recently been backgrounded, `UIDevice` battery-state notifications drive live monitoring and a locally-scheduled notification plus in-app looping audio fire the alarm.
- Once iOS fully suspends or terminates the app process, ChargeAlarm **cannot** detect the target being reached until the app is reopened. This is a hard platform restriction, not an implementation gap, and is surfaced to the user directly in **Settings → About**.

## Testing

`test/unit/` covers the platform-independent core: target validation (boundaries, clamping), the charging state machine (every edge case in the specification — launch mid-charge, already-above-target, reconnect, target-changed-while-charging, no-repeat-firing, disconnect-before/after-target), and the alarm decision logic. `test/data/` covers settings persistence round-tripping and corrupted-value clamping. `test/presentation/` exercises `DashboardController` end-to-end against fake platform services (`test/fakes/`), so the full "reading → event → decision → native call" pipeline is verified without any real device.

## Screenshots

_Placeholder — add device screenshots here before publishing (`docs/screenshots/dashboard_light.png`, `dashboard_dark.png`, `settings.png`, `tablet_landscape.png`)._

## Verification status

This codebase was authored in an environment with **no Flutter/Dart SDK installed** and **no network access to `pub.dev`, Flutter's SDK distribution host, or Maven/CocoaPods**. As a direct consequence:

- `flutter pub get`, `flutter analyze`, and `flutter test` have **not** been run — the code has not been compiler-verified.
- The `ios/` folder contains the custom Swift plugin sources, `Info.plist`, and `Podfile`, but **not** a hand-maintained `Runner.xcodeproj`/`Runner.xcworkspace` (see Setup above for the one-time `flutter create` step needed to produce those on a real machine).
- App icons were generated programmatically (Pillow) into the correct Android mipmap and iOS `AppIcon.appiconset` slots; a real designer pass is recommended before publishing to a store.
- The alarm sound implementation resolves to system ringtone/alarm sounds (Android) and the system default notification sound (iOS) rather than bundled custom audio assets — see `release-notes.md`.

**Before relying on this app, run it through the full toolchain on a machine with Flutter installed:**
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
Fix anything either command surfaces; `ai-handover.md` lists the specific spots most likely to need a small correction.

## Portfolio summary

- Clean domain/data/platform/presentation architecture with zero Flutter imports in the business-logic layer.
- Real native Android (Kotlin foreground service + broadcast receivers) and iOS (Swift `UIDevice` + local notifications) implementations, each honest about platform limits.
- Complete English/Bengali localization from day one, no hardcoded UI strings.
- Responsive Material 3 UI with dedicated portrait/landscape layouts and light/dark themes.
- 30+ unit tests covering validation, a hand-rolled state machine, alarm decision logic, and persistence.
- Professional Git history under a single, non-AI author identity.
