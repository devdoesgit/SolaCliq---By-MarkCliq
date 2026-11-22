# Admin website: the company's side, on screen

Status: `spec`, waiting for the owner's review (2026-11-22). No code yet.
The admin actions exist (`admin-actions.md`). Endpoints below move into
`api/openapi.yaml` phase by phase, once this is approved.

## Goal

An org admin runs their company from `solacliq.markcliq.com` without
MarkCliq, the seed or the API: adds the team, verifies customers, gives
out and approves work, and settles expenses, commission and payments
(QA-04).

## Today

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

## For the owner to decide

1. **Look.** Recommended: the app's iOS v2 tokens from W0, as
   `decisions.md` planned for when the site is redone, so screens aren't
   built twice.
2. **Go-live.** 7 to 10 days were kept for this site (`decisions.md`),
   and the legal date is 25 November. Recommended: move the date to when
   W0 to W4 are done.
3. **Stages without site work** (quote, subsidy paperwork) only move
   when an installer's task is approved. Recommended: a "Move stage"
   action for the admin, in W2.
4. **A wrong price** can't be corrected after verifying. Recommended:
   editable until the advance is paid, in W2.
5. **Customers without an agent.** Only agents can register one.
   Recommended: after launch, unless RY Enterprises has no agents.
6. **Payout bank details.** The Privacy Policy says only the last 4
   digits are ever shown, so the admin can't pay from SolaCliq's copy.
   Recommended: keep that for the pilot; show the last 4.
