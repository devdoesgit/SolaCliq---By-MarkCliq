# How SolaCliq handles data

The one place for the rules on who can see what, where data lives, what
is encrypted and how long it is kept. Written so it can be read with a
client. Each rule is marked:

- **Built**: in the code today, and tested.
- **Decided**: agreed, built with the feature that needs it.
- **Open**: not decided yet.

The public Privacy Policy built from these rules is
`../legal/privacy-policy.md`.

Keep this file current: when a rule changes, change it here and in the
Privacy Policy, and log the decision in `decisions.md`.

## Each company's data is kept apart

- **Built.** Every company's records (team, tasks, photos, expenses,
  notifications) are visible only to that company. The app's own checks
  enforce this on every request, and the database enforces it again
  underneath (row-level security): even a mistake in the app's code
  can't show one company another company's rows.
- **Built.** The server connects to the database with a restricted
  login that can't bypass those rules, and refuses to start with one
  that could.
- **Built.** A person sees only their own work inside a company: a
  worker sees their own tasks and expenses, not their colleagues'.
- **Built.** MarkCliq's platform admins see each company's registration
  details (to approve it), not its day-to-day records.

## Photos and documents

- **Built.** Files (proof photos, receipts, KYC documents) go straight
  from the phone to private storage (Cloudflare R2), never through our
  server. Nothing in the bucket is public.
- **Built.** Every file belongs to one company and is stored under that
  company's own folder. A file can only be attached to that company's
  records, and the server refuses to hand out a link to a file of any
  other company.
- **Built.** Files are shown through links that work for 15 minutes for
  that one file.
- **Built.** Before a record points at a file, the server checks the
  file really arrived, whole. Files nobody used within 24 hours are
  deleted.
- **Built.** Proof photos come from the live camera only (never the
  gallery), with the GPS position, its accuracy, the time, and whether the
  phone reported a faked location. These are stored as the phone gives
  them; SolaCliq doesn't check or flag them.
- **Built 2026-11-22: a customer's site location.** When registering a
  customer, the sales agent can tap to save the phone's position (lat
  and long only). It is optional, read only on that tap, not checked,
  and used for the installer's directions. The assigned installer and
  the company see it.
- **Built.** Size limits: a KYC document file 50 MB, up to 5 files a
  document (since 2026-11-22; replaced files stay linked to their
  customer, so deleting their KYC removes those too), a
  receipt or proof photo 10 MB, a logo 1 MB.
- **Built.** Each kind of file is for the people who use it: proof
  photos for installers, receipts for installers and sales agents, KYC
  documents for sales agents, any of them for the company's admin.
  Customers upload nothing yet.
- **Built.** A company's logo (F15) is stored like every other file:
  private, in the company's own folder, shown through 15-minute links,
  and only to that company's own people (workers, sales agents,
  customers). Only the company's admin can upload or remove it. A
  replaced logo is deleted.
- **Built.** R2 encrypts every stored file on its disks (Cloudflare's
  default). We add no second layer of file encryption: the private
  bucket, per-company folders and short links protect access.

## KYC (Aadhaar, PAN and other documents)

- **Built 2026-11-17** (customer registration, phase 9):
  - **No Aadhaar or PAN number is collected or stored**: the agent
    photographs the documents, and nothing asks for the numbers.
    (Agreed earlier: if numbers are ever added, Aadhaar is stored masked
    to the last 4 digits and PAN encrypted, like bank account numbers.)
  - KYC files: protected as photos and documents above.
- **Built 2026-11-17: who sees KYC.** The customer, the agent who
  registered them, and their company's admin. Not other agents or
  workers, and not MarkCliq's platform admins by default.
- **Built 2026-11-22 (F18), off until `KYC_RETENTION=true` on the
  server: how long KYC is kept** (decided 2026-11-17).
  - A registration that's rejected: its KYC files and details are
    deleted 30 days after the rejection.
  - An installed customer: KYC files are kept until **1 year after
    handover** (covering the subsidy claim), then deleted.
- **Open.** Whether a customer can ask for earlier deletion, and how
  (in the app, or through the company).

## Deleting an account

- **Built 2026-11-22 (F18).** In the app, with the password. The login
  and personal data are erased and memberships end. A company's records
  of the person's work or install stay with it, with the name (default,
  to confirm with the lawyer). A company's admin writes to MarkCliq.

## Agreeing to the terms

