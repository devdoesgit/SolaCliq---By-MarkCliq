/*
    Code-first sign-up (QA-27, QA-28)
    --------------------------------------------------------------------
    - `signups`: an email being proven. No account, and nothing the
      person typed, exists until the code is entered: an unproven row
      has nothing anyone could inherit
    - one row per email: the code (as an HMAC) and, once it was right,
      a hash of the one-time setup token
    - what the old flow left on unverified accounts is cleared: the
      password, the typed name and phone, and the agreement, as none of
      them are known to be the inbox owner's
    - from here Postgres itself refuses a password on an unverified
      account, whatever code writes it
*/

CREATE TABLE signups (
    email             text        PRIMARY KEY,
    -- HMAC-SHA256 with CODE_SECRET. Empty once the code was used.
    code_hash         bytea,
    attempts          int         NOT NULL DEFAULT 0,
    expires_at        timestamptz NOT NULL,
    -- When the code was sent: no new one within 60 seconds.
    created_at        timestamptz NOT NULL DEFAULT now(),
    -- SHA-256 of the setup token, for 15 minutes after the right code.
    token_hash        bytea       UNIQUE,
    token_expires_at  timestamptz,
    CHECK ((token_hash IS NULL) = (token_expires_at IS NULL))
);

-- Only the old sign-up put a password on an unverified account.
DELETE FROM agreements a
 USING users u
 WHERE a.user_id = u.id AND a.source = 'signup'
   AND u.email_verified_at IS NULL AND u.password_hash IS NOT NULL;

UPDATE users
   SET password_hash = NULL,
       name = split_part(email, '@', 1),
       phone = NULL,
       updated_at = now()
 WHERE email_verified_at IS NULL AND password_hash IS NOT NULL;

ALTER TABLE users ADD CONSTRAINT users_password_needs_verified
    CHECK (password_hash IS NULL OR email_verified_at IS NOT NULL);

DELETE FROM email_codes WHERE purpose = 'verify_email';
