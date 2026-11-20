#!/usr/bin/env bash
# Run on the server, as root: sudo bash release.sh /tmp/solacliq-<commit>.tar.gz
# Unpacks the release next to the earlier ones, points `current` at it and
# restarts the API, which runs any new migrations as it starts. If the API
# doesn't answer within 30 seconds, `current` goes back to the previous
# release. Migrations can't be undone that way; restore a backup for that.
set -euo pipefail

archive="${1:?usage: release.sh /path/to/solacliq-<commit>.tar.gz}"
releases=/opt/solacliq/releases
name="$(basename "$archive" .tar.gz)"

mkdir -p "$releases"
tar -C "$releases" -xzf "$archive"
chown -R root:root "$releases/$name"
chmod 755 "$releases/$name/backend"

previous="$(readlink -f /opt/solacliq/current || true)"
ln -sfn "$releases/$name" /opt/solacliq/current
systemctl restart solacliq-api

for _ in $(seq 30); do
  if curl -fsS http://127.0.0.1:8080/api/v1/health >/dev/null 2>&1; then
    echo "Live: $name"
    # Keep the last five releases.
    ls -1dt "$releases"/solacliq-* | tail -n +6 | xargs -r rm -rf
    exit 0
  fi
  sleep 1
done

echo "The API didn't answer. Its log:" >&2
journalctl -u solacliq-api -n 30 --no-pager >&2
if [[ -n "$previous" && "$previous" != "$releases/$name" ]]; then
  ln -sfn "$previous" /opt/solacliq/current
  systemctl restart solacliq-api
  echo "Rolled back to $(basename "$previous")." >&2
fi
exit 1
