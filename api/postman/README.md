# Postman collection

`SolaCliq.postman_collection.json` covers every endpoint in
`../openapi.yaml` (66 operations, 80 requests). It is generated: change
`generate.py` or the contract, then `make postman`. Don't edit the JSON
by hand. Every person, company and value in it is illustrative.

## Use it

1. Local API with the seed:
   ```
   make db
   cd backend && cargo run -- seed
   cargo run -- make-platform-admin dev@example.com   # once, for folder 10
   make api
   ```
2. Import the JSON into Postman. `baseUrl` is
   `http://localhost:8080/api/v1`.
3. Run folder **1** first: it logs in as each seeded role and saves their
   tokens (`token_worker`, `token_agent`, `token_customer`,
   `token_admin`). Each request then sends the right one.
4. Folders 2–11 follow one install's life: the admin sets up two tasks,
   Ravi does them, Meena registers a customer with KYC, Rajinder claims a
   payment, Dev decides on all of it, then notifications, profile, team,
   company registration and sessions. Run them in order after a fresh
   seed and every request passes; one by one they work too, as long as
   the ids they use are in the right state.

Folder 12 (sign up, passwords) sends real emails and needs the code from
them: set `email` to an inbox you read, then `code`. It isn't part of the
automatic run.

## How it works

- **Roles.** Seeded people (password `sunlight1`): Ravi (installer),
  Meena (sales agent, commission), Rajinder (customer), Dev (the
  company's admin, and MarkCliq platform admin after the command above).
- **Files.** Requests that need one (proof photos, receipts, KYC) upload
  it first in their pre-request script, as the app does: `POST /uploads`,
  then a `PUT` of a small file to the signed R2 URL. So R2 must be set
  up in `backend/.env`.
- **Checks.** Every request checks its status against the contract, and
  any 5xx fails the run, so the collection is also a smoke test.
- **Unique values.** The first request starts a new `run` number used in
  emails, phones, consumer numbers and a valid GSTIN, so runs don't
  collide.

## Run it from the terminal

Folders 9 and 10 send email (a new member's invite, the registration to
MarkCliq's review inbox). Run against a server whose mail goes to the
log:

```
cd backend
MAIL_FROM= GOOGLE_SERVICE_ACCOUNT_KEY_FILE= FCM_SERVICE_ACCOUNT_KEY_FILE= cargo run
```

then, from the repo root, after a fresh seed:

```
make postman-run
```

Last run, 2026-11-17: 75 requests plus 22 uploads, 150 checks, none failed.
