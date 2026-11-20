# F16 Agreeing to the terms

Every account agrees to the Terms of Use and the Privacy Policy
(`legal/`) with a tick, and the server keeps a record of it: who agreed,
to which version, when and where from. A tick shown only in the app
proves nothing; the DPDP Act (section 6(10)) puts the burden of proving
consent on us. Asked by the owner on 2026-11-20.

## How it works

- **One version number for the documents**, `TERMS_VERSION` in the
  backend (starts at `1`). It goes up only for a change that matters
  (new data collected, a new use, a new provider). A wording fix doesn't
  change it.
- **Every agreement is a new row**, never an update, so the history
  stays: `agreements (id, user_id, org_id, document, version,
  accepted_at, source, ip)`.
  - `document`: `terms` (Terms of Use and Privacy Policy, agreed
    together) or `company_terms` (with `org_id`).
  - `source`: `signup`, `org_registration` or `app`.
  - `ip`: the request's address, as part of the proof. Kept with the
    account; deleted with it.
- **Where the tick is:**

  | Who | Where they agree | How it's sent |
  |---|---|---|
  | Someone signing up | Sign-up screen | `terms_version` in `POST /auth/signup` |
  | A company owner | Registration form, a second tick for the Company Terms | `terms_version` in `POST /org-registrations` (records both documents) |
  | Installers, agents and customers whose account someone else made | A screen after their first login | `POST /me/terms` |
  | Anyone, after the version goes up | The same screen, once, after their next login or app start | `POST /me/terms` |

  The tick starts off. Pressing the button without it shows "Tick to
  agree to continue." under it and sends nothing (the same pattern as
  the quote form's consent). Above it, two lines say what is stored and
  why, with links to the two documents. Quick forms (development only)
  ticks it like every other choice; a release never does.
- **`/me` says whether to show the screen:** `terms.accepted_version`
  (the latest the person agreed to; empty if never) and
  `terms.current_version`. The app shows the screen whenever they
  differ and lets the person do nothing else until they agree or log
  out.
- **An old app version is fine.** Sign-up records the version the app
  showed. If that's older than the current one, the screen asks again
  after login. A version higher than the current one, or none, is 422
  `terms.required`.
- **The documents are web pages:** `solacliq.markcliq.com/terms`,
  `/privacy` and `/company-terms`, public, built from `legal/*.md` into
  the website. The app opens them in the browser.

## Built (2026-11-20)

- Backend: migration `20261120000001_agreements.sql` (the UPDATE right
  revoked from the API's role), `src/terms.rs`, sign-up and registration
  record in the same transaction as the account or company, `/me` and
  login return `terms`, `POST /me/terms`. The seed gives seeded accounts
  with a password an agreement. Tests: `tests/terms.rs` (10).
- App: `lib/legal/` (the version, the pages' links, `TermsAgreement`,
  `TermsPage`), `WorkspaceNeedsTerms` in the workspace gate, Profile
  links. An account saved on the phone by an older app version is read
  again from the server. Tests: repository, gate, pages, accessibility.
- Website: `/terms`, `/privacy`, `/company-terms`, made from `legal/*.md`
  at build time (`legalMarkdown` in `vite.config.ts`, `marked`).
- Checked on the emulator against the local API: the tick on sign-up
  (refused without, row `signup` with), an installer without an
  agreement landing on "Before you start", the back button not getting
  past it, agreeing (row `app`), then home.

## Not in scope

- Server-side blocking of other requests until the person agrees. The
  app enforces the screen; the server records. The website gets the same
  screen before `TERMS_VERSION` first goes above 1 (its org admins all
  agreed at registration).
- Separate consents for separate purposes (marketing, sharing with
  partners). There are none today. The quote form's "MarkCliq can
  contact me" stays as it is.
- Account deletion: its own feature, next (Google Play and the DPDP
  right to erasure).

## API

- `POST /auth/signup` and `POST /org-registrations`: new required field
  `terms_version` (integer).
- `GET /me`: new `terms` object.
- `POST /me/terms` with `{ "version": n }`: records it. 204. `n` must be
  the current version (422 `terms.required` otherwise).

## Screens

- Sign-up: the notice, the tick and the links, above "Create account".
- Company registration: the same, plus a second tick for the Company
  Terms.
- "Before you start" screen: the same notice and tick, a "Continue"
  button, and "Log out". Shown after login while `/me` says so.
- Profile → "Terms of Use" and "Privacy Policy" links.
- Website: the three public pages.

## Data

Migration: the `agreements` table above. Not under row-level security
per company (it belongs to the person, like `users`); the API reads only
the caller's own rows.

## Tests

- Sign-up without `terms_version`, or with a version above the current
  one: 422 `terms.required`, no account made.
- Sign-up with the current version: one `terms` row, source `signup`.
- Registration: two rows, `terms` and `company_terms` with the org.
- A team member created by an admin: `/me` shows `accepted_version`
  empty; `POST /me/terms` adds a row and `/me` then matches.
- `POST /me/terms` with an old version: 422.
- App: the button is off until ticked; the screen shows when the
  versions differ and not after agreeing.
