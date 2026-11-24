# F22 MarkCliq's company review (website)

Status: `built` (2026-11-25), approved by the owner the same day. Website
tests (7), and the browser check against the local preview: approve,
reject with a reason, suspend, restore, at desktop and phone widths.

## Goal

MarkCliq's platform admins review new solar companies on the website
instead of through the API: see who registered, check their details,
approve or reject them, and suspend or restore a company later.
Finishes what F2 left for later ("a website review page").

## Who

Platform admins only (`users.is_platform_admin`, set on the server with
`make-platform-admin`). Anyone else who opens these pages gets the
website's "not found" page; the API refuses them anyway (403
`platform.not_admin`).

## Endpoints

All exist, built and tested with F2. **No change to `api/openapi.yaml`.**

| Endpoint | Use |
|---|---|
| `GET /platform/orgs?status=&cursor=&limit=` | The list, one status at a time, paged |
| `GET /platform/orgs/{org_id}` | One company's registration details and owner |
| `POST /platform/orgs/{org_id}/status` | `active` (approve, or restore), `rejected` (with a note, emailed to the owner), `suspended` |

Allowed moves (enforced by the API): pending → active or rejected;
active → suspended; suspended → active. Anything else is 409
`org.status_change_not_allowed`.

## Screens

### Home (`/`), for a platform admin

Today a platform admin with no company sees "MarkCliq's pages aren't
built yet", and one with a single active company is sent straight into
it. Changed:

- A platform admin always lands on the home page (no automatic jump
  into a company), which shows a **MarkCliq** card: "Companies", with
  the number waiting for review, linking to the list.
- Their own companies, if any, are listed below it as today.
- Everyone else: unchanged.

### Companies (`/platform/companies`)

- Tabs by status: **Waiting** (pending, the default), **Active**,
  **Suspended**, **Not approved** (rejected). Waiting shows its count.
- One row per company: trade name (legal name under it if different),
  city, GSTIN, registered on (date, India time), owner's name.
- Newest first, as the API returns them; "Load more" when there's a
  next page.
- Empty states per tab ("No companies waiting for review").
- A row opens the company.

### Company (`/platform/companies/:orgId`)

- Header: trade name, status pill, registered on.
- **Business:** legal name, trade name, business type, GSTIN, PAN (from
  the GSTIN), address, city, state, PIN, phone.
- **Owner:** name, email, phone, each with copy, and phone as a `tel:`
  link (the review starts with a call to the owner).
- **Review:** reviewed on and the note, once there is one.
- Actions, by status:
  - pending: **Approve** and **Reject**
  - active: **Suspend**
  - suspended: **Restore**
  - rejected: none (final)
- Each action asks first, in a dialog that says what happens:
  - Approve: "The owner is emailed how to log in. Their company can use
    SolaCliq from now on."
  - Reject: a required note (up to 1000 characters) and "The owner is
    emailed this note." The button stays off until the note has text.
  - Suspend: "Everyone in the company sees that it's suspended until
    you restore it." Optional note.
  - Restore: "The company can use SolaCliq again."
- After a change: the page shows the new status, the lists refresh, and
  a short confirmation is announced (for screen readers too).
- A 409 (someone else changed it first): "This company changed while
  you were looking. Here's how it is now." and the page reloads it.

## What MarkCliq sees, and doesn't

Only the registration details and the owner's contact: what the API's
platform scope allows (`docs/data-policy.md`). No customers, KYC,
tasks, expenses or team. No change to the data policy.

## Design

There's no artboard for these pages in the canvas. They're built from
the admin canvas's existing patterns, opened and compared before and
after building, like every admin screen:

- the list: `Admin2Customers` (tabs, rows, counts)
- the company page: `Admin2CustReview` (details in cards, decision
  buttons) and the decision dialogs already used for customers
- the layout: the admin shell, with "MarkCliq" in place of a company
  name and a link back to the home page

Same tokens and components; no new ones unless a pattern above lacks
one, then noted in `admin-website.md`.

## Not in this feature

- Support access to a company (F14).
- A GST lookup to check the GSTIN against the government register.
- Search, editing a company's details, deleting a company.
- A rejected company being reconsidered (the API doesn't allow it; the
  owner registers again).

## Tests

- Website tests: each tab's list and empty state; the company page per
  status shows only its allowed actions; reject needs a note; a 409
  reloads; a non-platform-admin gets "not found"; the home page's
  MarkCliq card and no automatic jump for platform admins.
- Browser suite against the local API: register a company, approve it
  on the page, reject another with a note, suspend and restore.
- On production after release: approve the first real company here.

## Notes from building

- The company and MarkCliq frames share one sidebar (`app/Shell.tsx`);
  `CompanyLayout` and `PlatformLayout` only say what goes in it.
- `ActionDialog` takes `refresh`, the data read again after a decision:
  a company's (default) or MarkCliq's (`['platform']`).
- Suspending and restoring aren't emailed (the API emails only the
  decision on a new registration), so the suspend note is for MarkCliq.
- The owner's contact lines stack in the side card, so a long email
  isn't broken mid-word.
