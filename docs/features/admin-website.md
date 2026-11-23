# Admin website: the company's side, on screen

Status: W0 to W4 `built` 2026-11-22, waiting for the owner's review.
Approved the same day ("go ahead and build the admin site from w0-w4").
W5 and W6 are built (2026-11-22). The admin actions
exist (`admin-actions.md`).

## Goal

An org admin runs their company from `solacliq.markcliq.com` without
MarkCliq, the seed or the API: adds the team, verifies customers, gives
out and approves work, and settles expenses, commission and payments
(QA-04).

## Before W0 (what was found)

- Built: log in, forgot and reset password, the three legal pages, and
  an account page that lists companies. No navigation and no work screens.
- API: the decisions exist. Most of what the admin must see to make them
  doesn't. Checked against a local API with the seed on 2026-11-22:

| # | Finding | Checked by | Effect |
|---|---|---|---|
| A1 | No customers list or detail for the admin, and no link to any KYC file | 403 and 404; no `read_url` for documents | Can't verify anyone |
| A2 | Task list, detail, photos and history are installer-only | 403 | Can't see proof before approving |
| A3 | Expense list, detail and receipt are for their owner only | 403 | Can't see a receipt |
| A4 | An approved expense leaves the review queue and is listed nowhere | Approved one | Can never be marked paid |
| A5 | No read gives the admin the id of a payment that isn't claimed | Contract | Can't ask for the next payment or record cash |
| A6 | Nothing notifies an admin; a worker's reply isn't in the queue | Claim and reply: 0 notifications | Both go unseen |
| A7 | The company's UPI id has no endpoint (seed only) | Code | Customers never get the UPI button |
| A8 | Cookie POSTs without a body accept any Origin. `SameSite=Lax` lets every `*.markcliq.com` page send them | Form POST with another Origin marked an expense paid | CSRF from a sibling site |
| A9 | Two tabs refreshing together count as token theft | One 204, one 401, then the session was dead | Admins logged out at random |
| A10 | `account.password_not_set` has no message on the website | 403, mapped to `unknown` | A new owner sees "Something went wrong" |
| A11 | `quotes::rupees` drops paise in notifications and the home screens the server writes | Code: 455 becomes "₹4" | Wrong amounts (QA-05 fixed only the app) |
| A12 | Commission dates use the database's `current_date` | Database is UTC | Wrong day from 00:00 to 05:30 in India |
| A13 | Removing an installer leaves their open tasks with them | 5 before, 5 after | Work nobody can do |
| A14 | Create task takes no Idempotency-Key | Code | A double click makes two tasks |

## Phases

Each is built, tested and reviewed before the next.

| Phase | Screens | API to add or fix |
|---|---|---|
| W0 Base | Navigation, company switch, pending and suspended screens, shared table, form, dialog and file viewer, India time | A8, A9, A10, A11, A12 |
| W1 Team (F3) | List, add, remove, invited or active | Warn about open tasks on remove (A13) |
| W2 Customers (F4, F5) | List with search and stage, detail, KYC viewer, return a document, verify with price, reject | `GET customers`, `GET customers/{id}` with document links, install, payments, commission |
| W3 Tasks (F6) | List, create, proof photos with a map link, history, approve, return, cancel, reschedule or reassign | `GET` admin task list, detail with history and problem photo; A14 |
| W4 Money (F7, F8, F9) | Expenses with receipt, commissions, payments, UPI id | `GET` admin expense list and detail, `GET` and `PUT` settings |
| W5 Inbox | Home from the review queue with counts, notifications | Write admin notifications; replies in the queue; amounts on queue items |
| W6 Settings and attendance (F15, F17) | Logo, attendance today, month and CSV | None |

- W0 to W4 are the least a vendor can run on. W5 and W6 can follow.
- The admin reads are new endpoints under `/orgs/{org_id}/admin/...`, so
  the app's role rules and response shapes don't change.
- Every list is paged. Every read and action runs in the company's
  row-level security scope.
- Files open from 15-minute signed links. A PDF opens in a new tab.
- Nothing judges a file or a location: the admin does.

