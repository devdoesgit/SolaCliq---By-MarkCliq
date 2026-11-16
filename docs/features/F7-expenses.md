# F7 Expenses

Status: `building`. Worker and agent side built 2026-11-17 (backend
#34–37, app since 2026-10-26). The admin's approvals queue comes with the
admin website.

## Goal

A worker or agent logs what they spent for the company (fuel, material,
labour, other), with a receipt photo and the task it was for. The admin
approves it, sends it back with a note, or marks it paid with salary or
cash. Approval is the end of it: reimbursement itself isn't tracked
(`product.md`).

## Lifecycle

`in_review` → `approved` → `paid`, or `needs_fix` (the admin's note) →
a new receipt → `in_review` again.

## In scope (built)

- `GET /orgs/{org_id}/expenses`: the caller's own, newest first, paged.
- `POST /orgs/{org_id}/expenses` (idempotent): amount in paise (1 to
  ₹10 lakh), category, note (up to 200, may be empty), the day (India;
  not in the future, not over a year ago), optional receipt (an upload of
  this company, purpose `receipt`, checked in R2), optional task (one of
  the caller's own). Numbered `EXP-0001` per company.
- `GET /orgs/{org_id}/expenses/{expense_id}`: one of the caller's own,
  with a 15-minute receipt link, the admin's note while it needs a fix,
  and who decided.
- `PUT .../expenses/{expense_id}/receipt`: only while `needs_fix` (409
  `expense.locked`); back to `in_review`, with an optional note.
- The worker's home: "Expenses · with admin" counts their `in_review`
  ones.

## Not in scope yet

The admin's queue (approve, send back, mark paid) and the notifications
it sends (`expense_approved`, `expense_returned`, `expense_paid`): admin
website. `cargo run -- seed` gives Ravi one expense in each state
meanwhile.
