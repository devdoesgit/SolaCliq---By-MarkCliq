# F4 Customer registration (Sales, phase 9)

Status: `built` (agent side), 2026-11-17: #38–42 and the agent's home, run end to end in the app against R2. The admin's side waits for the website. Spec drafted and approved by the owner 2026-11-17. The app's
screens are built against the mock (2026-10-26 onwards); this is the
backend behind them, endpoints #38–42 (`backend-handoff.md`, M5).

## Goal

A sales agent registers a customer on site: their details, the site and
connection, the KYC documents, and the customer's consent. The customer
gets an app account and an email at once. The company admin verifies the
registration on the website, or sends one document back for the agent
to fix. The agent follows each customer they brought in: KYC, install
stage and, for a commission agent, their commission.

## Who

- **Agents** (`agent`, either pay type): register, list and open their
  own customers, fix a returned document.
- **Workers and customers**: "my documents" (#38).
- The admin's side (verify, reject, return a document, approve or change
  a commission) comes with the admin website. The seed writes customers
  in each state meanwhile.

## Lifecycle

Registration (what the agent sees as `kyc_status`):

`in_review` → `approved` (the admin verified it), or `needs_fix` (one
document sent back with a note) → the agent sends a new one →
`in_review`. The admin can also reject it (`rejected`): see "Open" for
how the agent sees that.

The contract's `CustomerRegistration.status` (`submitted`, `verified`,
`rejected`) is the same thing seen from the registration: `submitted`
covers `in_review` and `needs_fix`.

## Registering a customer (#39)

`POST /orgs/{org_id}/customer-registrations`, idempotent.

**Checked, in this order:**

1. Fields as in the contract: name, 10-digit phone, email, address,
   city, PIN code (6 digits), state, DISCOM, consumer number, sanctioned
   load and proposed size in kW (more than 0, up to 1000), connection
   type, roof type, subsidy, `consent` true (else 422 on `consent`).
   The site's `lat` and `lng` are optional (2026-11-22): both or
   neither, stored as sent. See "Site location".
2. Documents: each kind at most once. Required: Aadhaar, PAN,
   electricity bill, land document, signature
   (`registration.document_required`, 422, naming the kind); bank proof
   too when `subsidy` is on (`registration.bank_proof_required`).
   Optional: roof photo, name change.
3. Commission: only for a commission agent (else 422
   `registration.commission_not_allowed`); 0 to ₹10 lakh in paise, with
   an optional note.
4. **Already a customer here** (decided 2026-11-17): if this company already has
   a customer with the same email, phone or consumer number, 409
   `registration.duplicate`, saying who registered them and when. The
   first registration stands; the admin sorts out a real dispute.
5. Each document is an upload of this company (purpose `kyc`), the
   agent's own, checked in R2 like every attached file.

**Then, in one transaction:**

- the customer record, numbered `SC-0001` per company, with the agent
  as its registrar and `kyc_status = in_review`;
- one document row per file (status `in_review`);
- the commission, if any (`in_review`);
- the customer's account and membership (below).

**The customer's account** (`product.md`, "How customers arrive"):

- No account with that email: one is made with no password, and a
  `customer` membership in this company.
- An account exists and its email is **verified**: no new account; a
  `customer` membership is added and the email says so.
- An account exists but its email was **never verified** (decided
  2026-11-17):
  it gets the membership too, but any password on it is cleared. Anyone
  could have signed up with that email; only the real owner, proving it
  with the emailed code, can set one now.
- Already a member here in another role (a worker, say): 409
  `registration.duplicate` too. A person holds one role per company (a
  membership is one row per person and company).

**After it commits:** the email to the customer: who registered them
(the company and the agent), what was registered (size, address), and
how to set up the app ("Set up your account": the emailed code sets a
password and verifies the email).

## Site location (owner, 2026-11-22)

"Just get lat, long, no checks on our end for now."

- Step 2 has "Site location (optional)". A tap asks for permission and
  reads the phone's position once. It's never read without a tap.
- Location off, not allowed or not found: says so (with Open settings
  for the first two) and never blocks "Next" or submitting. A failed
  retake keeps the position it had.
