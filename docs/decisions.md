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

