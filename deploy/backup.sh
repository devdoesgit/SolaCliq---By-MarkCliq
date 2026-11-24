#!/usr/bin/env bash
# A dump of the database into $SOLACLIQ_BACKUPS (outside Docker), the last
# 14 days of daily ones kept. Prints the file's path.
#   sudo bash backup.sh            the nightly one (solacliq-backup.timer)
#   sudo bash backup.sh release    before a release (release.sh)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/common.sh"
kind="${1:-daily}"
mkdir -p "$SOLACLIQ_BACKUPS"
umask 077
file="$SOLACLIQ_BACKUPS/solacliq-$([[ $kind == daily ]] || echo "$kind-")$(date +%Y%m%d-%H%M%S).dump"
# Into a temporary name first: a dump that stops half way is never mistaken for a backup.
if ! compose exec -T db pg_dump -U postgres --format=custom solacliq > "$file.part"; then
  rm -f "$file.part"
  echo "The backup failed." >&2
  exit 1
fi
mv "$file.part" "$file"
if [[ $kind == daily ]]; then
  find "$SOLACLIQ_BACKUPS" -name 'solacliq-2*.dump' -mtime +14 -delete
else
  # The last ten of the other kinds (one per release).
  ls -1t "$SOLACLIQ_BACKUPS"/solacliq-"$kind"-*.dump 2>/dev/null | tail -n +11 | xargs -r rm -f
fi
echo "$file"
