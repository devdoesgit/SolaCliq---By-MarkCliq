-- Refresh follows OAuth 2.1 for the app and the website alike (decision
-- 2026-11-11): every session has a refresh token, every refresh replaces
-- both tokens, and reusing an old refresh token revokes the session.

-- Web sessions made before this had no refresh token. They can't follow
-- the new rules, so they end here (those admins log in again).
DELETE FROM sessions WHERE refresh_hash IS NULL;
ALTER TABLE sessions ALTER COLUMN refresh_hash SET NOT NULL;
ALTER TABLE sessions ALTER COLUMN refresh_expires_at SET NOT NULL;

-- The refresh token this session had before its last refresh. If it is
-- ever sent again, someone kept a copy: the session is revoked.
-- UNIQUE also gives the index that lookup needs.
ALTER TABLE sessions ADD COLUMN previous_refresh_hash bytea UNIQUE;

-- Why the session ended: 'logout' or 'refresh_reuse' for now.
ALTER TABLE sessions ADD COLUMN revoked_reason text;
