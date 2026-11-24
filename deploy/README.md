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
- **The production bucket:** in Cloudflare R2, create `solacliq-uploads-prod`
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
In Cloudflare: R2 → `solacliq-uploads-prod` → Settings → CORS policy → Edit:

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
curl -si -X OPTIONS "https://<account id>.r2.cloudflarestorage.com/solacliq-uploads-prod/check" \
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

A vendor can't use the website until MarkCliq approves them. As a platform
admin (step 10.4), log in at https://solacliq.markcliq.com → **Companies**
→ the company → **Approve** (or **Reject**, with the reason the owner is
emailed). Suspend and Restore are on the same page.

Without the website, through the API, on any machine with curl and
Python. Run each block by itself.

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

The key's certificate, to recognise it: SHA-256
`15f7e66f949531d1d79168144d66cbcaed67ea5e5ad9546d69b5c213b3bf6f9e`
(`CN=Devesh Rajput, O=MarkCliq`).

### A release: a new APK, through Shorebird

**Always build the APK with Shorebird.** An APK from `flutter build` can
never receive a patch. Ask before releasing: it reaches real users.

```
cd mobile
export PATH="$HOME/.shorebird/bin:$PATH"
shorebird release android --flavor production -t lib/main_production.dart --artifact apk --flutter-version=3.47.7
```

It builds, signs and registers the release with Shorebird, then prints
the APK's path (`build/app/outputs/flutter-apk/app-production-release.apk`):
that's the file to hand out. The release build needs about 7 GB of
memory; close what you can first.

### A patch: a Dart fix, over the air

For a change to Dart code only (screens, logic, text). New plugins,
permissions, Android settings or the icon need a release instead;
Shorebird refuses a patch that changes them. Ask before patching: it
reaches real users.

```
shorebird patch android --flavor production -t lib/main_production.dart --release-version <version, e.g. 1.0.0+1>
```

Phones download it in the background and run it from their next start.
If it misbehaves:

```
shorebird patches rollback --flavor production --release-version <version> --patch-number <n>
```

Try a patch on `--flavor staging` first: staging and development have
their own Shorebird apps (`mobile/shorebird.yaml`), so nothing reaches
real users.

### The app from GitHub

`.github/workflows/app.yml` builds releases and patches on GitHub, so
they don't depend on this PC. It is **off** until you add its secrets:
every job is skipped unless the repo variable `APP_PIPELINE` is `on`.

On GitHub's free plan the secrets are repository secrets: anyone with
**write access** to the repo could read them, by changing a workflow.
So: **only you have write access.** Anyone else gets read access, or
works through pull requests from a fork. Before giving anyone write
access, take the signing key out (or move to GitHub Pro, where secrets
can be limited to your release tags).

**Switching it on**, once (Settings → Secrets and variables → Actions):

1. Secrets:
   - `SHOREBIRD_TOKEN`: a service account key, made on
     console.shorebird.dev (Account → Service accounts). Revoke it
     there if it ever leaks.
   - `ANDROID_KEYSTORE_BASE64`: the output of
     `base64 -w0 ~/solacliq-upload.jks`, pasted.
   - `ANDROID_KEYSTORE_PASSWORD`: the key's password.
   - `GOOGLE_SERVICES_JSON`: the contents of
     `mobile/android/app/google-services.json`.
2. Variables: `APP_PIPELINE` = `on`.
3. Turn on two-step login on your GitHub account, if it isn't: the
   account now guards the signing key.

**Using it.** Every step that reaches users is a step you take:

- **A release:** set `version:` in `mobile/pubspec.yaml` (e.g. `1.0.1+2`),
  commit, then `git tag app-v1.0.1+2 && git push origin app-v1.0.1+2`.
  The APK appears on the tag's GitHub Release; handing it out is yours.
- **A patch:** Actions → App → Run workflow → `patch`, with the release
  it's for. It goes to the `staging` track only: no phone gets it.
  Check it on your own phone (`shorebird preview --track staging`).
- **Promote:** Run workflow → `promote`, with the patch's number: every
  phone on that release gets it on its next start.
- **Roll back:** Run workflow → `rollback`, with the patch's number.

## Deploying from GitHub (CI/CD)

After the first deploy works by hand, GitHub can do the building and
sending. Two workflows:

- **CI** (`.github/workflows/ci.yml`), on every push and pull request:
  the server (format, clippy, every test against Postgres), its Docker
  image, the app (format, analyze, tests, a debug APK), the website
  (lint, types, tests, build), and the API contract.
