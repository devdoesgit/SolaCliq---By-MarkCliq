# F19 Stage templates

Each company names its own 7 install stages and sets, for each, the
checklist and the photos a task at that stage asks for. Asked by the
owner on 2026-11-23 ("stage templates should be editable for every org");
options chosen the same day.

## Goal

A company's installers see its own words: "Mounting" instead of
"Structure" if that's what they call it, and the checks the company
wants done at each stage, without the admin typing them into every task.

## Rules

- **Always 7 stages.** A company renames them and fills their templates;
  it can't add, remove or reorder them. A running project's stage number
  keeps its meaning (owner, 2026-11-23).
- **Defaults.** Until a company changes a stage, it has the standard
  name (Site survey, Structure, Panel installation, Wiring and inverter,
  Earthing, Net meter, Handover) and an empty template.
- **A stage** has a name (1 to 40 characters), a checklist (up to 20
  items, each up to 120 characters) and the photos to take (up to 8
  labels, each up to 60 characters). Blank items are dropped; repeats
  are kept once.
- **Who:** the company's admin edits them on the website (Settings).
  Every member reads them; the app and the website show the company's
  names everywhere a stage is named ("Stage 2 · Mounting").
- **New task** fills its title, checklist and photos from the chosen
  stage's template. The admin can still change them for that task. A
  task keeps what it was created with: editing a template later doesn't
  change tasks already made.
- **Isolation:** templates are company data, under row-level security
  like every company table. Company A never sees company B's.

## API

- `GET /orgs/{org_id}/stages`: any member. The 7 stages, in order.
- `PUT /orgs/{org_id}/admin/stages/{index}`: admins. Replaces one stage's
  name, checklist and photos; returns all 7.
- `AdminSettings.stages` (names) stays, filled from the same table.

## Not in this feature

- More or fewer than 7 stages, or reordering.
- Templates shared between companies, or a library of them.

## Status

Built 2026-11-23. See `docs/features.md`.
