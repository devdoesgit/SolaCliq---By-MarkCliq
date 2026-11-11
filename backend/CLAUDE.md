# Backend

Rust API for SolaCliq. **Built by the owner.** Claude drafts the API spec in
`../api/openapi.yaml` and helps when asked, but does not write or change
backend code unless the owner asks.

Stack, API conventions and design patterns: `../docs/architecture.md`.
What to build first, and the rules the app relies on:
`../docs/backend-handoff.md`. The same work split into phases, each tested
before the next: `../docs/backend-phases.md`.

## Running it

```
make db          # local Postgres 17 in a container (dev only)
cp backend/.env.example backend/.env
make api         # migrates, then serves localhost:8080
make api-test    # fmt check, clippy -D warnings, tests
cargo run -- openapi   # (in backend/) print the generated spec
```

`GET /api/v1/health` answers 200, or 503 when the database is down;
interactive docs at `/api/docs`.

## Skeleton (set up by Claude, 2026-11-09; the owner builds from here)

- `src/main.rs`: config, tracing, Postgres pool, migrations at start,
  graceful shutdown on Ctrl-C/SIGTERM.
- `src/lib.rs`: `app(state)` builds the router (also used by tests): every
  route under `/api/v1`, request ids (`x-request-id`), 30 s timeout,
  request tracing, problem-JSON 404 fallback.
- `src/config.rs`: environment variables (`.env.example` lists them).
- `src/error.rs`: `ApiError` → RFC 9457 `Problem` with `code`; database
  errors are logged and returned as a plain 500.
- `src/routes/`: one module per area with a `router()`, merged in
  `routes/mod.rs`; handlers carry `#[utoipa::path]`.
- `src/openapi.rs`: generated spec and the Scalar docs page.
- `migrations/`: sqlx migrations (empty so far).
- `tests/`: router tests without a database; use `#[sqlx::test]` for
  database ones.

## Responsibilities

- REST API at `solacliq.markcliq.com/api/v1`, for both the mobile app and the
  admin website (bearer tokens and cookies on the same endpoints).
- Postgres: schema, migrations, row-level security per org.
- Auth: accounts, email verification, sessions and tokens, roles from
  memberships.
- Business rules: stages, approvals, referrals, location flags on captures.
  Rules live here so most fixes need no app update.
- R2: presigned upload and download URLs for the private bucket.
- GST verification API calls (keys stay on the server).
- Email through Google Workspace; push notifications; SMS later.
- OpenAPI spec generated with `utoipa`, served at `/api/docs`, checked in CI
  against `../api/openapi.yaml`.

## Modules

| Module | Feature |
|---|---|
| auth, users | F1 |
| orgs, gstin, platform approval | F2 |
| memberships | F3 |
| customers, stages, cost lines, payments | F4 |
| uploads, documents | F5 |
| jobs, captures | F6 |
| expenses, approvals | F7 |
| commissions | F8 |
| customer linking | F10 |
| referrals | F11 |
| notifications | F12 |
| org suspension, support access, audit log | F14 |
