# Backend phases

The backend work list (`backend-handoff.md`, whose numbers like #5 this
page uses) in small phases. Each phase is built, tested and working in
the app before the next. Shapes are in `../api/openapi.yaml`.

The month ends 2026-11-18: phases 1–5 are the must-haves for the pilot;
the role phases (8–10) go in the order the pilot vendor needs them.

## How a phase is tested

1. `make api-test`: fmt, clippy `-D warnings`, `cargo test`. Tests call
   `app(state)` directly; `#[sqlx::test]` gives each test an empty
   database (needs `make db`). Helpers: `backend/tests/common/mod.rs`.
2. By hand: `make api`, then `curl` or `localhost:8080/api/docs`.
   `cargo run -- seed` gives illustrative people (password `sunlight1`).
3. In the app, against the real API:
   `flutter run --flavor development -t lib/main_development.dart
   --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.
   A phase is done when its screens work unchanged.

## Status

| Phase | What | Endpoints | Status |
|---|---|---|---|
| 0 | Skeleton | `GET /health` | Done |
| 1 | Sign up | #2 | Done 2026-11-09 |
| 2 | Log in and `/me` | #5, #10 | Done 2026-11-09 |
| 3 | Email codes, refresh, log out | #3, #4, #6–9 | Done 2026-11-14 |
| 4 | Companies, memberships, team; company registration and review (F2) | #10, #11, team, platform | Done 2026-11-14 |
| 5 | First deploy | — | After the app's flows (decided 2026-11-15) |
| 6 | Personal workspace | #12, #16–20 | Done 2026-11-15 |
| 7 | Push notifications; shared company plumbing, row-level security | devices, #21–24 | Building: home (#21), company notifications (#23–24) and row-level security (restricted login; orgs, memberships, notifications) and uploads (#22, a real photo through R2) done 2026-11-16; push waits for Firebase |
| 8 | Worker | #25–38 | |
| 9 | Sales | #39–42 | |
| 10 | Customer | #43–44 | |

## Done: what each phase left behind

- **1–2.** `users`, `sessions`. Passwords: Argon2. Tokens: 32 random
  bytes, only their SHA-256 stored; access 15 min, refresh 30 days
  (`ACCESS_TOKEN_MINUTES`, `REFRESH_TOKEN_DAYS`). `AuthUser` takes a
  bearer token or the `solacliq_session` cookie. Unknown emails take as
  long as a wrong password. Runtime queries (`sqlx::query`), not `query!`.
- **3.** OAuth 2.1 refresh rotation for app and website alike; reusing an
  old refresh token revokes the session. `email_codes`: one per account
  and purpose, an HMAC of the code (`CODE_SECRET`), 5 minutes, 5 tries,
  one per minute. Reset revokes every session and verifies the email.
  `Mailer` trait; development uses `LogMailer` (codes in the server log).
  Known minor gaps: 405 has an empty body, an oversized body is 422 not
  413, refresh with malformed JSON is 401 not 422.
- **4.** `orgs`, `memberships` (Postgres enums; one role per person per
  company; one admin per company; `pay_type` only for agents; soft delete
  with `removed_at`). `OrgMember<Roles>` guards every `/orgs/{org_id}/...`
  handler: 403 `org.not_member`, `org.pending`, `org.suspended`,
  `org.rejected`, `org.role_not_allowed`. Team endpoints. Company
  registration (`POST /org-registrations`: GSTIN checksum, PAN and state
  from it; saved pending with its owner as `org_admin`; MarkCliq emailed
  at `REVIEW_EMAIL`) and review (`/platform/orgs`, `PlatformAdmin`;
  approve, reject with a note, suspend, reactivate). `APP_ENV`, the seed
  and `make-platform-admin`. Checked in the app: companies, the suspended
  message, the registration form (state from the GSTIN).
- **6.** Quote requests: saved with a general estimate (figures in
  `routes/quotes.rs`), emailed to `REVIEW_EMAIL`, a `quote_shared`
  notification. Idempotency keys for app writes (`idempotency.rs`; a
  retry or a race with one key does the work once). Details with the
  bank number encrypted (AES-256-GCM, `BANK_KEY`; last 4 and bank name
  from the IFSC returned). Settings with defaults. Personal notifications
  and `POST /me/notifications/read`. Invites dropped. Checked in the app:
  quote, notification and read all, settings, details, bank.

## Phase 5. First deploy

Put it on the VPS early so the pilot can test on real phones.

- **Built ahead (2026-11-15):** the Gmail API mailer; the API refuses
  to start with `APP_ENV=production` without `MAIL_FROM` and the key
  file, so codes never go only to the log. Verified the same day: all
  10 kinds of email delivered from `support@solacliq.markcliq.com`
  (DNS, service account and delegation set up in the markcliq.co
  Workspace). On the server: the key at
  `/etc/solacliq/gmail-sender.json`, mode 600.
- **Build:** release build, a `systemd` service, nginx proxying
  `solacliq.markcliq.com/api` (with `proxy_set_header X-Real-IP
  $remote_addr;` for the rate limits), production `.env` on the server only
  (`CODE_SECRET`, `BANK_KEY`, `REVIEW_EMAIL=info@markcliq.com`,
  `COOKIE_SECURE=true`, `MAIL_FROM`, `GOOGLE_SERVICE_ACCOUNT_KEY_FILE`),
  daily Postgres backup. Two database logins: the owner
  (`DATABASE_URL`, migrations) and `solacliq_api` (`APP_DATABASE_URL`,
  a strong password), made as in `backend/dev-roles.sql`; the server
  won't start on a login that bypasses row-level security. CI: `make api-test` and the spec check
  (`cargo run -- openapi` against `api/openapi.yaml`). Make the first
  platform admin with `make-platform-admin`.
- **Done when:** the app, built with the production URL, logs in on a
  real phone, and a test registration reaches info@markcliq.com.

## Phase 7. Push notifications, then shared company plumbing (#21–24)

**First, push (decided 2026-11-15).** Firebase Cloud Messaging. Spec:
`features/F12-notifications.md` (drafted, waiting for review). The app
sends its FCM token with `PUT /me/device`; a `devices` table ties it to
the session, so log out stops pushes with no extra call, and a token
moves to whoever logged in on the phone last. A push worker picks up new
notifications (`pushed_at` empty), skips people with push off, sends to
FCM's HTTP v1 API with a service-account key and deletes tokens FCM
reports dead. The app opens the notification's screen on tap. Needs from
the owner: a Firebase project (`google-services.json` for the `.dev`,
`.stg` and production app ids; a service-account key for the server).

- **Test:** the worker's device choice and its handling of FCM's
  answers, against a stand-in for FCM.
- **Done when:** a notification written on the server shows on a real
  phone with the app closed, and tapping it opens its screen.

**Then:**

`GET /orgs/{org_id}/home` composed per role (see "Home" in the handoff),
`POST /uploads` with presigned R2 URLs, company notifications and mark
read. Row-level security starts here, with the first company-owned
tables: the API connects as a role that doesn't own the tables, policies
filter on `current_setting('app.org_id')`, and each company request runs
in a transaction that sets it.

- **Test:** a query with its `org_id` filter left out still returns no
  other company's rows.
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
