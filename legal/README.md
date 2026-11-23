# Legal

SolaCliq's public legal documents, and what still has to happen before
they protect us. Drafted 2026-11-20 from what the code actually does
(`docs/data-policy.md`, the migrations, the app's permissions).

**These are drafts, not legal advice.** Before real vendors or the Play
Store, have an Indian technology lawyer review them; it is a few hours
of their time. Keep them in step with `docs/data-policy.md`: when a data
rule changes there, change the Privacy Policy too.

| File | For | Published at |
|---|---|---|
| `privacy-policy.md` | Everyone | `solacliq.markcliq.com/privacy` |
| `terms-of-use.md` | Everyone (includes the app's end-user licence) | `solacliq.markcliq.com/terms` |
| `company-terms.md` | Each solar company (includes the data-processing terms) | `solacliq.markcliq.com/company-terms` |

## The laws these are written against

- **Digital Personal Data Protection Act, 2023** and the **DPDP Rules,
  2025** (notified November 2025; most duties apply from May 2027, but
  we follow them now). Notice and consent, security, breach
  notification, the rights to access, correction and erasure, a contact
  for grievances, no accounts for under-18s.
- **IT Act, 2000** and the **SPDI Rules, 2011** (in force until the DPDP
  Act fully replaces them). Passwords and bank details are "sensitive
  personal data": a published privacy policy, consent and a Grievance
  Officer are required.
- **IT (Intermediary Guidelines) Rules, 2021**: Grievance Officer,
  acknowledge within 24 hours, resolve within 15 days.
- **Google Play user data policy**: privacy policy linked in the store
  and in the app, account deletion in the app *and* on the web, a
  data-safety form that matches the policy.

## Filled in (owner, 2026-11-20)

Name MarkCliq; address the GST principal place of business (Khushi
Enclave-3, Jhampur, Mohali, SAS Nagar, Punjab 140301); contact and
Grievance Officer at info@markcliq.com; server at Rackoona, Delhi;
courts at SAS Nagar (Mohali); Company Terms: 15 days to suspension for
unpaid fees, 30 days' notice, deletion 60 days after leaving; security
logs 1 year; effective 25 November 2026.

Still to settle with the lawyer:

- **Legal name.** GST is registered under the trade name MARK8ONICS (a
  proprietorship). The documents say MarkCliq, as the owner chose. A
  lawyer may want the registered name, or the proprietor's, added
  ("MarkCliq, a trade name of MARK8ONICS").
- **Grievance Officer's name.** The IT Rules ask for the officer's name
  as well as a contact; the documents give the role and email only.
- **Effective date vs. the go-live.** If the deploy moves past
  25 November, move the date with it.

## Code and product changes needed (to build, one at a time)

Ordered by risk.

1. **Agree at sign-up: built 2026-11-20 (F16).** A tick on sign-up,
   company registration (plus the Company Terms) and a "Before you
   start" screen for accounts someone else made; every agreement stored
   (`docs/features/F16-terms-consent.md`).
2. **Publish the pages: built 2026-11-20 (F16)** on the website, linked
   from the app's Profile. Live once the website is deployed.
3. **Account deletion: built 2026-11-22 (F18)**, in the app, with
   `/delete-account` on the website.
4. **Customer consent notice: built 2026-11-22**, above the agent's
   toggle and in the welcome email.
5. **Retention jobs: built 2026-11-22, switched off.** Set
   `KYC_RETENTION=true` on the server to make the Privacy Policy's
   periods true.
6. **Location note: built 2026-11-22**, before the proof camera asks for
   location.
7. **Breach plan: drafted 2026-11-22**, `docs/breach-plan.md`.
8. **The website asks again when the terms change: built 2026-11-22.**

For the lawyer, besides the list above: whether a deleted person's name
may stay on a company's records (F18's default), and the breach plan.

## Decisions for the owner

- **Quote requests.** The consent says "MarkCliq can contact me". If
  MarkCliq will ever pass a request to a solar company, the consent and
  the Privacy Policy must say so first. The draft says MarkCliq doesn't.
- **Aadhaar.** Ask vendors to use masked Aadhaar where the subsidy
  portal accepts it. Storing full Aadhaar copies is the most sensitive
  thing SolaCliq holds.
- **Off-site backups.** If backups are later copied off the VPS (e.g. to
  R2), add that place to the Privacy Policy's provider list.
- **A signed pilot agreement** with each vendor that accepts the
  Company Terms. Clicking "register" is weaker than a signature for a
  business customer.
