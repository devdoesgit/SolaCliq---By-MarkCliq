# SolaCliq Privacy Policy

**Effective:** 25 November 2026

**Last updated:** 2026-11-22 (draft, pending legal review)

This policy explains what personal data the SolaCliq app and website
collect, why, who it is shared with, how long it is kept, and the rights
you have over it. It is written to meet India's Digital Personal Data
Protection Act, 2023 and its Rules, the Information Technology Act, 2000
and its rules on sensitive personal data, and Google Play's user data
policy.

## 1. Who we are

SolaCliq is made and run by **MarkCliq**, Khushi Enclave-3, Jhampur,
Mohali, SAS Nagar, Punjab 140301, India ("MarkCliq", "we", "us").

Contact for anything in this policy: **info@markcliq.com**.
Grievance Officer: see section 11.

## 2. Two kinds of data, two different roles

SolaCliq is used by solar EPC companies ("companies") to run their work
with their staff and customers. That gives us two roles:

- **Your account (we decide how it's used).** Your name, email, phone,
  password, settings, and anything you send to MarkCliq directly, such as
  a solar quote request. For this data MarkCliq is the *Data Fiduciary*:
  we decide why and how it is processed, and this policy applies in full.
- **A company's records (the company decides).** When a company uses
  SolaCliq, the records it keeps about its customers, installers and
  sales agents (installs, tasks, proof photos, expenses, KYC documents,
  payments) are that company's records. The company is the *Data
  Fiduciary* for them, and MarkCliq is its *Data Processor*: we store and
  process them only to run SolaCliq for that company, under our
  agreement with it. For questions or requests about those records,
  contact the company first; we will help it answer, and you can always
  write to us too.

## 3. What we collect

| What | From whom | Why |
|---|---|---|
| Name, email, mobile number | Everyone with an account | To create your account, log you in, and contact you about it |
| Password | Everyone | To log you in. Stored only as a one-way hash; nobody, including us, can read it |
| Email codes | Everyone | To verify your email and reset your password. Stored only as a keyed hash, valid 5 minutes |
| Company registration details: GSTIN, legal and trade name, business type, address | Company owners | To review and approve the company on SolaCliq |
| Address, emergency contact, bank account holder, IFSC, bank name and account number | Installers and sales agents, if they choose to add them | So their company can reach them and reimburse or pay them. The account number is encrypted; only its last 4 digits are ever shown |
| Customer details: name, phone, email, address, electricity connection details (DISCOM, consumer number, sanctioned load, connection type), roof, planned system size, subsidy choice, the site's GPS position if the agent adds it | Customers, entered by a sales agent with the customer's agreement | So the company can quote, install and claim the subsidy |
| KYC document photos (for example Aadhaar card, PAN card, electricity bill) | Customers, photographed by a sales agent with the customer's agreement | For the government subsidy application and net metering. **We do not record Aadhaar or PAN numbers**, only the photos the agent takes |
| Proof photos with GPS position, accuracy and time | Installers | To prove each installation step was done on site |
| Crash reports: the error's type and where in the app it happened, phone model, Android version, app version, a random id for the install | Everyone who uses the app | To find and fix crashes. We don't add your name, email or what you typed |
| Expenses and receipt photos, commission entries | Installers and sales agents | So the company can approve them |
| Payments recorded ("I paid") | Customers | So the company can confirm what was paid. We never collect money or see bank or UPI logins |
| Solar quote request: PIN code, city, bill range, roof type, timeline, phone | Anyone who asks for a quote | To give an estimate and have MarkCliq call you, only if you tick the box agreeing to be contacted |
| Company logo | Company admins | To show the company's logo to its own people in the app |
| Your agreement to these terms: which version, when, and the IP address it came from | Everyone | To prove you agreed, as the law requires. Kept with your account and deleted with it |
| Phone's push notification token | Everyone who allows notifications | To send notifications to your phone |
| Technical data: IP address, request times, app version | Everyone | To keep the service secure (rate limits, abuse prevention) and fix faults |

**Phone permissions.** The app asks for:

- **Camera**: to take proof photos, receipts and documents.
- **Location**: while the proof camera is open, to tag the photo with
  where it was taken, and once when a sales agent taps to save a
  customer's site, for the installer's directions. The app does not
  track your location at any other time, and never in the background.
- **Notifications**: to show task, approval and payment updates. You can
  turn them off in the app's settings or in Android settings.

**What we don't collect:** contacts, call logs, SMS, other apps, your
location outside those two uses, or advertising identifiers. We do not
use advertising or analytics tracking, and we do not sell personal data.

## 4. Consent and your choices

- By creating an account you agree to this policy for your account
  data. We ask clearly, in plain language, and you can withdraw consent
  at any time by deleting your account (section 8).
- A sales agent registering a customer must confirm that the customer
  agreed to share their details and documents with the company. The
  company is responsible for getting and keeping that agreement.
- Quote requests are sent only if you tick that MarkCliq may contact you.
- Withdrawing consent does not undo what was lawfully done before, and
  some records may have to be kept for the reasons in section 7.

## 5. Who sees your data

Inside SolaCliq:

- Each company's records are visible only to that company's people, and
  each person sees only what their role needs: an installer sees their
  own tasks and expenses, not their colleagues'. This is enforced in the
  app and again in the database itself.
- KYC documents are visible only to the customer, the sales agent who
  registered them, and that company's admin.
- MarkCliq's platform admins see a company's registration details to
  approve it, not its day-to-day records. If a company asks for support,
  we may enter its account for a limited time, and that access is logged.

Outside SolaCliq, we use these service providers, only to run the
service and under their own security and confidentiality terms:

| Provider | What for | Where |
|---|---|---|
| Rackoona (VPS) | Our server, database and its daily backups | Delhi, India |
| Cloudflare (R2) | Private storage for photos and documents | Cloudflare data centres, may be outside India |
| Google (Gmail API, Google Workspace) | Sending account emails | Google data centres, may be outside India |
| Google (Firebase Cloud Messaging) | Delivering push notifications (title and short text only, never codes, bank details or documents) | Google data centres, may be outside India |
| Google (Firebase Crashlytics) | Receiving crash reports from the app | Google data centres, may be outside India |

We may also disclose data when Indian law requires it, for example to a
court or a government authority with a lawful order, or to protect
someone's safety. We never sell or rent personal data, and never share it
for advertising.

## 6. How we protect it

- All traffic is encrypted (HTTPS).
- Passwords and email codes are stored only as hashes; bank account
  numbers are encrypted (AES-256-GCM).
- Photos and documents are in private storage; nothing is public. They
  are shown through links that work for 15 minutes for one file.
- Each company's data is walled off in the database (row-level security).
- Logins, codes and uploads are rate-limited; sessions expire.
- Daily backups, kept on our server.

If a breach affects your personal data, we will tell you, and the Data
Protection Board of India, as the law requires, including what happened,
what it may mean for you and what you can do.

## 7. How long we keep it

| Data | Kept until |
|---|---|
| Your account | You delete it, or we close it |
| KYC documents of a rejected registration | 30 days after the rejection |
| KYC documents of an installed customer | 1 year after handover (covers the subsidy claim) |
| Uploaded files never attached to a record | 24 hours |
| Email codes | 5 minutes, or used |
| Login sessions | 30 days without use |
| Database backups | 14 days |
| Company records (tasks, photos, expenses, payments) | As long as the company uses SolaCliq, then as our agreement with it says |
| Crash reports | 90 days |
| Security logs | 1 year, as the DPDP Rules require |

Where a law (for example tax or GST law) requires a record to be kept
longer, we keep only that record, only as long as required.

## 8. Your rights

You have the right to:

- **Access**: a summary of the personal data we hold about you and how
  we use it.
- **Correction and updating**: most details can be changed in the app;
  for others, ask us.
- **Erasure**: to delete your account, email info@markcliq.com from
  your account's email and we will delete it within 30 days. Records a company keeps about work you
  did for it, or about your install, are the company's; we pass your
  request to it.
- **Withdraw consent** at any time (section 4).
- **Grievance redressal** (section 11).
- **Nominate** someone to exercise these rights if you die or can no
  longer do so yourself.

We answer requests within 30 days, and at most within the time the law
allows. We may ask you to confirm who you are first.

## 9. Children

SolaCliq is for adults. You must be 18 or older to create an account.
We do not knowingly collect data from children; if we learn we have,
we delete it.

## 10. Changes to this policy

If we change this policy in a way that matters, we will tell you in the
app or by email before the change applies. The date at the top shows the
latest version.

## 11. Grievance Officer

If you have a complaint about how your data is handled, contact our
Grievance Officer:

Grievance Officer, MarkCliq
Email: info@markcliq.com
Address: Khushi Enclave-3, Jhampur, Mohali, SAS Nagar, Punjab 140301, India

We acknowledge complaints within 24 hours and resolve them within 15
days. If you are not satisfied with our answer, you can complain to the
Data Protection Board of India.
