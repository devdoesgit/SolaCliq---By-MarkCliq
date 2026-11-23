#!/usr/bin/env bash
# Run on the server, as root:
#   sudo bash restore.sh /var/backups/solacliq/<dump> [solacliq-<commit>]
# Puts a backup back, into a new empty database that then takes the live
# one's name. Nothing is dropped: the database it replaces is kept as
# solacliq_replaced_<time>, and if the dump won't load the live one is
# never touched. Give the release the dump was made with when it's older
# than the live one: an API only starts on a schema it knows.
# (`pg_restore --clean` into the live database doesn't work: it leaves
# what newer migrations added, and the next release then can't migrate.)
set -euo pipefail

dump="${1:?usage: restore.sh /path/to/backup.dump [solacliq-<commit>]}"
release="${2:-}"
releases=/opt/solacliq/releases
cd /tmp

if [[ -n "$release" && ! -x "$releases/$release/backend" ]]; then
  echo "No such release: $releases/$release" >&2
  exit 1
fi
pg() { runuser -u postgres -- "$@"; }
sql() { pg psql -qAt -v ON_ERROR_STOP=1 -d postgres -c "$1"; }

stamp="$(date +%Y%m%d_%H%M%S)_$$"
fresh="solacliq_restoring_$stamp"
sql "CREATE DATABASE $fresh OWNER solacliq"
if ! pg pg_restore --exit-on-error -d "$fresh" "$dump"; then
  sql "DROP DATABASE $fresh"
  echo "The backup didn't load. The live database is untouched." >&2
  exit 1
fi

systemctl stop solacliq-api
sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
     WHERE datname = 'solacliq' AND pid <> pg_backend_pid()" >/dev/null
sql "ALTER DATABASE solacliq RENAME TO solacliq_replaced_$stamp"
sql "ALTER DATABASE $fresh RENAME TO solacliq"
[[ -z "$release" ]] || ln -sfn "$releases/$release" /opt/solacliq/current
systemctl start solacliq-api

for _ in $(seq 30); do
  if curl -fsS http://127.0.0.1:8080/api/v1/health >/dev/null 2>&1; then
    echo "Restored. The database it replaced is kept as solacliq_replaced_$stamp."
    exit 0
  fi
  sleep 1
done
echo "Restored, but the API didn't answer. Its log:" >&2
journalctl -u solacliq-api -n 30 --no-pager >&2
exit 1
