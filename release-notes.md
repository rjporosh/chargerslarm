# Release Notes

## v1.0.0 (initial build)

### Completed features
- Dashboard: live battery percentage, charging status, progress-to-target gauge, alarm status, quick 80%/100%/custom target chips.
- Custom target entry (1–100%) with inline validation.
- Settings: alarm enable/disable, sound picker (4 options), vibration toggle, auto-stop-on-unplug toggle, language switch (English/Bengali).
- 100%-reached messaging ("Battery Full — Please Unplug the Charger") and generic target-reached messaging, both fully localized.
- Unplug behavior: alarm auto-stops on disconnect when enabled in settings; dashboard and notification state update immediately.
- Android: foreground-service-backed background monitoring, `BOOT_COMPLETED` recovery, notification with an in-line "Stop Alarm" action.
- iOS: `UIDevice` battery monitoring, local-notification + in-app looping audio alarm, explicit and honest limitation messaging for background behavior.
- Responsive Material 3 UI: distinct portrait and landscape/tablet layouts, light + dark themes, generated brand icon on both platforms.
- Full English + Bengali localization (~50 keys, natural Bengali wording, no hardcoded strings).
- 30+ unit tests: target validation, charging state machine (all specified edge cases), alarm trigger decision logic, settings persistence (including corrupted-value clamping), and an end-to-end `DashboardController` test against fake services.

### Known limitations
- **iOS background alerting** cannot fire once the OS has fully suspended/terminated the app process — this is an Apple platform restriction, not a bug. Documented in `README.md` and surfaced to the user in Settings.
- **Android OEM battery-optimization** on aggressive vendor skins (some MIUI/ColorOS/OneUI configurations) can still kill the foreground service despite correct implementation; users may need to manually exempt the app.
- **Alarm audio** currently resolves to system ringtone/alarm sounds rather than bundled custom sound assets (no bundled `.caf`/`.mp3` files ship yet — see `roadmap.md`).
- **App icon** is a programmatically generated brand mark (teal-to-navy gradient, lightning bolt), not a designer-produced asset.
- Native (Android/iOS) alarm notification text is currently hardcoded in English rather than reading from the Flutter ARB files, since native code doesn't share Dart's localization pipeline — the in-app Flutter UI itself is fully localized. Tracked in `roadmap.md`.

### Testing status
- **Unit tests:** written and believed correct; **not yet executed**, because this environment has no Flutter SDK installed (see `README.md` → Verification status). Run `flutter test` on a machine with Flutter installed before relying on this build.
- **Static analysis:** `flutter analyze` has not been run for the same reason.
- **Manual/device testing:** not performed. No emulator/simulator/physical device was available in the build environment.
