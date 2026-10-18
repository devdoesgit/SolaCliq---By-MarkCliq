# Features

Built one at a time, in this order. Each feature is small, finished and
tested before the next one starts. Order and scope are a proposal until the
owner confirms them.

Status: `planned` → `spec` (spec written, under review) → `building` →
`done`.

| # | Feature | Status |
|---|---|---|
| F0 | Foundation | building |
| F1 | Accounts and login | building |
| F2 | Org signup, GSTIN autofill, platform approval | planned |
| F3 | Team: org admin creates worker and agent accounts | planned |
| F4 | Customers and install stages | planned |
| F5 | Documents | planned |
| F6 | Worker jobs and geotagged installation photos | planned |
| F7 | Expenses and the approvals queue | planned |
| F8 | Agent commission | planned |
| F9 | Customer app: stage, cost breakdown, payments | planned |
| F10 | Customer linking | planned |
| F11 | Referrals | planned |
| F12 | Notifications | planned |
| F13 | Distribution and updates | planned |
| F14 | Platform admin: suspend, support access | planned |

## Which part each feature touches

| # | Backend (owner) | Mobile (Claude) | Admin (Claude) |
|---|---|---|---|
| F0 | Axum skeleton, DB, CI | Flutter shell, theme, tooling | React shell, theme |
| F1 | Accounts, auth, tokens and cookies | Sign up, log in | Log in, password reset |
| F2 | Orgs, GSTIN lookup, approval | — | Org signup; platform approve/deny |
| F3 | Memberships | Org switcher | Team accounts |
| F4 | Customers, stages, costs, payments | Agent: my customers | Customers, pipeline, detail |
| F5 | Uploads, documents | — (to confirm) | Documents on customer detail |
| F6 | Jobs, captures, location flags | Worker jobs, camera capture | Assign jobs, review flags |
| F7 | Expenses, approvals | Log expenses | Approvals queue |
| F8 | Commission | Enter commission | Approve commission |
| F9 | Customer read endpoints | Customer: stage, costs, payments | — |
| F10 | Linking on verified email/phone | Link notice | — |
| F11 | Referral codes, attribution | Share link | Referral settings |
| F12 | Email, push, in-app | Notifications | Notifications |
| F13 | — | Updater, Shorebird, signing | APK download page |
| F14 | Suspension, support access, audit | Suspended-org message | Org list, suspend, support access |

## Scope per feature

**F0 Foundation.** Repo layout, Flutter and React app shells with the MarkCliq
theme, OpenAPI spec skeleton, client generation, Prism mock, dev tooling
(emulator, MCP servers), CI.

**F1 Accounts and login.** Global user accounts, email signup and
verification, login, password reset, bearer tokens (mobile) and cookies
(admin), roles from memberships.

**F2 Org signup.** Vendor signs up with GSTIN; checksum check, state and PAN
derived, details pre-filled from a GST verification API; org is pending
until a platform admin approves or denies it.

**F3 Team.** Org admin creates worker and agent accounts; an existing email
gets a membership instead of a new account; org switcher.

**F4 Customers.** Customer records, install stages, stage changes, cost
breakdown and recorded payments (admin side).

**F5 Documents.** Upload and view customer documents through presigned R2
URLs; document types; role-based access.

**F6 Worker jobs.** Assign workers to customers; worker sees their jobs;
live-camera capture with GPS, accuracy and time; server-side location
flags.

**F7 Expenses.** Workers and agents log expenses with receipts; the shared
approvals queue for the org admin.

**F8 Commission.** Agents enter commission per customer; goes through the
approvals queue.

**F9 Customer app.** Customer sees stage timeline, cost breakdown and
payments.

**F10 Customer linking.** Auto-link org customer records to accounts on
verified email or phone; notify on every link.

**F11 Referrals.** Referral links for agents and customers; attribution;
bonus or discount set by the org admin.

**F12 Notifications.** In-app for everyone; email for customers; SMS once
DLT registration is done.

**F13 Distribution.** Download page, APK on R2, `latest.json` updater,
Shorebird patches, signing setup.

**F14 Platform admin.** Suspend orgs; time-limited, logged support access.

## Per-feature spec

When a feature starts, write `docs/features/F<n>-<name>.md` with:

- Goal: one sentence.
- Users: which roles touch it.
- In scope / out of scope.
- API: endpoints added to `api/openapi.yaml`.
- Screens: mobile and admin.
- Data: tables and columns added.
- Acceptance: the checks that mean it is done.
- Notes: what was learned or changed while building it.
