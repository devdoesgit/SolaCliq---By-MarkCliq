/*
    Landing-page leads (F20)
    --------------------------------------------------------------------
    - a company's landing page server sends each lead with the company's
      lead key. Only the key's SHA-256 is kept; a new key replaces it
    - the company tracks a lead (new, contacted, won, lost) and can hand
      it to one of its Sales Agents
    - kept until the company's admin deletes it (docs/data-policy.md,
      "Leads")
    - company-scoped by row-level security
*/

CREATE TABLE lead_keys (
    org_id        uuid         PRIMARY KEY REFERENCES orgs (id),
    key_hash      bytea        NOT NULL,
    made_at       timestamptz  NOT NULL DEFAULT now(),
    made_by       uuid         NOT NULL REFERENCES users (id),
    last_used_at  timestamptz
);

ALTER TABLE lead_keys ENABLE ROW LEVEL SECURITY;
CREATE POLICY lead_keys_company ON lead_keys TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

CREATE TYPE lead_status AS ENUM ('new', 'contacted', 'won', 'lost');

CREATE TABLE leads (
    id            uuid         PRIMARY KEY,
    org_id        uuid         NOT NULL REFERENCES orgs (id),
    -- The landing page's own id, so a resend makes no second lead.
    external_id   text,

    name          text         NOT NULL,
    -- Ten digits.
    phone         text         NOT NULL,
    email         text,
    city          text,
    pin_code      text,
    monthly_bill  text,
    roof_type     text,
    message       text,
    source        text         NOT NULL,
    campaign      text,
    page_url      text,
    -- Any other short answers from the form, by question.
    extra         jsonb        NOT NULL DEFAULT '{}',

    status        lead_status  NOT NULL DEFAULT 'new',
    note          text,
    -- The Sales Agent it's with.
    agent_id      uuid         REFERENCES users (id),

    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),

    UNIQUE (org_id, external_id)
);
-- The list, newest first; the agent's list; the sidebar's count of new ones.
CREATE INDEX leads_org ON leads (org_id, created_at DESC, id DESC);
CREATE INDEX leads_agent ON leads (org_id, agent_id, created_at DESC);
CREATE INDEX leads_new ON leads (org_id) WHERE status = 'new';

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY leads_company ON leads TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

-- A notification can point at a lead.
ALTER TABLE notifications ADD COLUMN lead_id uuid REFERENCES leads (id) ON DELETE CASCADE;
