/*
    Push notifications (F12)
    --------------------------------------------------------------------
    - devices: each app login's Firebase token, so the push worker knows
      where a person's notifications go. Like `sessions`, a person-level
      table without row-level security: a token moves to whoever logged
      in on that phone last, across people
    - notifications.pushed_at: set once the push worker has handled the
      row (sent, or skipped), so no notification is pushed twice
    - the push worker reads and marks notifications of every person, in
      its own scope (`scope::push`): app.push = 'on'
*/

CREATE TABLE devices (
    -- The FCM registration token: one per app install.
    token       text        PRIMARY KEY,
    -- One token per login. Deleting a session deletes its token.
    session_id  uuid        NOT NULL UNIQUE REFERENCES sessions (id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    platform    text        NOT NULL CHECK (platform IN ('android')),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX devices_user_id ON devices (user_id);

ALTER TABLE notifications ADD COLUMN pushed_at timestamptz;
-- Notifications written before push existed are not news.
UPDATE notifications SET pushed_at = created_at;
-- The worker's queue: only the rows not handled yet.
CREATE INDEX notifications_to_push ON notifications (created_at) WHERE pushed_at IS NULL;

CREATE FUNCTION app_push() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$ SELECT coalesce(current_setting('app.push', true), '') = 'on' $$;

-- The push worker: reads every notification, and marks them handled.
CREATE POLICY notifications_push_read ON notifications FOR SELECT TO solacliq_app
    USING (app_push());
CREATE POLICY notifications_push_mark ON notifications FOR UPDATE TO solacliq_app
    USING (app_push())
    WITH CHECK (app_push());
