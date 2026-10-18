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
- Brand: matches markcliq.com (see `../CLAUDE.md`). Theme, tokens, fonts
  and widgets live in `packages/sola_ui`; screens use its widgets and
  tokens, never raw colours, sizes or `TextStyle`s.

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

Shared: sign up (customers), log in, org switcher, notifications, profile.

| Role | Screens | Feature |
|---|---|---|
| Worker | My jobs, job detail (customer, address, directions) | F6 |
| Worker | Installation capture (camera + GPS) | F6 |
| Worker | My expenses, log expense with receipt | F7 |
| Agent | My customers | F4/F10 |
| Agent | My expenses, log expense | F7 |
| Agent | My commission, enter commission | F8 |
| Agent | Share referral link | F11 |
| Customer | My installation: stage timeline | F9 |
| Customer | Cost breakdown, payments made | F9 |
| Customer | Share referral link | F11 |

Not settled (see `../questioner.md`): whether agents add leads in the app,
and whether customers see their documents and installation photos.
