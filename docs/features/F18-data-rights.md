# F18 Account deletion, KYC retention and notices

Items 3 to 7 of `legal/README.md`. Started 2026-11-22 under the owner's
"do whatever remains". The choices marked **(default)** were not decided
by the owner; confirm them with the lawyer before go-live.

## Account deletion

- `POST /me/delete` `{password}` → 204. A POST, as some proxies drop a
  DELETE's body. Wrong password: 400 `account.password_incorrect`
  (limited like log in). Can't be undone.
- Refused, 409: `account.last_admin` (a company that isn't rejected
  would be left with no admin) and `account.platform_admin`. Both are
  handled by writing to MarkCliq. A company has one admin today, so
  in practice a company's admin writes to us.
- Erased: email (replaced by a placeholder, so it can be used again),
  password, phone, details and bank account, settings, devices,
  sessions, codes, agreements, quote requests, notifications, saved
  request answers. Memberships end.
- Kept: the company's records of the person's work or install.
- **(default)** The name stays for someone who was ever in a company,
  as it is on that company's records (tasks, attendance, commission).
  With no company it becomes "Deleted account".
- App: Delete account, under Log out, asks for the password.
- Website: public `/delete-account` says how in the app, or by email
  without it (Google Play asks for such a page).

## KYC retention (decided 2026-11-17)

- Rejected, 30 days later: the customer row, its documents, every file
  (replaced sets too) and the notifications about them. Their membership
  ends; an account that was only made for this and never set up is
  erased.
- Handed over, 1 year later: the documents and every file. The customer
  and install stay.
- Files leave R2 first, then the rows; a failure is retried next hour.
- **(default) Off until switched on:** without `KYC_RETENTION=true` the
  server only logs how many are due. A deploy must not be the thing
  that first deletes real data.

## Notices

- Add customer: what the customer agrees to, above the toggle, with
  the Privacy Policy. The welcome email repeats it with the link.
- Proof camera: the location note shows before the system asks for
  location permission, until it is granted.
- `docs/breach-plan.md`.

## Not here

Earlier deletion of KYC on request (still Open in the data policy),
deleting a company, downloading one's data.
