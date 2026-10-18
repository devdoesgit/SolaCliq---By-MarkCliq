# API contract

`openapi.yaml` (added in F0) is the contract between `../backend`, `../mobile`
and `../admin`. It is written spec first, one feature at a time: Claude drafts
the endpoints for a feature, the owner reviews, and it is committed before
code.

- The backend's `utoipa`-generated spec must match this file (checked in CI).
- The mobile Dart client and the admin TypeScript client are generated from
  it with `make gen`.
- Prism serves mock responses from it while endpoints are being built.

Conventions are in `../docs/architecture.md` under "API conventions".
