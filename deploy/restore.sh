#!/usr/bin/env bash
# Puts a backup back (deploy/README.md), on the server, as root:
#   sudo bash /opt/solacliq/restore.sh /var/backups/solacliq/<dump> [solacliq-<commit>]
# It loads into a new, empty database first, which then takes the live
# one's name. Nothing is dropped: the database it replaces is kept as
# solacliq_replaced_<time>, and if the dump won't load the live one is
# never touched. Give the release the dump was made with when it's older
# than the live one: an API only starts on a schema it knows.
# (`pg_restore --clean` into the live database doesn't work: it leaves
# what newer migrations added, and the next release then can't migrate.)
set -euo pipefail
dump="${1:?usage: restore.sh /path/to/backup.dump [solacliq-<commit>]}"
release="${2:-}"
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/common.sh"
[[ -r "$dump" ]] || { echo "Can't read $dump" >&2; exit 1; }
if [[ -n "$release" ]] && ! docker image inspect "solacliq-api:${release#solacliq-}" > /dev/null 2>&1; then
  echo "No such release: $release (its image is gone)" >&2
  exit 1
fi

stamp="$(date +%Y%m%d_%H%M%S)_$$"
fresh="solacliq_restoring_$stamp"
psql_db -d postgres -c "CREATE DATABASE $fresh OWNER solacliq"
if ! compose exec -T db pg_restore -U postgres --exit-on-error -d "$fresh" < "$dump"; then
  psql_db -d postgres -c "DROP DATABASE $fresh"
  echo "The backup didn't load. The live database is untouched." >&2
  exit 1
fi
compose stop api
psql_db -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
     WHERE datname = 'solacliq' AND pid <> pg_backend_pid()" > /dev/null
psql_db -d postgres -c "ALTER DATABASE solacliq RENAME TO solacliq_replaced_$stamp"
psql_db -d postgres -c "ALTER DATABASE $fresh RENAME TO solacliq"
if [[ -n "$release" ]]; then
  ln -sfn "$releases/$release" "$SOLACLIQ_HOME/current"
  docker tag "solacliq-api:${release#solacliq-}" solacliq-api:current
fi
compose up -d api
if answers; then
  echo "Restored. The database it replaced is kept as solacliq_replaced_$stamp."
  exit 0
fi
echo "Restored, but the API didn't answer. Its log:" >&2
compose logs --no-color --tail 30 api >&2 || true
exit 1
