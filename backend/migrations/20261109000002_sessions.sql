-- MarkCliq staff who approve companies (F2). Set by hand for now.
ALTER TABLE users ADD COLUMN is_platform_admin boolean NOT NULL DEFAULT false;

-- One row per login. The tokens themselves are never stored: only their
-- SHA-256, so a leaked database can't be used to log in as anyone.
--
-- app: an access token (15 minutes) plus a refresh token (30 days).
-- web: the solacliq_session cookie (12 hours), no refresh token.
CREATE TABLE sessions (
    id                  uuid        PRIMARY KEY,
    -- ON DELETE CASCADE: deleting an account deletes its sessions.
    user_id             uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    client              text        NOT NULL CHECK (client IN ('app', 'web')),
    access_hash         bytea       NOT NULL UNIQUE,
    access_expires_at   timestamptz NOT NULL,
    refresh_hash        bytea       UNIQUE,
    refresh_expires_at  timestamptz,
    -- Set by log out, password reset or refresh-token reuse (phase 3).
    revoked_at          timestamptz,
    created_at          timestamptz NOT NULL DEFAULT now()
);

-- "All sessions of this person", for log out everywhere and password reset.
CREATE INDEX sessions_user_id ON sessions (user_id);
