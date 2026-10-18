# Architecture

Stack, infrastructure, API contract and design patterns. Reasons for each
choice are in `decisions.md`.

## Stack

| Part | Choice | Built by |
|---|---|---|
| Backend | Rust, Axum + sqlx, `utoipa` for the OpenAPI spec | Owner |
| Database | Self-managed Postgres on the owner's VPS | Owner |
| Object storage | Cloudflare R2 (free plan) | Owner |
| Mobile app (workers, agents, customers) | Flutter (Dart), Android first | Claude |
| Admin website (org admin, platform admin) | React + Vite + TypeScript, static SPA | Claude |
| Over-the-air updates | Shorebird (free plan to start) | Claude |

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
  through the VPS.

## API contract

One OpenAPI spec is the contract between backend and frontends.

1. **Spec first.** Claude drafts `api/openapi.yaml` for each feature; the
   owner reviews; it is committed before code.
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
5. **Contract testing:** Schemathesis runs generated requests against the
   real API and reports anything that breaks the spec.

### API conventions

- Versioned paths: `/api/v1/...`.
- Errors: RFC 9457 `application/problem+json`, with a machine-readable code
  such as `expense.limit_exceeded`.
- Money: integer **paise** (`i64`). Never floats.
- IDs: UUIDv7. Dates: ISO 8601, UTC.
- Lists: cursor pagination (`?cursor=&limit=`).
- Org-scoped endpoints live under `/orgs/{org_id}/...` (decided in F3).
  The server checks membership, that the org is `active`, and the role.
- Auth: `Authorization: Bearer` for mobile, cookies for the admin website,
  same endpoints.
- Uploads: `POST /uploads` returns a presigned R2 URL.
- Writes from the mobile app carry an `Idempotency-Key`, so offline retries
  never create duplicates.

## Design patterns

- **Tenancy:** `org_id` on every org-owned table, plus Postgres row-level
  security as a backstop against a missed `WHERE`.
- **Identity:** global `users`, `memberships (user, org, role)`, and per-org
  `customers` records linked to a user.
- **Linking:** auto-link only on verified email or phone; notify the person
  every time.
- **Approvals:** one request model for expenses and commission (later
  discounts): pending → approved / rejected, with who decided, when, and a
  note. The org admin's dashboard is built around this queue.
- **Org lifecycle:** pending → active → suspended, set by the platform admin.
- **Geotagged capture:** photos only from the live camera, never the gallery.
  The device records GPS coordinates, accuracy and time at the moment of
  capture. The server flags captures far from the customer's site, with poor
  accuracy, or with a mocked location. Flags go to review; nothing is blocked.
- **Photos** are compressed on the device before upload.
- **Server-side rules:** pricing, approvals and stage rules live in the
  backend, so most fixes need no app update.

Mobile code structure (state management, routing, folder layout) is decided
when F0 starts and recorded here.

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

- Installed 2026-10-18 under `~/development` (no sudo; PATH set in
  `~/.bashrc`, backup at `~/.bashrc.bak-solacliq`). Claude Code started
  from VS Code doesn't read `~/.bashrc`, so `flutter`, `dart`, `adb` and
  `emulator` are also symlinked into `~/.local/bin`:
  - Flutter 3.47.7 stable, Dart 3.13.5 (`~/development/flutter`).
  - JDK 21 (Temurin) for Gradle, set with `flutter config --jdk-dir`. The
    system Java is 25, too new for Gradle; it is left untouched.
  - Android SDK (`~/development/android-sdk`): platform-tools, build-tools
    36.1.0, platform 36, emulator 37.2.12, system images for API 35 and 36.
  - `flutter doctor`: Flutter, Android toolchain, Chrome all pass. The Linux
    desktop toolchain is missing and not needed.
  - A debug APK builds (verified with a throwaway app).
- **Emulator: use the host GPU.** AVDs `solacliq_phone` (API 36, main) and
  `solacliq_phone_35` are set to `hw.gpu.mode=host` (NVIDIA RTX 3060) and
  boot in about 20 s. Start with `flutter emulators --launch solacliq_phone`.
  The software renderer (SwiftShader, `-gpu swiftshader_indirect` or
  `auto`) crashes on this machine because SELinux blocks its JIT code
  (`execheap` denial). Don't fix that with `setsebool selinuxuser_execheap`;
  it weakens SELinux for every user program.
- **Stability (2026-10-18):** the PC froze once while the emulator (GPU
  mode) and a Gradle build ran together; the emulator had also crashed
  inside the NVIDIA driver several times. The owner chose to keep GPU mode.
  Precautions: Gradle heap capped at 3 GB and Kotlin daemon at 1 GB
  (`mobile/android/gradle.properties`); boot the emulator, start the mock
  and build one after another. `-gpu guest` doesn't help: it still renders
  through SwiftShader on the host.
- mobile-mcp (installed): screenshots, taps, device logs, crashes, GPS
  override. Works with a real phone too.
- Dart and Flutter MCP server: widget tree, runtime errors, hot reload,
  analyzer, tests. Connects once Claude Code starts with Flutter on PATH.
- Golden tests for screen states.
- Very Good CLI 1.5.0 (`dart pub global activate`, linked into
  `~/.local/bin`), needed by the VGV plugin's MCP server.
- Claude skills for the mobile app are listed in `mobile/CLAUDE.md`.

## Proposed, not confirmed

- Sentry for crash reporting (free tier, or self-hosted).
- Offline-first storage with `drift` (SQLite): captures, expenses and job
  updates saved locally and synced when there is signal.
- Feature flags from the API, to switch off a broken feature without an
  update.
