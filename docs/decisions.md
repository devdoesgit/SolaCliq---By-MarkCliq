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
- **Email via the Gmail API from `no-reply@app.markcliq.com`** (sender changed 2026-11-15 to `support@solacliq.markcliq.com`). Needs the
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
- **Brand illustration drawn in code** (`SolaRooftopScene` in `sola_ui`),
  after the markcliq.com banner's line-art style: an Indian flat-roof house
  with a water tank, panels on a raised frame, a rust sun and the dashed
  arc with its square. Code rather than an image file: sharp at any size,
  brand tokens only, no new package, and it can animate. The full scene is
  the welcome screen's hero and the app's one entrance animation (the arc
  draws to the panels; still with reduce-motion). On the account screens
  (owner's request: login in the middle, blended with the illustration)
  the page reads as one scene: the sun's arc (`SolaSunArc`) lands its
  square on the form's title, the form sits in the middle on the sky's
  paper, and the rooftop (`SolaSceneView.ground`) stands at the foot. The
  page scrolls as a whole, so on short screens the house's lower floor
  leaves view rather than the form covering its panels.
  No rule divides the scene from the page: the ground line is solid only
  under the house and breaks into shrinking dashes at the edges, and a
  walkway from the front door widens down into the text below. The hero's
  animation has two stages: the arc lands on the panels, then a dashed
  conduit runs down the wall and lights the electricity meter (net
  metering). Indian details: water tank, chajjas over the windows, potted
  plants by the door. MarkCliq's red slashes (`SolaBrandSlashes`) mark the
  name. The real MarkCliq logo file is not in this repo yet.

## 2026-10-25

- **"Bold" redesign tried, then dropped.** A navy and sun-orange theme
  replaced the markcliq.com look on the welcome, log in and request-access
  screens. The owner superseded it with iOS v2 before it was finished.
- **The mobile app follows the "iOS v2" design, not markcliq.com.** Source:
  the "SolaCliq Login" design canvas, page "iOS v2" (25 screens). Warm
  cream, sand, stone and sky backgrounds per role, sun `#F6C445` accent,
  brown cards, white rounded cards and grouped fields, pill buttons, a
  floating tab bar. `design/tokens.json` v4 holds its values; the admin
  website keeps the markcliq.com look until it is redone, last.
- **Inter replaces Space Grotesk and Space Mono in the app** (the design's
  stand-in for SF Pro; OFL, bundled in `sola_ui`).
- **Photos from the design are bundled** (`sola_ui/assets/images`: hero
  install, quote home, four thumbnails) for the welcome screen, the quote
  card and sample data. Their origin and licence are unknown, and the hero
  shows a "SOLAR GRID EPC" vest: confirm or replace before release.
- **Home screens are composed by the server.** `GET /orgs/{org_id}/home`
  returns parts (headline, week, energy, two tiles, a progress bar, a
  list) and the app draws them, so each role's home can change without an
  app update.
- **New endpoints for the designs' flows, drafted for the owner's review:**
  `POST /uploads` (presigned upload to private R2; receipt or KYC),
  `GET/POST /orgs/{org_id}/expenses` (amount in paise, category, note,
  day, receipt, `Idempotency-Key`), and
  `POST /orgs/{org_id}/customer-registrations` (an agent's new customer
  with KYC upload ids and consent, approved by the admin on the web).
- **Plain dates travel as `YYYY-MM-DD`.** The Dart client maps OpenAPI
  `date` to `String` (`make gen-dart`); the generator otherwise sent a full
  timestamp, which the contract rejects.

## 2026-10-26

- **Text colours darkened from the design for WCAG AA.** Muted `#8C7F74`
  read at 3.6:1 on cream; it is now `#6D635A` (4.5:1 on every background).
  Faint is `#8D837B` (3:1) and used only for icons and placeholders. Tan
  text and warning were nudged to 4.5:1 on their pills. Field workers read
  these outdoors in sunlight. Noted on each token.
- **Every tap target is at least 48px,** keeping the design's look: the
  field rows' inputs span the whole row, chips and segments have a 48px
  target around a 36px shape, text links and keypad keys are 48px tall.
- **The expense form has no project pill.** The design shows the expense
  linked to a customer's job; jobs come with F6, so the link waits for it.
  *Superseded the same day:* with F6's tasks, the form has a task pill
  (`ExpenseCreate.task_id`).
- **Setting a password still asks for the emailed code.** The design opens
  it from a welcome-email link; until that link exists the code proves the
  email belongs to the person.
- **The quote form keeps "When".** The design leaves it out, but the
  contract needs it to route the lead.
- **The admin website keeps its own tokens for now.** `design/tokens.web.json`
  is the markcliq.com set the admin site was built on; `make tokens`
  generates the admin CSS from it and the app's tokens from
  `design/tokens.json`. When the admin site is redone (last), it moves to
  the main file and the web file goes.
- **"Quick forms" for walking the app against the mock** (owner's
  request). Development flavor only and on by default: a form sent with
  nothing typed takes illustrative sample values, default choices and
  placeholder document ids, so every screen can be passed without typing.
  Toggled in the Development section or with `QUICK_FORMS=false`; tests
  and production run without it.
- **Success screens use a green tick, not the design's sun circle**
  (owner's call). Green already means done on every status pill, so a
  sent screen reads as success at a glance; sun stays the accent for
  actions and what's next. Token `shadow-success` gives it its glow.
- **F6 worker tasks drafted from the new worker designs.** The contract adds
  `tasks` and `notifications` tags; task list, detail, photos, checklist,
  submit, problems, messages and history; expense detail and receipt
  replacement; notifications with read-all; worker stats. Upload purpose
  `proof`; expense status `paid`. Spec in `features/F6-worker-tasks.md`,
  awaiting the owner's review.
- **The proof camera has no gallery or flip button.** The design shows
  both. Proof comes only from the live back camera, so the gallery button
  would break the rule and a selfie camera has nothing to prove.
- **A task with a reported problem shows "On hold", not "Assigned".** The
  design keeps "Assigned"; the worker can't act on it until the admin
  decides, and the list should say so.
- **Task screens open over the tab bar.** The design shows the tab bar on
  Submitted, Reported and Cancelled; they are pushed pages here, like the
  other task states, so back always returns to where the worker was.
- **Tasks have no search yet.** The design shows a search button; a
  worker's day is a handful of tasks, so it waits for a real need.
- **The app keeps its own photo and checklist progress on an open task.**
  The Prism mock keeps no state, so the app overlays what the worker did
  until the server's task leaves the worker (submitted, approved,
  cancelled). Against a real server the overlay matches what it returns.
- **Pills shorten long text, and the nav bar grows with scaled text.**
  Found by the accessibility test on a 360dp phone: the expense form's
  task pill overflowed and the nav bar's title and subtitle didn't fit a
  fixed 52px.

## 2026-10-27

- **The v2 designs are copied into the repo.** The canvas split "iOS v2"
  into five pages; the four mobile ones (100 screens) are in
  `design/ios-v2/` with an index. Admin web (page 5) waits for the admin
  phase.
- **Every v2 mobile screen is wired, one screen per job, not per person.**
  The designs repeat a screen for each sample customer or state (Sunita,
  Arjun, Harpal...); the app has one customer page, one fix page, one
  task page, driven by the data. Help is the existing sheet, with a "Call
  your company" row.
- **Agents are shown as "Sales", with a pay type.** `Membership.pay_type`
  is `commission` or `salary`. Commission agents enter a commission on the
  review step (`CustomerRegistrationCreate.commission`), see Earnings and
  a payout bank; salaried ones get an Alerts tab instead. The role stays
  `agent` in the contract.
- **Each role has its own tab shell.** Sales: home, customers, add,
  earnings or alerts, profile. Customer: home, track, payments, profile. Home tiles, rows and the avatar ask the shell to switch tabs;
  rows carry an `action` (`task`, `customer`, `documents`, `track`).
- **Earnings are summed in the app** from `GET /orgs/{org_id}/my-customers`
  (each with its commission), so there is no earnings endpoint.
- **New endpoints, drafted for the owner's review:** `my-customers` (list,
  detail, replace a returned document), `me/details` (phone, address,
  emergency contact, payout bank; the account number is write-only),
  `me/settings`, `me/documents`, `me/notifications` (Personal),
  `my-install` and its payment claim. Notifications gain Sales,
  customer and personal kinds and a `customer_id`.
