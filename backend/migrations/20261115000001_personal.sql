/*
    The Personal workspace (phase 6)
    --------------------------------------------------------------------
    - quote_requests: people asking for solar; MarkCliq follows up
    - user_details, user_settings: one row per person, made on first save
    - notifications: personal ones now (org_id empty); company ones from
      phase 7
    - idempotency_keys: app writes are retried safely (`idempotency.rs`)
*/

CREATE TYPE quote_for      AS ENUM ('home', 'business', 'farm');
CREATE TYPE bill_band      AS ENUM ('under_1500', 'from_1500_to_3000', 'from_3000_to_6000', 'over_6000');
CREATE TYPE roof_type      AS ENUM ('rcc', 'tin_shed', 'other');
CREATE TYPE quote_timeline AS ENUM ('this_month', 'in_1_to_3_months', 'exploring');
CREATE TYPE quote_status   AS ENUM ('open', 'accepted', 'closed');

CREATE TABLE quote_requests (
    id           uuid           PRIMARY KEY,
    user_id      uuid           NOT NULL REFERENCES users (id),
    quote_for    quote_for      NOT NULL,
    pin_code     text           NOT NULL,
    city         text           NOT NULL,
    bill_band    bill_band      NOT NULL,
    roof         roof_type      NOT NULL,
    timeline     quote_timeline NOT NULL,
    -- The number MarkCliq calls: the request's, or the account's.
    phone        text           NOT NULL,
    status       quote_status   NOT NULL DEFAULT 'open',
    -- The estimate shown to the person, kept as it was then.
    kw_min       int            NOT NULL,
    kw_max       int            NOT NULL,
    price_min    bigint         NOT NULL,
    price_max    bigint         NOT NULL,
    subsidy_max  bigint         NOT NULL,
    created_at   timestamptz    NOT NULL DEFAULT now()
);
CREATE INDEX quote_requests_user ON quote_requests (user_id);

CREATE TABLE user_details (
    user_id            uuid        PRIMARY KEY REFERENCES users (id),
    address            text,
    emergency_contact  text,
    bank_holder        text,
    bank_ifsc          text,
    -- From the IFSC's first four letters.
    bank_name          text,
    bank_last4         text,
    -- AES-256-GCM with BANK_KEY: a 12-byte nonce, then the ciphertext.
    bank_account_enc   bytea,
    updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_settings (
    user_id   uuid    PRIMARY KEY REFERENCES users (id),
    push      boolean NOT NULL,
    whatsapp  boolean NOT NULL,
    sound     boolean NOT NULL
);

CREATE TABLE notifications (
    id           uuid        PRIMARY KEY,
    user_id      uuid        NOT NULL REFERENCES users (id),
    -- Empty for the person's own (Personal workspace).
    org_id       uuid        REFERENCES orgs (id),
    -- The contract's notification kinds; a list that grows, so text.
    kind         text        NOT NULL,
    title        text        NOT NULL,
    body         text        NOT NULL,
    -- What it opens, when anything (tables arrive in later phases).
    task_id      uuid,
    expense_id   uuid,
    customer_id  uuid,
    read_at      timestamptz,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_feed ON notifications (user_id, org_id, created_at DESC, id DESC);

CREATE TABLE idempotency_keys (
    user_id     uuid        NOT NULL REFERENCES users (id),
    key         uuid        NOT NULL,
    -- "POST /api/v1/quote-requests": a key can't be reused elsewhere.
    request     text        NOT NULL,
    status      int         NOT NULL,
    body        jsonb       NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, key)
);
