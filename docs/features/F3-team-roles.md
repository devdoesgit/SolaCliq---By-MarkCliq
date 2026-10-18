# F3 Team and roles

Status: `building`. Spec approved by the owner on 2026-10-18.

Mobile first (see `../decisions.md`, 2026-10-18): the app side is built now
against the mock; the team page on the admin website is built in the admin
phase.

## Goal

Everyone who logs in to the app lands on the home that fits who they are
(worker, agent or customer) in the right org, can switch orgs if they work
for more than one, and sees a clear message instead of a broken app when an
org is pending or suspended.

## Users

- **Workers and agents:** accounts made by their org admin; they set a
  password through "Set up your account" (F1) and land on their home.
- **Customers:** no memberships; they land on the customer home.
- **People in several orgs** (an agent for two vendors, say): choose the org
  once, switch from the header.
- **Org admins:** add and remove workers and agents (endpoints now, website
  screens in the admin phase).

## In scope

**Backend (owner):**
- `GET/POST /orgs/{org_id}/members`, `DELETE /orgs/{org_id}/members/{user_id}`.
- Adding an email with no account creates one with no password and sends
  the set-up email; an existing account only gets a membership and an "you
  were added to <org>" email.
- One role per person per org (proposed; asked of RY Enterprises in
  `questioner.md`). The app treats each `(org, role)` pair as its own
  context, so allowing two roles later needs no app change. The org admin
  can't be removed.
- Removing a member stops their access to that org immediately (checked on
  every org-scoped request, not only at login).
- **Convention for every org-scoped endpoint from now on:**
  `/orgs/{org_id}/...`. The server checks the caller has a membership in
  that org, that the org is `active`, and that the role may do the action.

**Mobile (Claude):**
- **Home gate.** After login and on every start, the app picks a context
  from `/me`:
  - no memberships → customer home;
  - one membership → that org and role;
  - several → the last one used on this phone, else the org picker.
  The chosen org is remembered on the phone (not secret; cleared on log
  out) and dropped if the membership is gone.
- **Role homes** with a bottom bar, built as shells the later features fill:
  - Worker: Jobs (F6), Account.
  - Agent: Customers (F4), Account.
  - Customer: My installation (F9), Account.
  Tabs for later features (expenses, commission, referrals) are added when
  those features are built, not shown empty now. The main tab shows a
  finished empty state that says what will appear there, not "coming soon".
- **Org header and switcher.** People with more than one membership see
  the org name in the header; tapping it opens a sheet listing each org
  with role and status. Switching is instant and keeps each org's screens
  separate (no data from one org shown under another).
- **Org status screens:**
  - `pending`: "<Org> is waiting for approval. You'll be able to start once
    MarkCliq approves it."
  - `suspended`: "<Org>'s access is paused. Contact <Org> for help." Other
    orgs stay reachable from the switcher.
- **Org admins use only the website** (owner, 2026-10-18). An org admin
  membership never opens a home in the app; the app shows "Your admin tools
  are on the website" with the address. If the person also holds another
  membership, the switcher offers only those.
- **Staying current:** `/me` is re-read when the app comes back to the
  foreground (at most once a minute), so a new membership, a removal or a
  suspension shows without logging out. A 403 from an org-scoped request
  also re-reads `/me`.
- **Account tab:** name, email, the current org and role, switch org, log
  out. Replaces the F1 account page.
- **Dev tool (development flavor only):** pick which `/me` example the mock
  returns (customer, worker, agent, multi_org, org_admin), so every home can
  be seen and tested. Uses Prism's `Prefer: example=` header.

## Out of scope

- Admin website team page (admin phase).
- Org signup and approval (F2, admin phase); orgs are set up by backend
  command for now.
- Editing a member's name or role; more than one admin per org; staff
  sub-roles.
- The content of each home tab (F4, F6, F9).

## API

Added in `api/openapi.yaml` v0.3.0:

| Method | Path | Who |
|---|---|---|
| GET | `/orgs/{org_id}/members` | Org admin |
| POST | `/orgs/{org_id}/members` | Org admin |
| DELETE | `/orgs/{org_id}/members/{user_id}` | Org admin |

Codes: `member.already_in_org` (409), `member.role_not_allowed` (422),
`member.cannot_remove_admin` (422). `GET /me` gains named examples for each
kind of person (all illustrative).

## Data

- `memberships (user_id, org_id, role, created_at, created_by)`, unique on
  `(user_id, org_id)`.
- Member `status` is derived: `invited` while the account has no password.

## Screens (mobile)

1. Org picker (first start with several orgs).
2. Worker, agent and customer homes: bottom bar, header, empty main tab.
3. Org switcher sheet.
4. Pending, suspended and org-admin notices.
5. Account tab.

Each is checked on the emulator through mobile-mcp at 360dp and with large
text (font scale 1.3), and gets widget tests and golden tests in `sola_ui`
for any new shared widget (bottom bar, org header, sheet).

## Acceptance

- Each `/me` example lands on the right home with no flash of the wrong
  screen.
- With several orgs: the picker on first start, the last org on the next
  start, switching from the header, and a removed membership falls back
  cleanly.
- Pending and suspended orgs show their notice; other orgs still work.
- Coming back to the app after a membership change shows the change.
- Log out clears the remembered org.
- Tests pass; coverage stays above 85%; `dart analyze --fatal-infos` clean.

## Decided

- Org admins have no app access; their tools are on the website.
- Org-scoped endpoints use `/orgs/{org_id}/...`.

## Open

- Can one person be both a worker and an agent for the same vendor? Asked
  in `questioner.md`; one role per org until answered.

## Notes

(Filled in while building.)
