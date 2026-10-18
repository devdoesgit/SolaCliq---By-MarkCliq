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
| Platform admin (MarkCliq) | Admin website | Approves or denies new orgs, suspends orgs, gives support access when an org asks |
| Org admin (one per org) | Admin website | Sees everything in their org, creates worker and agent accounts, approves requests |
| Worker (installer) | Mobile app | Jobs, geotagged installation photos, own expenses |
| Agent | Mobile app | Brings customers, shares referral links, logs own expenses and commission |
| Customer | Mobile app | Sees stage, cost breakdown and payments; shares referral links |

## Orgs and accounts

- **Org signup is self-serve, then approved.** A vendor signs up with their
  GSTIN. The backend checks the checksum, derives state and PAN, and fetches
  the business details (legal name, trade name, address, status, business
  type) from a GST verification API to pre-fill the form. A cancelled GSTIN
  is rejected. The org stays **pending** until a MarkCliq platform admin
  approves or denies it. MarkCliq offers setup help on request.
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

**B. Registered by an agent** (decided 2026-10-18):
1. The agent enters the customer in the app. The customer's account is
   created automatically.
2. A 6-digit code is emailed to the customer; the customer reads it out
   and the agent enters it. This proves the email is real and that the
   customer agreed.
3. The agent completes the registration (details, documents) and submits
   it. Registration status: **draft → submitted → verified / rejected**.
   The **org admin** verifies or rejects it on the website. A verified
   registration enters the install stages at "lead" (assumed; to confirm).
4. The customer later logs in with their email. The first time, they set a
   password using a fresh emailed code ("Set up your account").
5. If the email already has an account, no new account is made; the
   existing one is linked and the person is notified.

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

- Org list with GSTIN details, signup date, status (pending, active,
  suspended) and basic counts.
- Approve or deny new orgs.
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
