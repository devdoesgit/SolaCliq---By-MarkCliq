# F15 Company logo

Each company's people see its logo inside SolaCliq, so the app feels like
theirs. Asked by the owner on 2026-11-17; built 2026-11-18.

## Scope

- **Upload.** The company's admin asks for an upload of purpose `logo`
  (`POST /orgs/{org_id}/uploads`): PNG or JPEG, up to 1 MB, admin only.
  The file goes straight to R2 at `orgs/<org_id>/logo/<upload_id>`.
- **Set.** `PUT /orgs/{org_id}/logo` with `upload_id`. The server checks
  the file arrived whole (as for every upload), points the company at it,
  and deletes the logo it replaces (row and file).
- **Remove.** `DELETE /orgs/{org_id}/logo`: back to initials.
- **Read.** `/me` gives each membership's company a `logo_url`, a
  15-minute signed link; absent when there's no logo.
- **App.** The logo shows above the titles in the home header (40 dp
  tall, up to 160 dp wide) and in a white round badge in the workspace
  list. With no logo, or if it fails to load, the company's initials show
  as before. The image is cached by the link's path, which only changes
  with the logo.

## Not in scope

- Per-company colours, app name, icon or splash (SolaCliq is one shared
  app; `docs/product.md`).
- The website's upload page: built with the website's settings. Until
  then MarkCliq sets a logo through the API as the company's admin.
- A separate square mark for small sizes (see Open).

## Open

- **Small sizes.** A full logo with words (like RY Enterprises') gets
  tiny in the 40 px workspace badge. Options: an optional second, square
  "mark" upload; or ask vendors for a square logo.
- **Header size.** 40 dp tall reads as a brand stamp; the owner may want
  it larger.

## Tests

- Backend `tests/logo.rs`: members see the logo the admin sets; a new
  logo replaces the old one and its file; only the admin, only a `logo`
  upload, only one that arrived; PNG or JPEG up to 1 MB; another
  company's upload is refused.
- App `test/workspace/company_logo_test.dart`: initials without a logo,
  the logo with one, the fallback when it fails, caching by path, the
  header's logo.
