# Deploying SolaCliq

Everything runs on the VPS under `solacliq.markcliq.com`: Caddy in front
(HTTPS), and in Docker the Rust API (on `127.0.0.1:8080`, behind `/api`)
and Postgres 17. The admin website's static files are served by Caddy at
`/`. Files and photos are in Cloudflare R2, not on the server.

> **The database is the Docker volume `solacliq-db`.**
> `docker compose down` keeps it. `docker compose down -v`, or
> `docker volume rm solacliq-db`, **erases every company's data**.
> The nightly dumps in `/var/backups/solacliq` are outside Docker.

The owner runs every command on the server; Claude has no access to it.
Commands marked **local** run on the development machine, in the repo.

| File | Where it goes |
|---|---|
| `compose.yml`, `db-init.sh`, `db-setup.sql` | `/opt/solacliq/` (the containers) |
| `common.sh`, `backup.sh`, `release.sh`, `restore.sh` | `/opt/solacliq/` (run as root) |
| `db.env.example` | filled in as `/etc/solacliq/db.env` |
| `solacliq.env.example` | filled in as `/etc/solacliq/solacliq.env` |
| `solacliq-backup.service`, `.timer` | `/etc/systemd/system/` |
| `Caddyfile` | a block in `/etc/caddy/Caddyfile` |
| `build.sh` | **local**: builds a release archive (API image + website) |
| `../backend/Dockerfile` | the API's image, built by `build.sh` |

On the server:

```
/etc/solacliq/            db.env, solacliq.env, gmail-sender.json, firebase-key.json
/opt/solacliq/            compose.yml and the scripts
/opt/solacliq/releases/   one folder per release (the website's files)
/opt/solacliq/current     link to the live release; the image solacliq-api:current is its API
/var/backups/solacliq/    database dumps: daily ones for 14 days, the last 10 releases'
```

## First deploy

### 0. Before you start

- **DNS:** an `A` record for `solacliq.markcliq.com` pointing at the
  VPS's IP address (where markcliq.com's DNS is managed). Check with
  `dig +short solacliq.markcliq.com`: it must print that IP before
  step 9, or Caddy can't get the certificate.
- **The production bucket:** in Cloudflare R2, create `solacliq-uploads`
  and an API token with Object Read & Write on that bucket only. Keep its
  Access Key ID and Secret for step 6.
- **On this machine, Docker** for `build.sh`: your user isn't in the
  `docker` group, so use Podman's socket in that terminal:
  `systemctl --user start podman.socket && export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock`
  (or `sudo usermod -aG docker $USER` and log in again).

### 1. Check the server

```
cat /etc/os-release | head -2; uname -m
caddy version; docker --version; docker compose version
sudo ss -ltnp | grep -E ':80 |:443 |:8080 '
```

Expected: Ubuntu 22.04+ or Debian 12+, `x86_64`, Docker 24+ with the
compose plugin, nothing else on port 8080. If Docker is missing, install
it from Docker's own apt repository (docs.docker.com, "Install Docker
Engine on Ubuntu"), which includes compose. If something else differs,
stop and tell Claude what it printed.

Ports 80 and 443 must be open to the internet (nothing answers on them
today). With ufw: `sudo ufw allow 80,443/tcp`. Also check the hosting
provider's firewall in its control panel. Postgres needs no port: it's
reachable only by the API, inside Docker. (Docker's published ports skip
ufw; the API's is bound to 127.0.0.1, so it's closed to the internet
anyway.)

### 2. The folders

```
sudo install -d -o root -g root -m 755 /etc/solacliq
sudo install -d -o root -g root -m 755 /opt/solacliq/releases
sudo install -d -o root -g root -m 700 /var/backups/solacliq
```

### 3. The deploy kit

**local**: `scp deploy/compose.yml deploy/db-init.sh deploy/db-setup.sql deploy/common.sh deploy/backup.sh deploy/release.sh deploy/restore.sh deploy/*.example deploy/*.service deploy/*.timer <you>@solacliq.markcliq.com:/tmp/`

```
cd /tmp && sudo install -m 644 compose.yml db-setup.sql common.sh /opt/solacliq/
sudo install -m 755 db-init.sh backup.sh release.sh restore.sh /opt/solacliq/
```

