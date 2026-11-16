/*
    Row-level security (phase 7)
    --------------------------------------------------------------------
    - a safety net under the app's own checks: inside a company request,
      Postgres itself returns only that company's rows, even if a query
      forgets its `org_id` filter
    - how: every company request runs in a transaction that switches to
      `solacliq_app` (`SET LOCAL ROLE`) and records the company in the
      `app.org_id` setting (`org.rs`, `OrgMember::begin`). Policies on
      company tables compare a row's org_id with that setting; with no
      setting (NULL, or '' once a transaction that set it has ended)
      there is no match, so nothing is visible
    - `solacliq_app` owns nothing, so the policies apply to it. Requests
      outside a company (log in, /me, the personal feed) keep running as
      the owner, which policies don't restrict
    - each new company table (tasks, expenses, customers, …) turns this on
      in its own migration, with the same policy
*/

-- Roles belong to the whole server, not one database: create it once.
DO $$
BEGIN
    CREATE ROLE solacliq_app NOLOGIN;
EXCEPTION
    -- Another database on this server made it first (tests run many at once).
    WHEN duplicate_object OR unique_violation THEN NULL;
END
$$;

-- The API's login may switch to it, and it may use every table.
GRANT solacliq_app TO CURRENT_USER;
GRANT USAGE ON SCHEMA public TO solacliq_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO solacliq_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO solacliq_app;

/*
    Company notifications: within a company, only that company's rows.
    Personal ones (org_id empty) are read outside any company, as the
    owner
*/
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notifications_by_org ON notifications TO solacliq_app
    USING (org_id = NULLIF(current_setting('app.org_id', true), '')::uuid)
    WITH CHECK (org_id = NULLIF(current_setting('app.org_id', true), '')::uuid);
