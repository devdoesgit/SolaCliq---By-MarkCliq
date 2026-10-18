# F0 Foundation

Status: `building`. Spec approved by the owner on 2026-10-18.

## Goal

Empty but working mobile and admin apps that share one API contract and one
set of design tokens, with tests and CI, so F1 starts on screens rather than
setup.

## Users

None directly. Builders only: the owner (backend) and Claude (mobile, admin).

## In scope

**Repo**
- Root `Makefile`: `make tokens`, `make gen`, `make mock`, `make test`,
  `make lint`.
- `.gitignore` for Flutter, Node, Rust and editor files (replaces the Next.js
  template).
- `design/tokens.json`: a copy of the design system's tokens, the single
  source for both apps. `make tokens` generates
  `mobile/lib/theme/tokens.g.dart` and `admin/src/styles/tokens.css` from it
  (small Node script, `tools/tokens.mjs`). Generated files are committed and
  never edited by hand.

**API contract** (`api/openapi.yaml`)
- Info, server `/api/v1`, the two auth schemes (bearer for mobile, cookie for
  admin), shared components: `Problem` (RFC 9457), `Cursor` and `Limit`
  parameters, `Money` (integer paise), `Id` (UUIDv7), `Timestamp` (ISO 8601
  UTC), `Idempotency-Key` header.
- One endpoint: `GET /health`, no auth, returns `{ "status", "version",
  "database" }`: `ok`/`ok` with 200, or `degraded`/`unavailable` with 503
  when the database can't be reached. Lets both apps and CI check the client, the mock and
  (once the owner builds it) the real server end to end.
- Lint with Spectral (`make lint`).
- `make mock`: Prism serves the spec on `localhost:4010`.
- `make gen`: Dart client into `mobile/packages/api_client` (OpenAPI
  Generator, `dart-dio`, runs on the JDK 21 already installed) and
  TypeScript types into `admin/src/api/schema.d.ts` (`openapi-typescript`,
  used with `openapi-fetch`).

**Mobile** (`mobile/`)
- Created with Very Good CLI's `flutter_app` template. Package
  `com.markcliq.solacliq`, app name "SolaCliq". The name may change: it lives
  in one place per app (mobile: flavor config and the ARB file; admin: one
  config module), never hard-coded in widgets. Android first; the iOS folder
  stays but isn't built.
- Flavors: `development` (talks to the Prism mock or a local backend),
  `staging`, `production` (`solacliq.markcliq.com`).
- State: Bloc/Cubit. Every Bloc, subscription, controller and timer is
  closed or disposed; no leaks. Routing: `go_router`. Lints: `very_good_analysis`.
  Tests: `flutter_test`, `bloc_test`, `mocktail`, golden tests.
- Layout, VGV layered: `lib/app/`, `lib/theme/`, `lib/<feature>/` per
  feature; `packages/api_client` (generated); `packages/sola_ui` for the
  design-system widgets.
- Theme from the tokens: `ThemeData` with no `fontFamily`, no shadows or
  elevation, radius 0/2, plus a `ThemeExtension` for status colours,
  spacing and the mono text styles.
- `sola_ui` widgets for the seven design-system components: Button,
  TextField, StatusPill, StageTracker, ListRow, Amount, Notice. Each has a
  `Key` and `Semantics` label parameter, a widget test and a golden test.
- `formatPaise` (Indian grouping, `₹1,85,000.00`, minus sign for negatives)
  and `formatDate` (`18 Oct 2026`, `18 Oct 2026, 14:05`), with unit tests.
- One screen: a component gallery reached only in the `development` flavor,
  showing every component with data labelled "Illustrative", plus a line that
  calls `GET /health` and shows the result.
- English strings in one ARB file (the template's l10n setup), so text isn't
  scattered through widgets. No translations.

**Admin** (`admin/`)
- Vite + React + TypeScript, static build. React Router; TanStack Query with
  `openapi-fetch`. Plain CSS with the generated token variables (no CSS
  framework).
- The same seven components, matching the design system's `bundle.css`, with
  focus rings and the 36px admin control size.
- One page: the same component gallery and health check, in dev builds only.
- Vitest + Testing Library for components and formatters; ESLint and
  Prettier.

**CI** (GitHub Actions, on push and pull request)
- Spec: Spectral lint.
- Tokens and clients: `make tokens` and `make gen` leave no diff (generated
  files are up to date).
- Mobile: format, analyze, tests (including goldens), debug APK build.
- Admin: lint, typecheck, tests, build.
- The backend job is the owner's to add.

## Out of scope

- Any real feature screen (login is F1).
- Backend code (owner).
- Shorebird, release signing, the updater, the download page (F13).
- iOS builds, dark theme, icons, logo, translations.
- Sentry, `drift`, feature flags (still undecided).

## API

- `GET /api/v1/health` (no auth) → `200 { status: ok, version, database:
  ok }`, or `503` with `status: degraded, database: unavailable`.

## Screens

- Mobile: component gallery (development flavor only).
- Admin: component gallery (dev builds only).

## Data

None.

## Acceptance

1. `make lint`, `make test` and CI pass on a clean clone.
2. `make mock` serves the spec; the mobile gallery (on `solacliq_phone`) and
   the admin gallery both show "ok" from `GET /health` through their
   generated clients.
3. Changing a colour in `design/tokens.json` and running `make tokens`
   changes both apps; CI fails if it wasn't run.
4. Every component renders in both galleries to match the design system
   previews; golden tests capture the mobile versions.
5. On the emulator, every interactive gallery widget is found by its label
   through mobile-mcp, and taps are at least 48dp.
6. `formatPaise` and `formatDate` tests cover zero, negatives, lakhs and
   crores, and times.
7. A design-polish pass on the mobile gallery reaches PASS.

## Answers from the owner (2026-10-18)

1. Package ID `com.markcliq.solacliq` for now. The name may change; it is
   only locked once an APK reaches real phones (F13), so ask again then.
2. Bloc/Cubit. Code clean, reusable and free of memory leaks.
3. CI on GitHub Actions in `devdoesgit/SolaCliq---By-MarkCliq`.
4. `/health` reports database status.

## Notes

- 2026-10-18: theme switched to match markcliq.com in both apps (fonts
  included); see decisions.md. Tokens moved into the repo as
  `design/tokens.json` v2; the design-system artifact is now out of date.
- Generated Dart tokens live in `mobile/packages/sola_ui` (not
  `mobile/lib/theme`), next to the widgets that use them.
- The VGV template pinned Kotlin 2.2.10; raised to 2.2.21 (Flutter 3.47
  needs ≥ 2.2.20). Gradle heap capped at 3 GB after a PC freeze.
- json_serializable output needs Dart ≥ 3.8; `make gen-dart` raises the
  generated client's SDK constraint.
- Done: tokens, contract, Dart and TS clients, `sola_ui` (40 tests incl.
  goldens with real fonts), mobile shell (19 tests, runs on the emulator
  against Prism), admin shell (23 tests, builds, checked in Chrome at
  desktop and phone width). Left: CI, design-polish pass.
