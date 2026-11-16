/*
    The database roles, for local development (`make db` runs this)
    --------------------------------------------------------------------
    - solacliq_app: no login; the row-level security policies and the
      table grants are written for it (migration ..._row_level_security)
    - solacliq_api: the login the server answers requests with
      (APP_DATABASE_URL); a member of solacliq_app, owns nothing, so every
      policy applies to it
    - production makes the same two with a real password (the deploy
      checklist, docs/backend-phases.md phase 5)
    - safe to run again: each step skips what already exists
*/
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'solacliq_app') THEN
        CREATE ROLE solacliq_app NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'solacliq_api') THEN
        CREATE ROLE solacliq_api LOGIN PASSWORD 'solacliq_api';
    END IF;
END
$$;
GRANT solacliq_app TO solacliq_api;
