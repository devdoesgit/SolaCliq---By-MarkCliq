/*
    Each company's install stages (F19)
    --------------------------------------------------------------------
    - always 7: a company renames them and sets what a new task at each
      asks for. It can't add, remove or reorder, so a project's stage
      number keeps its meaning
    - no row means the standard name and an empty template
    - company-scoped by row-level security
*/

CREATE TABLE org_stages (
    org_id      uuid         NOT NULL REFERENCES orgs (id),
    -- From 1.
    position    smallint     NOT NULL CHECK (position BETWEEN 1 AND 7),
    name        text         NOT NULL CHECK (char_length(name) BETWEEN 1 AND 40),
    -- What a new task at this stage asks to tick off, in order.
    checklist   text[]       NOT NULL DEFAULT '{}' CHECK (cardinality(checklist) <= 20),
    -- The photos a new task at this stage asks for.
    photos      text[]       NOT NULL DEFAULT '{}' CHECK (cardinality(photos) <= 8),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    updated_by  uuid         NOT NULL REFERENCES users (id),

    PRIMARY KEY (org_id, position)
);

ALTER TABLE org_stages ENABLE ROW LEVEL SECURITY;
CREATE POLICY org_stages_company ON org_stages TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
