# Mobile app

Flutter app for **workers, agents and customers**. Android first. **Built by
Claude.** Org admins and the platform admin do not use this app; they use the
admin website (`../admin`).

Stack, distribution, updates and tooling: `../docs/architecture.md`.

## Rules

- Talk to the backend only through the Dart client generated from
  `../api/openapi.yaml`. Never hand-write API calls.
- Every interactive widget gets a `Key` and a Semantics label.
- Photos for installation proof come from the live camera only, never the
  gallery, with GPS, accuracy and time recorded at capture.
- Writes carry an `Idempotency-Key`.
- Money is integer paise; format only for display.
- Brand: the iOS v2 design (see `../CLAUDE.md`). Theme, tokens, fonts,
  icons, photos and widgets live in `packages/sola_ui`; screens use its
  widgets and tokens, never raw colours, sizes or `TextStyle`s.
- Every screen meets the tap target (48px), label and WCAG AA contrast
  guidelines; `test/app/accessibility_test.dart` checks them. Add new
  screens to it.

## Skills

- **dart-flutter** (official, user scope): Dart MCP server plus skills for
  tests, layout fixes, routing, architecture.
- **vgv-ai-flutter-plugin** (Very Good Ventures, project scope): skills for
  accessibility, theming, animations, testing and goldens, navigation,
  security, UI packages; a `flutter-reviewer` agent. Its hooks run
  `dart analyze` and `dart format` on every edited `.dart` file, and block
  `flutter create` and `flutter test` in the shell: use the Very Good CLI MCP
  tools instead. Its advice is opinionated (Bloc, mocktail, GoRouter,
  `very_good_analysis`); where it conflicts with the design system or a
  decision in `../docs/decisions.md`, those win.
- **design-polish** (project skill, `.claude/skills/`): visual polish pass per
  screen against the design system, with an evaluator sub-agent.

## Emulator

`emulator -avd solacliq_play -gpu host -no-boot-anim`: GPU rendering
only, never software (`swiftshader`), which hangs the machine. The AVD
always cold-boots (snapshots off in its `config.ini`).

Known emulator faults on this machine (NVIDIA, Wayland), 2026-11-17:

- The host OpenGL translator loses its context and crashes the
  emulator when an app's surfaces are torn down: restoring a snapshot,
  or uninstalling the app (which `flutter drive` does at the end of a
  run). Core dumps: `coredumpctl info <pid>`, `TextureResize`.
- Guest ANGLE (`-feature GuestAngle`, Vulkan) avoids that crash but
  draws Flutter's Impeller with corrupted frames. Not to be used.
- **Memory.** The machine has 15 GB and froze twice on 2026-11-17 when
  it ran out (88% and 97% used; swap is compressed RAM, so it thrashes
  instead of killing anything). The emulator plus Gradle's daemons plus
  a full Rust test build is too much at once. So: never run the
  emulator together with `make api-test` or another heavy build; stop
  Gradle's daemons after an Android build (`pkill -f '[G]radleDaemon';
  pkill -f '[K]otlinCompileDaemon'`); build Rust with
  `CARGO_BUILD_JOBS=4` while the emulator is up.
- `solacliq_play` (Android 16, Google Play image) is the one to use:
  its Play services checks in, so it gets push tokens. The older
  `solacliq_phone` (`google_apis`) fails check-in
  (`AUTHENTICATION_FAILED`) and never gets one.
- `make app-e2e` keeps the app installed (`--keep-app-running`), which
  avoids the uninstall crash. Typing with `adb shell input text` can
  drop the first key after a field gains focus: wait a second first.

## Push notifications

The Android build needs `android/app/google-services.json` (git-ignored):
`cp ~/Desktop/solacliq-google-services.json mobile/android/app/google-services.json`.
The `main_*` files pass `FirebasePushMessaging`; tests get none
(`lib/push/`).

## Flow tests

`make app-e2e` (API and emulator running) seeds the local API, then
drives each role's main flow in the real app (`integration_test/`).
The whole lifecycle through the API is `backend/tests/lifecycle.rs`.

## Hot reload

When the app is running, after editing `mobile/lib/` code (not tests or
comments): connect with the Dart MCP server (`dtd`), then `hot_reload`
for widget changes or `hot_restart` for state, `initState` or `main()`.

## Screens by role

Shared: sign up (customers), log in, company registration ("I run a
solar EPC company", F2), company picker and switcher (F3), notifications,
account tab, the message for a pending, suspended or rejected company.

Every home is a workspace, one `(company, role)` pair (see
`lib/workspace/`). Home tabs come from `lib/home/view/home_page.dart`; add
a feature's tab there when its feature is built, never as an empty
placeholder. Org admins get only a "use the website" screen.

In development, pick the mock person (personal, customer, worker, agent,
sales, multi_org, org_admin) in the workspace sheet (tap the avatar) under
Development, or run with `--dart-define=MOCK_PERSONA=<name>`. The same
section simulates a customer whose system is handed over (live energy
home).

**Quick forms** (development only, on by default): submitting a form with
nothing typed fills every blank with an illustrative sample and every
choice with a default, so you can walk all the screens against the mock.
Switch it in the same Development section, or start with
`--dart-define=QUICK_FORMS=false` to test validation. Production never
has it (`lib/app/dev/quick_forms.dart`).

| Role | Screens | Feature |
|---|---|---|
| Worker | Home, tasks (today, upcoming, done), task (every status), history (built) | F6 |
| Worker | Proof camera (live camera + GPS), report a problem (built) | F6 |
| Worker | My expenses, expense detail, log expense with receipt and task (built) | F7 |
| Worker | Notifications, profile, personal details, ID documents, bank (built) | F12 |
| Sales | Home, customers (filter, search), customer, fix a returned document (built) | F4 |
| Sales | Add customer with commission (commission pay type) (built) | F4/F8 |
| Sales | Earnings, payout bank (commission) or Alerts tab (salary) (built) | F8 |
| Customer | Home, track install, payments (UPI or bank, claim), documents (built) | F9 |
| Everyone | Profile, settings, help sheet, workspaces; Personal: Learn, notifications (built) | F1/F12 |
| Sales, Customer | Share referral link | F11 |

Not settled (see `../questioner.md`): whether customers see their documents
and installation photos.
