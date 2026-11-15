# Architecture

Stack, infrastructure, API contract and design patterns. Reasons for each
choice are in `decisions.md`.

## Stack

Claude builds every part; the owner reviews.

| Part | Choice |
|---|---|
| Backend | Rust, Axum + sqlx, `utoipa` for the OpenAPI spec |
| Database | Postgres 17 on the owner's VPS (`make db` locally) |
| Object storage | Cloudflare R2 (free plan) |
| Mobile app (workers, agents, customers) | Flutter (Dart), Android first |
| Admin website (org admins) | React + Vite + TypeScript, static SPA |
| Over-the-air updates | Shorebird (free plan to start) |

## Hosting

- Everything on the owner's VPS under `solacliq.markcliq.com`:
  - `/` admin website (static files, no Node server)
  - `/api` Rust API
  - `/r/<code>` referral links (Android App Links open the app)
  - `/app` APK download page
- Not a path on markcliq.com: the website and SolaCliq stay separate.

## Storage

- **Private R2 bucket:** customer documents and photos. Access only through
  short-lived presigned URLs; nothing public.
- **Public R2 bucket:** APK files and the `latest.json` update manifest only.
- Uploads go straight from the client to R2 with presigned URLs, never
  through the VPS: `POST /uploads` returns a short-lived URL, method and
  headers; the app sends the bytes there (with a separate HTTP client that
  never carries the API token) and attaches the returned `upload_id` to the
  record. 10 MB at most; JPEG, PNG or PDF. The development mock hands out
  `.invalid` URLs, which the app treats as already uploaded.

## Email

- Sent through the **Gmail API** as a Workspace user (`MAIL_FROM`, e.g.
  `SolaCliq <support@solacliq.markcliq.com>`), not SMTP: no mailbox password
  on the server, and Workspace signs it (DKIM) for markcliq.com.
- The server signs in as a Google Cloud **service account** with
  domain-wide delegation, allowed only
  `https://www.googleapis.com/auth/gmail.send`, acting as the `MAIL_FROM`
  user. Its JSON key sits on the server only
  (`GOOGLE_SERVICE_ACCOUNT_KEY_FILE`).
- Handlers queue emails (`state.mailer.send`); one background task sends
  them, trying a network error, 429 or 5xx three times. Bodies never go
  to the log (they hold codes). On shutdown the queue is sent first, for
  up to 30 seconds.
- Development without those settings prints emails to the log;
  production refuses to start without them.
- Every email goes out as plain text and HTML (multipart/alternative).
  The page around each is shared (`src/mail/template.rs`: wordmark,
  badge, heading, white card, a note on why it was sent, footer); what's
  in the card is each email's own, built from the pieces there (code,
  steps, callout, company card, details table, call button, figure).
  Each sets its inbox preview line; only code emails keep the sun dot
  there. Inline styles and tables only, the app's colours, no images.
- Replies to any email go to `SUPPORT_EMAIL` (`info@markcliq.com`, in
  `lib.rs`) through a Reply-To header; the app's Help sheet shows the
  same address.
- Check the setup with `cargo run -- send-test-email <to>`.

## Rate limits

- The public endpoints are limited per IP, and log in also per email
  (`src/rate_limit.rs`): sign-up 10/hour, log in 30 per 15 minutes per
  IP and 10 per account, code emails 10/hour, code checks 30 per 15
  minutes, company registration 5/hour. Over the limit: 429
  `auth.too_many_attempts` with `Retry-After`. "You already have an
  account" goes out at most once an hour per address.
- Why: every email shares the Workspace sender's cap (about 2,000 a
  day), so floods would stop real people's codes.
- Counts are in memory (one API process). The IP is `X-Real-IP`, which
  nginx must set: `proxy_set_header X-Real-IP $remote_addr;`.

## API contract

One OpenAPI spec is the contract between backend and frontends.

1. **Spec first.** Claude drafts `api/openapi.yaml` for each feature; the
   owner reviews it before code.
2. **Backend:** spec generated from Axum handlers with `utoipa`; interactive
   docs at `/api/docs`; CI fails if the generated spec differs from the
   committed one; tests with `#[sqlx::test]`.
3. **Clients:** `make gen` regenerates the Dart client (mobile) and the
   TypeScript client (admin, `openapi-typescript` + `openapi-fetch`). A
   contract change breaks the build until the frontend is updated.
4. **Mocking:** Prism serves responses from the spec, so frontend work does
   not wait for endpoints. One mock (`make mock`, port 4010) serves both
   apps; it keeps no state. It serves the spec's paths without `/api/v1`;
   the real backend serves them under `/api/v1`. Pointing at a local
   backend: mobile `--dart-define=API_BASE_URL=http://10.0.2.2:<port>/api/v1`,
   admin `BACKEND_URL=http://localhost:<port> npm run dev`.
   Named examples let one mock play different people: `/me` and
   `/auth/login` have `personal`, `customer`, `worker`, `agent`, `sales`,
   `multi_org` and `org_admin`, picked with Prism's
   `Prefer: example=<name>` header. The
   app's development flavor sends it: choose the person under Account →
   Development, or start with `--dart-define=MOCK_PERSONA=<name>`.
