/*
    Registering a company with an email that already has an account
    ----------------------------------------------------------------------
    - the request isn't logged in, so it can't speak for an account in
      use: tying one to a made-up company would make its person a
      company's admin and record an agreement in their name
    - an account nobody uses is different: no password set, and no
      company but rejected ones. That's what an earlier registration
      leaves behind when it was turned down; registering again reuses it
    - like `gstin_registered`, this looks past the applicant's scope (the
      memberships are other companies' rows), so it runs as its owner and
      answers only yes or no
*/
CREATE FUNCTION account_unused(account uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path = public, pg_temp
    AS $$
        SELECT u.password_hash IS NULL
           AND NOT EXISTS (
               SELECT 1 FROM memberships m JOIN orgs o ON o.id = m.org_id
               WHERE m.user_id = u.id AND o.status <> 'rejected'
           )
        FROM users u WHERE u.id = account
    $$;
