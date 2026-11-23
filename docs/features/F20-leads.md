# F20 Leads

People who fill a company's landing page reach that company's Leads
screen within seconds. The admin tracks each lead and can hand it to a
sales agent, who calls from the app. Asked by the owner on 2026-11-23;
options chosen the same day (push, track and assign).

## Goal

No lead sits in a spreadsheet or an inbox: each one is on one list, with
who has it and where it stands, the moment the person submits the form.

## How a lead arrives (push)

1. The landing page's own backend (run by MarkCliq for the company) gets
   the form.
2. It sends the lead to SolaCliq: `POST /api/v1/leads` with the
   company's **lead key** as `Authorization: Bearer <key>`.
3. SolaCliq saves it under that company and tells the company's admins.

- **The lead key** is made by the company's admin in Settings, shown
  once, and stored only as a hash. Making a new one stops the old one at
  once. It must stay on the landing page's server: a browser call is
  refused (no CORS, and cross-site writes are refused).
- **What's sent:** name and phone (required), and optionally email,
  city, PIN code, monthly bill, roof type, message, source (e.g. "Meta
  ad"; default "Landing page"), campaign, page URL, and up to 20 more
  short fields as `extra`. `consent` must be true: the form must say the
  company may contact the person (otherwise 422 `lead.consent_required`).
- **Retries.** An `external_id` (the landing page's own id for the form)
  makes a resend return the first lead instead of making a second.
- **Abuse.** At most 300 leads an hour per company key (429). A wrong or
  old key is 401 `lead.bad_key`.

## Working a lead

- **Status:** `new` → `contacted` → `won` or `lost`, in any order (a lost
  lead can come back). A note (up to 1,000 characters) for what was said.
- **Assign:** the admin hands a lead to a Sales Agent (either pay type) of
  the company, or takes it back. The agent gets a push notification and
  sees the lead in the app (Leads, from their Home), with a call button.
- **The agent** can change the status and note of their own leads, not
  anyone else's, and can't reassign.
- **Won:** the agent or admin registers the customer the normal way
  (F4). A lead isn't turned into a customer automatically.
- **Delete:** the admin can delete a lead (a person asking to be
  forgotten). Nothing else deletes it.
- **Admins** see a count of new leads in the sidebar, and a
  `lead_new` notification for each.

## Isolation and data

Leads are company data under row-level security. The company is the Data
Fiduciary for its leads; MarkCliq's landing page passes them on for the
company. See `docs/data-policy.md`, "Leads".

## API

- `POST /leads`: public, lead key. Creates a lead (201), or returns the
  one with that `external_id` (200).
- `GET /orgs/{org_id}/leads`: admins. Filters: `status`, `agent_id`, `q`.
- `GET /orgs/{org_id}/leads/mine`: sales agents. Their leads.
- `GET /orgs/{org_id}/leads/{lead_id}`: admins, or the agent it's with.
- `PATCH /orgs/{org_id}/leads/{lead_id}`: admins (status, note, agent);
  the agent it's with (status, note).
- `DELETE /orgs/{org_id}/leads/{lead_id}`: admins.
- `GET`/`POST /orgs/{org_id}/admin/lead-key`: admins. Whether a key is
  set (and when it was last used); make a new one.

## Not in this feature

- Pulling leads from another system (a Sync button).
- Meta or Google lead forms sending straight to SolaCliq.
- Automatic WhatsApp or email to the lead.
- Leads from the app's own quote requests (those stay MarkCliq's; owner,
  2026-11-23: "our app leads we will manage independently").

## Status

Built 2026-11-23. See `docs/features.md`.
