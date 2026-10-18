# Backend

Rust API for SolaCliq. **Built by the owner.** Claude drafts the API spec in
`../api/openapi.yaml` and helps when asked, but does not write or change
backend code unless the owner asks.

Stack, API conventions and design patterns: `../docs/architecture.md`.

## Responsibilities

- REST API at `solacliq.markcliq.com/api/v1`, for both the mobile app and the
  admin website (bearer tokens and cookies on the same endpoints).
- Postgres: schema, migrations, row-level security per org.
- Auth: accounts, email verification, sessions and tokens, roles from
  memberships.
- Business rules: stages, approvals, referrals, location flags on captures.
  Rules live here so most fixes need no app update.
- R2: presigned upload and download URLs for the private bucket.
- GST verification API calls (keys stay on the server).
- Email through Google Workspace; push notifications; SMS later.
- OpenAPI spec generated with `utoipa`, served at `/api/docs`, checked in CI
  against `../api/openapi.yaml`.

## Modules

| Module | Feature |
|---|---|
| auth, users | F1 |
| orgs, gstin, platform approval | F2 |
| memberships | F3 |
| customers, stages, cost lines, payments | F4 |
| uploads, documents | F5 |
| jobs, captures | F6 |
| expenses, approvals | F7 |
| commissions | F8 |
| customer linking | F10 |
| referrals | F11 |
| notifications | F12 |
| org suspension, support access, audit log | F14 |
