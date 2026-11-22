# F1 Accounts and login

Status: `done` in the app, the website and the backend (phases 1–3).
Left: the SMTP mailer (backend phase 5).

## Goal

People can create an account, prove their email, log in and out on the app
and the admin website, and reset a forgotten password, so every later
feature knows who is using it and in which orgs.

## Users

- **Customers:** create their own account in the app.
- **Workers and agents:** log in to the app with accounts the org admin
  creates (creating them is F3).
- **Org admins:** log in to the admin website (their account is created at
  org signup, F2).
- **Platform admin (MarkCliq):** logs in to the admin website. The account is
  created on the server (`cargo run -- make-platform-admin <email>`), not
  through any screen.

## In scope

- One global account per person: email, password, name.
- Customer sign-up in the app, with a 6-digit code emailed to verify the
  address. An account can't log in until its email is verified.
- Log in and log out, app and website. "Who am I": the user and their
  memberships `(org, role, org status)`.
- Forgot password: a 6-digit code by email, then a new password. Resetting
  logs the person out everywhere.
- **First-time set-up** (added 2026-10-18): accounts created for someone
  (customers registered by an agent in F4; workers and agents in F3) have
  no password. Logging in to one returns `account.password_not_set`; the app
  then offers "Set up your account", which is the forgot-password flow
  worded for a first visit (`POST /auth/password/forgot` then
  `/auth/password/reset` both work for an account without a password).
- Sessions:
  - **App:** a short-lived access token (Bearer) and a long-lived refresh
    token, kept in the phone's secure storage (Android Keystore). The app
    refreshes silently; refresh tokens rotate on every use, and reusing an
    old one revokes that login (theft detection).
  - **Website:** an `HttpOnly`, `Secure`, `SameSite=Lax` session cookie.
    State-changing requests must come from our own origin (the server
    checks `Origin`), which stops cross-site request forgery.
- Who may use which surface:
  - The admin website accepts org admins and the platform admin. Anyone else
    sees "This website is for solar vendors. Use the SolaCliq app."
  - The app accepts everyone; F1's signed-in screen shows the person's name
    and memberships, or, for a new customer, "Your account is ready. When
    your installer adds you, your installation will appear here."

## Out of scope

- Org signup and approval (F2); creating worker and agent accounts and the
  org switcher (F3); linking customers to org records (F10).
- Phone number login and SMS codes (after DLT registration).
- Changing email or password while logged in, deleting an account (later;
  note for DPDP: account deletion must exist before public launch).
- Social login, two-factor authentication.
- Remember-me choices: the app stays logged in; the website session lasts
  the same fixed time for everyone.

## Security rules (backend)

- Passwords: at least 8 characters, at most 128; hashed with Argon2id.
  A breached-password check (Have I Been Pwned range API) may come later.
- No account enumeration: sign-up, resend and forgot-password answer the
  same way whether or not the email exists. Sign-up with an email that
  already has an account sends that person an "you already have an account"
  email instead of a code.
- Login failure always says "Email or password is wrong." An unverified
  account gets `account.email_unverified` only after the right password.
- Codes: 6 digits, valid **5 minutes**, 5 tries, stored hashed (PostgreSQL),
  single use.
- A wrong, expired, used-up or unsent code all answer
  `auth.code_invalid` (2026-11-22, QA-08).
- Rate limits: login 5 tries per 15 minutes per email and per IP; code
  emails 3 per hour per email.
- Emails go through the Gmail API (Google Workspace) from
  `support@solacliq.markcliq.com`, server only: verification code, reset code,
  set-up code, "you already have an account", and an activation/welcome
  email for accounts created by an agent or org admin (sent in F3/F4). In development the backend prints
  codes to its log; the Prism mock returns example responses.

## Known flaw: sign-up takeover (QA-27, QA-28), to fix later

Found 2026-11-22; deferred by the owner the same day. **Open.**

**The flaw.** Sign-up saves the password, name, phone and terms
agreement before the code. A second sign-up with that unverified email
keeps all of them, and entering the code activates them. Tested against
the API:

| Who makes the account first | Result |
|---|---|
| Admin adds the email | Safe: no password until set with an emailed code |
| Attacker, then the person signs up | Taken over |
| Attacker, admin adds them, they sign up | Taken over, as installer |
| Attacker, owner registers the company, owner signs up | Taken over, as the company's admin |
| Attacker, then the person uses Forgot password | Safe: the attacker's password is replaced |
| An agent registers that unverified customer | Password cleared by that code; name and phone stay |

**Until it's fixed:** someone taken over gets the account back with
Forgot password, which ends the attacker's sessions.

