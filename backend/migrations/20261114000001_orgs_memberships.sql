/*
    Companies and who belongs to them (phase 4, with F2 registration)
    --------------------------------------------------------------------
    - orgs: a solar company (EPC vendor), registered by its owner with
      its GST details, then approved or rejected by MarkCliq
    - memberships: one (person, company, role). A person can belong to
      several companies; each membership is a workspace in the app
    - the lists below are Postgres enums: the database refuses any other
      value, and Rust reads them straight into its own enums
      (`org::Role` etc., via `sqlx::Type`)
*/

CREATE TYPE org_status    AS ENUM ('pending', 'active', 'suspended', 'rejected');
CREATE TYPE member_role   AS ENUM ('org_admin', 'worker', 'agent', 'customer');
CREATE TYPE pay_type      AS ENUM ('commission', 'salary');
CREATE TYPE business_type AS ENUM (
    'proprietorship', 'partnership', 'llp',
    'private_limited', 'public_limited', 'other'
);

CREATE TABLE orgs (
    id          uuid        PRIMARY KEY,
    -- The name people see in the app.
    name        text        NOT NULL CHECK (btrim(name) <> ''),
    -- The company's number, for its own people to call.
    phone       text        NOT NULL,
    /*
        pending until MarkCliq reviews it, then active or rejected;
        suspended for non-payment or abuse. Members of a company that
        isn't active get no data from it, only a message (`org::OrgMember`)
    */
    status      org_status  NOT NULL DEFAULT 'pending',

    -- From the registration (F2).
    legal_name      text          NOT NULL,
    business_type   business_type NOT NULL,
    -- 15 characters, uppercase; checksum checked by the API.
    gstin           text          NOT NULL,
    -- Characters 3-12 of the GSTIN.
    pan             text          NOT NULL,
    address_line_1  text          NOT NULL,
    address_line_2  text,
    city            text          NOT NULL,
    -- From the GSTIN's first two digits.
    state           text          NOT NULL,
    pin_code        text          NOT NULL,

    -- The platform admin's last decision (approve, reject, suspend...).
    reviewed_at     timestamptz,
    reviewed_by     uuid REFERENCES users (id),
    -- Why it was rejected or suspended; emailed to the owner on reject.
    review_note     text,

    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

/*
    One live registration per GSTIN. Rejected ones don't count, so a
    company that was turned down can register again
*/
CREATE UNIQUE INDEX orgs_gstin_live ON orgs (gstin) WHERE status <> 'rejected';

-- The review queue: companies by status, newest first.
CREATE INDEX orgs_status_newest ON orgs (status, created_at DESC, id DESC);

CREATE TABLE memberships (
    id          uuid        PRIMARY KEY,
    /*
        No ON DELETE: deleting a person or a company that has members
        fails. Companies are suspended, never deleted, and deleting a
        person's account (DPDP) will be its own designed step
    */
    user_id     uuid        NOT NULL REFERENCES users (id),
    org_id      uuid        NOT NULL REFERENCES orgs (id),
    role        member_role NOT NULL,
    -- Agents only, and always set for them (the CHECK below).
    pay_type    pay_type,
    /*
        When they were added, or added back after being removed. The team
        list is ordered by it
    */
    created_at  timestamptz NOT NULL DEFAULT now(),
    /*
        Soft delete. Set when the org admin removes the person: they lose
        access at once and the row stays. Adding them back clears it on
        this same row, with the new role
    */
    removed_at  timestamptz,

    -- One role per person per company, removed or not.
    UNIQUE (user_id, org_id),
    CHECK ((role = 'agent') = (pay_type IS NOT NULL))
);

/*
    One admin per company. Partial: only rows still in the company count,
    so a removed admin doesn't block a new one
*/
CREATE UNIQUE INDEX memberships_one_admin
    ON memberships (org_id) WHERE role = 'org_admin' AND removed_at IS NULL;

/*
    The team list: one company's members, newest first. The UNIQUE above
    already indexes (user_id, org_id), which serves `/me`
*/
CREATE INDEX memberships_org_newest
    ON memberships (org_id, created_at DESC, id DESC);
