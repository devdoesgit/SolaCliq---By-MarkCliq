/*
    Agreements (F16)
    --------------------------------------------------------------------
    - one row each time a person agrees to a document: the proof the
      DPDP Act asks us to keep (section 6(10))
    - rows are only ever added, never changed: a new version agreed is
      a new row, so the full history stays
    - a person-level table, like `users` and `sessions`: no row-level
      security per company; the API reads only the caller's own rows
*/

CREATE TYPE agreement_document AS ENUM ('terms', 'company_terms');
CREATE TYPE agreement_source   AS ENUM ('signup', 'org_registration', 'app');

CREATE TABLE agreements (
    -- UUIDv7, made in Rust, so rows sort by time.
    id           uuid               PRIMARY KEY,
    -- Who agreed. Deleted with the account.
    user_id      uuid               NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- `terms`: the Terms of Use and Privacy Policy, agreed together.
    -- `company_terms`: agreed by the owner for their company.
    document     agreement_document NOT NULL,
    -- The company, for `company_terms` only.
    org_id       uuid               REFERENCES orgs (id) ON DELETE CASCADE,
    -- TERMS_VERSION shown to the person when they ticked (`terms.rs`).
    version      int                NOT NULL CHECK (version >= 1),
    -- Where they ticked: sign-up, company registration, or the app's
    -- "Before you start" screen.
    source       agreement_source   NOT NULL,
    -- The request's address (X-Real-IP from Caddy), part of the proof.
    -- Empty only when the server couldn't tell (tests calling the
    -- router directly).
    ip           inet,
    accepted_at  timestamptz        NOT NULL DEFAULT now(),

    CHECK ((document = 'company_terms') = (org_id IS NOT NULL))
);

-- `/me`: the latest version each person agreed to.
CREATE INDEX agreements_user ON agreements (user_id, document, version DESC);

-- Add-only, enforced by the database: the API can add and read rows,
-- never edit one.
REVOKE UPDATE ON agreements FROM solacliq_app;
