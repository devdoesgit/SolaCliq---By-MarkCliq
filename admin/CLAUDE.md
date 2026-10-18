# Admin website

React + Vite + TypeScript website for **org admins** and the **MarkCliq
platform admin**. Served as static files at `solacliq.markcliq.com`. **Built
by Claude.** Workers, agents and customers do not use it; they use the mobile
app (`../mobile`).

Stack and API conventions: `../docs/architecture.md`.

## Rules

- Talk to the backend only through the TypeScript client generated from
  `../api/openapi.yaml` (`openapi-typescript` + `openapi-fetch`).
- Cookie-based sessions.
- Money is integer paise; format only for display.
- Brand: matches markcliq.com (see `../CLAUDE.md`). Use the components in
  `src/components` and the CSS variables in `src/styles/tokens.css`
  (generated); never hard-code a colour, size or font.
- Desktop first; must still work on a phone browser.

## Screens by role

| Role | Screens | Feature |
|---|---|---|
| Vendor (signing up) | Org signup with GSTIN autofill, "pending approval" | F2 |
| Org admin | Log in, password reset | F1 |
| Org admin | Team: create worker and agent accounts | F3 |
| Org admin | Customers list and pipeline by stage | F4 |
| Org admin | Customer detail: stage, cost breakdown, payments, documents, photos | F4–F6 |
| Org admin | Assign workers to jobs; review flagged captures | F6 |
| Org admin | Approvals queue: expenses and commission | F7/F8 |
| Org admin | Referral settings: bonus or discount | F11 |
| Org admin | Dashboard overview | after F8 |
| Platform admin | Pending orgs: approve or deny | F2 |
| Platform admin | Org list, suspend, support access | F14 |
