# Decisions

One line per decision, newest last. Add the date, what was decided and why.
Change a decision by adding a new line, not by editing an old one.

## 2026-10-18

- **Multi-tenant SaaS from the MVP.** Every vendor uses the same app.
- **Four app roles plus a platform admin.** Org admin, worker, agent,
  customer; MarkCliq approves orgs.
- **No WhatsApp in the MVP.** Keeps the month focused.
- **Expense tracking, not payment collection.** No gateway; customer payments
  are recorded only.
- **One global account per person, with memberships.** One person can work
  for several orgs; makes customer auto-linking clean.
- **Auto-link only on verified email or phone, and notify.** Stops an org
  attaching a stranger's account.
- **Self-serve org signup with GSTIN autofill, then platform approval.** Fast
  signup; approval catches fake orgs, since a GSTIN can be copied.
- **Hosting on `solacliq.markcliq.com`, not a path on markcliq.com.** No new
  domain to buy; keeps SolaCliq independent of the website's hosting.
- **Backend in Rust, Postgres on the owner's VPS, R2 for files.** Owner's
  choice; R2 egress is free.
- **Mobile in Flutter, over Expo and Capacitor.** The owner prioritised
  quality and Claude being able to debug the app itself; Flutter gives the
  deepest tooling (Dart MCP, golden tests) and identical rendering on cheap
  phones. Trade-off: iPhone testing needs an Apple Developer account and
  cloud builds.
- **Shorebird for over-the-air updates.** One command to ship Dart fixes;
  free plan covers the pilot.
- **Self-hosted APK, not the Play Store early on.** MarkCliq distributes the
  app to orgs directly.
- **Admin website in React + Vite.** Static files, no Node server.
- **OpenAPI spec as the contract, spec first.** Owner and Claude work in
  parallel; generated clients make mismatches fail at compile time.
- **Owner builds the backend; Claude builds the mobile app and admin
  website.**
- **English only.** No translation work in the MVP.
- **Publisher name: MarkCliq.**
- **Brand: SolaCliq shares MarkCliq's theme.**
- **Build feature by feature.** Limited, focused scope; each feature is
  finished before the next starts.
- **One repo with `api/`, `backend/`, `mobile/`, `admin/`.** The shared
  contract and `make gen` work across all three without syncing repos; each
  part has its own `CLAUDE.md`.
- **Org admin and platform admin use the website only; workers, agents and
  customers use the mobile app only.**
- **Design system first, before screens** (draft, owner to review):
  https://claude.ai/artifact/DHZ36BtTE4ZCxGNoUbxSbN. MarkCliq's brand
  extended with status colours, field-use sizing (48px taps, 16px body) and
  seven components. Light theme only; no logo or icon set yet.
- **SolaCliq uses the system font (San Francisco on Apple devices), not
  Space Grotesk and Space Mono.** Owner's choice: the iPhone look. SF files
  are never bundled or served, since Apple's licence allows them only on
  Apple platforms; apps ask for the system font, so Android shows Roboto and
  Windows Segoe UI. MarkCliq's website keeps its own fonts.
- **Official Flutter agent rules go in `mobile/CLAUDE.md`.** The rules repo
  has one rule so far (hot reload after editing `lib/`); it is Flutter-only,
  so it loads only when working on the mobile app.
- **Android emulator runs on the host GPU, not SwiftShader.** The owner has
  an iPhone, which can't run builds from Linux. SwiftShader crashed because
  SELinux blocks its JIT; using the GPU avoids that without loosening
  SELinux.
- **Flutter skills: official dart-flutter, VGV AI Flutter plugin, and an
  adapted design-polish skill.** Owner asked for the best Flutter UI/UX
  skills. The official skills have no visual-design guidance; Very Good
  Ventures (Flutter consultancy, Claude partner) covers accessibility,
  theming, testing and security, with automatic analyze and format.
  design-polish (Chunky Tofu Studios, MIT) adds a scored design review,
  rewritten to use our design system and mobile-mcp instead of its own
  emulator script. Rejected: community UI skills that assume rounded
  corners, FABs and dark mode, or are generic. VGV favours Bloc; state
  management is still decided at F0.
- **F0 approved: package `com.markcliq.solacliq`, Bloc/Cubit, GitHub
  Actions CI, `/health` reports the database.** "SolaCliq" is a working
  name; it is kept in one place per app so a rename is a small change, and
  the package ID is confirmed again before the first APK release.
- **SolaCliq matches markcliq.com in everything, fonts included (replaces
  the system-font decision above).** Owner's request, for both apps: Space
  Grotesk and Space Mono, the site's type, spacing, square corners and
  editorial easing, read from the live site into `design/tokens.json`. The
  fonts are OFL and bundled (Flutter assets in `sola_ui`; Fontsource in the
  admin site). Kept for field use, as noted on the tokens: labels 11px
  rather than the site's 10px, 48dp tap targets, status pills in Space Mono
  Bold (regular measured 3.7:1 at 11px), and typed values at weight 400.
- **F1 approved.** Email verification and password reset by 6-digit codes;
  app refresh tokens 60 days renewed on use, access tokens 15 minutes;
  website sessions 12 hours; platform admin created by a backend command;
  no breached-password check for now.
- **Email through Google Workspace, not Zoho.** The owner already has a
  Workspace account and will create the sender there.
- **Main branch is `master`.** The owner committed and pushed to it; CI
  runs on `master`.
- **SolaCliq is sold to solar EPC businesses as a service.** Pilot with 2–3
  vendors for 2–3 months, then wider.
- **Customers can sign up on their own** (later from the Play Store) and are
  linked automatically when they work with a MarkCliq vendor.
- **Agents register customers in the app.** The account is created
  automatically, the email verified with a 6-digit code the customer reads
  out, the agent completes and submits the registration, the org admin
  verifies or rejects it. The customer sets a password on first login.
- **Email-only login for now**; phone login after DLT.
- **Email codes expire after 5 minutes** (was 15), 5 tries, stored hashed in
  PostgreSQL, rate limited. Redis not needed for the MVP (Claude's
  recommendation; the owner's call as backend owner).
- **Email via the Gmail API from `no-reply@app.markcliq.com`.** Needs the
  subdomain in Workspace with SPF, DKIM and DMARC. Emails: verification
  code, reset code, set-up code, activation/welcome.
- **Play Store in about 3 months, not for the pilot.** The pilot uses the
  self-hosted APK. Before the Play Store: privacy policy, data-safety form,
  in-app and web account deletion, and an organisation developer account
  (a personal one needs a 12-tester, 14-day closed test first).
- **Mobile first, admin website last.** The owner builds the backend while
  Claude builds the mobile app against the Prism mock, feature by feature,
  with the endpoints agreed in `api/openapi.yaml` first. Each mobile
  feature is tested against the real backend as soon as its endpoints
  exist, since the mock keeps no state. The admin website (org signup,
  team, customers, approvals) is built last, with 7–10 days kept for it
  before the pilot; until then orgs and teams are set up by backend
  command. Aim: the highest-quality mobile UI/UX.
- **F3 approved.** Org admins use only the website: an org-admin
  membership opens no home in the app, only a notice pointing to the
  website. Org-scoped endpoints are `/orgs/{org_id}/...`; the server checks
  membership, org status and role in one place. One role per person per
  org until RY Enterprises says whether someone can be both worker and
  agent.
