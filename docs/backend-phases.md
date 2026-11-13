# Backend phases

The backend work list (`backend-handoff.md`) split into small phases. Each
phase is built, tested and working in the app before the next starts.
Exact request and response shapes are in `../api/openapi.yaml`; the rules
behind each endpoint are in `backend-handoff.md` (numbers like #5 refer to
its tables).

Written 2026-11-09. The month ends 2026-11-18, so phases 1–5 are the
must-haves for a pilot; the role phases (7–9) go in the order the pilot
vendor needs them.

## How to test every phase

1. **Rust tests** (`cargo test`): `#[sqlx::test]` gives each test its own
   empty database with migrations applied. Call the router with
   `app(state).oneshot(request)` as in `backend/tests/health.rs`.
2. **By hand** (`curl` or the docs page at `localhost:8080/api/docs`).
3. **In the app**: run it against the real API instead of the mock:
   `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`
   (10.0.2.2 is the computer, seen from the Android emulator). A phase is
   done when its screens work unchanged.

## Status

| Phase | What | Endpoints | Status |
|---|---|---|---|
| 0 | Skeleton | `GET /health` | Done |
| 1 | First table: sign up | #2 | Built and tested 2026-11-09; in-app check to do |
| 2 | Log in and `/me` | #5, #10 | Done 2026-11-09 (app logs in) |
| 3 | Email codes, refresh, log out | #3, #4, #6–9 | 3a (refresh, log out) done 2026-11-11; 3b (codes) to do |
| 4 | Companies and memberships | `/me` memberships, team endpoints, seed command | |
| 5 | First deploy | — | |
| 6 | Personal workspace | #11–20 | |
| 7 | Shared company plumbing | #21–24 | |
| 8 | Worker | #25–38 | |
| 9 | Sales | #39–42 | |
| 10 | Customer | #43–44 | |

## Phase 1. First table: sign up

The first real round trip: a migration, an insert, a JSON body in, a
status code out.

- **Build:** a `users` migration (id UUIDv7, email unique and lowercased,
  name, password hash, `email_verified_at`, timestamps). `POST /auth/signup`
  hashes the password with `argon2` and inserts the user. Always 202, even
  if the email exists. Rejects a weak password with 422
  `auth.password_too_weak`.
- **Learn:** migrations, `sqlx::query(...).bind(...)`, the `ApiJson<T>`
  extractor, `serde::Deserialize`, returning `ApiError`.
- **Notes (as built):** files `migrations/20261109000001_users.sql`,
  `src/routes/auth.rs`, `src/password.rs`, `src/extract.rs`,
  `tests/signup.rs`. Queries are checked at run time (`sqlx::query`), not
  compile time (`sqlx::query!`), so a new migration never blocks the build;
  switch later with `cargo sqlx prepare` if wanted. No email and no 429
  yet: both arrive in phase 3 (the log says which email would go).
- **Test:** signing up creates one row; signing up twice still returns
  202 and doesn't create a second; a short password is 422 with the code.
- **Done when:** the app's sign-up screen gets past "Create account".
  (The code screen comes in phase 3.)

## Phase 2. Log in and `/me`

- **Build:** `POST /auth/login` checks the hash and returns
  `LoginResponse` (short-lived access token, long-lived refresh token).
  Store refresh tokens hashed in a `sessions` table. An `AuthUser`
  extractor reads `Authorization: Bearer` and rejects a missing or bad
  token with 401. `GET /me` returns the user with empty `memberships`.
  Until phase 3, mark accounts verified by hand in SQL.
- **Learn:** writing your own extractor (`FromRequestParts`), JWT or
  random opaque tokens (your choice), `Option` and `?` for errors.
- **Test:** wrong password is 401 `auth.invalid_credentials`; unverified
  is 403 `account.email_unverified`; `/me` without a token is 401, with
  one returns the user.
- **Done when:** the app logs in and lands on the Personal workspace.
- **Notes (as built):** opaque tokens, not JWTs: 32 random bytes, only
  the SHA-256 stored (`sessions` table, `src/session.rs`). Access 15
  minutes, refresh 30 days, web cookie 12 hours. `AuthUser` in
  `src/extract.rs` takes a bearer token or the `solacliq_session` cookie;
  a missing, expired or revoked one is 401 `auth.unauthenticated`, which
  makes the app refresh (phase 3) and retry. Unknown emails are checked
  against a dummy hash so they take as long as a wrong password.
  `COOKIE_SECURE=false` only for local HTTP. Tests: `tests/login.rs`.

