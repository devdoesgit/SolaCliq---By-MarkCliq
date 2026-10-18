# SolaCliq

SolaCliq is MarkCliq's product for **solar EPC vendors**: one app to manage their
customers, field workers and agents. It falls under MarkCliq's Custom SaaS and
Lead Management offerings, built for the Solar EPC vertical.

Agency context (who MarkCliq is, offerings, clients, team, brand) is shared with
the website repo and imported here. It is read from `~/Desktop/MarkCliq`; if
that repo moves, update this path.

@../MarkCliq/AGENCY.md

## Project

- Separate repo from the website (`~/Desktop/MarkCliq`). Never add SolaCliq code
  there, and never reach into the website repo except to read `AGENCY.md`.
- Timeline: **one month**, starting 2026-10-18. Scope accordingly — an MVP solar
  vendors can actually use, not a platform.
- Builders: the owner writes the Rust backend; Claude writes the Flutter
  mobile app and the React admin website.
- Building has **not** started. The owner will say when to begin.

## Layout

One repo, three parts sharing one API contract. Each part has its own
`CLAUDE.md` with its rules and screens or modules.

| Folder | What | Users | Built by |
|---|---|---|---|
| `api/` | OpenAPI contract (`openapi.yaml`) | — | Claude drafts, owner reviews |
| `backend/` | Rust API, Postgres, R2 | — | Owner |
| `mobile/` | Flutter app | Workers, agents, customers | Claude |
| `admin/` | React + Vite website | Org admins, platform admin | Claude |

## Records

Keep these current. They are the record of what SolaCliq is and why.

- `docs/product.md`: what the product does, roles, rules.
- `docs/architecture.md`: stack, hosting, API contract and conventions,
  design patterns, distribution, tooling.
- `docs/features.md`: feature list, build order and status.
- `docs/features/F<n>-<name>.md`: spec and notes for each feature, written
  when it starts.
- `docs/decisions.md`: dated log of decisions and their reasons.
- `questioner.md`: open questions for the pilot vendor. Nothing in it is
  settled.
- Design system: `design/tokens.json` is the source of truth (generated
  into both apps by `make tokens`). The published design system,
  https://claude.ai/artifact/DHZ36BtTE4ZCxGNoUbxSbN, still shows the old
  system-font version (fonts, type scale, 2px radius); republish it from
  the tokens before relying on its README. Both apps take their values
  from the tokens.

## How we work

- **Feature by feature.** Build one feature from `docs/features.md` at a
  time, with limited, focused scope. Finish and test it before starting the
  next. Don't add anything a feature's spec doesn't list; suggest it instead.
- **Spec first.** Before code, write the feature's spec and its endpoints in
  `api/openapi.yaml`; the owner reviews both.
- **Keep the record.** When a decision is made, add it to `decisions.md` and
  update the doc it affects. When a feature is finished, update its status
  and notes.
- **Ask before shipping.** Shorebird patches and APK releases reach real
  users; confirm with the owner each time.

## Conventions

- Brand: SolaCliq matches **markcliq.com** in everything: Space Grotesk and
  Space Mono (bundled in both apps, OFL), type, spacing, square corners, 1px
  rules, editorial easing. `design/tokens.json` holds the values, read from
  the live site; apps generate theirs from it with `make tokens`. Deviations
  exist only where field use needs them, and are noted on the token.
- Mobile: every interactive widget gets a `Key` and a Semantics label, so
  Claude can find and tap it through mobile-mcp and it is accessible to users.
- Money is integer paise everywhere. Never floats.
- Any data shown in demos or screenshots that is not real must be labelled
  illustrative — same rule as the website.
