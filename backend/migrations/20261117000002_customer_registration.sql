/*
    Customer registration and documents (phase 9, F4)
    --------------------------------------------------------------------
    - an agent registers a customer: the phase 8 `customers` record gains
      the registration (who registered them, contact, site, connection,
      consent), its KYC status, the install stage once approved, and the
      agent's commission
    - `documents`: KYC files of a customer, and (later, from the admin
      website) a worker's own ID documents. One row per kind, pointing at
      an upload of the same company. No Aadhaar or PAN number is stored,
      only the photos (data-policy.md)
    - a company can't have the same customer twice: unique email, phone
      and consumer number per company (decided 2026-11-17)
    - company-scoped by row-level security, like every company table
*/

CREATE TYPE connection_type AS ENUM ('residential', 'commercial', 'industrial');
CREATE TYPE kyc_status AS ENUM ('in_review', 'needs_fix', 'approved', 'rejected');
CREATE TYPE kyc_kind AS ENUM (
    'aadhaar', 'pan', 'electricity_bill', 'bank_proof', 'roof_photo',
    'land_document', 'signature', 'name_change'
);
CREATE TYPE document_status AS ENUM ('in_review', 'needs_fix', 'verified');
CREATE TYPE commission_status AS ENUM ('in_review', 'approved', 'payable', 'paid');

ALTER TABLE customers
    -- The agent who registered them (none: the company added them).
    ADD COLUMN registered_by        uuid REFERENCES users (id),
    -- Their app account, made or linked at registration.
    ADD COLUMN user_id              uuid REFERENCES users (id),
    ADD COLUMN email                text,
    ADD COLUMN city                 text,
    ADD COLUMN pin_code             text,
    ADD COLUMN state                text,
    ADD COLUMN discom               text,
    ADD COLUMN consumer_number      text,
    ADD COLUMN sanctioned_load_kw   double precision CHECK (sanctioned_load_kw > 0),
    ADD COLUMN connection_type      connection_type,
    ADD COLUMN roof                 roof_type,
    -- Applying for PM Surya Ghar.
    ADD COLUMN subsidy              boolean,
    -- When the customer agreed to share their documents with the company.
    ADD COLUMN consent_at           timestamptz,
    -- A customer the company added itself counts as approved.
    ADD COLUMN kyc_status           kyc_status NOT NULL DEFAULT 'approved',
    -- The install stage they're at (1-based), once approved.
    ADD COLUMN stage_index          integer CHECK (stage_index >= 1),
    ADD COLUMN decided_by           uuid REFERENCES users (id),
    ADD COLUMN decided_at           timestamptz,
    -- Why the company won't go ahead, when rejected.
    ADD COLUMN rejected_note        text,
    -- Commission agents only, in paise. `commission` is the current
    -- amount; `commission_proposed` keeps the agent's when the admin
    -- changed it.
    ADD COLUMN commission            bigint CHECK (commission BETWEEN 0 AND 100000000),
    ADD COLUMN commission_proposed   bigint,
    ADD COLUMN commission_note       text,
    ADD COLUMN commission_status     commission_status,
    ADD COLUMN commission_admin_note text,
    ADD COLUMN commission_admin_by   uuid REFERENCES users (id),
    ADD COLUMN commission_admin_at   timestamptz,
    ADD COLUMN commission_payable_since date,
    ADD COLUMN commission_paid_on    date,
    ADD CONSTRAINT customers_commission_has_status
        CHECK ((commission IS NULL) = (commission_status IS NULL));

-- One customer once per company (registration.duplicate).
CREATE UNIQUE INDEX customers_email ON customers (org_id, email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX customers_phone ON customers (org_id, phone) WHERE phone IS NOT NULL;
CREATE UNIQUE INDEX customers_consumer_number
    ON customers (org_id, consumer_number) WHERE consumer_number IS NOT NULL;
-- An agent's list, newest first.
CREATE INDEX customers_registered_by ON customers (org_id, registered_by, created_at DESC);

CREATE TABLE documents (
    id             uuid             PRIMARY KEY,
    org_id         uuid             NOT NULL REFERENCES orgs (id),
    -- Whose: a customer's KYC, or a worker's own ID (exactly one).
    customer_id    uuid,
    user_id        uuid             REFERENCES users (id),
    kind           kyc_kind         NOT NULL,
    upload_id      uuid             NOT NULL,
    status         document_status  NOT NULL DEFAULT 'in_review',
    -- Why the admin sent it back.
    admin_note     text,
    admin_note_by  uuid             REFERENCES users (id),
    admin_note_at  timestamptz,
    -- Who sent the file: the agent, for a customer's KYC.
    uploaded_by    uuid             NOT NULL REFERENCES users (id),
    created_at     timestamptz      NOT NULL DEFAULT now(),
    updated_at     timestamptz      NOT NULL DEFAULT now(),
    CHECK ((customer_id IS NULL) <> (user_id IS NULL)),
    FOREIGN KEY (org_id, customer_id) REFERENCES customers (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, upload_id) REFERENCES uploads (org_id, id),
    UNIQUE (customer_id, kind),
    UNIQUE (org_id, user_id, kind)
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY documents_company ON documents TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
