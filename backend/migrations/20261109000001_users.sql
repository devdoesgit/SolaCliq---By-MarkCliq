-- Accounts. One row per person, across every company they work with
-- (companies come in phase 4 as memberships).
--
-- sqlx runs each file in migrations/ once, in name order, and records it in
-- the _sqlx_migrations table. Never edit a file that has already run on a
-- shared database: add a new one instead.

CREATE TABLE users (
    -- UUIDv7, made in Rust (Uuid::now_v7), so ids sort by creation time.
    id                 uuid        PRIMARY KEY,
    -- Stored trimmed and lowercased, so "Asha@Example.com" and
    -- "asha@example.com" are the same account.
    email              text        NOT NULL UNIQUE,
    name               text        NOT NULL,
    -- 10 digits, no +91. Optional at sign-up.
    phone              text,
    -- Argon2id PHC string. NULL for an account an admin or agent created,
    -- until the person sets a password (account.password_not_set).
    password_hash      text,
    -- NULL until the 6-digit code is entered (phase 3). Login refuses
    -- unverified accounts.
    email_verified_at  timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);
