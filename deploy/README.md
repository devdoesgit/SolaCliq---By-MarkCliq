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
| `release.sh` | on the server: puts a release live |

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
scp deploy/out/solacliq-<commit>.tar.gz deploy/release.sh <you>@solacliq.markcliq.com:/tmp/
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
5. Next morning: `ls -l /var/backups/solacliq/` shows a dump.

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

**local**: commit, `deploy/build.sh`, `scp` the archive.
**Server**: `sudo bash /tmp/release.sh /tmp/solacliq-<commit>.tar.gz`.

A release with a migration changes the database for good: take a backup
first (`sudo systemctl start solacliq-backup`).

## Restore a backup

```
sudo systemctl stop solacliq-api
sudo -u postgres pg_restore --clean --if-exists -d solacliq /var/backups/solacliq/solacliq-<date>.dump
sudo systemctl start solacliq-api
```

## Logs

`journalctl -u solacliq-api -f` (the API), `journalctl -u caddy -f`.