## Done when

- Per endpoint: the admin sees it, every other role gets 403, another
  company's record is 404.
- Per screen: loading, empty, failed, 409 (someone already decided) and
  422 states; works by keyboard and at phone width.
- One browser run of the whole lifecycle with no API call by hand:
  approved company → team → registration → verify → task → approve →
  payment → commission → handover.

## Not in scope

Referrals (F11), MarkCliq's own pages (F2, F14), APK download (F13),
reports, editing the payment plan, more than one admin per company.

Needed for launch but separate from this: the sign-up takeover (QA-27),
account deletion (app and web), KYC retention jobs, the re-agree screen
before terms version 2.

## API (tag `admin`, org admins only)

| Endpoint | Answers |
|---|---|
| `GET .../admin/customers?q&kyc_status&stage` | A page of customers. `q`: name, phone, email, reference or consumer number |
| `GET .../admin/customers/{id}` | The registration, every document with its link, price, payments, commission |
| `PUT .../admin/customers/{id}/stage` | Move stage, either way, until handover |
| `PUT .../admin/customers/{id}/price` | New total and subsidy until a payment is paid. The parts are worked out again |
| `GET .../admin/tasks?view&assignee_id&customer_id` | A page of tasks. `view`: open, submitted, problem, done |
| `GET .../admin/tasks/{id}` | The task with photos, problem photo, checklist and history |
| `GET .../admin/expenses?status` | A page of expenses, everyone's |
| `GET .../admin/expenses/{id}` | One, with its receipt and the payee's last 4 digits |
| `GET .../admin/commissions?status` | A page of commissions, with the agent's last 4 digits |
| `GET .../admin/payments?status` | A page of customer payments |
| `GET`, `PUT .../admin/settings` | The company's UPI id, and the stage names |

- A payment a customer claimed goes back to `due` when the price changes:
  the claim was for another amount. The customer is told.
- Cookie writes from another origin are 403 `auth.cross_origin`. Requests
  with a bearer token, and clients that aren't browsers, are unaffected.
- `POST .../tasks` requires an `Idempotency-Key`.

## Decided by the owner, 2026-11-22

