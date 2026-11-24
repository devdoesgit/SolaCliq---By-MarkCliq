# Shared by backup.sh, release.sh and restore.sh. Every path can be moved
# with the variable of the same name (to try the scripts elsewhere).
SOLACLIQ_HOME="${SOLACLIQ_HOME:-/opt/solacliq}"
SOLACLIQ_ETC="${SOLACLIQ_ETC:-/etc/solacliq}"
SOLACLIQ_BACKUPS="${SOLACLIQ_BACKUPS:-/var/backups/solacliq}"
SOLACLIQ_PORT="${SOLACLIQ_PORT:-8080}"
export SOLACLIQ_ETC SOLACLIQ_PORT
releases="$SOLACLIQ_HOME/releases"

compose() { docker compose -f "$SOLACLIQ_HOME/compose.yml" "$@"; }
# psql as Postgres's superuser, inside the database container.
psql_db() { compose exec -T db psql -U postgres -qAt -v ON_ERROR_STOP=1 "$@"; }
migrations() { psql_db -d solacliq -c 'SELECT count(*) FROM _sqlx_migrations' 2>/dev/null || echo 0; }

# Waits up to 60 s for the API to answer; 0 when it does.
answers() {
  for _ in $(seq 60); do
    curl -fsS "http://127.0.0.1:$SOLACLIQ_PORT/api/v1/health" >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}
