# Product

What SolaCliq does and for whom. Decided by the owner unless marked
otherwise. Open questions for the pilot vendor are in `../questioner.md`;
nothing listed there is settled.

**Pilot vendor:** RY Enterprises (Bhadrak).

## Product shape

- One shared app, **SolaCliq**, used by every org. It onboards solar
  businesses and runs their whole customer, worker and agent lifecycle. Not
  white-labelled per vendor.
- **A product MarkCliq sells to solar EPC businesses.** Pilot with 2–3
  vendors for about 2–3 months, then open to more businesses.
- Multi-tenant: every org-owned row belongs to an org (vendor).
- Android first. iOS later; the owner wants to test on their own iPhone.
- The admin dashboard is a website. Workers, agents and customers use the
  mobile app only (no customer web portal for now).
- English only.
- No in-app purchases or billing. MarkCliq sells and distributes the app to
  orgs directly, outside the app.
- WhatsApp is not in the MVP.

## Roles

| Role | Where | What they do |
|---|---|---|
| Platform admin (MarkCliq) | API now; admin website later | Approves or rejects new companies, suspends them, gives support access when an org asks |
| Org admin (one per org) | Admin website | Sees everything in their org, creates EPC installer and sales agent accounts, approves requests |
| EPC Installer (`worker` in code) | Mobile app | Jobs, geotagged installation photos, own expenses |
| Sales Agent (`agent` in code) | Mobile app | Brings customers, shares referral links, logs own expenses and commission |
| Customer | Mobile app | Sees stage, cost breakdown and payments; shares referral links |

## Orgs and accounts

- **Companies register themselves, then MarkCliq approves.** In the app
  ("I run a solar EPC company") the owner gives their name, email and
  mobile, and the company's GSTIN, legal and trade name, business type and
  address. The server checks the GSTIN's checksum and takes the PAN and
  state from it; a GSTIN can have one live registration. The company is
  saved **pending**, with the owner as its admin, and MarkCliq is emailed
  (info@markcliq.com). After a background check and a call, MarkCliq
  approves it (**active**; the owner is emailed how to log in) or rejects
  it (**rejected**, with a reason emailed; they can register again).
  Later: a GST verification API to pre-fill the form and refuse cancelled
  GSTINs.
- One admin per org for now (no staff sub-roles).
- The org admin creates worker and agent accounts and hands out the logins.
- Login is by **email** (with password) for everyone. Phone number login
  comes after SMS (DLT registration).

## How customers arrive

**A. On their own.** They install the app (from the Play Store once it is
there), sign up with email, verify it with a 6-digit code and look around.
A new account starts empty. If they later work with any MarkCliq vendor,
the vendor's customer record links to their account automatically (see
Customer linking).

**B. Registered by an agent** (decided 2026-10-18; changed 2026-11-15):
1. The agent enters the customer in the app (details, site, documents)
   and submits it. No code and no verification step with the customer.
2. On submission the customer's account is created automatically, with
   no password yet, and the customer is emailed at once: who registered
   them (the company and the agent), what was registered, and how to set
   up their account in the app, where they follow every stage of their
   install.
3. Registration status: **draft → submitted → verified / rejected**. The
   **org admin** verifies or rejects it on the website; the customer sees
   the status in the app. A verified registration enters the install
   stages at "lead" (assumed; to confirm).
4. To set up, the customer opens the app and sets a password with an
   emailed code ("Set up your account"); that also verifies their email.
5. If the email already has an account, no new account is made; the
   existing one is linked and the person is told.

Customer details (the org's record), the login account, and document
records are kept separate.
- **Identity:** one global account per person, joined to orgs through
  memberships `(user, org, role)`. A person can hold roles in several orgs
  (org switcher in the app). An org adding an existing email adds a
  membership, not a duplicate account.
- **Customer linking:** each org keeps its own customer record, linked to the
  person's account automatically when the org's record matches it on a
  **verified** email or phone, or when the customer signs up through a
  referral link. The person is notified of every link.

## Platform admin

Kept small:

- Company list with GST details, registration date and status (pending,
  active, suspended, rejected). Through the API for now
  (`/platform/orgs`); a website page later.
- Approve or reject new companies.
- Suspend an org (non-payment, abuse). Its users see a message, not a broken
  app.
- Support access: enter an org only when it asks, time-limited and logged.
  Customer documents are not in the platform admin's default view (DPDP Act).

## Customers

- Install stages: lead → site survey → quote → subsidy paperwork → install →
  net metering → service.
- Customers see their stage, their full cost breakdown and everything they
  have paid. Payments are recorded, never collected (no gateway).

## Workers and agents

- Workers capture installation photos with the camera and geolocation.
- Workers and agents log their own expenses.
- Agents enter their own commission; the org admin reviews it.
- Approval is the end of an expense or commission request. Reimbursement is
  not tracked.

## Referrals

- Referral links can be shared by agents, past customers and others, and
  identify who referred.
- A referred customer gets a cash bonus or a discount on installation. The
  org admin sets it.
- Whether the referrer gets anything is open (in `../questioner.md`).

## Documents

- Document uploads (customer papers, quotes, etc.) to private storage.

## Notifications

- In-app notifications for everyone. Customers also get SMS and email.
- Email goes through MarkCliq's Google Workspace (decided 2026-10-18;
  replaces Zoho).
- SMS needs DLT registration in India; the owner is checking how long it
  takes. Until then, SMS is not scheduled.
