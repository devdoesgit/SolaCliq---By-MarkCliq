#!/usr/bin/env bash
# Puts a release live (deploy/README.md), on the server, as root:
#   sudo bash /opt/solacliq/release.sh /tmp/solacliq-<commit>.tar.gz
# 1. Unpacks it next to the earlier ones and loads its API image.
# 2. Stops the API and backs the database up (backup.sh).
# 3. Points `current` (website files and API image) at it and starts the
#    API; new migrations run as it starts.
# 4. If it doesn't answer within 60 seconds, the previous release comes
#    back, with the backup if a migration had run (an older API won't
#    start on a newer schema). Nothing is written in between, so nothing
#    is lost.
set -euo pipefail
archive="${1:?usage: release.sh /path/to/solacliq-<commit>.tar.gz}"
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/common.sh"
name="$(basename "$archive" .tar.gz)"
image="solacliq-api:${name#solacliq-}"

mkdir -p "$releases"
tar -C "$releases" -xzf "$archive"
[[ -f "$releases/$name/api-image.tar" ]] || { echo "No API image in $archive." >&2; exit 1; }
docker load -i "$releases/$name/api-image.tar" > /dev/null
rm -f "$releases/$name/api-image.tar"
docker image inspect "$image" > /dev/null
# The archive keeps its build time; the clean-up below goes by install time.
touch "$releases/$name"

previous=""
[[ -L "$SOLACLIQ_HOME/current" ]] && previous="$(basename "$(readlink -f "$SOLACLIQ_HOME/current")")"
if [[ -z "$previous" ]]; then
  # The first release: the database starts (and sets itself up) first.
  compose up -d --wait db
else
  compose stop api
fi
before="$(migrations)"
if ! dump="$(bash "$here/backup.sh" release)"; then
  [[ -z "$previous" ]] || compose up -d api
  echo "The backup failed, so nothing was released." >&2
  exit 1
fi

ln -sfn "$releases/$name" "$SOLACLIQ_HOME/current"
docker tag "$image" solacliq-api:current
compose up -d api
if answers; then
  echo "Live: $name (backup from just before: $dump)"
  # Keep the last five releases, and their images.
  for old in $(ls -1dt "$releases"/solacliq-* | tail -n +6); do
    docker rmi "solacliq-api:$(basename "$old" | sed 's/^solacliq-//')" > /dev/null 2>&1 || true
    rm -rf "$old"
  done
  exit 0
fi

echo "The API didn't answer. Its log:" >&2
compose logs --no-color --tail 30 api >&2 || true
if [[ -n "$previous" && "$previous" != "$name" ]]; then
  compose stop api
  if [[ "$(migrations)" != "$before" ]]; then
    bash "$here/restore.sh" "$dump" "$previous" >&2
  else
    ln -sfn "$releases/$previous" "$SOLACLIQ_HOME/current"
    docker tag "solacliq-api:${previous#solacliq-}" solacliq-api:current
    compose up -d api
    answers || echo "The previous release didn't answer either." >&2
  fi
  echo "Rolled back to $previous." >&2
fi
exit 1
