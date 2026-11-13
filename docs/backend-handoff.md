# Backend handoff: what the mobile app needs

Written 2026-10-29, when the mobile app's screens were all built and wired
against the Prism mock. This is the work list for the Rust API. The exact
shapes (every field, enum and example) are in `../api/openapi.yaml`; this
page says what to build, in what order, and the rules behind each endpoint
that a schema can't express.

Every endpoint below is called by the app today (`make mock` serves the
same contract), so an endpoint is done when the app works against it
unchanged. Check one by pointing the app at the real API:
`--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.

## Conventions (all endpoints)

From `architecture.md`, restated where the app depends on them:

- **Base:** `/api/v1`. JSON, `snake_case`.
- **Auth:** `Authorization: Bearer <access>` from the app; the session
  cookie `solacliq_session` from the admin website, on the same endpoints.
  `security: []` marks the public ones.
- **Org scope:** every `/orgs/{org_id}/...` call needs a membership of the
  caller in that org with the role the endpoint names, else 403. Rows are
  filtered by org (row-level security) and, for "my" endpoints, by the
  caller.
- **Errors:** RFC 9457 `application/problem+json` with `code`
  (`<area>.<reason>`), `detail` safe to show, and `errors[]` per field on
  422. The app reacts to these codes; others show the generic message:

  | Code | Status | When |
  |---|---|---|
  | `auth.invalid_credentials` | 401 | Wrong email or password |
  | `account.email_unverified` | 403 | Login before verifying |
  | `account.password_not_set` | 403 | Login on an account an admin or agent created |
  | `auth.code_invalid` / `auth.code_expired` | 400 | Verify or reset code |
  | `auth.too_many_attempts` | 429 | Any rate limit |
  | `auth.password_too_weak` | 422 | Under 8 characters or no number |
  | `auth.session_expired` | 401 | Refresh token dead: app logs out |
  | `validation.failed` | 422 | Any other field error |
  | `registration.bank_proof_required` | 422 | Subsidy on, no bank proof |
  | `registration.commission_not_allowed` | 422 | Salaried agent sent a commission |
  | `task.incomplete` | 422 | Submit with photos or checklist missing |
  | `task.locked` | 409 | Change to a task not with the worker |
  | `quote.consent_required` / `quote.phone_required` | 422 | Quote form |
  | `member.*` | 409/422 | Team (admin website) |

- **Money:** integer paise (`i64`) in every amount. Never floats.
- **IDs:** UUIDv7. **Timestamps:** RFC 3339 UTC. **Plain dates**
  (`spent_on`, `due_on`, `paid_on`...): `YYYY-MM-DD` strings.
- **Idempotency:** writes marked *idem* below take an `Idempotency-Key`
  header (UUID). Store key + caller + response for at least 24 h and return
  the stored response on a repeat; the app retries after lost responses.
- **Lists:** `?cursor=&limit=` with `page.next_cursor` (null on the last
  page), where the schema has `page`.
- **Images and files:** never in JSON. `POST /uploads` hands out a
  presigned PUT URL to the private R2 bucket; the record then carries the
  `upload_id`. Reads return short-lived presigned GET URLs.
- **Phones:** 10 digits, no `+91`.
- **Mock-only header:** the app sends `Prefer: example=<name>` in
  development. Ignore it.

## Build order

Each milestone makes one part of the app work for real. Within a
milestone, top to bottom.

### M1. Accounts and sessions (F1) — everything else needs it

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 1 | `GET /health` | public | — | `Health` | 503 when the DB is down; shows on the welcome screen in dev |
| 2 | `POST /auth/signup` | public | `SignupRequest` | 202 | Creates the account unverified and emails a 6-digit code. 202 even if the email exists (no account probing) |
| 3 | `POST /auth/email/verify` | public | `VerifyEmailRequest` | 204 | Codes last 5 minutes, 5 tries; the sixth is 429 |
| 4 | `POST /auth/email/resend` | public | `EmailRequest` | 202 | One new code per minute per email; within it, 202 and nothing sent |
| 5 | `POST /auth/login` | public | `LoginRequest` | `LoginResponse` | Tokens for the app (`access_expires_in` in seconds; lifetimes are yours to set). For the website, sets two HttpOnly, SameSite=Lax cookies: `solacliq_session` (access) and `solacliq_refresh` (refresh, `Path=/api/v1/auth/refresh`) |
| 6 | `POST /auth/refresh` | public | `RefreshRequest` | `TokenPair` | OAuth 2.1 rotation, app and website alike: every refresh returns a new access **and** refresh token and the old refresh token dies; reusing an old one revokes the session → `auth.session_expired`. The website sends the refresh cookie instead of a body and gets new cookies |
| 7 | `POST /auth/logout` | auth | — | 204 | Revokes the session; the website's cookies are cleared |
| 8 | `POST /auth/password/forgot` | public | `EmailRequest` | 202 | Emails a 6-digit code (5 minutes). Same flow sets a first password (`account.password_not_set`) |
| 9 | `POST /auth/password/reset` | public | `ResetPasswordRequest` | 204 | Revokes all sessions; also verifies the email |
| 10 | `GET /me` | auth | — | `Me` | **Drives the whole app.** `memberships[]` with `org {id, name, status, phone}`, `role`, and for agents `pay_type` (`commission`/`salary`) |

### M2. Personal workspace and joining a company

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 11 | `POST /access-requests` | public | `AccessRequestCreate` | 202 | An EPC asks to join. Notify MarkCliq (email) |
| 12 | `POST /quote-requests` | auth, *idem* | `QuoteRequestCreate` | `QuoteRequest` | Lead for verified EPCs near the PIN code. Returns the indicative estimate |
| 13 | `GET /me/invites` | auth | — | `InviteList` | Pending invites for the caller's email |
| 14 | `POST /invites/{invite_id}/accept` | auth | — | `Me` | Creates the membership; returns the updated `Me` |
| 15 | `POST /invites/{invite_id}/decline` | auth | — | 204 | |
| 16 | `GET /me/notifications` | auth | cursor | `NotificationPage` | Personal only: `quote_shared`, `invite_received`, `guide` |
| 17 | `GET /me/details` | auth | — | `PersonalDetails` | Phone, address, emergency contact, payout bank. Bank comes back as `account_last4` + `bank_name`, **never** the full number |
| 18 | `PUT /me/details` | auth | `PersonalDetails` | `PersonalDetails` | Partial: only fields sent change. A bank needs `account_number` + `ifsc`; fill `bank_name` from the IFSC. Encrypt the account number at rest |
| 19 | `GET /me/settings` | auth | — | `Settings` | Defaults: push on, WhatsApp off, sound on, `en` |
| 20 | `PUT /me/settings` | auth | `Settings` | `Settings` | Whole object |

### M3. Shared company plumbing

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 21 | `GET /orgs/{org_id}/home` | any member | — | `HomeSummary` | **Server-composed per role** (see "Home" below) |
| 22 | `POST /uploads` | auth | `UploadCreate` | `Upload` | `content_type` jpeg/png/pdf, `size_bytes` ≤ 10 MB (422 over), `purpose` `receipt`/`kyc`/`proof`. Presigned PUT valid 15 min. An upload id can be used once, by its owner |
| 23 | `GET /orgs/{org_id}/notifications` | any member | cursor | `NotificationPage` | Newest first, `unread_count`. Each carries the id it opens: `task_id`, `expense_id` or `customer_id` |
| 24 | `POST /orgs/{org_id}/notifications/read` | any member | — | 204 | Marks all read |

### M4. Worker (F6, F7)

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 25 | `GET /orgs/{org_id}/tasks?view=today\|upcoming\|done` | worker | view | `TaskPage` | Only the caller's tasks. `done` = approved + cancelled |
| 26 | `GET /orgs/{org_id}/tasks/{task_id}` | worker | — | `Task` | Photos as presigned URLs |
| 27 | `POST .../tasks/{task_id}/photos` | worker | `ProofPhotoCreate` | `Task` | `slot_id`, `upload_id`, `taken_at`, `lat`, `lng`, `accuracy_m`, `mocked_location`. Flag (don't reject) a photo far from the site or with a mocked location; the admin sees the flag. 409 `task.locked` unless `assigned`/`returned` |
| 28 | `PUT .../tasks/{task_id}/checklist/{item_id}` | worker | `{done}` | `Task` | 409 when locked |
| 29 | `POST .../tasks/{task_id}/submit` | worker, *idem* | `{note?}` | `Task` | 422 `task.incomplete` unless every slot has a photo (retakes retaken) and every item is ticked. → `submitted` |
| 30 | `POST .../tasks/{task_id}/problems` | worker, *idem* | `TaskProblemCreate` | `Task` | `reason` + `note`; notifies the admin. Task stays `assigned`, shown "On hold" |
| 31 | `POST .../tasks/{task_id}/messages` | worker | `{text}` | 204 | Reply to the admin on a returned task; goes into history |
| 32 | `GET .../tasks/{task_id}/history` | worker | — | `TaskHistory` | Append-only events |
| 33 | `GET /orgs/{org_id}/me/stats` | worker | — | `WorkerStats` | This month: tasks, returned, average minutes on site |
| 34 | `GET /orgs/{org_id}/expenses` | worker, agent | — | `ExpensePage` | The caller's own, newest first |
| 35 | `POST /orgs/{org_id}/expenses` | worker, agent, *idem* | `ExpenseCreate` | `Expense` | `amount` (paise), `category`, `note`, `spent_on`, optional `receipt_upload_id`, `task_id` (must be the caller's). Server assigns `reference` `EXP-nnnn` per org |
| 36 | `GET /orgs/{org_id}/expenses/{expense_id}` | owner | — | `Expense` | |
| 37 | `PUT .../expenses/{expense_id}/receipt` | owner | `{upload_id, note?}` | `Expense` | Only when `needs_fix` (else 409); → `in_review` |
| 38 | `GET /orgs/{org_id}/me/documents` | worker, customer | — | `MyDocumentList` | Worker: their ID (Aadhaar, PAN). Customer: their KYC, with `uploaded_by` (the agent) |

### M5. Sales: agents and salaried sales staff (F4, F8)

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 39 | `POST /orgs/{org_id}/customer-registrations` | agent, *idem* | `CustomerRegistrationCreate` | `CustomerRegistration` | Details, site, connection, KYC `documents[]` (upload ids), `consent` must be true. `commission` (paise) + `commission_note` only for `pay_type=commission` (else 422 `registration.commission_not_allowed`). Bank proof required when `subsidy` (422). 409 if the email is already this org's customer. Reference `SC-nnnn` |
| 40 | `GET /orgs/{org_id}/my-customers` | agent | — | `CustomerList` | Customers the caller registered, newest first, each with `kyc_status`, a one-line `detail` you compose ("Bill photo blurry", "Stage 2 · structure", "Sent today") and, for commission agents, `commission`. **The app sums Earnings from this list**, so include every customer with a commission |
| 41 | `GET /orgs/{org_id}/my-customers/{customer_id}` | agent (registrar) | — | `CustomerDetail` | Adds `phone`, `stage {index, count, label}` once approved, `returned {kind, title, note}` when a document is sent back, `documents`, `advance {status, paid_on}`, and `commission` with `proposed_amount` + `admin_note` when the admin changed it. 404 for someone else's customer |
| 42 | `PUT .../my-customers/{customer_id}/documents/{kind}` | agent (registrar) | `{upload_id}` | `CustomerDetail` | Only the returned document (else 409); → `in_review` |

### M6. Customer (F9)

| # | Endpoint | Who | Request | Response | Notes |
|---|---|---|---|---|---|
| 43 | `GET /orgs/{org_id}/my-install` | customer | — | `Install` | Stages with `done`/`next`/`upcoming`, `next_visit` (who, when, phone), `total`, `subsidy`, `payments[]` (`due`/`claimed`/`paid`/`later`), `upi_uri` for the due one, `handed_over_on` after handover |
| 44 | `POST .../my-install/payments/{payment_id}/claim` | customer, *idem* | `{method: upi\|bank_transfer}` | `Install` | Only the `due` payment (else 409) → `claimed`, and notify the admin. The company marks it `paid` (website). **Paying the advance makes the agent's commission `payable`** |

### Admin website (already built, F1 and F3)

`GET/POST /orgs/{org_id}/members`, `DELETE /orgs/{org_id}/members/{user_id}`
(org admins only), plus login, logout, `/me` and password reset above.
Adding a member with an email that has an account adds a membership; a new
email creates the account with no password (`account.password_not_set`) and
emails a set-up link.

## Server-side rules the app relies on

**Roles.** `org_admin` (website only; the app shows "use the website"),
`worker`, `agent` (shown as Sales, with `pay_type`), `customer`. One person
can hold several memberships; each `(org, role)` is its own workspace in
the app.

**Home (`GET /orgs/{org_id}/home`).** The app draws whatever parts you
return, so each role's home changes without an app update. Per role:

- *Worker:* `week` (7 days with dots), `headline` (tasks today), tiles with
  actions `to_submit` and `expenses`, list "Up next" of tasks, rows with
  `action: "task"` and the task id as `id`.
- *Agent (commission):* headline (customers this month), tiles `fix` (KYC to
  fix) and `earnings` (payable), progress "KYC this month", list "Recent
  customers" with `action: "customer"`.
- *Agent (salary):* same, but tiles `fix` and `review`, progress "Installs".
- *Customer before handover:* headline (stage x of 7), tiles `track` (next
  visit) and `payments` (advance due), progress with stage labels, rows
  `documents` and `track`.
- *Customer after handover:* `energy` instead of the headline (live kW,
  today's kWh, sunrise/sunset, hourly curve), tiles `savings` and `bill`.
- Always `unread_notifications` for the bell dot.

Tile and row actions the app understands: `to_submit`, `expenses`, `fix`,
`review`, `earnings`, `track`, `payments`, `savings`, `bill`; rows `task`,
`customer`, `documents`, `track`. Anything else is not tappable.

**Task status.** `assigned` → (photos, checklist) → `submitted` → admin
`approved` (and the next stage's task is created and assigned) or
`returned` (with a note; retake slots marked `retake`) → back to
`assigned`-like editing → `submitted`. `cancelled` by the admin at any
point. Only `assigned`/`returned` accept changes (409 `task.locked`).

**Expense status.** `in_review` → `approved` → `paid` (with salary), or
`needs_fix` (with `admin_note`) → new receipt → `in_review`.

**Customer KYC.** `in_review` → `approved` (account created or linked,
welcome email with a set-password link) or `needs_fix` (one document
returned with a note) → re-upload → `in_review`.

**Commission** (commission agents only). `in_review` → `approved` (admin
may change the amount: keep the agent's as `proposed_amount` and add an
`admin_note`) → `payable` when the customer's advance is paid →
`paid` when the admin pays out (`paid_on`).

**Notifications to create** (kind → who → links):

| Event | Kind | To | Link |
|---|---|---|---|
| Task assigned / approved / returned / cancelled / rescheduled | `task_*` | worker | `task_id` |
| Expense approved / returned / paid | `expense_*` | worker, agent | `expense_id` |
| KYC returned / submitted / approved, install started | `kyc_*`, `install_started` | agent | `customer_id` |
| Commission changed / payable / paid | `commission_*` | commission agent | `customer_id` |
| Visit booked, payment due, documents verified | `visit_booked`, `payment_due`, `documents_verified` | customer | — (opens Track, Payments, Documents) |
| Quote shared, invite received, new guide | `quote_shared`, `invite_received`, `guide` | person (`/me/notifications`) | — |

## Not in the contract yet: the admin actions behind this data

The app reads tasks, approvals, KYC decisions, commissions and payments
that an org admin creates on the website. Those admin endpoints are drafted
in the admin phase (build order: admin last). Until then, seed them with a
backend command or SQL so the app has real data:

- Create a customer's install (stages, payment plan, subsidy) and tasks per
  stage with photo slots and a checklist; assign a worker.
- Approve or return a submitted task; cancel or reschedule a task.
- Approve, return or mark paid an expense.
- Approve a customer registration or return one document; approve or
  change a commission; mark a commission paid.
- Mark a customer's payment paid; book the next visit; hand over.

## Not needed

- No customer chat (dropped 2026-10-27). The only messages are a worker's
  replies on a task (`POST .../tasks/{task_id}/messages`).
- No earnings endpoint: summed in the app from `my-customers`.
- No "my quote requests" list yet.

## Open for you to decide

- `pay_type` lives on the membership; default `commission` for agents if
  missing. Confirm that's where you want it.
- Encryption and retention for bank account numbers and KYC files.
- Where the PM Surya Ghar subsidy figure comes from (fixed table by kW, or
  entered by the admin).
- UPI: the `upi_uri` uses the org's UPI id; who sets it (org settings,
  admin phase).
