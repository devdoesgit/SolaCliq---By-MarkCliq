# Features

Built one at a time. Each feature is small, finished and tested before the
next one starts.

**Build order: mobile first, admin website last** (decided 2026-10-18).
The mobile screens are built and run against the mock; the backend now
catches up phase by phase (`backend-phases.md`). The admin side of every
feature is built last; until then MarkCliq and org admins use the API
directly or the seed.

Admin order: F3 → F4 → F5 → F6 → F7 → F8 → F11 → F12 → F13 → F14 (F2
review page if needed).

Status: `planned` → `spec` (spec written, under review) → `building` →
`done`.

| # | Feature | Status |
|---|---|---|
| F0 | Foundation | done (CI with the first deploy) |
| F1 | Accounts and login | done (app, website, backend; SMTP with the first deploy); **open: sign-up takeover QA-27, fix deferred 2026-11-22** |
| F2 | Company registration and MarkCliq review | done (app form, backend; review through the API, no website page; GST lookup API later) |
| F3 | Team: org admin creates worker and agent accounts | building (app and backend done; website Team page to build) |
| F4 | Customers and install stages | building (Sales: register, customers list and detail, fix a returned document; endpoints await owner review; spec to write) |
| F5 | Documents | spec: several files per document (50 MB limit built) (`features/F5-documents.md`), waiting for review |
| F6 | Worker jobs and geotagged installation photos | building (worker screens on the mock; spec and endpoints await owner review) |
| F7 | Expenses and the approvals queue | building (worker: log, sent, list, detail, replace receipt; spec to write) |
| F8 | Agent commission | building (mobile: commission on review, earnings, payout bank; endpoints await owner review) |
| F9 | Customer app: stage, cost breakdown, payments | building (mobile: track, payments with UPI or bank claim, documents; endpoints await owner review) |
| F10 | Customer linking | planned |
| F11 | Referrals | planned |
| F12 | Notifications | built 2026-11-17: in-app lists for every role and Personal, settings, and push (`features/F12-notifications.md`), run end to end on a phone through the real FCM |
| F13 | Distribution and updates | planned |
| F14 | Platform admin: suspend, support access | planned |
| F15 | Company logo | building 2026-11-18: backend and app done, checked end to end with RY Enterprises' logo in the R2 dev bucket; website upload page to build (`features/F15-company-logo.md`) |
| F16 | Agreeing to the terms | built 2026-11-20: backend, app, website pages; checked on the emulator (`features/F16-terms-consent.md`) |
| F17 | Attendance | building: backend and app done 2026-11-22 (offline tap checked on the emulator against the real API); website pages to build (`features/F17-attendance.md`) |

## Which part each feature touches

| # | Backend | Mobile | Admin website |
|---|---|---|---|
| F0 | Axum skeleton, DB, CI | Flutter shell, theme, tooling | React shell, theme |
| F1 | Accounts, auth, tokens and cookies | Sign up, log in | Log in, password reset |
| F2 | Registration, GSTIN check, review | Registration form | (later) review page |
| F3 | Memberships | Org switcher | Team accounts |
| F4 | Customers, stages, costs, payments | Agent: my customers | Customers, pipeline, detail |
| F5 | Uploads, documents | — (to confirm) | Documents on customer detail |
| F6 | Jobs, captures | Worker jobs, camera capture | Assign jobs, review photos |
| F7 | Expenses, approvals | Log expenses | Approvals queue |
| F8 | Commission | Enter commission | Approve commission |
| F9 | Customer read endpoints | Customer: stage, costs, payments | — |
| F10 | Linking on verified email/phone | Link notice | — |
| F11 | Referral codes, attribution | Share link | Referral settings |
| F12 | Email, push, in-app | Notifications | Notifications |
| F13 | — | Updater, Shorebird, signing | APK download page |
| F14 | Suspension, support access, audit | Suspended-org message | Org list, suspend, support access |
| F15 | Logo upload kind, set and remove, link in `/me` | Logo in the home header and workspace list | Logo upload in settings |
| F16 | Agreements table, `terms_version`, `/me/terms` | Tick on sign-up and registration, "Before you start" screen | Public terms and privacy pages |
| F17 | Attendance days, start and end of day | "Start day" and "End day" on Home | Today and month views, CSV |

## Scope per feature

**F0 Foundation.** Repo layout, Flutter and React app shells with the MarkCliq
theme, OpenAPI spec skeleton, client generation, Prism mock, dev tooling
(emulator, MCP servers), CI.

**F1 Accounts and login.** Global user accounts, email signup and
verification, login, password reset, bearer tokens (mobile) and cookies
(admin), roles from memberships.

**F2 Company registration.** A company registers in the app with its GST
details; the server checks the GSTIN (checksum; PAN and state from it)
and saves it pending with its owner as admin. MarkCliq checks it, calls
them, and approves or rejects it (with a reason emailed). Later: GST
verification API to pre-fill the form and catch cancelled GSTINs.

**F3 Team.** Org admin creates worker and agent accounts; an existing email
gets a membership instead of a new account; org switcher.

**F4 Customers.** Customer records, install stages, stage changes, cost
breakdown and recorded payments (admin side). Agents register customers in
the app: the account is created and the email verified with a code the
customer reads out; registration status draft → submitted → verified /
rejected, decided by the org admin.

**F5 Documents.** Upload and view customer documents through presigned R2
URLs; document types; role-based access.

**F6 Worker jobs.** Assign workers to customers; worker sees their jobs;
live-camera capture with GPS, accuracy and time; the server
stores them as sent.

**F7 Expenses.** Workers and agents log expenses with receipts; the shared
approvals queue for the org admin. Spec: `features/F7-expenses.md`.

**F8 Commission.** Agents enter commission per customer; goes through the
approvals queue.

**F9 Customer app.** Customer sees stage timeline, cost breakdown and
payments. Spec: `features/F9-customer-install.md`.

**F10 Customer linking.** Auto-link org customer records to accounts on
verified email or phone; notify on every link.

**F11 Referrals.** Referral links for agents and customers; attribution;
bonus or discount set by the org admin.

**F12 Notifications.** In-app for everyone; email for customers; SMS once
DLT registration is done.

**F13 Distribution.** Download page, APK on R2, `latest.json` updater,
Shorebird patches, signing setup.

**F14 Platform admin.** Suspend orgs; time-limited, logged support access.

**F16 Agreeing to the terms.** Every account ticks to agree to the Terms of
Use and Privacy Policy (`legal/`); the server records who, which version,
when and where from.

**F17 Attendance.** Every EPC Installer and Sales Agent marks their own
day in the app: "Start day" and "End day", timed by the server's clock.
No location, no photo. Offline taps are sent later with the phone's
time and flagged if it is far from when they arrived; a day never ended
shows "no check-out". The org admin only monitors: today (who's in,
since when, who hasn't started) and a month grid with a CSV export, on
the website. The admin doesn't mark or correct anyone. Out of scope:
location, selfies, leave, holidays, payroll.

## Per-feature spec

`docs/features/F<n>-<name>.md`, written when a feature starts: goal,
users, in and out of scope, API, screens, data, acceptance checks, notes.
