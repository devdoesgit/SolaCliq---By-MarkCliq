#!/bin/sh
# Runs once, when the database volume is empty (Postgres's own first start):
# the database and its roles, from db-setup.sql, with the passwords from
# db.env.
set -eu
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -v owner_pw="$SOLACLIQ_OWNER_PASSWORD" -v api_pw="$SOLACLIQ_API_PASSWORD" \
  -f /solacliq/db-setup.sql
