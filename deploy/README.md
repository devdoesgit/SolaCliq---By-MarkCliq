# Deploying SolaCliq

Everything runs on the VPS under `solacliq.markcliq.com`: Caddy in front
(HTTPS), the Rust API on `127.0.0.1:8080` behind `/api`, the admin
website's static files at `/`, Postgres 17 on the same machine. Files and
photos are in Cloudflare R2, not on the server.

The owner runs every command on the server; Claude has no access to it.
Commands marked **local** run on the development machine, in the repo.

| File | Where it goes |
|---|---|
| `Caddyfile` | a block in `/etc/caddy/Caddyfile` |
| `solacliq-api.service` | `/etc/systemd/system/` |
| `solacliq-backup.service`, `.timer` | `/etc/systemd/system/` |
| `solacliq.env.example` | filled in as `/etc/solacliq/solacliq.env` |
| `db-setup.sql` | run once with `psql` |
| `build.sh` | **local**: builds a release archive |
| `release.sh` | on the server: backs up, puts a release live, rolls back if it fails |
| `restore.sh` | on the server: puts a backup back (also used by `release.sh`) |

On the server:

```
/etc/solacliq/            solacliq.env, gmail-sender.json, firebase-key.json
/opt/solacliq/releases/   one folder per release (backend + admin/)
/opt/solacliq/current     link to the live release
/var/backups/solacliq/    daily database dumps, 14 days
```

## First deploy

### 1. Check the server

```
cat /etc/os-release | head -2; uname -m
caddy version; psql --version
sudo ss -ltnp | grep -E ':80 |:443 |:5432 |:8080 '
```

Expected: Ubuntu 22.04+ or Debian 12+, `x86_64`, nothing else on port
8080. If something differs, stop and tell Claude what it printed.

Ports 80 and 443 must be open to the internet (nothing answers on them
today). With ufw: `sudo ufw allow 80,443/tcp`. Also check the hosting
provider's firewall in its control panel.

### 2. Postgres 17

Skip if `psql --version` shows 17. Otherwise, from the PostgreSQL apt
repository:

```
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo apt install -y postgresql-17
```

It listens on localhost only by default; keep it that way.

### 3. The service user and folders

```
sudo useradd --system --no-create-home --shell /usr/sbin/nologin solacliq
sudo install -d -o root -g solacliq -m 750 /etc/solacliq
sudo install -d -o root -g root -m 755 /opt/solacliq/releases
sudo install -d -o postgres -g postgres -m 700 /var/backups/solacliq
```

### 4. The database

**local**: `scp deploy/db-setup.sql <you>@solacliq.markcliq.com:/tmp/`

Then on the server, with two new passwords:

```
OWNER_PW=$(openssl rand -hex 24); API_PW=$(openssl rand -hex 24)
sudo -u postgres psql -v ON_ERROR_STOP=1 -v owner_pw="$OWNER_PW" -v api_pw="$API_PW" -f /tmp/db-setup.sql
echo "owner: $OWNER_PW"; echo "api: $API_PW"
```

The passwords go into the settings in step 6. Clear the terminal after.

### 5. The key files

The Firebase key is on the development machine; the Gmail key may
already be on the server (`ls -l /etc/solacliq/`).

