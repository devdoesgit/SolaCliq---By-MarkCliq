/*
    Uploads (phase 7)
    --------------------------------------------------------------------
    - one row per file a person sends to R2: `POST /orgs/{org_id}/uploads`
      makes it and signs the URL; the file itself goes straight to R2
    - every file belongs to one company, like every company row: it is
      named `orgs/<org_id>/<purpose>/<id>` in the bucket, and row-level
      security keeps the row inside that company's scope
    - the record it belongs to (a task's photo, an expense's receipt, a
      KYC document) points here with (org_id, upload_id), so it can only
      take an upload of its own company, and `used_at` is set: one file,
      one use
*/

CREATE TYPE upload_purpose AS ENUM ('receipt', 'kyc', 'proof');

CREATE TABLE uploads (
    id            uuid           PRIMARY KEY,
    org_id        uuid           NOT NULL REFERENCES orgs (id),
    owner_id      uuid           NOT NULL REFERENCES users (id),
    purpose       upload_purpose NOT NULL,
    content_type  text           NOT NULL,
    size_bytes    bigint         NOT NULL CHECK (size_bytes BETWEEN 1 AND 10485760),
    -- Where it is in the bucket: orgs/<org_id>/<purpose>/<id>.
    r2_key        text           NOT NULL UNIQUE
                                 CHECK (r2_key LIKE 'orgs/' || org_id || '/%'),
    used_at       timestamptz,
    created_at    timestamptz    NOT NULL DEFAULT now(),
    UNIQUE (org_id, id)
);
CREATE INDEX uploads_owner ON uploads (owner_id, created_at DESC);
-- The sweep: unused uploads, oldest first.
CREATE INDEX uploads_unused ON uploads (created_at) WHERE used_at IS NULL;

/*
    - company: the company's uploads (making one, attaching it)
    - platform: the hourly sweep of abandoned uploads, across companies;
      it reads and deletes, never writes one
*/
ALTER TABLE uploads ENABLE ROW LEVEL SECURITY;
CREATE POLICY uploads_company ON uploads TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
CREATE POLICY uploads_platform_read ON uploads FOR SELECT TO solacliq_app
    USING (app_platform());
CREATE POLICY uploads_platform_delete ON uploads FOR DELETE TO solacliq_app
    USING (app_platform());