**The fix (the owner's order: code first, then password).**

1. Email only: a code is sent.
2. Code: the server returns a one-time setup token (15 minutes).
3. Name, mobile, password and terms, with that token: the account is
   completed and logged in. Nothing typed earlier is kept.

- Invited accounts (no password) can finish through the same steps.
  Today "Create account" verifies them, then says "password not set".
- Login answers `auth.invalid_credentials` for an account with no
  password (today 403 tells anyone that the email was invited) and for
  an unverified one (403 today: QA-28). The login screen always shows
  "Set up your account".
- Passwords already saved on unverified accounts are cleared.
- Forgot password stays as it is.
- Contract change: apps built before it can't sign up. Spec and
  `openapi.yaml` first; each row above becomes a test.

## API

Added to `api/openapi.yaml` (tag `auth`). All under `/api/v1`.

| Method and path | Auth | What it does |
|---|---|---|
| `POST /auth/signup` | none | Create a customer account; emails a code. Always `202`. |
| `POST /auth/email/verify` | none | Verify with the code. `204`. |
| `POST /auth/email/resend` | none | Send a new code. Always `202`. |
| `POST /auth/login` | none | `client: app` → tokens in the body; `client: web` → session cookie. Both return the user. |
| `POST /auth/refresh` | none (refresh token in body) | App only: new token pair. |
| `POST /auth/logout` | bearer or cookie | Ends this session. `204`. |
| `POST /auth/password/forgot` | none | Emails a reset code. Always `202`. |
| `POST /auth/password/reset` | none | Code and new password; ends every session. `204`. |
| `GET /me` | bearer or cookie | The user and their memberships. |

Errors use problem+json codes: `auth.invalid_credentials`,
`account.email_unverified`, `account.password_not_set`,
`auth.code_invalid`, `auth.code_expired`,
`auth.too_many_attempts`, `auth.password_too_weak`, `auth.session_expired`,
`validation.failed`.

## Screens

**Mobile app**
1. Welcome: product name, "Log in" (primary) and "Create account".
2. Create account: name, email, password.
3. Verify email: the 6-digit code, "Send a new code".
4. Log in: email, password, "Forgot password?".
5. Forgot password: email → Reset password: code and new password.
6. Signed in (placeholder until F3/F9): name, memberships or the new-customer
   message, "Log out".

**Admin website**
1. Log in: email, password, "Forgot password?" (and, from F2, "Register your
   business").
2. Forgot password → Reset password.
3. Signed in (placeholder until F2/F3): name, orgs, "Log out"; or the "use
   the app" message for people without an admin role.

## Data (backend)

- `users`: id, email (case-insensitive, unique), email_verified_at,
  password_hash, name, is_platform_admin, created_at, updated_at.
- `orgs` (only the columns memberships need; F2 adds the rest): id, name,
  status (`pending`, `active`, `suspended`).
- `memberships`: user_id, org_id, role (`org_admin`, `worker`, `agent`),
  created_at; unique (user_id, org_id).
- `sessions`: id, user_id, client (`app`, `web`), refresh_token_hash or
  cookie_token_hash, family_id (for refresh rotation), created_at,
  last_used_at, expires_at, revoked_at, user_agent.
- `email_codes`: id, user_id, purpose (`verify_email`, `reset_password`),
  code_hash, expires_at, attempts, used_at.

## Acceptance

1. A new customer can create an account in the app, verify with the emailed
   code, and land on the signed-in screen.
2. Logging in with a wrong password, or an email with no account, shows the
   same message.
3. The app stays logged in after being closed and reopened, and refreshes
   its access token without the person noticing; "Log out" ends it.
4. An org admin logs in to the website; a customer trying the website sees
   the "use the app" message.
5. Forgot password works end to end and logs out other sessions.
6. All screens work against the Prism mock first, then against the real
   backend with only the base URL changed.
7. Every field and button has a label screen readers read; tap targets are
   at least 48dp; errors are announced.
8. Tests: repository and cubit tests (mobile), component and flow tests
   (admin), including token refresh and expired-session handling.

## Answers from the owner (2026-10-18)

1. Email verification by a 6-digit code: yes.
2. Sessions: app access token 15 minutes, refresh token 60 days renewed on
   use; website session 12 hours. Yes.
3. Breached-password check: not now; maybe later.
4. Platform admin account created by a backend command: yes.
5. Email: sent from the owner's Google Workspace (SMTP relay or Gmail API
   with a MarkCliq sender address), not Zoho. The owner creates the sender
   account. Workspace sends about 2,000 emails a day per account, enough for
   the pilot. The sending domain needs SPF and DKIM set up so codes don't
   land in spam.

## Notes

- 2026-10-18, mobile done against the Prism mock: welcome, create account,
  verify email, log in, forgot and reset password, signed-in placeholder.
  60 app tests (repository incl. token refresh, interceptor retry, routing
  rules, every screen, the whole app log-in/log-out flow); checked on the
  emulator through mobile-mcp.
- Login opens offline with the last known account; only a server rejection
  (401) logs the person out, never a network failure or a 500.
- `sola_ui` now exposes each widget's `ValueKey<String>` as the platform
  accessibility identifier (Android resource-id), so mobile-mcp and tests can
  find fields by id; Flutter gives field labels to Android as hints, which
  TalkBack reads but mobile-mcp doesn't show.
- The app icon is still the VGV template's; replace when there is a logo.
- 2026-10-18, admin website done against the Prism mock: log in, forgot
  and reset password, signed-in page with the "use the app" message for
  people without an admin role. Session via cookie; `next` after log in is
  only followed for paths on this site. 40 admin tests.
- The contract's login and logout responses carry example `Set-Cookie`
  headers so the mock keeps a browser signed in during development.
- Done end to end (backend phases 1–3): the app runs against the real API
  with only the base URL changed.