**local**: `scp ~/Desktop/solacliq-firebase-key.json <you>@solacliq.markcliq.com:/tmp/firebase-key.json`
(and the Gmail key the same way if it isn't there yet).

```
sudo mv /tmp/firebase-key.json /etc/solacliq/
sudo chown root:solacliq /etc/solacliq/*.json
sudo chmod 640 /etc/solacliq/*.json
```

640 with group `solacliq`, not 600: the API runs as `solacliq` and has to
read them.

### 6. The settings

**local**: `scp deploy/solacliq.env.example <you>@solacliq.markcliq.com:/tmp/`

```
sudo install -o root -g solacliq -m 640 /tmp/solacliq.env.example /etc/solacliq/solacliq.env
openssl rand -hex 32   # run twice: one for CODE_SECRET, one for BANK_KEY
sudo nano /etc/solacliq/solacliq.env
```

Fill in the two database passwords, `CODE_SECRET`, `BANK_KEY` and the
production R2 token's four values. Save `BANK_KEY` in your password
manager: without it the stored bank account numbers can't be read.

**The bucket's CORS rule.** Without it the website can't upload a logo.
In Cloudflare: R2 → `solacliq-uploads` → Settings → CORS policy → Edit:

```json
[
  {
    "AllowedOrigins": ["https://solacliq.markcliq.com"],
    "AllowedMethods": ["PUT"],
    "AllowedHeaders": ["content-type"],
    "MaxAgeSeconds": 3600
  }
]
```

Check it from any machine, with your account id. Expected: a line
`access-control-allow-origin: https://solacliq.markcliq.com`.

```
curl -si -X OPTIONS "https://<account id>.r2.cloudflarestorage.com/solacliq-uploads/check" \
  -H "Origin: https://solacliq.markcliq.com" -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: content-type" | grep -i allow-origin
```

### 7. The services

**local**: `scp deploy/*.service deploy/*.timer <you>@solacliq.markcliq.com:/tmp/`

```
sudo mv /tmp/solacliq-api.service /tmp/solacliq-backup.service /tmp/solacliq-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable solacliq-api
sudo systemctl enable --now solacliq-backup.timer
```

The API starts with the first release, next.

### 8. The first release

**local**:

```
deploy/build.sh
scp deploy/out/solacliq-<commit>.tar.gz deploy/release.sh deploy/restore.sh <you>@solacliq.markcliq.com:/tmp/
```

On the server:

```
sudo bash /tmp/release.sh /tmp/solacliq-<commit>.tar.gz
```

It prints `Live: solacliq-<commit>`, or the API's log if it didn't
start. The most likely cause then is a setting in step 6; the log names
it.

### 9. Caddy

Add the block from `deploy/Caddyfile` to `/etc/caddy/Caddyfile`, then:

```
caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
curl https://solacliq.markcliq.com/api/v1/health
```

Expected: `{"status":"ok","version":"0.1.0","database":"ok"}`. The first
request can take a few seconds while Caddy gets the certificate.

### 10. Check it end to end

1. Email: `sudo systemd-run --pty --wait -q --uid=solacliq -p EnvironmentFile=/etc/solacliq/solacliq.env /opt/solacliq/current/backend send-test-email info@markcliq.com`
2. The app, built for production (below), on a real phone: sign up,
   enter the emailed code, log in.
3. Register a test company in the app; the review email reaches
   info@markcliq.com.
4. Make your account MarkCliq's platform admin (it must have signed up first):
   `sudo systemd-run --pty --wait -q --uid=solacliq -p EnvironmentFile=/etc/solacliq/solacliq.env /opt/solacliq/current/backend make-platform-admin <your email>`
5. Approve that test company (next section), open
   https://solacliq.markcliq.com as its owner, choose "First time here?
   Set your password", and add a logo in Settings (it proves R2's rule).
6. Next morning: `ls -l /var/backups/solacliq/` shows a dump.

## Approve a company

A vendor can't use the website until MarkCliq approves them, and there's
no page for it yet. On any machine with curl and Python, as a platform
admin (step 10.4). Run each block by itself.

Log in (the password isn't shown or saved):

```
API=https://solacliq.markcliq.com/api/v1
read -rp "Your email: " EMAIL
```

```
read -rsp "Your password: " PW
```

```
TOKEN=$(EMAIL="$EMAIL" PW="$PW" python3 -c 'import json,os; print(json.dumps({"email": os.environ["EMAIL"], "password": os.environ["PW"], "client": "app"}))' \
  | curl -fsS -H 'content-type: application/json' -d @- "$API/auth/login" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tokens"]["access_token"])'); unset PW
```

See who is waiting:

```
curl -fsS -H "Authorization: Bearer $TOKEN" "$API/platform/orgs?status=pending" \
  | python3 -c 'import json,sys; [print(o["id"], o["name"], (o.get("owner") or {}).get("email", "")) for o in json.load(sys.stdin)["items"]]'
```

Approve one, after calling the owner. They get an email with the link to
set their password:

```
ORG=paste-the-id-here
```

```
curl -fsS -H "Authorization: Bearer $TOKEN" -H 'content-type: application/json' \
  -d '{"status":"active"}' "$API/platform/orgs/$ORG/status"
```

To turn one down instead, send
`{"status":"rejected","note":"The reason, which the owner is emailed"}`.
The token works for 15 minutes; log in again after that.

## The production app

The production app talks to `https://solacliq.markcliq.com/api/v1`
(`mobile/lib/app/config/app_config.dart`). A release build needs the
signing key, made once and kept forever: every later update (and
Shorebird patch) must be signed with the same key, or phones can't
install it over the old one.

**local**, once:

```
keytool -genkey -v -keystore ~/solacliq-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias solacliq
```

Back up `~/solacliq-upload.jks` and its password (password manager plus
one copy off this machine). Then point `mobile/android/key.properties` at
it (git-ignored):

```
storeFile=/home/dev/solacliq-upload.jks
storePassword=...
keyAlias=solacliq
keyPassword=...
```

Build and install:

```
cd mobile
flutter build apk --release --flavor production -t lib/main_production.dart
adb install build/app/outputs/flutter-apk/app-production-release.apk
```

## Later releases

**local**: commit, `deploy/build.sh`, then `scp` the archive with
`deploy/release.sh` and `deploy/restore.sh`, and reload Caddy if
`deploy/Caddyfile` changed.
**Server**: `sudo bash /tmp/release.sh /tmp/solacliq-<commit>.tar.gz`.

It stops the API for a few seconds, takes a backup, then starts the
release. If that doesn't start, the previous release comes back by
itself, with the backup if a migration had run. Don't roll back by
moving `current` yourself after a migration: an older API won't start on
a newer database.

## Restore a backup

```
sudo bash /tmp/restore.sh /var/backups/solacliq/<dump> [solacliq-<commit>]
```

Give the release the dump was made with when it's older than the live
one. What was written after the dump was taken is not in it. The
database it replaces is kept as `solacliq_replaced_<time>`; once you're
sure, drop it with `sudo -u postgres dropdb <that name>`. Don't use
`pg_restore --clean` on the live database: later releases can then never
migrate it.

## Logs

`journalctl -u solacliq-api -f` (the API), `journalctl -u caddy -f`.