1. **Look:** the app's iOS v2 tokens, from W0.
2. **Go-live:** moves to when W0 to W4 are done.
3. **Stages:** the admin can move a customer's stage without a task.
   (The seven stages built are all site work; quote and paperwork in
   `product.md` aren't among them. Open with the pilot vendor.)
4. **Price:** editable until the advance is paid.
5. **Customers without an agent:** after launch.
6. **Payout bank details:** the admin sees the last 4 digits only.

## Built (2026-11-22)

| Finding | Now |
|---|---|
| A1 to A5, A7 | The endpoints above and their screens |
| A6 | Replies show in the task's history. Admin notifications, and replies in the queue: W5 |
| A8 | `backend/src/origin.rs` |
| A9 | A browser lock and a shared marker (`admin/src/api/refresh.ts`) |
| A10 | Log in always offers "Set your password" (it can't say who needs it: QA-28) |
| A11, A12 | Exact paise; India's date |
| A13 | Warned on remove, marked "Removed", reassignable |
| A14 | `Idempotency-Key` required |

Also fixed while building: verifying with a price under ₹4 was a 500
(now 422 under ₹10).

Tested:

- `backend/tests/admin_site.rs`; `admin/src/features/admin.test.tsx`.
- 97 steps in Chrome on the production build, over HTTPS, against the
  real API and Postgres: registration to handover, the app's side
  through its endpoints, a real sibling-site CSRF attempt, two tabs,
  four widths, axe (WCAG A and AA).
- Not tested: real R2 (a stand-in), real email, Safari and Firefox, a
  real phone, and the app's screens against these changes on an
  emulator.

## W5 and the dead ends (2026-11-22)

- **Inbox** is a company's home: the review queue by kind, oldest first,
  with amounts, and the count in the menu. A registration sent back
  isn't in it (it waits for the agent); an approved expense is (it
  waits to be paid); so is an installer's reply nothing has followed.
- **Notifications:** registration sent or fixed, proof, problem, reply,
  expense sent or fixed, payment claimed. One row per admin, on the
  website only, never pushed. "Mark all read".
- **Payment not received** (`POST …/payments/{id}/not-received`): claimed
  goes back to due; the customer is told why and can claim again.
- **Don't accept an expense** (`POST …/expenses/{id}/reject`): from in
  review or sent back, with a reason; final; not counted in the month.
- **The customer is told** when a visit moves or is cancelled (without
  the installer's note) and when they aren't taken up (with the reason,
  which the dialog says).
- **A content security policy** in the Caddyfile.
- A NUL character in text is 422, not 500.

Suggested, not built (not in this spec):

- Photo and checklist templates per stage, so each task isn't typed out.
- App clients that tolerate enum values newer than themselves: today a
  new notification kind or status needs a new APK before the API.

## W6 notes (2026-11-22)

- The logo goes from the browser straight to R2, so **the bucket needs a
  CORS rule** allowing `PUT` with `content-type` from the website's
  origin (owner, at deploy).
- Attendance reads only. The CSV is fetched through the API client and
  saved with a UTF-8 mark, for Excel.

## Run as it will be deployed (2026-11-23)

Release binary, the real Caddyfile, the dev R2 bucket, Chrome and
Firefox. Found and fixed:

- A deploy left open browsers on a blank page (no cache rules; a missing
  script was answered with index.html).
- Log in always landed on the inbox, never the page that was opened.
- The attendance month couldn't be changed by typing, and not at all in
  Firefox: it's a list of months now.
- A refresh's unread reply kept its request open in the browser.
- A customer without documents was said to be past retention.
- Rolling back after a migration took the site down, and the documented
  restore left a database that could never migrate again
  (`deploy/release.sh`, `deploy/restore.sh`).
- The deploy guide had no way to approve a company and no R2 CORS rule.

Checked: 152 browser steps covering all 48 API calls of the built site,
46 in Firefox, 60 rows through every "Show more", and install, upgrade,
failed release and restore from `build.sh`'s archive. Not checked:
Safari, phone browsers, real email and push, the VPS itself.

Suggested, not built: a MarkCliq page to approve companies (today:
`deploy/README.md`, "Approve a company").

## The admin design (2026-11-23)

The first build used the tokens and never opened the admin artboards
(owner: "whats up with the bland UI?"). Every screen is rebuilt to
`design/ios-v2/5-admin/` and compared with it side by side.

- Home is the Overview. Verified customers open as Projects. Tasks are a
  board, expenses a list beside the open claim, a member has a page.
- Read-only API added for it: `GET .../admin/overview`, task views
  `assigned` and `returned`, and list fields (`place`, `system_kw`,
  `advance_status`, `commission_amount`, `Member.customers`).
- Whole rupees show without ".00", as in the app; paise still show.

Different from the artboards, on purpose:

| Artboard | Website | Why |
|---|---|---|
| Sun tile logo | The awning logo | Chosen after the canvas (2026-11-17) |
| Light grey text, pale field edges | Darker | AA contrast |
| "New leads" tile | "To collect" | There are no leads to count |
| ₹18.4L | ₹18,40,000 | Money is never rounded |
| Worker, Sales | EPC Installer, Sales Agent | The product's role names |
| No Payments, Attendance, notifications | Added in the same style | Built after the canvas |
| W1 to W4 | Dates | Says which week |

Drawn, and not built (each needs a backend and a decision):

- **Change a member's role** or pay type.
- **Create the next task on approve**, with its installer.
- **Edit the note** on a task.
- **Reject a commission** (it can be approved at a changed amount).
- **Export commissions for accounts.**
- **A note when approving an expense.**
- "Names match", "at site", "bill matches": checks nobody makes (the
  admin judges; owner, 2026-11-22). "Their last 5 approved" average.

Built since (2026-11-23): **Leads** (F20, the company's own landing-page
leads: the artboard's cards with Call and "Give to", not its quote
requests with Accept and Pass) and **Stage templates** (F19, as the
Settings artboard, with a name field the artboard lacks).
