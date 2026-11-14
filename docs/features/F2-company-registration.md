# F2 Company registration and MarkCliq review

Status: `done` (2026-11-14, with backend phase 4). Left for later: a
website review page, and a GST verification API lookup.

## Goal

A solar company registers itself; MarkCliq checks it and approves or
rejects it before anyone can use it.

## Flow

1. In the app ("I run a solar EPC company"): the owner's name, email and
   mobile; the company's GSTIN, legal name, trade name (optional, shown in
   the app), business type and address. The app checks the GSTIN's
   checksum and shows the state it stands for.
2. `POST /org-registrations` checks everything again (GSTIN checksum;
   PAN and state taken from it; one live registration per GSTIN) and, in
   one transaction, saves the company `pending`, the owner's account (no
   password; an existing account is reused) and their `org_admin`
   membership. MarkCliq (`REVIEW_EMAIL`, info@markcliq.com) and the owner
   are emailed.
3. MarkCliq checks the company and calls them, then
   `POST /platform/orgs/{id}/status`: `active` (owner emailed how to log
   in, using "Forgot password?" for a first password) or `rejected` with a
   note (emailed; the GSTIN can register again). Later `suspended` ⇄
   `active`.

Until approved, the owner sees their company in `/me` with a message, and
`/orgs/{id}/...` answers 403 `org.pending` (or `org.rejected`).

## Data

`orgs`: `legal_name`, `business_type` (enum), `gstin` (unique among
non-rejected), `pan`, `address_line_1/2`, `city`, `state`, `pin_code`,
`reviewed_at`, `reviewed_by`, `review_note`; status `rejected` added.

## Codes

`org.gstin_invalid` (422), `org.gstin_taken` (409), `org.rejected` (403),
`platform.not_admin` (403), `org.status_change_not_allowed` (409).

## Tests

`backend/tests/registration.rs`, `backend/src/gstin.rs`,
`mobile/test/access/`.
