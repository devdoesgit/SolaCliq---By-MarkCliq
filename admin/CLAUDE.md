# Admin website

React + Vite + TypeScript website for **org admins** (and later the
MarkCliq platform admin). Static files at `solacliq.markcliq.com`. Built
last, by Claude. Built so far: log in, password reset, account page, and the public
legal pages (`/terms`, `/privacy`, `/company-terms`, made from
`../legal/*.md` at build time; F16).
Workers, agents and customers use the mobile app.

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
| Org admin | Log in, password reset | F1 |
| Org admin | Team: create worker and agent accounts | F3 |
| Org admin | Customers list and pipeline by stage | F4 |
| Org admin | Customer detail: stage, cost breakdown, payments, documents, photos | F4–F6 |
| Org admin | Assign workers to jobs; review photos | F6 |
| Org admin | Approvals queue: expenses and commission | F7/F8 |
| Org admin | Referral settings: bonus or discount | F11 |
| Org admin | Dashboard overview | after F8 |
| Platform admin | Pending companies: approve or reject (API only for now) | F2 |
| Platform admin | Org list, suspend, support access | F14 |
