# F21 Editing a team member

The company's admin changes what's the company's to decide about a
member: their role and how they're paid, and can send the invite again.
Asked by the owner on 2026-11-23 ("the only thing that remains is team
edit"); scope settled the same day.

## Rules

- **People edit their own details.** Name, phone, email, address and
  bank stay the person's, edited in the app's Profile, as today. An
  account can belong to several companies, so an admin's edit would
  reach the others (owner, 2026-11-23: "we let the person edit, not the
  admin").
- **Change pay type** (Sales Agents: commission or salary): any time,
  from now on. Customers already registered keep their commission as it
  stands; new ones follow the new pay type. Attendance is tracked from
  the change for salary, and stops for commission.
- **Change role** (EPC Installer or Sales Agent): only when nothing is
  open in the old role, so nothing is moved or lost unseen:
  - an installer: no task assigned, in review or sent back;
  - an agent: no customer in review or with the agent, no commission
    waiting (in review, waiting for the advance, or payable), no lead
    new or contacted.
  Otherwise 409 `member.has_open_work`, saying what's open. Becoming an
  agent needs a pay type. Past records (tasks done, customers, expenses,
  attendance) stay with the person. Their app shows the new role's home
  the next time it loads.
- **Not changeable here:** the admin's own membership, and making
  someone else the admin (one admin per company; MarkCliq does that).
- **Resend the invite:** for a member who hasn't set a password yet
  ("Invited"). The same email as when they were added. At most 3 an hour
  per address (429).

## API

- `PATCH /orgs/{org_id}/members/{user_id}`: admins. `role`, `pay_type`;
  returns the member.
- `POST /orgs/{org_id}/members/{user_id}/invite`: admins. 204; 409
  `member.already_set_up` once they have a password.

## Website

On a member's page: "Change role or pay" (a dialog) and, while invited,
"Resend invite". Both as the Team artboards' Manage rows.

## Status

Built 2026-11-23. See `docs/features.md`.
