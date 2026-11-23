# Admin actions: the company's side of every app flow

Status: `built` (the API), 2026-11-17. Tested action by action
(`backend/tests/admin.rs`) and through the whole lifecycle
(`backend/tests/lifecycle.rs`). Asked for by the owner ("complete the
app end to end"): without these, every flow in the app stops halfway
and only the seed can move it on. These are the API calls the admin
website will make; its screens come later, on top of them.

All are `/orgs/{org_id}/...`, for the company's admin only
(`OrgMember<Admins>`), in the company's row-level security scope. Each
writes the history and the notification the person on the other side
sees, in the same transaction. A wrong state is 409 with the area's
`*.locked` or `*.not_*` code; anything not in the company is 404.

## Review queue

- `GET /orgs/{org_id}/review`: everything waiting for the admin, oldest
  first: tasks submitted or with a problem, expenses in review,
  registrations in review, commissions in review, payments claimed.

## Tasks (F6)

- `POST /orgs/{org_id}/tasks` (with an `Idempotency-Key`): create one
  for a worker: the customer,
  title, stage, due time, a note, photo slots `[{id, label, hint?}]` and
  checklist `[{id, text}]`. Numbered `TSK-0001` per company. Notifies
  the worker (`task_assigned`) and the customer (`visit_booked`).
- `POST .../tasks/{task_id}/approve`: a submitted task → `approved`.
  The customer moves to the next stage (the last stage: handover is its
  own action). Notifies the worker (`task_approved`).
- `POST .../tasks/{task_id}/return` with a note and the slots to retake:
  → `returned`. Notifies the worker (`task_returned`).
- `POST .../tasks/{task_id}/cancel` with a note: an open task →
  `cancelled`. Notifies the worker (`task_cancelled`).
- `PUT .../tasks/{task_id}/schedule` with a new time and, optionally,
  another worker: closes a reported problem. Notifies the worker
  (`task_rescheduled`; a new worker gets `task_assigned`).

## Expenses (F7)

- `POST .../expenses/{expense_id}/approve` → `approved`
  (`expense_approved`).
- `POST .../expenses/{expense_id}/return` with a note → `needs_fix`
  (`expense_returned`).
- `POST .../expenses/{expense_id}/paid` → `paid`, from `approved`
  (`expense_paid`).

## Customers (F4)

- `POST .../customers/{customer_id}/verify` with the price (`total`,
  paise) and optionally the subsidy (else the PM Surya Ghar table when
  `subsidy` was asked for, 0 when not): KYC → `approved`, every document
  `verified`, stage 1, and the install with the default plan (advance
  due in 7 days). Notifies the agent (`kyc_approved`) and the customer
  (`documents_verified`, `payment_due`).
- `POST .../customers/{customer_id}/reject` with a reason: →
  `rejected` (`kyc_returned` to the agent, worded as not taken up). The
  30-day deletion of its KYC files runs from here.
- `POST .../customers/{customer_id}/documents/{kind}/return` with a
  note: that document → `needs_fix`, the customer → `needs_fix`
  (`kyc_returned` to the agent).
- `POST .../customers/{customer_id}/commission` with an optional new
  amount and a note: `in_review` → `approved` (`commission_changed` to
  the agent when the amount changed). Becomes `payable` once the
  advance is paid (now, if it already is).
- `POST .../customers/{customer_id}/commission/paid` → `paid`
  (`commission_paid`).
- `POST .../customers/{customer_id}/handover`: the last stage done,
  the install handed over today.

## Payments (F9)

- `POST .../payments/{payment_id}/request` with a due date: a `later`
  payment → `due` (`payment_due` to the customer).
- `POST .../payments/{payment_id}/confirm`: `claimed` (or `due`, paid
  in cash at the office) → `paid` today. The first payment (the advance)
  makes an approved commission `payable` (`commission_payable`).

## Not here

The website's lists, screens and UPI id are in `admin-website.md`
(built 2026-11-22). Not yet: a worker's ID documents and editing a
payment plan. The KYC deletion jobs are F18 (built, switched off).
