# How SolaCliq handles data

The one place for the rules on who can see what, where data lives, what
is encrypted and how long it is kept. Written so it can be read with a
client. Each rule is marked:

- **Built**: in the code today, and tested.
- **Decided**: agreed, built with the feature that needs it.
- **Open**: not decided yet.

Keep this file current: when a rule changes, change it here and log the
decision in `decisions.md`.

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
  gallery), with the GPS position, its accuracy and the time. Photos far
  from the site (over 500 m), with poor GPS (over 50 m) or a faked
  location are flagged to the admin.
- **Built.** R2 encrypts every stored file on its disks (Cloudflare's
  default). We add no second layer of file encryption: the private
  bucket, per-company folders and short links protect access.

## KYC (Aadhaar, PAN and other documents)

- **Decided 2026-11-17** (built with customer registration, phase 9):
  - Aadhaar numbers are stored **masked, last 4 digits only**. The full
    number is never stored as text.
  - PAN numbers are stored **encrypted**, with the same method as bank
    account numbers.
  - KYC files: protected as photos and documents above.
- **Decided 2026-11-17: how long KYC is kept.**
  - A registration that's rejected: its KYC files and details are
    deleted 30 days after the rejection.
  - An installed customer: KYC files are kept until **1 year after
    handover** (covering the subsidy claim), then deleted; only the
    masked numbers stay.
- **Open.** Whether a customer can ask for earlier deletion, and how
  (in the app, or through the company).

## Passwords, logins and codes

- **Built.** Passwords are stored only as an Argon2 hash; nobody can
  read them, including us.
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

## Where it all lives

- **Built.** The database and API run on MarkCliq's own server
  (`solacliq.markcliq.com`); files are in Cloudflare R2; emails are sent
  through Google Workspace (Gmail API).
- **Open, at the first deploy (phase 5).** Database backups: how often,
  where they're kept, how long, and a tested restore.

## Not collected

- No location tracking: the app reads the phone's position only while
  the proof camera is open.
- No contacts, call logs or other phone data.
