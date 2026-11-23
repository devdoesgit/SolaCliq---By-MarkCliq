# Admin website

React + Vite + TypeScript website for **org admins** (and later the
MarkCliq platform admin). Static files at `solacliq.markcliq.com`. Built
last, by Claude. Built: log in and password reset, team, customers and
KYC, tasks and proof, expenses, commissions, payments, UPI id (W0 to W4,
`../docs/features/admin-website.md`), and the public legal pages
(`/terms`, `/privacy`, `/company-terms`, made from `../legal/*.md` at
build time; F16). Also built: the overview and notifications (W5), logo and
attendance (W6), stage templates (F19) and leads (F20).
Workers, agents and customers use the mobile app.

Stack and API conventions: `../docs/architecture.md`.

## Rules

- Talk to the backend only through the TypeScript client generated from
  `../api/openapi.yaml` (`openapi-typescript` + `openapi-fetch`).
- Cookie-based sessions.
- Money is integer paise; format only for display.
- Brand: the admin design, canvas page "v2 · 5 Admin web", copied to
  `../design/ios-v2/5-admin/`. **Open the screen's artboard before you
  change it, and compare a 1280 x 800 screenshot with it after.** The
  tokens alone are not the design. Use the components in `src/components`
  and the CSS variables in `src/styles/tokens.css` (generated); never
  hard-code a colour or font. Layout widths from the artboards live at
  the top of `src/styles/screens.css`.
- A screen is read again each time it opens: people act in the app while
  the admin works. Don't add a `staleTime`.
- Every decision goes through `ActionDialog`. A `DialogButton` whose
  place another action can take gets a key of the state it acts on, so
  an open dialog can't become a different one.
- Times show and are typed in India time (`lib/format.ts`), never the
  browser's. A company's screens live under `/c/:orgId`.
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