## Phase 3. Email codes, refresh, log out

- **Build:** 6-digit codes (hashed, 5 minutes, 5 tries) for verify (#3),
  resend (#4), forgot and reset (#8, #9). Refresh follows OAuth 2.1 for
  the app and the website alike: each refresh returns a new access and
  refresh token, the old refresh token dies, and reusing it revokes the
  session (#6). The website gets a refresh cookie scoped to
  `/auth/refresh`, replacing the 12-hour cookie. Log out revokes (#7).
  Email behind a small `Mailer` trait: prints to the log in development,
  sends through Google Workspace SMTP in production.
- **Learn:** traits (the `Mailer`), transactions (`db.begin()`),
  `chrono` for expiry.
- **Test:** expired and wrong codes give the right codes; the sixth try
  is 429; reset revokes sessions; refresh reuse logs the family out.
- **Done when:** sign-up → code → login and forgot password both work in
  the app, with the code read from the server log.
- **Notes (as built, 3a, 2026-11-11):** migration
  `20261111000001_session_refresh.sql` makes every session carry a
  refresh token (old web-only rows are deleted) and adds
  `previous_refresh_hash` and `revoked_reason`. `session::rotate` checks
  and swaps both tokens in one `UPDATE`, so two refreshes with the same
  token can't both win; the loser counts as reuse and revokes the session.
  The refresh expiry moves forward on every refresh. `POST /auth/refresh`
  takes the token from the JSON body (app, 200 `TokenPair`) or the
  `solacliq_refresh` cookie (website, 204 and new cookies); `POST
  /auth/logout` revokes and clears both cookies. `WEB_SESSION_HOURS` is
  gone. Tests: `tests/refresh.rs` (7). Checked in the app with
  `ACCESS_TOKEN_MINUTES=1`: still logged in after the access token
  expired; log out revokes the session. The admin website refreshes on a
  401 (`admin/src/api/refresh.ts`).

## Phase 4. Companies and memberships

Everything after this is per company.

- **Build:** `orgs` and `memberships (user, org, role, pay_type)` tables,
  `/me` returns memberships as in #10. An `OrgMember` extractor for
  `/orgs/{org_id}/...` that loads the caller's role and returns 403 when
  they aren't a member or have the wrong role. Row-level security on
  org-owned tables. A seed command (`cargo run -- seed`) that creates an
  illustrative company with one person per role. The admin website's
  team endpoints (members list, add, remove).
- **Learn:** enums in Postgres and Rust (`sqlx::Type`), path extractors
  (`Path<Uuid>`), RLS with `set_config` per request.
- **Test:** a worker can't call an agent's endpoint (403); a member of
  org A can't read org B (403, and RLS returns no rows even if a check is
  missed).
- **Done when:** a seeded worker, agent and customer each log in and see
  their workspace in the app; the website's Team page works.

## Phase 5. First deploy

Put it on the VPS early so the pilot can test on real phones.

- **Build:** release build, a `systemd` service, nginx proxying
  `solacliq.markcliq.com/api` to it, production `.env` on the server only,
  daily Postgres backup. CI: `cargo test`, clippy, and the spec check
  (`cargo run -- openapi` against `api/openapi.yaml`).
- **Done when:** the app, built with the production URL, logs in on a
  real phone.

## Phase 6. Personal workspace (#11–20)

Access and quote requests, invites (accept creates a membership), personal
notifications, details (bank number encrypted, only last 4 returned),
settings with defaults.

- **Done when:** the Personal workspace's screens all work, and accepting
  an invite opens the company's workspace.

## Phase 7. Shared company plumbing (#21–24)

`GET /orgs/{org_id}/home` composed per role (see "Home" in the handoff),
`POST /uploads` with presigned R2 URLs, company notifications and mark
read.

- **Done when:** each role's home loads, and a test upload reaches R2.

## Phases 8–10. Worker, Sales, Customer

One role at a time, in the order the pilot vendor needs them. Each needs
its admin-side data seeded (see "Not in the contract yet" in the
handoff): tasks for workers, approvals for sales, an install for
customers.

- **8 Worker (#25–38):** tasks, photos with location flags, checklist,
  submit, problems, history, stats, expenses, documents.
- **9 Sales (#39–42):** customer registration, my customers, fixing a
  returned document.
- **10 Customer (#43–44):** my install and claiming a payment.
- **Done when:** that role can do a full day's work in the app against
  the real API.