- **A customer's payment is claimed, not confirmed, by the app.** "Pay by
  UPI" opens the UPI app from the server's `upi_uri`; either button then
  marks it `claimed` until the company confirms it on the website.
- **Language is saved but English only for now.** Settings stores
  Hindi or Punjabi and says they arrive in an update; there are no
  translations yet.
- **Money totals are shown in full** ("₹2,85,000", not the design's
  "₹2.85L"), so a rounded figure is never mistaken for the price.
- **No customer chat (owner's call).** The design's "Message Arka Solar"
  tab is dropped: not needed while an install is under way. Customers call
  the company from Help; the contract has no `messages` endpoints. A
  worker's reply on a returned task stays.
- **A new workspace always starts at its home.** Switching workspace, or
  another person signing in (another mock person in development), closes
  any open screen and opens the new home; a different person no longer
  inherits the last one's Personal workspace.

## 2026-11-09

- **Backend skeleton set up; the owner builds the rest.** Axum 0.8, sqlx
  0.9 (Postgres, migrations at start), utoipa 6 with Scalar docs at
  `/api/docs`, tower-http request ids, timeout and tracing. Only
  `GET /health` exists. Local Postgres runs with `make db` (podman or
  docker, no compose needed); `make api` and `make api-test` run and
  check it.
- **Sessions use opaque tokens, not JWTs.** Random 32-byte tokens, stored
  only as SHA-256 in a `sessions` table and looked up on each request.
  Log out, password reset and suspension take effect at once, there is no
  signing key to protect or rotate, and one lookup per request is cheap
  at this scale. Access 15 minutes, refresh 30 days, website cookie 12
  hours.
- **Any 401 other than refresh is `auth.unauthenticated`.** The app
  refreshes and retries on every 401, so no finer codes are needed.

## 2026-11-11

- **The app and the website both refresh, by OAuth 2.1 rules.** Access
  token 15 minutes, refresh token 30 days. Every refresh returns a new
  access and refresh token and the old refresh token stops working;
  reusing one revokes the session. The app keeps tokens in secure storage;
  the website gets them as HttpOnly cookies, the refresh cookie scoped to
  `/auth/refresh`. No grace window: each client runs one refresh at a
  time. Replaces the website's fixed 12-hour cookie. Lifetimes are set in
  the backend's environment (`ACCESS_TOKEN_MINUTES`,
  `REFRESH_TOKEN_DAYS`).

