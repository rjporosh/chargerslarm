# ChargeAlarm — AI Development Prompt

You are the lead Flutter engineer responsible for building a real, portfolio-ready mobile application named **ChargeAlarm**.

Build the complete application from scratch according to `master-specification.md`. Do not create a fake/demo-only prototype. The final project must be clean, maintainable, production-minded, responsive, localized, documented, testable, and ready to showcase in a professional software-engineering portfolio.

## Core Product

ChargeAlarm monitors device charging and alerts the user when the configured battery percentage is reached.

Default alarm targets:

- 80%
- 100%

The user must also be able to configure any custom target percentage from **1%–100%**.

When the configured percentage is reached while charging:

1. Trigger a prominent notification/alarm.
2. Play the configured alarm sound using the maximum capability permitted by the operating system.
3. Clearly tell the user the battery percentage has been reached.
4. For 100%, recommend unplugging the charger.
5. Continue the supported alert behavior until charging stops/unplug occurs or the user dismisses/stops it.
6. Never claim unsupported background behavior on iOS.

The application must correctly handle charger connected, charging, full/reached-target, unplugged, and charging-state changes.

## Platform Strategy

Use **Flutter** for the shared application layer.

Use native platform implementations where required:

### Android
Implement real Android battery/charging monitoring using appropriate native APIs, BroadcastReceiver/Foreground Service/notification mechanisms, and modern Android background-execution rules.

The Android implementation must work when the screen is locked and the application is not visible, subject to Android/OEM restrictions.

### iOS
Use the real iOS battery APIs such as UIDevice battery monitoring/state notifications where applicable.

Respect Apple's background-execution restrictions.

Do NOT invent or simulate an unrestricted iOS background service.

If iOS cannot guarantee the exact Android behavior, implement the strongest officially supported behavior and document the limitation clearly in the project documentation.

## UI/UX

Create an exceptionally polished, modern, elegant, charming, professional, eye-catching UI.

The application must look like a real published product, not a tutorial project.

Requirements:

- Responsive on phones and tablets.
- Excellent portrait layout.
- Dedicated/adaptive landscape layout.
- Proper handling of small and large screens.
- No awkward empty areas.
- No excessive padding.
- No clipped widgets.
- No overflowing text.
- No unnecessary scrolling.
- No screen-width-specific hardcoded layouts.
- Use responsive/adaptive layout principles.
- Maintain visual hierarchy at every screen size.
- Support light and dark themes where appropriate.
- Smooth animations, but never sacrifice usability or performance.
- Consistent typography, spacing, icons, cards, controls and visual language.
- Accessible contrast and touch targets.
- Professional loading, empty, success, warning and error states.

Create a professional application icon/logo for ChargeAlarm and configure it correctly for supported platforms.

Do not use generic placeholder graphics in the final application.

## Localization

Implement complete localization from the beginning.

Languages:

- English
- Bengali (Bangla)

Every user-visible string must come from localization resources.

The user must be able to switch language from Settings.

Do not hardcode English/Bengali text directly inside UI widgets.

Use proper Bengali Unicode and natural Bengali wording.

## Main Features

### Dashboard

Show:

- Current battery percentage
- Charging status
- Current target percentage
- Progress toward target
- Charger connected/disconnected status
- Alarm status
- Quick target controls
- 80% target
- 100% target
- Custom target shortcut

### Alarm Targets

Support:

- 80%
- 100%
- Custom percentage

Custom percentage:

- Minimum: 1%
- Maximum: 100%
- Validate invalid values.
- Prevent impossible/meaningless states.
- Allow changing the target at any time.

### Alarm Settings

Allow the user to configure:

- Enable/disable alarm
- Target percentage
- Default alarm sound
- User-selected supported sound/audio where platform rules permit
- Alarm volume behavior where platform APIs permit
- Vibration where supported
- Notification behavior
- Auto-stop behavior
- Language

Clearly distinguish between features guaranteed by the platform and platform-dependent features.

### 100% Behavior

When battery reaches 100% while charging:

Show a clear message equivalent to:

"Battery Full — Please Unplug the Charger"

The exact wording must come from localization resources.

### Unplug Behavior

When the charger is disconnected:

- Stop active charging alarm behavior where platform capability permits.
- Update dashboard state immediately.
- Update notification state appropriately.
- Do not repeatedly trigger the same alarm after unplugging.

### Edge Cases

Handle:

- App launched while already charging.
- App launched when battery is already above target.
- Charger connected below target.
- Charger connected above target.
- Battery reaches target very quickly.
- Battery reaches 100%.
- Charger unplugged before target.
- Charger unplugged after target.
- Reconnecting charger.
- Target changed while charging.
- Device reboot where supported.
- App process killed.
- Screen locked.
- Dark mode.
- Rotation/orientation changes.
- Low-memory/process lifecycle situations.
- Android OEM background restrictions.
- iOS background limitations.

