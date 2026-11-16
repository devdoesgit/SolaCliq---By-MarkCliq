/*
    Uploads (phase 7)
    --------------------------------------------------------------------
    - one row per file a person sends to R2: `POST /uploads` makes it and
      signs the URL; the file itself goes straight to R2
    - the record it belongs to (a task's photo, an expense's receipt, a
      KYC document) points here, and `used_at` is set: one file, one use
    - no row-level security: this is the person's own row, and a file is
      only ever shown through the company record that uses it, which is
      company-scoped
*/

CREATE TYPE upload_purpose AS ENUM ('receipt', 'kyc', 'proof');

CREATE TABLE uploads (
    id            uuid           PRIMARY KEY,
    owner_id      uuid           NOT NULL REFERENCES users (id),
    purpose       upload_purpose NOT NULL,
    content_type  text           NOT NULL,
    size_bytes    bigint         NOT NULL CHECK (size_bytes BETWEEN 1 AND 10485760),
    -- Where it is in the bucket: <purpose>/<id>.
    r2_key        text           NOT NULL UNIQUE,
    used_at       timestamptz,
    created_at    timestamptz    NOT NULL DEFAULT now()
);
CREATE INDEX uploads_owner ON uploads (owner_id, created_at DESC);