## 2026-11-13

- **Email codes are stored as HMAC-SHA256 with a server secret.** A
  6-digit code has a million values, so a plain hash could be reversed
  by trying them all; the HMAC key (`CODE_SECRET`, at least 32
  characters, required) is never in the database. One live code per
  account and purpose (`email_codes`, keyed on both): asking again
  replaces it and resets the tries; a right code is deleted, so it works
  once. 5 minutes, 5 tries (the sixth is 429).
- **One new code per minute per account and purpose.** Within the minute
  the request still answers 202 and sends nothing, so the cooldown
  doesn't reveal which emails have accounts. Stops inbox flooding through
  sign-up, resend and forgot.
- **A password reset also verifies the email** (the code reached the
  inbox) **and ends every session** of the account.
- **Signing up again with a taken email**: an unverified account gets a
  new code; a verified one gets a "you already have an account" email.
  The password sent with it is ignored.
- **Email goes through a `Mailer` trait** whose `send` returns at once,
  so no request waits on a mail server. Development prints emails to the
  server log (`LogMailer`); the SMTP mailer comes before production.

## 2026-11-14

- **Phase 3 is done; the SMTP mailer moves to phase 5 (first deploy).**
  Phase 3's goal (sign-up, code, log in and forgot password working in
  the app, codes read from the server log) is met. Real email matters
  only once real users arrive, so it ships with the production `.env`,
  together with a start-up check that refuses production without SMTP
  settings.
- **Verifying from the log in screen logs straight in.** The server only
  answers "unverified" after the right password, so the app keeps that
  password in memory (never stored) and logs in once the code is
  accepted, as it already did after sign-up. If that log in fails (the
  held password can be wrong when someone signed up twice), the app opens
  log in with "Email verified" instead of staying on the used code.
- **The app's resend countdown is 60 seconds**, matching the server's
  one-code-a-minute rule; a shorter wait let people ask for a code the
  server silently didn't send.
- **An agent without a pay type is treated as salaried.** The app used to
  assume `commission`, which would show a salaried person the commission
  step, Earnings and a payout bank, and send a commission the server
  refuses (`registration.commission_not_allowed`). `pay_type` is always
  set for agents (the database `CHECK` in phase 4), and the app now sends
  `commission` and `commission_note` only for commission agents.
- **Companies register themselves; MarkCliq approves or denies.** A
  company submits all its details (GSTIN and business details, as in
  `product.md`), which creates the company as `pending`. MarkCliq does a
  background check and a call with them, then approves or denies it in
  the platform admin, and helps them onboard. This replaces the
  contract's "request access" flow (`POST /access-requests`, a short form
  MarkCliq acts on by hand); the contract and the app's request-access
  screen change with F2.