- Saved as `customers.lat` and `lng`, which the installer's Directions
  already use. Not in scope: accuracy, distance or mock checks, a map,
  changing it after submitting.

## My customers (#40, #41)

- `GET /orgs/{org_id}/my-customers`: the customers the caller
  registered, newest first, all of them (no paging: the app sums
  Earnings from this list).
- `GET /orgs/{org_id}/my-customers/{customer_id}`: one of them; 404 for
  anyone else's.
- `detail`, the one line under each customer:
  - `in_review`: "Sent today" / "Sent 14 Nov";
  - `needs_fix`: the returned document and the admin's words, e.g.
    "Electricity bill: photo is blurry";
  - `approved`: "Stage 2 · Structure" (the 7 stages below).
- `stage` once approved; `returned` while a document is back with the
  agent; `documents` as a summary ("All 6 verified", "1 to fix");
  `commission` for commission agents (status, the agent's amount if the
  admin changed it, the admin's note).
- `advance`: comes with payments (phase 10); left out until then.

**Install stages** (the app's and the contract's list; one fixed list
until companies can set their own): Site survey, Structure, Panel
installation, Wiring and inverter, Earthing, Net meter, Handover.

## Fixing a returned document (#42)

`PUT .../my-customers/{customer_id}/documents/{kind}` with `upload_id`:
only the document the admin sent back (409 `registration.locked`
otherwise). The new file replaces it (the old one stays in R2 as a
record), the document and the customer go back to `in_review`.

## My documents (#38)

`GET /orgs/{org_id}/me/documents`:

- **Customer:** their KYC documents in this company (kind, status, a
  short detail), and `uploaded_by`: the agent who collected them.
- **Worker:** their own ID documents in this company. Nothing writes
  these until the admin website can (empty until then).

## Storage and privacy (`data-policy.md`)

- One `documents` table for customer KYC and worker IDs: company-scoped
  by row-level security, each pointing at an upload in the company's
  own folder.
- **No Aadhaar or PAN number is collected.** The form takes only the
  document photos (the contract has no number fields), so there is no
  number to mask or encrypt. The data policy says so.
- Retention, as decided: a rejected registration's KYC files are
  deleted 30 days after the rejection; an installed customer's 1 year
  after handover. The deletion job is built with the admin's reject
  action and with handover (phase 10), the first moments either can
  happen.

## Notifications

- None in this phase: every event an agent is notified of
  (`kyc_returned`, `kyc_approved`, `install_started`,
  `commission_*`) is an admin action, written when the website does it.

## Not in scope

The admin's side; payments and the advance (phase 10); referral links
(F11); editing a registration after it's sent (only the returned
document can change).

## Decided with the owner (2026-11-17)

- **Duplicates:** 409 `registration.duplicate` when the company already
  has a customer with the same email, phone or consumer number; the
  first registration stands. (Also answers the vendor question in
  `questioner.md`, "two agents claim the same customer", until the
  pilot vendor says otherwise.)
- **Unverified existing accounts:** linked, password cleared.
- **No Aadhaar or PAN numbers:** the form takes the document photos
  only, so no number is stored.
- **Rejected customers stay in the agent's list** as "Not taken up"
  (`KycStatus` gains `rejected`, in the contract and the app), so a
  deal the company later turns down doesn't silently vanish.
- New error codes: `registration.duplicate` (409) and
  `registration.locked` (409, a document that wasn't sent back).

## Notes (tested 2026-11-17)

- Scenario tests (`backend/tests/customers.rs`, 25): two agents
  registering one household at once give one customer; an email in other
  capitals is the same customer; a receipt, another agent's or another
  company's file, or one file twice is refused with nothing kept and no
  email; one person registered by two companies is one account in two
  workspaces; two returned documents are fixed one at a time; the new
  customer sets a password with the emailed code and sees the company.
- In the app: a duplicate shows who registered the customer first; the
  agent corrects the details and resubmits with the same documents
  (the refused attempt used none of them). Leaving the form with
  anything entered asks before discarding it.
