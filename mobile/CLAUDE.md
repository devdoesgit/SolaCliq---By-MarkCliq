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

## Hot reload

From the official Flutter rules
(https://github.com/flutter/agent-plugins/tree/main/rules,
`flutter-hot-reload.md`).

After editing any `.dart` file under `mobile/lib/`:

- **Skip** edits outside `lib/` (`test/`, `integration_test/`, `benchmark/`,
  `test_driver/`, `example/`) and edits that only touch comments, docs or
  whitespace.
- **Connect:** find the running app with the Dart MCP server (`dtd`,
  `list_running_apps` or `vm_service`).
- **Hot reload** (`hot_reload`) straight after changing widgets, including
  `build` methods, or simple methods.
- **Hot restart** (`hot_restart`) after changing core logic, state
  initialisation (`initState`), global or static state, or `main()`.

## Screens by role

Shared: sign up (customers), log in, company picker and switcher (F3),
notifications, account tab.

Every home is a workspace, one `(company, role)` pair (see
`lib/workspace/`). Home tabs come from `lib/home/view/home_page.dart`; add
a feature's tab there when its feature is built, never as an empty
placeholder. Org admins get only a "use the website" screen.

In development, pick the mock person (personal, customer, worker, agent,
sales, multi_org, org_admin) in the workspace sheet (tap the avatar) under
Development, or run with `--dart-define=MOCK_PERSONA=<name>`. The same
section simulates an invite and a customer whose system is handed over
(live energy home).

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