- **A salaried sales person's profile counts "approved", not
  "installing".** The design (`Ios2SalesProfile`) shows customers ·
  installing · to fix; the app shows customers · approved · to fix.
  Approved (documents accepted) is what a sales person controls, it needs
  no contract change (the customer list has no install stage), and the
  install picture is already on their home ("1 installing · 2 not
  started"). A deliberate deviation from the design.
- **Phase 4 schema choices.** Roles, pay types and company status are
  native Postgres enums (`sqlx::Type`): the lists are stable. One role per
  person per company stays (`PRIMARY KEY (user_id, org_id)`). Removing a
  member is a soft delete for now: `memberships.removed_at` is set, the
  person loses access at once (`OrgMember` and `/me` skip removed rows),
  and adding them back clears it on the same row, with the new role.
- **A suspended or pending company shows a message, never its data.**
  Every `/orgs/{org_id}/...` request from its members returns 403
  `org.suspended` or `org.pending`. `/me` still lists the membership with
  the company's name and status, so the app shows "Example Solar is
  suspended" instead of the company vanishing or the app breaking.
- **Row-level security starts in phase 7, not phase 4.** Phase 4's
  `OrgMember` check is the first lock; RLS is a second one in Postgres, so
  a query that forgets its `org_id` filter still can't return another
  company's rows (KYC documents, bank details). Phase 4 has no
  company-owned data to protect yet, and `/me` reads `memberships` across
  companies, so RLS starts with the first company tables in phase 7.
- **Only companies are suspended.** A person is never suspended; removing
  a member just drops the company from their `/me`, with no message.
- **Adding an agent needs a pay type.** `AddMemberRequest.pay_type`
  (`member.pay_type_required` / `member.pay_type_not_allowed`, 422) was
  missing, so the website couldn't have added an agent. `PayType` is now
  one shared schema, used by `Membership`, `Member` and `AddMemberRequest`.
- **`APP_ENV` says development or production; unset means production.**
  Development-only tools (the seed) refuse to run unless it is
  `development`, so a server that forgot to set it is treated as the real
  one. Phase 5's "no production without SMTP" check will use it too.
- **Claude writes the backend too; the owner reviews.** From phase 4 the
  owner asked Claude to be the main developer across the repo, to ship
  fast without lowering the bar.
- **A new member sets up their account with "Forgot password?".** The
  "you were added" email carries no code (it would expire in the inbox);
  the app's forgot-password flow sends one and sets a first password,
  which also verifies the email.
- **Company registration is built now, with phase 4** (F2 pulled
  forward). Registering saves the company as pending; MarkCliq reviews
  through `/platform/orgs` endpoints (no website page: the owner calls
  them directly). Replaces `POST /access-requests`.
- **A `rejected` status**, separate from `suspended`. Rejecting needs a
  reason, emailed to the owner; a rejected GSTIN can register again.
  Allowed moves: pending → active or rejected; active ⇄ suspended.
- **The GSTIN is checked by its checksum, and the PAN and state are read
  from it**, in the app and on the server. A GST verification API (to
  pre-fill and refuse cancelled GSTINs) needs a paid provider; later.
- **New registrations email `REVIEW_EMAIL`** (info@markcliq.com), a
  required setting.
- **Docs trimmed for working context.** Finished backend phases keep a
  short "what it left behind"; the build history is in git.
- **Migrations stay editable until the first deploy.** No real database
  exists yet, so phase 4's three migrations were merged into one that
  creates `orgs` complete (`rejected` in `org_status` from the start).
  From phase 5 on, every change is a new migration.
- **Customer registration takes three more documents.** A land document
  (property ownership; required), the customer's signature (a photo of
  it on paper; required), and a name change document (optional, for a
  bill in another person's name; the admin judges it, no extra fields).
  Document pickers take a PDF as well as a photo (`file_picker`).

## 2026-11-15

- **App first, then the admin website and the deploy.** Admin-made data
  (tasks, approvals, installs) comes from the seed until the website's
  admin endpoints are built.
- **Invites are dropped.** Adding a member is direct (they're in at once
  and emailed); the app's invite banner, page and endpoints are gone.
- **Quote requests go to MarkCliq** (`REVIEW_EMAIL`) as leads; companies
  accepting leads comes with the website. The estimate uses general
  figures, not a vendor's prices: bill band → 1–2, 2–3, 3–5 or 5–10 kW;
  ₹55,000–65,000 per kW; PM Surya Ghar subsidy for homes only (₹30,000/kW
  for 2 kW, ₹18,000 for the 3rd, ₹78,000 at most). In `routes/quotes.rs`.
- **App writes are idempotent by a stored key** (`idempotency_keys`): the
  response is stored with the key in the same transaction, so a retry or
  a race with one key does the work once. Forms keep one key for their
  lifetime (the quote form now does, like add-customer).
- **Bank account numbers are encrypted with AES-256-GCM** under a
  required `BANK_KEY`; only the last 4 digits and the bank name (from the
  IFSC's first four letters; common banks listed) are readable.
- **`POST /me/notifications/read`** added: "Read all" in the Personal
  workspace marked them read only on screen.
- **178 unused app strings removed** (old screen copy, invites).
- **Push notifications come next, through Firebase Cloud Messaging.**
  Firebase only delivers: our server keeps which tokens belong to whom (a
  `devices` table, filled at log in, cleared at log out) and asks
  Firebase to send each message to each token. Then uploads and the rest
  of phase 7. Plan in `backend-phases.md`.
- **Email: the Gmail API with a service account, built now** (ahead of
  the deploy). The sender is a Workspace user; the server acts as it
  through domain-wide delegation limited to `gmail.send`, so no mailbox
  password or refresh token is stored and nothing expires. Chosen over
  SMTP with an app password, and over a plain @gmail.com account (a
  7-day refresh token while the Google app is unverified, and mail from
  @gmail.com lands in spam more). Details in `architecture.md`, "Email".
- **Google Workspace is on `markcliq.co`; `markcliq.com` mail stays on
  Zoho** (`info@markcliq.com`). The sender is
  `support@solacliq.markcliq.com`, a user on `solacliq.markcliq.com`
  (the app's own address), added to the markcliq.co Workspace as a
  secondary domain; its MX, SPF, DKIM and DMARC records sit on the
  subdomain only, so Zoho is untouched. `support@`, not `no-reply@`:
  people reply to code emails, and replies help inbox placement. Not
  `markcliq.co`: codes from `.co` for an app on `.com` look like
  phishing.
- **Firebase and the Gmail service account live under the markcliq.co
  Workspace account**, not a personal Google account, so the
  organisation owns the project and its keys.
- **Emails look like the big services' account emails** (the owner's
  GitHub example): a centred heading, the code large in a bordered card,
  how long it lasts, a don't-share line, and a grey note on why it was
  sent. All emails share the layout, in the app's colours; plain text
  goes with every one.
- **Each email looks like what it says** (owner, same day): approved has a
  green tick and a "what's next" list, not approved a red callout with
  the reason, a registration a progress tracker, a lead a call button and
  the estimate, a team invite the company card and set-up steps. Only
  the code emails show the sun dot in the inbox preview; the others set
  their own preview line.
- **The approval email sends the owner to the dashboard, not the app.**
  Org admins run their company from the admin website; the email links
  to its log in (`WEBSITE` in `lib.rs`) and to "forgot password" with
  their email filled in, then says to add workers and agents there. The
  note says the address "was given as the owner's", since someone else
  may fill in the form.
- **Rate limits on the public endpoints** (review, owner agreed): per IP,
  and per account for log in; 429 `auth.too_many_attempts` with
  `Retry-After`. Protects the shared daily email cap and stops password
  guessing. Details in `architecture.md`, "Rate limits".
- **No code read-out when an agent registers a customer.** On submission
  the customer's account is created with no password and they're emailed
  at once with what was registered and how to set up the app to follow
  their install; they set a password with an emailed code when they
  first open it. Replaces the 2026-10-18 step where the customer read the
  code out to the agent, and moves the email from approval to
  submission (`product.md`, the contract and the handoff updated).
- **Admins get notifications on the website only**, no push or email:
  they check the site.
- **Role names users see: "EPC Installer" (`worker`) and "Sales Agent"
  (`agent`)**, in the app, website and emails. The code keeps `worker`
  and `agent`. "Installer" alone still means the solar company in
  customer copy ("your installer").
- **One support address: `info@markcliq.com`.** Every email's Reply-To
  is it (`SUPPORT_EMAIL` in `lib.rs`); emails are still sent from
  `support@solacliq.markcliq.com`.
- **The staging app points at the production API on purpose**, for
  testing while there's no real data; revisit before real vendors.
