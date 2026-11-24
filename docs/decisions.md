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
  card and sample data. The hero is AI-generated and stays, vest and all
  (owner, 2026-11-23); it was upscaled 2x with Real-ESRGAN the same day
  because it looked blurry on the log-in page.
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
- **Security review fixes, first batch (2026-11-16):** quote requests are
  limited to 5 a day per account (each emails MarkCliq, and one free
  account could otherwise use up the daily email cap), and `X-Real-IP`
  is trusted only from this machine (nginx), so clients can't fake their
  IP past the limits. The rest of the review is in the conversation
  record; next in line: member consent before admins see details,
  refresh races across tabs, a per-account code cap, a cap on parallel
  password hashing.
- **English only; the language setting is removed** (owner, 2026-11-16).
  No language choice in the app, no `language` in `Settings` (contract,
  backend) and no `language` column (removed from the phase 6
  migration; the local database was reset, as before the first deploy). Replaces
  "Language is saved but English only for now".
- **Row-level security: the mechanism now, tables as they come** (owner,
  2026-11-16). A `solacliq_app` role that owns nothing; each company
  request runs in a transaction that switches to it and sets the
  company; policies on company tables. Company notifications first; log
  in and `/me` unchanged. Details in `architecture.md`.
- **Uploads wait for the real R2 bucket** (owner, 2026-11-16), not a local
  stand-in.
- **Strict tenant isolation: the API's login is restricted** (owner,
  2026-11-16). The server connects as `solacliq_api`
  (`APP_DATABASE_URL`), which policies restrict, instead of the owner;
  with no scope a query sees nothing. Policies on `orgs` and
  `memberships` too, with three scopes (company, person, platform).
  The server won't start on a login that could bypass them. Replaces
  "log in and `/me` unchanged" above: they run in the person's scope.
  No tenant middleware: the extractors already do that check per
  handler.