- **Deploy** (`.github/workflows/deploy.yml`):
  1. `git tag v1.0.1 && git push origin v1.0.1` runs CI, builds the
     release archive and attaches it to a GitHub Release. Nothing goes
     live.
  2. **You put it live:** GitHub → Actions → Deploy → Run workflow → the
     tag. It sends the archive to the VPS, where `release.sh` backs up,
     puts it live, and rolls back by itself if it doesn't answer. Only
     people with write access to the repo can run it.

GitHub gets the narrowest way in: its own user, whose key can only send
a release (`deploy/solacliq-deploy`: no shell, nothing else), and `sudo`
for `release.sh` on an uploaded release only. A leaked key could only
deploy a release.

### Set it up once

On the VPS (from the repo clone, or `scp` the two files as in step 3):

```
sudo useradd --system --create-home --home-dir /var/lib/solacliq-deploy --shell /bin/bash solacliq-deploy
sudo chmod 700 /var/lib/solacliq-deploy
sudo install -m 755 deploy/solacliq-deploy /usr/local/bin/solacliq-deploy
sudo install -m 440 deploy/sudoers-solacliq-deploy /etc/sudoers.d/solacliq-deploy
sudo visudo -c
```

`visudo -c` must say `parsed OK`; if not, `sudo rm /etc/sudoers.d/solacliq-deploy`.

**local**, a key for GitHub only:

```
ssh-keygen -t ed25519 -N "" -C github-deploy -f ~/solacliq-github-deploy
cat ~/solacliq-github-deploy.pub
```

On the VPS, with the line it printed in place of `ssh-ed25519 AAAA...`:

```
sudo install -d -m 700 -o solacliq-deploy -g solacliq-deploy /var/lib/solacliq-deploy/.ssh
echo 'command="/usr/local/bin/solacliq-deploy",restrict ssh-ed25519 AAAA... github-deploy' \
  | sudo tee /var/lib/solacliq-deploy/.ssh/authorized_keys > /dev/null
sudo chown solacliq-deploy: /var/lib/solacliq-deploy/.ssh/authorized_keys
sudo chmod 600 /var/lib/solacliq-deploy/.ssh/authorized_keys
```

**local**, check the key does nothing else (expected: `Refused: send the release name`):

```
ssh -i ~/solacliq-github-deploy solacliq-deploy@solacliq.markcliq.com whoami
```

and record the server's identity for GitHub:

```
ssh-keyscan -t ed25519 solacliq.markcliq.com
```

On GitHub: the repo → Settings → Secrets and variables → Actions → New
repository secret, four of them:

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | `solacliq.markcliq.com` (or the VPS's IP) |
| `DEPLOY_PORT` | the SSH port, if not 22 (else leave it out) |
| `DEPLOY_SSH_KEY` | the whole of `~/solacliq-github-deploy` (the private one, from `-----BEGIN` to `END-----`) |
| `DEPLOY_KNOWN_HOSTS` | the line `ssh-keyscan` printed |

Then delete the private key from this machine
(`rm ~/solacliq-github-deploy`): GitHub has it, and a new one is easy to
make. To take GitHub's access away, empty
`/var/lib/solacliq-deploy/.ssh/authorized_keys`.

### A release

```
git tag v1.0.1 && git push origin v1.0.1
```

Wait for the Deploy run to go green (CI, then "Build the release"), then
Actions → Deploy → Run workflow → `v1.0.1`. The log shows `release.sh`'s
own output, ending `Live: solacliq-<commit>`, then a health check. A
release that doesn't answer rolls back by itself and the run goes red.

### When a deploy-kit file changed

A release carries the API and the website, not the deploy kit. When a
commit changes `deploy/compose.yml` (or another kit file), copy it to the
server by hand **before** putting that release live, as in step 3:

```
scp deploy/compose.yml root@solacliq.markcliq.com:/tmp/        # local
install -m 644 /tmp/compose.yml /opt/solacliq/                  # server
```

`release.sh` then starts the API with it.

## Later releases, by hand

Without GitHub (or if it's down): **local**: commit, `deploy/build.sh`, `scp` the archive (and any changed
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

The API logs one JSON line per request (its id, method, path, status
and time; never the query or the body) and every error. The health
check stays out. Useful ones:

```
alias dc='docker compose -f /opt/solacliq/compose.yml'   # once per login
dc logs --since 1h api | grep '"level":"ERROR"'        # errors in the last hour
dc logs api | grep '"status":5'                         # server errors
dc logs api | grep 3a6bfd41-a51c-46dc-a986-712c1bc4148d # one request, by its id
```

Every response carries its id in the `X-Request-Id` header (Postman
shows it under Headers). When someone reports a failure, that id finds
its log lines. A crash inside a request is caught, logged as
`handler panicked` and answered with a plain 500.
