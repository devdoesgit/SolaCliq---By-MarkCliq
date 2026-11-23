# Backend

Rust API (Axum + sqlx + Postgres) at `solacliq.markcliq.com/api/v1`, for
the app (bearer tokens) and the website (cookies) on the same endpoints.
Written by Claude, reviewed by the owner: ship fast, but clean, tested,
and commented in the owner's style (multi-line comments in `/* */`).

Work list and rules: `../docs/backend-handoff.md`; phases and status:
`../docs/backend-phases.md`; conventions: `../docs/architecture.md`.

## Running it

```
make db          # local Postgres 17 (rootless podman; rerun if it stops)
cp backend/.env.example backend/.env
make api         # migrates, then serves localhost:8080 (docs at /api/docs)
make api-test    # fmt check, clippy -D warnings, tests
cargo run -- openapi                     # (in backend/) the generated spec
cargo run -- seed                        # illustrative data, APP_ENV=development only
cargo run -- make-platform-admin <email>
cargo run -- send-test-email <to>        # checks the Gmail API setup
cargo run -- send-test-push <token>      # checks the Firebase (push) setup
```

## Rules

- Every `/orgs/{org_id}/...` handler takes `OrgMember<Roles>`; every
  `/platform/...` handler takes `PlatformAdmin` (`src/org.rs`).
- Queries on `orgs`, `memberships`, `notifications` and every company
  table run in a scoped transaction: `member.begin()`, `user.begin()`
  or `admin.begin()` (`src/scope.rs`). The server's login is restricted
  by row-level security, so a query outside one sees nothing. A new
  company table enables RLS with a company policy in its migration.
- Errors are `ApiError` with a contract code (`<area>.<reason>`);
  database errors become a plain 500.
- Queries are runtime `sqlx::query` with binds, and fixed strings (sqlx
  refuses SQL built at run time; see `select_org!` in `platform.rs`).
- Until the first deploy (phase 5) there's no real database: change the
  migrations freely and reset the local one (`podman rm -f solacliq-pg;
  podman volume rm solacliq-pgdata; make db; cargo run -- seed`). After
  it, never edit a migration that has run (sqlx checks a checksum); add a
  new one, and give a new enum value its own migration before anything
  uses it.
- Emails go through `state.mailer` after the transaction commits.
- App writes marked *idem* take `IdempotencyKey` and follow the pattern
  in `idempotency.rs`.
- Lists page with `page.rs` (`?cursor=&limit=`, newest first).
- Env: `.env.example` lists every variable; `APP_ENV` unset = production.

## Layout

- `src/main.rs`: commands (serve, `openapi`, `seed`,
  `make-platform-admin`, `send-test-email`, `send-test-push`),
  migrations at start, the push worker,
  graceful shutdown (queued emails sent first).
- `src/lib.rs`: `AppState` and `app(state)`, the router tests also use.
- `src/routes/`: `health`, `auth` (F1), `me`, `team` (F3),
  `registration` and `platform` (F2), `quotes` and `profile` (phase 6),
  `home`, `notifications` and `uploads` (phase 7), `tasks` and
  `expenses` (phase 8), `customers` (phase 9: registration, my
  customers, documents), `install` (phase 10), `admin` (the
  company's actions for the website), `admin_site` (what the website
  reads, price, stage, settings), `attendance` (F17), `logo` (F15),
  `stages` (F19), `leads` (F20, with the public `POST /leads`); merged in
  `routes/mod.rs`.
- `src/stages.rs`: a company's 7 stage names and templates
  (`stages::load` reads the scope's company); use it wherever a stage
  is named, never a fixed list.
- `src/origin.rs`: cross-site writes refused. `src/signup.rs`: code-first
  sign-up. `src/account.rs`: account deletion. `src/retention.rs`: KYC
  retention (F18).
- `src/scope.rs`: the row-level security scopes and the startup check.
- `src/storage.rs`: signed R2 URLs (uploads and reads), and the
  server's own HEAD and DELETE.
- `src/org.rs`: role, pay type, status and business type enums
  (`sqlx::Type`), `OrgMember`, `PlatformAdmin`.
- `src/session.rs`, `src/codes.rs`, `src/password.rs`: tokens, email
  codes, Argon2. `src/mail.rs`: the `Mailer` trait;
  `src/mail/gmail.rs`: the Gmail API mailer.
- `src/gstin.rs`, `src/validate.rs`, `src/page.rs`: shared checks and
  paging. `src/counter.rs`: per-company references (EXP-0001). `src/idempotency.rs`, `src/notify.rs` (notifications),
  `src/bank.rs` (encryption, bank names). `src/seed.rs`: the seed and platform-admin commands.
  `src/terms.rs`: the terms version and agreements (F16).
  `src/india.rs`: Indian time (today's date, midnight in UTC); use it
  for every date a person sees.
- `tests/`: one file per area; helpers in `tests/common/mod.rs`.