- **Built 2026-11-20 (F16).** Everyone agrees to the Terms of Use and
  Privacy Policy (`legal/`) with a tick: at sign-up, at company
  registration (with the Company Terms), or on a "Before you start"
  screen after login for accounts someone else made. The server keeps
  each agreement as its own row: who, which version, when, where from
  (sign-up, registration, app) and the IP address. Rows are never
  changed (the database refuses the API an edit) and are deleted with
  the account.
- **Built.** When the terms change in a way that matters, the version
  goes up and everyone is asked again after their next login.

## Attendance

- **Decided 2026-11-20 (F17, after go-live).** Installers and salaried
  sales staff mark the start and end of their working day in the app.
  Each day keeps only the start and end times (the server's, or the
  phone's when the tap was sent late from offline) and whether each was
  sent late. No location, no photo. The person and their company's admin
  see it; the admin only reads it and can't change it. A removed
  member's days stay with the company like their other records.

## Leads

- **Built 2026-11-23 (F20).** People who fill a company's landing page
  (run by MarkCliq for that company) are sent to that company's Leads
  in SolaCliq: name, phone, and what the form asked (email, city, bill,
  roof, a message, where they came from). The form must say the company
  may contact them; a lead without that agreement is refused.
- **Whose data:** the company's. It decides who calls, and can delete a
  lead at any time (someone asking to be forgotten). Only that
  company's admin, and the Sales Agent the admin gives it to, see it.
  MarkCliq's landing page only passes it on.
- **The key** the landing page sends with is the company's, stored only
  as a hash; making a new one stops the old one.
- **Open:** how long a company keeps a lead nobody followed up (today:
  until it deletes it); the landing page's own privacy notice, which
  must name the company. The app's own quote requests are separate and
  stay MarkCliq's.

## Passwords, logins and codes

- **Built 2026-11-22.** The website takes changes only from its own
  pages: another site, or another markcliq.com subdomain, can't act as a
  logged-in admin.
- **Built 2026-11-22.** A company's admin sees only the last 4 digits of
  an installer's or agent's payout account, not the number, IFSC or
  holder.
- **Built.** Passwords are stored only as an Argon2 hash; nobody can
  read them, including us.
- **Built 2026-11-22.** Sign-up proves the inbox first: no account, and
  no password, name or phone, exists until the emailed code is entered.
  An email that never finishes is deleted from the sign-up list within
  about a day. Log in doesn't reveal who has an account or was invited.
- **Built.** Email codes (sign-up, password reset) are 6 digits, last 5
  minutes, allow 5 tries, and are stored only as a keyed hash.
- **Built.** Login tokens are random and stored only as hashes. A
  session lasts up to 30 days and is renewed while used; access tokens
  last 15 minutes. Resetting a password ends every session.
- **Built.** Repeated attempts (logins, codes, registrations, uploads)
  are rate-limited.

## Money and bank details

- **Built.** All amounts are stored as whole paise, never as decimals.
- **Built.** Bank account numbers are encrypted (AES-256-GCM); the app
  only ever shows the last 4 digits.
- **Built.** SolaCliq tracks expenses and payments; it never collects
  money or holds card details. There is no payment gateway.
- **Built.** A customer pays the company directly, by UPI or bank
  transfer, then taps "I paid"; the company confirms it. The app only
  opens the customer's own UPI app with the company's UPI id and the
  amount filled in; it never sees bank or UPI credentials.

## Where it all lives

- **Built.** The database and API run on MarkCliq's own server
  (`solacliq.markcliq.com`); files are in Cloudflare R2; emails are sent
  through Google Workspace (Gmail API).
- **Built.** Push notifications go through Google's Firebase Cloud
  Messaging. A push carries only the notification's title and body
  (e.g. "New task assigned · Site survey") and ids, never codes, bank
  details or documents. The server keeps each logged-in phone's push
  token; logging out stops pushes to that phone, and a phone that
  changes hands only gets the newest login's. A person can turn pushes
  off in settings. Google Analytics is off in the Firebase project.
- **Built 2026-11-22: crash reports** go to Google's Firebase
  Crashlytics, from release builds only. A report has the error's type
  and where in the code it happened, the phone's model and Android
  version, the app's version, and a random id for the install. We add
  no name, email, user id, error message, form content or location.
  (A crash inside Android or a plugin is reported by Google's SDK with
  that crash's own message.) Google keeps reports 90 days.
- **Open, at the first deploy (phase 5).** Database backups: how often,
  where they're kept, how long, and a tested restore.

## Not collected

- No location tracking: the app reads the phone's position only while
  the proof camera is open, or once when a sales agent taps to save a
  customer's site.
- No contacts, call logs or other phone data.