## Architecture

Use clean, maintainable Flutter architecture.

Prefer:

- Feature-oriented structure
- Clear separation of presentation/domain/data/platform layers
- Dependency injection where useful
- Repository/service abstractions
- Platform interface abstraction
- Strong typing
- Small focused classes
- Testable business logic

Do not over-engineer a tiny app.

Avoid unnecessary dependencies.

Use stable, actively maintained packages only when they provide real value.

Keep platform-specific code isolated.

## State Management

Choose a lightweight, professional state-management solution appropriate for this application's size.

Do not introduce unnecessary architectural complexity.

The selected approach must be:

- predictable
- testable
- maintainable
- easy for another engineer to understand

Document the decision.

## Persistence

Persist user settings locally.

At minimum persist:

- Language
- Alarm enabled/disabled
- Target percentage
- Sound selection
- Vibration preference
- Relevant notification/alarm preferences

The app must work offline.

No backend is required.

No user account is required.

No analytics or tracking should be added unless explicitly required.

## Permissions

Request only permissions genuinely required by each platform.

Explain permissions to the user when appropriate.

Do not request unnecessary permissions.

## Testing

Create meaningful tests for:

- Target percentage validation
- Battery-state transitions
- Charging-state transitions
- Alarm trigger logic
- Alarm stop logic
- Settings persistence
- Localization
- Important platform-independent business rules

Run:

- `flutter analyze`
- `flutter test`

Fix all relevant errors and warnings before declaring completion.

Build/check Android and iOS configurations as far as the available environment permits.

## Git Requirements

Initialize/configure Git professionally.

Every meaningful milestone/phase must have a professional commit.

Commit messages must describe the actual engineering work.

Use this Git author identity for ALL commits:

Name:
MD IKRAMUL ISLAM SIDDIQUE POROSH

Email:
poroshScientist@outlook.com

Do NOT use:

- ChatGPT
- Claude
- OpenAI
- Anthropic
- AI Agent
- Assistant
- Any AI-generated author identity

Do not add AI co-authors or AI attribution to commits.

Do not put AI-agent names in commit messages.

Create a clean, meaningful Git history showing the actual evolution of the project.

Before final delivery:

- Verify Git author information.
- Verify commit history.
- Ensure no AI author/co-author appears in Git history.
- Ensure no accidental secrets/API keys are committed.
- Include `.gitignore`.

## Documentation

Maintain:

- `README.md`
- `ai-handover.md`
- `release-notes.md`
- `roadmap.md`
- `master-specification.md`

README must explain:

- Product purpose
- Features
- Supported platforms
- Architecture
- Setup
- Run/build instructions
- Localization
- Platform limitations
- Testing
- Screenshots/placeholders section where appropriate
- Portfolio-ready feature summary

## Critical Context/Token Handover Rule

If your available context/token budget is becoming insufficient to safely continue the implementation, STOP before starting another large task.

Before stopping, update all three:

### `ai-handover.md`

Document:

- What was completed
- What was changed
- What remains
- Current project state
- Current known issues
- Bugs encountered
- Root cause of each important bug
- Exact fix applied
- Why the chosen solution is appropriate
- Important alternatives considered
- Tradeoffs
- Next exact steps
- Commands that should be run next
- Important files/classes changed
- Git status
- Last successful milestone/commit

### `release-notes.md`

Document:

- Completed features
- User-visible improvements
- Bug fixes
- Platform-specific changes
- Known limitations
- Testing status

### `roadmap.md`

Update:

- Completed milestones
- Current milestone
- Remaining milestones
- Known technical debt
- Future improvements

Never leave the project in an undocumented half-finished state when context is running out.

## Final Delivery

At completion:

1. Finish implementation.
2. Run analysis/tests.
3. Fix important issues.
4. Verify localization.
5. Verify responsive layouts.
6. Verify Git history.
7. Verify Git author identity.
8. Update README.
9. Update release-notes.md.
10. Update roadmap.md.
11. Update ai-handover.md with final state.
12. Review the entire repository for unnecessary files, secrets, debug code and dead code.
13. Create a clean final Git commit.
14. Create a ZIP archive containing the complete project INCLUDING the `.git` directory and complete Git history.
15. Return the final ZIP archive.

The ZIP must preserve the complete Git repository/history.

Do not merely provide source files. Deliver the complete project repository.

## Engineering Standard

Think like a senior production Flutter engineer.

Do not optimize for "looks completed."

Optimize for:

- correctness
- maintainability
- platform realism
- responsive UX
- accessibility
- clean architecture
- reliable battery-state handling
- professional Git history
- documentation
- portfolio quality

If an operating-system limitation prevents a requested behavior, implement the strongest legitimate solution and document the limitation rather than creating a fake implementation.

Start by reading `master-specification.md`, inspect the environment, establish the project structure, then implement milestone by milestone.