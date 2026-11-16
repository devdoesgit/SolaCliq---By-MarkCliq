/*
    Row-level security (phase 7)
    --------------------------------------------------------------------
    - a safety net under the app's own checks: Postgres itself decides
      which rows of a company table a query can see or write, so a query
      that forgets its `org_id` filter still can't reach another company
    - the API logs in as `solacliq_api`, a member of `solacliq_app`, which
      owns nothing: every policy below applies to it. Only the owner (the
      login that runs these migrations, the seed and admin commands) sees
      everything. The server refuses to start if its login could bypass
      the policies (main.rs)
    - each request's transaction says whose rows it is for (`scope.rs`),
      with settings that last until the transaction ends:
        - company:  app.org_id   = the company (`OrgMember::begin`)
        - person:   app.user_id  = the person (`AuthUser::begin`)
        - platform: app.platform = 'on' (`PlatformAdmin::begin`)
      one scope per transaction. With none set, nothing is visible: a
      query outside a scope gets zero rows, never someone else's
    - each new company table (tasks, expenses, customers, …) turns this on
      in its own migration, with a company policy like the ones below
*/

/*
    The roles. They belong to the whole server, not one database: created
    once. `make db` (and the deploy checklist) normally make both first;
    the login has a password, so it is never made here
*/
DO $$
BEGIN
    CREATE ROLE solacliq_app NOLOGIN;
EXCEPTION
    -- Another database on this server made it first (tests run many at once).
    WHEN duplicate_object OR unique_violation THEN NULL;
END
$$;

-- The owner may switch to it too (`SET LOCAL ROLE`, scope.rs), and it may use every table.
GRANT solacliq_app TO CURRENT_USER;
GRANT USAGE ON SCHEMA public TO solacliq_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO solacliq_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO solacliq_app;

/*
    The current scope, as the policies read it. NULL (or false) when the
    transaction didn't set it; '' once a transaction that set it has
    ended, which NULLIF turns into NULL too
*/
CREATE FUNCTION app_org_id() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$ SELECT NULLIF(current_setting('app.org_id', true), '')::uuid $$;

CREATE FUNCTION app_user_id() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$ SELECT NULLIF(current_setting('app.user_id', true), '')::uuid $$;

CREATE FUNCTION app_platform() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$ SELECT coalesce(current_setting('app.platform', true), '') = 'on' $$;

/*
    Companies
    - company: its own row, and only that one
    - person: the companies they're a member of now (read only), for /me
      and the membership check
    - platform: every company, and setting their status
*/
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
CREATE POLICY orgs_company ON orgs TO solacliq_app
    USING (id = app_org_id())
    WITH CHECK (id = app_org_id());
CREATE POLICY orgs_person ON orgs FOR SELECT TO solacliq_app
    USING (EXISTS (SELECT 1 FROM memberships m
                   WHERE m.org_id = orgs.id AND m.user_id = app_user_id()
                     AND m.removed_at IS NULL));
CREATE POLICY orgs_platform ON orgs TO solacliq_app
    USING (app_platform())
    WITH CHECK (app_platform());

/*
    Memberships
    - company: the company's members (the team page adds and removes them)
    - person: their own, read only
    - platform: read only (each company's admin, for the review page)
*/
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
CREATE POLICY memberships_company ON memberships TO solacliq_app
    USING (org_id = app_org_id())
    WITH CHECK (org_id = app_org_id());
CREATE POLICY memberships_person ON memberships FOR SELECT TO solacliq_app
    USING (user_id = app_user_id());
CREATE POLICY memberships_platform ON memberships FOR SELECT TO solacliq_app
    USING (app_platform());

/*
    Notifications
    - company: the company's (org_id set)
    - person: their own personal ones (org_id empty)
*/
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notifications_company ON notifications TO solacliq_app
    USING (org_id = app_org_id())
    WITH CHECK (org_id = app_org_id());
CREATE POLICY notifications_person ON notifications TO solacliq_app
    USING (org_id IS NULL AND user_id = app_user_id())
    WITH CHECK (org_id IS NULL AND user_id = app_user_id());

/*
    Registering a company: is this GSTIN already live anywhere? The
    applicant belongs to no company yet, so no scope could show them the
    others. This runs as its owner (SECURITY DEFINER), which policies
    don't restrict, and answers only yes or no
*/
CREATE FUNCTION gstin_registered(number text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path = public, pg_temp
    AS $$ SELECT EXISTS (SELECT 1 FROM orgs WHERE gstin = number AND status <> 'rejected') $$;