- **R2 set up (2026-11-16): two private buckets, one key each.**
  `solacliq-uploads-dev` and `solacliq-uploads`, in MarkCliq's
  Cloudflare account (business card on file). Account API tokens (they
  outlive any one person's login), Object Read & Write on one bucket
  each. The server signs URLs itself, with no AWS SDK. Upload type and
  size are part of the signature.
- **Phase 8 shape (owner, 2026-11-16):** a basic `customers` table now
  (what a task shows: name, phone, address, map pin, kW, stages);
  Phase 9 adds the agent, KYC and documents to it. A task's photo slots
  and checklist are set per task (seed now, admin website later).
- **Uploads are checked when attached, not by webhook (owner,
  2026-11-16).** The app learns from R2's own answer to its PUT; the
  server learns when a record attaches the upload: a signed HEAD to R2
  (exists, right size), else 422. R2 has no direct webhook (event
  notifications need a Queue and a Worker), and nothing needs to know
  sooner. Uploads unused for 24 hours are swept hourly, file and row.
- **Worker task rules (2026-11-16, phase 8).** "Today" holds open work
  due today or overdue, plus returned tasks and tasks on hold whatever
  their date, and submitted ones still with the admin, in Indian time.
  Photos are flagged, never refused, over 500 m from the customer's pin
  or with a fix rougher than 50 m. Submitting closes an open problem
  (the work got done). Replies are allowed on any open task, not only
  returned ones. A problem or reply reaches the admin through the
  task's history; an admin feed for them comes with the admin website.
  History gets one "photos uploaded" line per round of photos.
- **Files belong to a company (owner, 2026-11-16).** Uploads moved to
  `POST /orgs/{org_id}/uploads`: the same membership check as every
  company endpoint. Files are named `orgs/<org_id>/<purpose>/<id>` in
  R2, the `uploads` row has `org_id` with a company row-level security
  policy, and records point at it with `(org_id, upload_id)`. The server
  signs only files under the request's company. Every place that takes
  an upload is already inside a company, so nothing needed a personal
  upload. One bucket per company was rejected: real separation, but
  buckets, tokens and CORS per customer for no gain at this size.

## 2026-11-17

- **Expense rules (phase 8, F7).** Amounts from 1 paisa to ₹10 lakh: a
  bigger one is a typo, not a site cost. The day is an Indian date, not
  in the future and not over a year ago. The note may be empty (the
  category says what it was). A linked task must be the caller's own. A
  new receipt is accepted only while the admin has it sent back
  (`expense.locked` otherwise); the earlier receipt stays in R2 as a
  record. Spec: `features/F7-expenses.md`.
- **References come from a per-company counter** (`org_counters`,
  `counter.rs`): `EXP-0001` now, the admin website's `TSK-` and `SC-`
  later. Taken in the record's own transaction, so two at once never
  share a number and a failed request gives its number back.
- **"My documents" (#38) moves to phase 9 (owner).** It only reads
  documents, and in phase 8 nothing can write them: worker IDs come from
  the admin website, customer KYC from customer registration (phase 9).
  Built now, its table would be designed before the KYC flow it mostly
  serves, and only the seed would fill it. It's built with registration
  instead, on one documents table, after the KYC encryption and
  retention question (handoff, "Open") is decided.
- **KYC storage and retention (owner).** Aadhaar stored masked (last 4
  digits), never in full; PAN encrypted like bank account numbers; KYC
  files get no second layer of encryption (private bucket, per-company
  folders, 15-minute links, R2's own encryption at rest). A rejected
  registration's KYC is deleted after 30 days; an installed customer's
  files 1 year after handover, keeping the masked numbers. Built in
  phase 9. All data rules now live in `data-policy.md`, one place to
  read with a client.
- **Customer registration rules (owner; spec `features/F4-customer-registration.md`).**
  A company can't register the same customer twice (same email, phone
  or consumer number): 409 `registration.duplicate`, naming who
  registered them; the first stands. An existing account whose email
  was never verified is linked with its password cleared, so only the
  email's owner can set one. No Aadhaar or PAN number is collected, only
  the document photos. A rejected customer stays in the agent's list as
  "Not taken up" (`KycStatus.rejected`).
- **The emulator always cold-boots, on the GPU (owner).** Its crashes
  came from restoring a quick-boot snapshot saved by an abrupt exit:
  the GPU layer rebuilt the screen before its graphics context existed
  and read a null string (core dumps, `gfxstream::TextureResize`). The
  AVD now never loads or saves snapshots; rendering stays `-gpu host`
  (RTX 3060). Software rendering is never used: it hangs the machine.
- **Customer install (owner, phase 10; spec `features/F9-customer-install.md`).**
  The subsidy is worked out from the PM Surya Ghar table (homes: ₹30,000
  per kW for 2 kW, ₹18,000 for the 3rd, ₹78,000 at most) and the admin
  can change it. The default payment plan is advance 30%, on
  installation 60%, on handover 10% (provisional, for the pilot vendor
  to confirm). Companies get a UPI id; without one the app offers bank
  transfer only. A customer whose install isn't set up gets
  `install.not_started` and the app says so instead of an error. Live
  energy after handover is out: it needs inverter data.
- **App fixes from testing phase 10.** "Pay by UPI" with no UPI app on
  the phone now says so (Android throws instead of answering false); ten
  screens' reload and retry no longer crash debug builds (a `setState`
  that returned a Future); home tiles shrink a long amount to fit
  instead of cutting it off; sizes read "5 kW", not "5.0 kW"; the
  payment screens no longer promise a receipt that doesn't exist.
- **The admin actions are built before the website (owner: "complete
  the app end to end").** Every app flow stopped at a step only the
  company takes (approve a task, verify a customer, confirm a payment);
  the API for those steps is built and tested now, the website's screens
  come on top later. A verified customer gets the install with the
  default plan, the advance due in 7 days; approving a task moves the
  customer to the next stage; paying the advance makes an approved
  commission payable. Spec: `features/admin-actions.md`.
- **End-to-end tests.** `backend/tests/lifecycle.rs` runs one install
  from company registration to handover through the API (every person
  sets a password with the emailed code). `make app-e2e` drives each
  role's main flow in the real app on the emulator against the seeded
  API.
- **Emulator on this machine (NVIDIA, Wayland).** The host OpenGL
  translator crashes the emulator when an app's surfaces are torn down
  (snapshot restore, uninstall). Guest ANGLE avoided that but drew
  Flutter corrupted; it is not used. The two machine freezes that day
  were the 15 GB of RAM running out (emulator, Gradle daemons and a
  full Rust test build at once), not the GPU: those never run together
  now (`mobile/CLAUDE.md`). Flow tests are best run on a real phone over USB; see
  `mobile/CLAUDE.md`.
- **Push notifications through Firebase (F12, owner approved the spec
  2026-11-17).** One Firebase project, `markcliq-solacliq`, under the
  markcliq.co Google Workspace, Analytics off, the three app ids
  registered. The server's key was made by allowing key creation on
  that one project, then the organisation's "no new keys" rule was put
  back. Keys live outside the repo (`~/Desktop/solacliq-firebase-key.json`,
  `FCM_SERVICE_ACCOUNT_KEY_FILE`). The Gmail and push sign-ins share
  `backend/src/google.rs`.
- **Attack testing, 2026-11-17.** A black-box script (159 checks: other
  companies' data, wrong roles, reused and forged tokens, reused or
  faked uploads, bad input, races, decisions out of order, removed
  members and suspended companies) and the real app on the emulator
  (server down, revoked login, removed access, denied permissions, big
  fonts, double taps). No server error, no data across companies, races
  held. Fixed: upload kinds are limited
  to the roles that use them; the app reads every page of tasks and
  expenses (a month with over 25 claims showed the wrong total); the
  expense keypad stops at the server's ₹10 lakh; the expense form asks
  before losing a draft; the camera no longer loops through permission
  prompts. Notifications still show the first page only (a feed).
  A proof photo's time is not checked against the server's clock: the
  admin judges an odd one when reviewing (owner, 2026-11-17).
- **SolaCliq's logo direction: the sun rising behind MarkCliq's awning
  (owner, 2026-11-17).** SolaCliq is MarkCliq's product, so its mark uses
  MarkCliq's own sign, the striped scalloped shop awning in MarkCliq's
  rust red (#b2402c) and white, with SolaCliq's sun (#f6c445) rising
  behind it, on a cream app-icon tile. Warm and friendly, for homeowners
  and field crews. Chosen file: `design/logo/round-3/logo-window-rise.svg`
  (dark: `-dark.svg`). The wordmark follows MarkCliq's ("Sola" upright,
  "Cliq" italic, the i's dot a sun). Rounds 1–3 and the rejected
  readings are kept in `design/logo/`. Not yet trademark-checked.
- **Logo kit built (2026-11-17).** `design/logo/kit/build_kit.py`
  generates every logo file from one geometry: SVG masters, PNGs, web
  icons and favicon, and the app's Android icons for all three flavours
  (adaptive launcher in a cream tile, round, themed monochrome, the
  status-bar icon). Below 24 px a small cut is used: all five awning
  panels solid and joined (three separate panels read as legs). Usage
  rules: `design/logo/kit/GUIDELINES.md`. Checked on the emulator: the
  launcher icon inside the round mask with its DEV badge, and a real
  push's status-bar and shade icons.
- **Splash from the logo kit (2026-11-18).** Android's launch screen is
  cream with the mark in the middle on every version (Android 12+ through
  its own splash API, using the launcher foreground, so dev and staging
  show their badge). The app's `SplashPage` draws the same mark
  (`SolaLogo`, generated by `build_kit.py`) at the same size and place,
  and the window behind the app is cream, so a cold start never flashes
  white or black. Cream in dark mode too: the app is light-only. Checked
  on the emulator (Android 16): cream throughout, no jump, a fade into
  the home screen.
- **Company logos inside the shared app (F15, owner, 2026-11-18).** Each
  company's admin uploads its logo (PNG or JPEG, up to 1 MB) and its
  people see it in the app: above the home header's titles and in the
  workspace list, with the company's initials when there is none. The
  app's name, icon and splash stay SolaCliq's (not white-labelled), and
  there are no per-company colours, which could break contrast. The
  logo is a private file like any other, shown through signed links;
  the app caches it by the link's path, so it isn't fetched again on
  every refresh. Until the website's settings page exists, MarkCliq sets
  logos through the API. Tried with RY Enterprises' logo (one of the
  first vendors) in the R2 dev bucket.
- **"SolaCliq" under the mark on the splash (owner, 2026-11-18).** The
  launch screen shows the mark over the wordmark (`ic_splash`, from the
  logo kit), the same on every flavour (dev and staging no longer show
  their badge there), replacing the mark-only splash above. Measured on the emulator:
  Android 12+ draws the splash icon at 288 dp with the middle 192 dp
  circle visible, not the 240 dp assumed before. So the lockup is sized
  to that circle, Android 7–11 and the app's `SplashPage` draw the same
  288 dp square, centred, and the hand-over holds still.
- **Marketing graphics with Stageshow (owner, 2026-11-18).** Four graphics
  of the app for the website, for vendors: an animated hero (a worker's
  proof photo approved, a 12 s loop) and three feature cards (install
  tracker, expenses, the vendor's own logo). Built with Stageshow (MIT) in
  the app's own look and icons, kept in `marketing/` as React components
  plus MP4/WebM and 2x PNGs; the website copies what it needs (this repo
  never writes there). All data illustrative; the hero's photos are the
  design files' thumbnails, licence unknown, to confirm before publishing.
- **A promo video with Remotion, as an evaluation (owner asked, 2026-11-18).**
  A 31 s video in `marketing/remotion/`, 16:9 for the website and 9:16 for
  Reels and Status (`marketing/media/solacliq-promo.mp4`, `-vertical.mp4`): the mark animating in, the
  promise, proof photos, expenses, the homeowner's tracker, the vendor's
  logo, the lockup. Remotion's licence is free only up to 3 employees or
  while evaluating; MarkCliq has four, so publishing it needs a Remotion
  Company License. Not decided yet.
- **First deploy kit (owner, 2026-11-19).** The VPS already runs Caddy,
  so Caddy fronts SolaCliq instead of nginx (HTTPS without certbot). The
  owner runs every server command; Claude has no access to production.
  The API binary is built locally with cargo-zigbuild for glibc 2.30+,
  so the server needs no Rust toolchain. The database owner login is not
  a superuser: CREATEROLE and the admin option on `solacliq_app` are
  enough for the row-level security migration (checked against a fresh
  Postgres 17). Production uses the one Firebase project and its own R2
  bucket, `solacliq-uploads`, with its own token and CORS. Correction to
  2026-11-16: only `solacliq-uploads-dev` exists in Cloudflare; the
  owner creates `solacliq-uploads` before the deploy. While the owner
  tests on the VPS with the staging app, a separate
  `solacliq-uploads-stg` is used; at go-live the test data is wiped and
  the settings point at `solacliq-uploads`. Backups are daily dumps on
  the same VPS for now; an off-site copy is still to decide.

## 2026-11-20

- **Legal drafts (owner asked; pending owner and lawyer review).**
  Privacy Policy, Terms of Use (with the app's end-user licence) and
  Company Terms (with the data-processing terms) in `legal/`, written
  from what the code does, against the DPDP Act 2023 and Rules 2025, the
  IT Act's SPDI Rules and Google Play's user data policy. MarkCliq is the
  Data Fiduciary for accounts and quote requests and each company's Data
  Processor for its records. The blanks to fill and the product changes
  they need (agree at sign-up, public pages, account deletion, customer
  consent notice) are in `legal/README.md`.
- **Agreements are stored, not just ticked (owner, 2026-11-20; F16).**
  A tick only on the screen proves nothing (DPDP Act s. 6(10) puts the
  proof on us), so each agreement is a row: version, time, source, IP;
  add-only, deleted with the account. Only a new account gets one at
  sign-up or registration (the request isn't logged in, so it can't
  speak for an existing account, which is asked after login instead).
  The tick follows the app's consent pattern (an error on submit, not a
  disabled button). Whether agreements outlive account deletion is
  decided with account deletion.
- **Production bucket created (owner, 2026-11-20).** `solacliq-uploads`
  in Cloudflare R2: location hint Asia-Pacific, public access off, CORS
  GET and PUT from `https://solacliq.markcliq.com` only (no localhost),
  an Account API token `solacliq-prod` with Object Read & Write on this
  bucket only. The keys are in the owner's password manager and go only
  into the server's settings file.
- **Attendance is self-marked, without location (owner, 2026-11-20;
  F17, after go-live).** Every EPC Installer and Sales Agent taps
  "Start day" and "End day"; the server's clock sets the time. No
  location is read, so the data policy's promise that only the proof
  camera reads it stays. The org admin only monitors (today, month,
  CSV) and doesn't mark or correct attendance: the admin isn't there to
  take a register. A tap shows the person opened the app, not where
  they were; one location reading per tap can be added later if a
  vendor needs it.
- **Commission agents don't mark attendance (owner, 2026-11-20; F17).**
  They aren't bound to the company or the hours they put in; they're
  paid per customer. Installers and salaried sales mark it.

## 2026-11-22

- **A tap's time is the server's clock less the phone's wait (F17).**
  The first rule (the server's time unless the tap arrived over 5
  minutes after the phone's time, then the phone's) recorded a wrong
  time for anyone whose phone clock runs slow: an online tap looked
  late and took the phone's time. The app now sends when it tapped and
  when it sent, both by the phone's clock; their gap is right whatever
  the clock says, so the server counts the tap that long before it
  arrived. Over 5 minutes' wait is still marked sent late.
- **A retry that races its first request gets the first answer (F17).**
  It used to meet the first request's row and answer "already started".
- **The admin's attendance lists keep anyone with a day in the range,
  whatever their role is now (F17)**, so a month's record never loses
  days when someone is re-added with another role.
- **No camera button in the installer's tab bar (owner, 2026-11-22).**
  It opened the camera on whichever task the app guessed was next, so a
  worker standing at one site could shoot proof for another customer's
  task; it was also the path behind the QA submit bug (QA-03). Proof is
  taken from a task, after the worker has picked it. The installer's tab
  bar is Home, Tasks, Expenses, Profile. Sales keep their "+" (adding a
  customer has no "which one" to guess).
- **Money shows exactly, never rounded (QA-05).** `formatRupees` drops
  only empty decimals: ₹1,240 and ₹4.55. A rounded amount on an expense
  or a payment is a wrong amount.
- **Any file is taken; the admin judges what it shows (owner,
  2026-11-22; QA-07).** A check of each file's bytes was built and
  removed the same day: it could block a real upload. The declared type
  comes from the name, else the first bytes, else JPEG, and is never a
  reason to refuse. A file that can't be previewed shows as a file icon.
- **One answer for a wrong, expired, used-up or unsent email code
  (QA-08).** "Expired", or "too many tries" on the sixth guess, came
  only for emails that had a code, which gave away who has an account.
  All are `auth.code_invalid` now (so the sixth try is no longer 429);
  the app and website say "wrong or has expired". 429 is only the per-IP
  limit. Only a race on a correct code still answers `auth.code_expired`.
- **Every app error reaches the device log (QA-02).** Flutter's, uncaught
  async errors and bloc errors print to logcat in every build. Bloc
  states print only in debug: they hold customers' details.
- **Crash reporting is on, through Firebase Crashlytics (owner,
  2026-11-22).** Replaces the proposed Sentry: Firebase is already in
  the app. Release builds only. An error goes as its type and stack,
  never its message, which can quote what someone typed. No user id,
  logs or Analytics. A broken screen counts as fatal; an async or bloc
  error doesn't.
- **A site's location is only a lat and long (owner, 2026-11-22: "just
  get lat, long, no checks on our end for now").** The agent taps to
  save it from their phone while registering; it's optional. Nothing
  compares or judges it, or a proof photo's position: the 500 m and
  50 m flags and the camera's "At site" are gone. The columns `far`,
  `inaccurate` and `distance_m` stay, unwritten, in case checks return.
- **The Privacy Policy changed inside version 1.** It isn't in effect
  until 25 November 2026, and F16 doesn't allow version 2 until the
  website has its re-agree screen. Anyone who agreed while testing isn't
  asked again (go-live wipes test data).
- **Sign-up becomes code first; fixed later (owner, 2026-11-22; QA-27,
  QA-28).** Today sign-up saves a password, name, phone and terms tick
  before the inbox is proven, and a second sign-up keeps them, so whoever
  signs up first with someone's email owns the account once its real
  owner enters the code. The direction: email, then code, then details
  and password. The owner put the fix off. Until it's built the takeover
  is live (`features/F1-accounts-login.md`, "Known flaw").
- **KYC documents up to 50 MB, for now (owner, 2026-11-22: "for now
  lets limit docs to 50mb").** Replaces "don't put a limit" from the
  same day. The app, API and database enforce it. Receipts and proof
  photos stay at 10 MB and logos at 1 MB; whether receipts follow is
  open (`features/F5-documents.md`).
- **The admin website is built as W0 to W4 now (owner, 2026-11-22: "go
  ahead and build the admin site from w0-w4"), W5 and W6 later
  (`features/admin-website.md`).** Approved with it: the app's iOS v2
  tokens from the start (`tokens.web.json` goes); go-live moves to when
  W0 to W4 are done; the admin can move a stage without a task; a price
  is editable until the advance is paid; customers without an agent come
  after launch; the admin sees only the last 4 digits of a payout account.
- **Cross-origin writes are refused by the server (A8).** `SameSite=Lax`
  treats every markcliq.com subdomain as the same site. The check is the
  browser's `Sec-Fetch-Site`, else `Origin` against `Host`, not a token:
  nothing for the app or the website to carry.
- **A price change sets a claimed payment back to due.** The claim was
  for another amount; confirming it would record money nobody sent.
- **An admin screen is always read again when opened, and an open
  decision closes if its record changes under it.** Found in the browser
  test: cached screens hid "Approve", and "Ask for it" could turn into
  "Yes, received".
- **"Do whatever remains. Fix whatever needs fixing" (owner,
  2026-11-22).** Builds what was specced, deferred or listed as a gap,
  each with its recommendation. Not a go-ahead to commit, push, deploy
  or ship.
- **Sign-up is code first now (QA-27, QA-28 fixed).** Replaces the
  deferral of the same day. An unproven email has no account row at
  all, and Postgres refuses a password on an unverified account.
- **Code emails are 3 an hour per email**, as F1's spec said and the
  code didn't: guessing was limited only per IP. The per-IP limits on
  sign-up and code emails go from 10 to 30 an hour, as Indian mobile
  networks put many phones behind one address.
- **Dead ends closed (2026-11-22).** A false payment claim goes back to
  due, an expense can be rejected for good, and customers hear when a
  visit moves or they aren't taken up. The rejection reason is shown to
  the customer too.
- **Admin notifications are never pushed**: written as already handled,
  as decided on 2026-11-15.
- **Several files per KYC document (F5, 2026-11-22), as specced.** A
  breaking change to registration: no old-build compatibility. Replaced
  files stay linked, so retention can delete them.
- **F18 data rights (2026-11-22), defaults to confirm:** a deleted
  person's name stays on a company's records; a company's admin closes
  their account through MarkCliq; KYC retention ships switched off, so a
  deploy can't be what first deletes real data.
- **`auth.code_expired` is gone (2026-11-22).** The race that still gave
  it answers `auth.code_invalid` like every other bad code.
- **Go-live stays 25 November; the lawyer items are parked; the admin
  site comes first (owner, 2026-11-22).**
- **A release backs up first and rolls back by restoring (2026-11-23).**
  An older API won't start on a newer schema, so moving `current` back
  alone isn't a rollback. Restores go into a new database and keep the
  one they replace.
- **The admin website is rebuilt to its own artboards (2026-11-23,
  owner).** Canvas page 5, missed on 2026-11-22 when only the tokens
  were used. Copied to `design/ios-v2/5-admin/`; CLAUDE.md now points at
  it. Designed features without a backend are listed, not faked.
- **Stage templates per company (F19, 2026-11-23, owner).** Each company
  renames its 7 stages and sets each stage's checklist and photos; the
  number stays 7, so a project's stage never changes meaning. New tasks
  fill from the template; tasks already made keep theirs.
- **Landing-page leads (F20, 2026-11-23, owner).** Pushed by the landing
  page's server with a per-company key (not pulled with a Sync button).
  The admin tracks them (new, contacted, won, lost), notes them and hands
  them to Sales Agents, who see theirs in the app. A won lead is
  registered as a customer the normal way. The app's quote requests stay
  MarkCliq's ("our app leads we will manage independently").
- **Lead notices go with the app release.** An older app can't read the
  new notification kinds, so the server with F20 ships with the new APK.
- **Team edit is role and pay, not personal details (F21, 2026-11-23,
  owner).** An account can belong to several companies, so name, phone,
  email and bank stay the person's own ("we let the person edit, not the
  admin"). A role changes only with nothing open in the old role; pay
  applies from now on.

## 2026-11-24

- **The API and Postgres run in Docker on the VPS (owner, 2026-11-24).**
  One compose file (`deploy/compose.yml`): Postgres 17 with its data in
  the `solacliq-db` volume, on a network with no way in or out, and the
  API image (`backend/Dockerfile`, built on the development machine by
  `deploy/build.sh`, so the server compiles nothing). The VPS's Caddy
  stays in front and serves the website's files: same origin for the
  cookie, the write protection and the CSP. Vercel was considered and
  not chosen: a second origin would need cross-site cookies or every API
  call proxied through it, Vercel would see personal data, and commercial
  use needs its paid plan. Release with automatic rollback, nightly
  backups (outside Docker) and restore keep their behaviour, now through
  the containers; all were drilled on a scratch server, including a
  failed release that had migrated. Replaces the systemd service and
  the Postgres installed on the server (2026-11-19).
- **CI/CD (owner, 2026-11-24).** CI now also checks the server (format,
  clippy, every test against Postgres 17) and builds its Docker image.
  A version tag builds the release and attaches it to a GitHub Release;
  putting it live is a manual "Run workflow" on the Deploy workflow, so
  nothing goes live without the owner (and it works on GitHub's free
  plan, which has no environment approvals for private repos). GitHub's
  key on the VPS can only run `solacliq-deploy`, which accepts a release
  name and runs `release.sh` through a sudo rule for that alone. The
  app's Shorebird patches join once Shorebird is set up; full APK
  releases stay manual.
- **Shorebird set up (owner, 2026-11-24).** One Shorebird app per flavor
  (production, staging, development); builds use Shorebird's Flutter
  3.47.7, the version the app is tested on. The owner made the signing
  key (`~/solacliq-upload.jks`, backed up off the machine; certificate
  SHA-256 `15f7e66f…3bf6f9e`). Proved on staging: release 1.0.0+1, a
  patch delivered and booted, then rolled back. Every production APK is
  built with `shorebird release`, never `flutter build`, or it can't be
  patched. Patches in CI wait for a decision on keeping the signing key
  and the Firebase config as GitHub secrets.
- **App releases and patches from GitHub (owner, 2026-11-24).** For a
  futureproof setup: builds come from CI, not one PC; the signing key,
  Firebase config and Shorebird key are repository secrets. On GitHub's
  free plan (the owner's) they can't be limited to release tags, so only
  the owner has write access; before anyone else gets it, the signing
  key comes out or the repo moves to Pro. Patches go to Shorebird's
  `staging` track first and reach phones only when promoted. The
  workflow (`app.yml`) stays off (`APP_PIPELINE`) until those secrets are
  in place. Later, with the Play Store: Play App Signing and an upload
  key, so a lost or leaked key can be reset.
- **The production bucket is `solacliq-uploads-prod` (owner, 2026-11-24).**
  The bucket the owner made is named that, not `solacliq-uploads` as the
  entries above say; the settings and deploy steps use the real name.
  Its CORS rule allows `GET` and `PUT` from `https://solacliq.markcliq.com`
  only (checked: another origin is refused).
- **MarkCliq reviews companies on the website (owner, 2026-11-25, F22).**
  The first production sign-up showed the gap: a platform admin saw
  "pages aren't built yet" and had to approve through the API. The
  pages use the existing endpoints, no contract change. A platform admin
  always lands on the home page (MarkCliq's Companies on top), never
  jumped straight into one company.
- **CI runs only what a change touches (owner, 2026-11-25).** It ran every
  job on every push, spending the private repo's free runner minutes on
  parts a change couldn't affect (a website push ran the Rust and Flutter
  suites). Now a first job decides: backend, app, website and the
  generated-files check each run when their files change; the API
  contract, its generator settings and `ci.yml` itself run all of them;
  a release tag always runs everything. A push to master is compared with
  the last master commit CI passed, not the push before it, so a push
  whose run was cancelled, skipped or failed is still checked by the next
  one (found by the cloud review). Skipped jobs show grey, not green.
- **Fixes from the full backend review (owner, 2026-11-25).** A cloud
  review of the whole backend (PR #1 on two temporary branches) found:
  1. In Docker, Caddy's connections reach the API from Docker's gateway,
     not loopback, so `X-Real-IP` was ignored and every visitor shared
     one set of per-IP limits (30 log-ins a quarter hour for everyone).
     Now TRUSTED_PROXIES (set in `deploy/compose.yml`: Docker's address
     pools) says where the header is believed; the port is published on
     127.0.0.1 only, so nothing else reaches those addresses.
  2. A public registration could make any existing account a pending
     company's admin and record an agreement in its name. Now only that
     account, logged in, or an account nobody uses (`account_unused`).
  3. Lead limits were counted before the key was checked, so made-up
     keys could use up a company's leads. Now wrong keys count per IP
     (`LeadBadKeyByIp`), and only right ones against the company.
  4. The limiter's map could grow without end: now pruned at most once a
     second, capped at 200,000 keys (new keys refused past it), and an
     IPv6 address counts by its /64.
  5. Password hashing had no cap: now a few at once (twice the CPUs), 503
     `common.busy` past a 5-second wait; a sign-up token is checked
     before hashing.
  6. The customer's progress bar named fixed stages; now the company's
     first and last (F19), cut short in the app if long.
  7. Push: one failed device cleanup no longer drops the rest of a
     batch, and freshness is checked again before each send.
  8. The subsidy is whole paise (watts first, then integers).
  9. Stacked `//` and `///` comments became `/* */` blocks.
  Tests added for each. The review is also why releases now carry a note
  to copy a changed deploy-kit file by hand first (README).
