/*
    Expenses (phase 8, F7)
    --------------------------------------------------------------------
    - a worker or agent logs what they spent for the company: amount in
      paise, category, a note, the day, an optional receipt photo and
      the task it was for
    - status: in_review → approved → paid (with salary or cash), or
      needs_fix (the admin's note) → a new receipt → in_review again.
      The admin's side comes with the admin website
    - `reference` (EXP-0001) is numbered per company, from org_counters
    - company-scoped by row-level security, like tasks
*/

/*
    Per-company numbering for references people read out (EXP-0001,
    later TSK- and SC- from the admin website). One row per company and
    series; taking a number locks that row until the transaction ends,
    so two expenses logged at once never share one
*/
CREATE TABLE org_counters (
    org_id  uuid    NOT NULL REFERENCES orgs (id),
    series  text    NOT NULL,
    value   integer NOT NULL CHECK (value >= 0),
    PRIMARY KEY (org_id, series)
);
ALTER TABLE org_counters ENABLE ROW LEVEL SECURITY;
CREATE POLICY org_counters_company ON org_counters TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

CREATE TYPE expense_category AS ENUM ('fuel', 'material', 'labour', 'other');
CREATE TYPE expense_status AS ENUM ('in_review', 'approved', 'needs_fix', 'paid');

CREATE TABLE expenses (
    id                 uuid              PRIMARY KEY,
    org_id             uuid              NOT NULL REFERENCES orgs (id),
    -- EXP-0001, per company.
    reference          text              NOT NULL,
    -- Who spent it and logged it.
    owner_id           uuid              NOT NULL REFERENCES users (id),
    -- Paise. Up to ₹10 lakh: a bigger amount is a typo.
    amount             bigint            NOT NULL CHECK (amount BETWEEN 1 AND 100000000),
    category           expense_category  NOT NULL,
    note               text              NOT NULL,
    spent_on           date              NOT NULL,
    status             expense_status    NOT NULL DEFAULT 'in_review',
    status_at          timestamptz       NOT NULL DEFAULT now(),
    receipt_upload_id  uuid,
    -- The task it was spent on, if any (the owner's).
    task_id            uuid,
    -- The admin's reason when they send it back.
    admin_note         text,
    -- Who approved, sent back or paid it, last.
    decided_by         uuid              REFERENCES users (id),
    -- The owner's note with a new receipt.
    fix_note           text,
    created_at         timestamptz       NOT NULL DEFAULT now(),
    UNIQUE (org_id, reference),
    UNIQUE (org_id, id),
    FOREIGN KEY (org_id, receipt_upload_id) REFERENCES uploads (org_id, id),
    FOREIGN KEY (org_id, task_id) REFERENCES tasks (org_id, id)
);
-- A person's own list, newest first.
CREATE INDEX expenses_owner ON expenses (org_id, owner_id, created_at DESC, id DESC);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY expenses_company ON expenses TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