### 4. The database passwords

```
sudo install -o root -g root -m 600 /tmp/db.env.example /etc/solacliq/db.env
for v in POSTGRES_PASSWORD SOLACLIQ_OWNER_PASSWORD SOLACLIQ_API_PASSWORD; do echo "$v=$(openssl rand -hex 24)"; done
sudo nano /etc/solacliq/db.env
```

Paste the three lines it printed over the empty ones. The owner and API
passwords also go into the settings in step 6. They're read once, when
the database is first created. Clear the terminal after.

### 5. The key files

The Firebase key is on the development machine; the Gmail key may
already be on the server (`ls -l /etc/solacliq/`).

**local**: `scp ~/Desktop/solacliq-firebase-key.json <you>@solacliq.markcliq.com:/tmp/firebase-key.json`
(and the Gmail key the same way if it isn't there yet).

```
sudo mv /tmp/firebase-key.json /etc/solacliq/
sudo chown 10001:10001 /etc/solacliq/*.json
sudo chmod 600 /etc/solacliq/*.json
```

10001 is the API's user inside its container: only it reads the keys.

### 6. The settings

```
sudo install -o root -g root -m 600 /tmp/solacliq.env.example /etc/solacliq/solacliq.env
openssl rand -hex 32   # run twice: one for CODE_SECRET, one for BANK_KEY
sudo nano /etc/solacliq/solacliq.env
```

Fill in the two database passwords (the same as in `db.env`), `CODE_SECRET`, `BANK_KEY` and the
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

### 7. The nightly backup

```
sudo mv /tmp/solacliq-backup.service /tmp/solacliq-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now solacliq-backup.timer
```

Docker restarts the containers by itself after a crash or a reboot
(`restart: unless-stopped`); there's no service for them.

### 8. The first release

**local** (Docker running; the archive holds the API image and the website):

```
deploy/build.sh
scp deploy/out/solacliq-<commit>.tar.gz <you>@solacliq.markcliq.com:/tmp/
```

On the server:

```
sudo bash /opt/solacliq/release.sh /tmp/solacliq-<commit>.tar.gz
```

The first time, the database container starts and sets itself up first.
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

1. Email: `sudo docker compose -f /opt/solacliq/compose.yml exec api solacliq-api send-test-email info@markcliq.com`
2. The app, built for production (below), on a real phone: sign up,
   enter the emailed code, log in.
3. Register a test company in the app; the review email reaches
   info@markcliq.com.
4. Make your account MarkCliq's platform admin (it must have signed up first):
   `sudo docker compose -f /opt/solacliq/compose.yml exec api solacliq-api make-platform-admin <your email>`
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

**local**: commit, `deploy/build.sh`, `scp` the archive (and any changed
file of the deploy kit, then `install` it as in step 3), and reload
Caddy if `deploy/Caddyfile` changed.
**Server**: `sudo bash /opt/solacliq/release.sh /tmp/solacliq-<commit>.tar.gz`.

It stops the API for a few seconds, takes a backup, then starts the
release. If that doesn't answer within a minute, the previous release
comes back by itself, with the backup if a migration had run. Don't roll
back by hand after a migration: an older API won't start on a newer
database. The last five releases and their images are kept.

## Restore a backup

```
sudo bash /opt/solacliq/restore.sh /var/backups/solacliq/<dump> [solacliq-<commit>]
```

Give the release the dump was made with when it's older than the live
one. What was written after the dump was taken is not in it. It loads
into a new database first: a dump that won't load leaves the live one
untouched. The database it replaces is kept as
`solacliq_replaced_<time>`; once you're sure, drop it:
`sudo docker compose -f /opt/solacliq/compose.yml exec db dropdb -U postgres <that name>`.
Don't use `pg_restore --clean` on the live database: later releases can
then never migrate it.

## Logs and status

```
sudo docker compose -f /opt/solacliq/compose.yml ps
sudo docker compose -f /opt/solacliq/compose.yml logs -f api
sudo docker compose -f /opt/solacliq/compose.yml logs -f db
journalctl -u caddy -f
```

Each container keeps 5 log files of 10 MB.
