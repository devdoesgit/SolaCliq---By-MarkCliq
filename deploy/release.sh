#!/usr/bin/env bash
# Run on the server, as root, with restore.sh next to it:
#   sudo bash release.sh /tmp/solacliq-<commit>.tar.gz
# Unpacks the release next to the earlier ones, stops the API, backs the
# database up, points `current` at the release and starts it; new
# migrations run as it starts. If it doesn't answer within 30 seconds the
# previous release comes back, with the backup if a migration had run (an
# older API won't start on a newer schema). Nothing is written between
# the backup and that, so nothing is lost.
set -euo pipefail

archive="${1:?usage: release.sh /path/to/solacliq-<commit>.tar.gz}"
here="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$here/restore.sh" ]] || { echo "Copy restore.sh next to this script first." >&2; exit 1; }
releases=/opt/solacliq/releases
backups=/var/backups/solacliq
name="$(basename "$archive" .tar.gz)"

previous=""
[[ -L /opt/solacliq/current ]] && previous="$(readlink -f /opt/solacliq/current || true)"

mkdir -p "$releases"
tar -C "$releases" -xzf "$archive"
chown -R root:root "$releases/$name"
chmod 755 "$releases/$name/backend"
# The archive keeps its build time; the clean-up below goes by install time.
touch "$releases/$name"
cd /tmp

migrations() {
  runuser -u postgres -- psql -qAt -d solacliq -c 'SELECT count(*) FROM _sqlx_migrations' 2>/dev/null || echo 0
}

[[ -z "$previous" ]] || systemctl stop solacliq-api
before="$(migrations)"
dump="$backups/solacliq-release-$(date +%Y%m%d-%H%M%S)-$$.dump"
if ! runuser -u postgres -- pg_dump --format=custom --file="$dump" solacliq; then
  [[ -z "$previous" ]] || systemctl start solacliq-api
  echo "The backup failed, so nothing was released." >&2
  exit 1
fi

ln -sfn "$releases/$name" /opt/solacliq/current
systemctl restart solacliq-api

for _ in $(seq 30); do
  if curl -fsS http://127.0.0.1:8080/api/v1/health >/dev/null 2>&1; then
    echo "Live: $name (backup from just before: $dump)"
    # Keep the last five releases.
    ls -1dt "$releases"/solacliq-* | tail -n +6 | xargs -r rm -rf
    exit 0
  fi
  sleep 1
done

echo "The API didn't answer. Its log:" >&2
journalctl -u solacliq-api -n 30 --no-pager >&2
if [[ -n "$previous" && "$previous" != "$releases/$name" ]]; then
  systemctl stop solacliq-api
  if [[ "$(migrations)" != "$before" ]]; then
    bash "$here/restore.sh" "$dump" "$(basename "$previous")" >&2
  else
    ln -sfn "$previous" /opt/solacliq/current
    systemctl start solacliq-api
  fi
  echo "Rolled back to $(basename "$previous")." >&2
fi
exit 1