5. **Contract testing:** Schemathesis runs generated requests against the
   real API and reports anything that breaks the spec.

### API conventions

- Versioned paths: `/api/v1/...`.
- Errors: RFC 9457 `application/problem+json`, with a machine-readable code
  such as `expense.limit_exceeded`.
- Money: integer **paise** (`i64`). Never floats.
- IDs: UUIDv7. Dates: ISO 8601, UTC.
- Lists: cursor pagination (`?cursor=&limit=`).
- Org-scoped endpoints live under `/orgs/{org_id}/...`. The server checks
  membership, that the org is `active`, and the role (`OrgMember<Roles>`).
  MarkCliq's endpoints live under `/platform/...` (`PlatformAdmin`).
- Auth: `Authorization: Bearer` for mobile, cookies for the admin website,
  same endpoints.
- Uploads: `POST /uploads` returns a presigned R2 URL.
- Writes from the mobile app carry an `Idempotency-Key`, so offline retries
  never create duplicates.

## Design patterns

- **Tenancy:** `org_id` on every org-owned table, plus Postgres row-level
  security (from phase 7) as a backstop against a missed `WHERE`.
- **Identity:** global `users`, `memberships (user, org, role)`, and per-org
  `customers` records linked to a user.
- **Linking:** auto-link only on verified email or phone; notify the person
  every time.
- **Approvals:** one request model for expenses and commission (later
  discounts): pending → approved / rejected, with who decided, when, and a
  note. The org admin's dashboard is built around this queue.
- **Org lifecycle:** registered as pending → active (approved) or
  rejected; active ⇄ suspended. Set by a platform admin.
- **Geotagged capture:** photos only from the live camera, never the gallery.
  The device records GPS coordinates, accuracy and time at the moment of
  capture. The server flags captures far from the customer's site, with poor
  accuracy, or with a mocked location. Flags go to review; nothing is blocked.
- **Photos** are compressed on the device before upload.
- **Server-side rules:** pricing, approvals and stage rules live in the
  backend, so most fixes need no app update.

- **Server-composed homes:** each role's home comes from
  `GET /orgs/{org_id}/home` as parts the app knows how to draw, so homes
  change without an app update.

- **Stateless mock:** the Prism mock picks named examples per request
  (`MockPersonaInterceptor`) and keeps no state, so screens that build up
  progress (a task's photos and checklist) keep it locally until the
  server's answer settles it.

Mobile code structure: Bloc/Cubit per feature, GoRouter with one redirect
(`appRedirect`) driven by the workspace, repositories wrapping the
generated client, and `packages/sola_ui` for every visual. Features live in
`lib/<feature>/{data,cubit,view}`.

## Distribution and updates

- **Pilot on a self-hosted APK; Play Store in about 3 months.** APK on the
  public R2 bucket, linked from `solacliq.markcliq.com/app` with a QR code.
  Before the Play Store: privacy policy, data-safety form, account deletion
  (in app and on the web), organisation developer account.
- **Dart fixes:** Shorebird patch. Users do nothing; urgent patches can prompt
  "restart to apply". Patches can be rolled back.
- **Native changes:** `make release` builds, signs and uploads the APK and
  updates `latest.json`. The app offers a one-tap update; a `required` flag
  blocks outdated versions.
- **Signing key:** generated once, backed up offline in two places. Losing it
  means the app can never be updated. If the Play Store comes later, use Play
  App Signing with this existing key.
- **Android developer verification:** register the developer account and the
  package name before Google's global enforcement (planned for 2027).
  Publisher name: MarkCliq (check whether Google requires the legal name,
  MARK8ONICS).
- **iOS:** TestFlight for the owner's testing (Apple Developer account +
  cloud build). Unlisted App Store distribution when vendors need iOS.

## Dev tooling

- Under `~/development` (no sudo), also symlinked into `~/.local/bin`
  because Claude Code started from VS Code doesn't read `~/.bashrc`:
  Flutter (stable) and Dart, JDK 21 for Gradle (`flutter config
  --jdk-dir`; the system Java 25 is too new), Android SDK
  (`~/development/android-sdk`). Very Good CLI for the VGV plugin.
- **Emulator:** AVD `solacliq_phone_35` (mobile-mcp device id
  `solacliq_phone_35`, adb `emulator-5554`), host GPU
  (`hw.gpu.mode=host`). The software renderer crashes here (SELinux
  blocks its JIT); don't loosen SELinux to fix it. The PC once froze with
  the emulator and a Gradle build running together: Gradle is capped at
  3 GB and Kotlin at 1 GB; boot the emulator, start the mock and build one
  after another. If mobile-mcp typing drops characters, type with
  `adb shell input text`.
- MCP: mobile-mcp (screens, taps, logs), the Dart and Flutter server
  (widget tree, hot reload, analyzer). Skills: `mobile/CLAUDE.md`.
- Local Postgres runs in rootless podman (`make db`); it can stop on its
  own, so run `make db` again if tests can't connect.

## Proposed, not confirmed

- Sentry for crash reporting (free tier, or self-hosted).
- Offline-first storage with `drift` (SQLite): captures, expenses and job
  updates saved locally and synced when there is signal.
- Feature flags from the API, to switch off a broken feature without an
  update.
