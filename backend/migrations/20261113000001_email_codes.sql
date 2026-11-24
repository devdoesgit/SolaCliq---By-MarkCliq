/*
    6-digit codes sent by email
    --------------------------------------------------------------------
    - used for: verifying an email after sign-up, and resetting (or first
      setting) a password
    - at most one live code per account and purpose: asking again
      replaces the row (an upsert), which kills the old code and resets
      the try count
    - a right code deletes the row, so each code works once
*/

CREATE TABLE email_codes (
    user_id     uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose     text        NOT NULL CHECK (purpose IN ('verify_email', 'reset_password')),
    /*
        HMAC-SHA256 of the code with CODE_SECRET. A plain hash of a
        6-digit code could be reversed by trying all million values;
        without the secret (which is not in the database) it can't
    */
    code_hash   bytea       NOT NULL,
    -- Tries so far, right or wrong. The sixth is refused (429).
    attempts    int         NOT NULL DEFAULT 0,
    -- Five minutes after the code was sent.
    expires_at  timestamptz NOT NULL,
    /*
        When the code was sent. No new code within 60 seconds of the
        last one, so nobody can flood an inbox
    */
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, purpose)
);
