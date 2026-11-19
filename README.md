<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="design/logo/kit/svg/solacliq-lockup-horizontal-dark.svg">
  <img src="design/logo/kit/svg/solacliq-lockup-horizontal.svg" alt="SolaCliq" width="360">
</picture>

### Every solar install, in one place.

The app for solar EPC companies, their field teams and their customers.<br>
By [MarkCliq](https://markcliq.com).

![Android](https://img.shields.io/badge/Android-first-3DDC84?logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-app-02569B?logo=flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-Axum-000000?logo=rust&logoColor=white)
![Postgres](https://img.shields.io/badge/Postgres-17-4169E1?logo=postgresql&logoColor=white)
![React](https://img.shields.io/badge/React-Vite-61DAFB?logo=react&logoColor=black)
![Status](https://img.shields.io/badge/status-pilot-b2402c)

<br>

<img src="docs/readme/promo.gif" alt="SolaCliq promo: proof photos from the roof, expenses approved from the office, the homeowner's install tracker and the company's own logo" width="800">

<sub>Illustrative screens, sample data. "Arka Solar" is an example company.</sub>

</div>

<br>

## What it is

A solar EPC runs on people who are rarely in the same place: the owner in
the office, installers on roofs, sales agents in the field, and homeowners
waiting to hear what happens next. Today that lives in WhatsApp groups,
phone calls and a spreadsheet someone forgot to update.

SolaCliq puts it in one app. Every customer moves through the same seven
stages, every step on the roof has a GPS-tagged photo behind it, every
rupee spent or owed is logged and approved, and every homeowner can see
where their install is without calling the office.

```
lead → site survey → quote → subsidy paperwork → install → net metering → service
```

<br>

## Built for four people

| Who | Where | What they do |
|---|---|---|
| **Company admin** | Admin website | Sees the whole company, sets up the team, assigns work, approves photos, expenses and commissions |
| **Installer** | Mobile app | Their tasks for the day, proof photos with GPS, checklists, expenses with the receipt |
| **Sales agent** | Mobile app | Registers customers with their KYC, follows them through the stages, logs commission |
| **Homeowner** | Mobile app | Their install's stage, the full cost breakdown, payments by UPI or bank transfer |

One account per person, across companies: an installer who works for two
EPCs switches between them inside the app.

<br>

## A look inside

<table>
  <tr>
    <td width="44%" valign="top">
      <img src="docs/readme/proof.gif" alt="An installer's panel installation task: the third GPS-tagged proof photo lands, the task is submitted, and the admin's approval arrives as a notification" width="100%">
    </td>
    <td valign="middle">
      <h3>Proof photos, from the roof</h3>
      <p>Installers shoot each step on site. Every photo carries its GPS
      position and goes straight to the admin, who approves it from the
      office. The installer gets a push notification and moves on to the
      next task.</p>
      <p>No more "send me a photo on WhatsApp". No more wondering whether
      the inverter was really mounted on Tuesday.</p>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td width="33%" valign="top" align="center">
      <img src="marketing/media/solacliq-install@2x.png" alt="A homeowner's install at stage 4 of 7, with the next payment of ₹40,000 and a Pay with UPI button" width="100%">
      <h4>Homeowners see every stage</h4>
      <sub>From site survey to handover, and what to pay next, without calling the office.</sub>
    </td>
    <td width="33%" valign="top" align="center">
      <img src="marketing/media/solacliq-expense@2x.png" alt="A worker's ₹1,240 fuel expense with its receipt, approved" width="100%">
      <h4>Expenses with the receipt</h4>
      <sub>Fuel, tools, travel: logged from the field with a photo of the bill, approved from the office.</sub>
    </td>
    <td width="33%" valign="top" align="center">
      <img src="marketing/media/solacliq-brand@2x.png" alt="The installer's home screen under the company's own logo" width="100%">
      <h4>Your logo, your team's app</h4>
      <sub>The company uploads its logo once. Every installer, agent and customer sees it.</sub>
    </td>
  </tr>
</table>

<div align="center"><sub>Illustrative screens, sample data. Graphics built with <a href="https://github.com/benjitaylor/skills">Stageshow</a>, in the app's own design; see <a href="marketing/README.md"><code>marketing/</code></a>.</sub></div>

<br>

## How it fits together

```mermaid
flowchart LR
    subgraph People
        A["Mobile app<br/>installers · agents · homeowners"]
        W["Admin website<br/>company admins"]
    end

    subgraph VPS["solacliq.markcliq.com"]
        C["Caddy<br/>HTTPS"]
        API["Rust API<br/>Axum + sqlx"]
        DB[("Postgres 17<br/>row-level security")]
    end

    R2[("Cloudflare R2<br/>photos · documents")]
    FCM["Firebase<br/>push"]
    G["Gmail API<br/>email"]

    A --> C
    W --> C
    C --> API
    API --> DB
    API -. "signed URLs" .-> R2
    A -- "uploads direct" --> R2
    W -- "uploads direct" --> R2
    API --> FCM
    API --> G
```

- **One API contract** (`api/openapi.yaml`) shared by all three parts. The
  Dart and TypeScript clients are generated from it, and CI fails if they
  fall out of date.
- **Each company's data is walled off in the database itself.** The API
  logs in as a role that row-level security restricts to the company of
  each request, so a query that forgets its filter still sees nothing
  else.
- **Files never pass through the server.** The API signs a short-lived
  URL for one file of one type and size; the phone uploads straight to R2.
- **Money is integer paise everywhere.** No floats, anywhere.

<br>

## The stack

| Part | Built with |
|---|---|
| Mobile app | Flutter (Dart), Android first, Inter, the "iOS v2" design |
| Admin website | React, Vite, TypeScript, a static site |
| Backend | Rust, Axum, sqlx, utoipa for the OpenAPI spec |
| Database | Postgres 17, row-level security per company |
| Files | Cloudflare R2, private bucket, presigned URLs |
| Push and email | Firebase Cloud Messaging, the Gmail API |
| Updates (planned) | Shorebird over-the-air patches, self-hosted APK for the pilot |

<br>

## The repo

| Folder | What's in it |
|---|---|
| [`api/`](api/) | The OpenAPI contract every part builds against, plus a Postman collection |
| [`backend/`](backend/) | The Rust API, its migrations and tests |
| [`mobile/`](mobile/) | The Flutter app, its design-system package `sola_ui` and the generated API client |
| [`admin/`](admin/) | The React admin website |
| [`design/`](design/) | Design tokens (one source for both apps), the logo kit and the app's screen designs |
| [`marketing/`](marketing/) | Website graphics and the promo videos |
| [`deploy/`](deploy/) | Caddy, systemd and backup files for the VPS |
| [`docs/`](docs/) | The record: product, architecture, features, decisions, data policy |

<br>

## Where things stand

The worker, sales and customer flows run end to end in the app against the
real API, along with push notifications and company logos. Next: the first
deploy, then the admin website's screens, referrals and in-app updates.
Pilot vendor: RY Enterprises, Bhadrak.

Feature by feature, with status: [`docs/features.md`](docs/features.md).

<br>

## Read more

| Doc | What it covers |
|---|---|
| [`docs/product.md`](docs/product.md) | What the product does, the roles and the rules |
| [`docs/architecture.md`](docs/architecture.md) | Stack, hosting, the API contract and its conventions |
| [`docs/features.md`](docs/features.md) | Every feature, build order and status |
| [`docs/decisions.md`](docs/decisions.md) | Dated log of decisions and why |
| [`docs/data-policy.md`](docs/data-policy.md) | How customer data is kept apart, stored, encrypted and deleted |
| [`design/logo/kit/GUIDELINES.md`](design/logo/kit/GUIDELINES.md) | Using the SolaCliq logo |

Each part has its own `CLAUDE.md` with its rules and how to run it.

<br>

<div align="center">

<img src="design/logo/kit/svg/solacliq-icon.svg" alt="" width="56">

<sub>SolaCliq is built by <a href="https://markcliq.com">MarkCliq</a>: performance marketing, custom software, intelligent automation.</sub>

</div>
