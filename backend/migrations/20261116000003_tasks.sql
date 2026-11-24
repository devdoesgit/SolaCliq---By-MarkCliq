/*
    Customers and installer tasks (phase 8)
    --------------------------------------------------------------------
    - a customer: who the install is for and where (what a task shows).
      Phase 9 adds the agent who registered them, KYC and documents
    - a task: one stage of a customer's install, assigned to one worker.
      Its photo slots and checklist are set per task (decided
      2026-11-16); the admin website writes them later, the seed now
    - status: assigned → submitted → approved (final), or → returned →
      submitted again; cancelled (final) by the admin. Only assigned and
      returned tasks take changes (`task.locked` otherwise)
    - task_events: the task's history, append-only
    - every table carries org_id and is company-scoped by row-level
      security, like orgs and memberships. Child rows point at their task
      with (org_id, task_id), and at uploads with (org_id, upload_id), so
      a row can't hang off another company's task or file
*/

CREATE TABLE customers (
    id           uuid             PRIMARY KEY,
    org_id       uuid             NOT NULL REFERENCES orgs (id),
    -- SC-0001, per company.
    reference    text             NOT NULL,
    name         text             NOT NULL,
    -- 10 digits, no +91.
    phone        text,
    address      text             NOT NULL,
    lat          double precision,
    lng          double precision,
    system_kw    double precision CHECK (system_kw > 0),
    -- How many install stages this customer's job has.
    stage_count  integer          NOT NULL DEFAULT 7 CHECK (stage_count BETWEEN 1 AND 20),
    created_at   timestamptz      NOT NULL DEFAULT now(),
    UNIQUE (org_id, reference),
    UNIQUE (org_id, id)
);

CREATE TYPE task_status AS ENUM ('assigned', 'submitted', 'returned', 'approved', 'cancelled');

CREATE TYPE task_problem_reason AS ENUM (
    'customer_away', 'material_missing', 'bad_weather', 'site_not_ready', 'safety', 'other'
);

CREATE TYPE task_event_kind AS ENUM (
    'assigned', 'photos_uploaded', 'submitted', 'resubmitted', 'returned', 'approved',
    'problem_reported', 'rescheduled', 'reassigned', 'cancelled', 'message'
);

CREATE TABLE tasks (
    id                 uuid                PRIMARY KEY,
    org_id             uuid                NOT NULL REFERENCES orgs (id),
    customer_id        uuid                NOT NULL,
    -- TSK-0001, per company.
    reference          text                NOT NULL,
    title              text                NOT NULL,
    -- The customer's install stage this task finishes, from 1.
    stage_index        integer             NOT NULL CHECK (stage_index >= 1),
    assignee_id        uuid                NOT NULL REFERENCES users (id),
    assigned_by        uuid                REFERENCES users (id),
    due_at             timestamptz         NOT NULL,
    status             task_status         NOT NULL DEFAULT 'assigned',
    -- When `status` last changed.
    status_at          timestamptz         NOT NULL DEFAULT now(),
    admin_note         text,
    admin_note_at      timestamptz,
    -- The worker's last submission.
    submitted_at       timestamptz,
    worker_note        text,
    -- Why the admin sent it back.
    returned_note      text,
    returned_by        uuid                REFERENCES users (id),
    returned_at        timestamptz,
    -- An open problem the worker reported; cleared when they submit.
    problem_reason     task_problem_reason,
    problem_note       text,
    problem_at         timestamptz,
    problem_upload_id  uuid,
    cancelled_note     text,
    cancelled_by       uuid                REFERENCES users (id),
    cancelled_at       timestamptz,
    approved_by        uuid                REFERENCES users (id),
    approved_at        timestamptz,
    -- The next stage's task, made when this one is approved.
    next_task_id       uuid                REFERENCES tasks (id),
    created_at         timestamptz         NOT NULL DEFAULT now(),
    UNIQUE (org_id, reference),
    UNIQUE (org_id, id),
    FOREIGN KEY (org_id, customer_id) REFERENCES customers (org_id, id),
    FOREIGN KEY (org_id, problem_upload_id) REFERENCES uploads (org_id, id)
);
-- A worker's lists: their tasks in a company, by due time.
CREATE INDEX tasks_assignee ON tasks (org_id, assignee_id, due_at);

/*
    One photo the task needs (`slot_id`, e.g. "clamp"), and the photo
    once taken. A retake replaces `upload_id`; the earlier file stays in
    R2 with its upload, as a record of what was sent
*/
CREATE TABLE task_photo_slots (
    org_id       uuid             NOT NULL,
    task_id      uuid             NOT NULL,
    slot_id      text             NOT NULL,
    position     integer          NOT NULL,
    label        text             NOT NULL,
    hint         text,
    -- The admin asked for this one again.
    retake       boolean          NOT NULL DEFAULT false,
    upload_id    uuid             UNIQUE,
    taken_at     timestamptz,
    lat          double precision,
    lng          double precision,
    accuracy_m   double precision,
    -- Flags for the admin; a photo is never refused for them.
    mocked       boolean          NOT NULL DEFAULT false,
    distance_m   double precision,
    far          boolean          NOT NULL DEFAULT false,
    inaccurate   boolean          NOT NULL DEFAULT false,
    PRIMARY KEY (task_id, slot_id),
    FOREIGN KEY (org_id, task_id) REFERENCES tasks (org_id, id) ON DELETE CASCADE,
    -- Only an upload of the task's own company.
    FOREIGN KEY (org_id, upload_id) REFERENCES uploads (org_id, id)
);

CREATE TABLE task_checklist_items (
    org_id    uuid        NOT NULL,
    task_id   uuid        NOT NULL,
    item_id   text        NOT NULL,
    position  integer     NOT NULL,
    text      text        NOT NULL,
    done      boolean     NOT NULL DEFAULT false,
    done_at   timestamptz,
    PRIMARY KEY (task_id, item_id),
    FOREIGN KEY (org_id, task_id) REFERENCES tasks (org_id, id) ON DELETE CASCADE
);

CREATE TABLE task_events (
    id          uuid             PRIMARY KEY,
    org_id      uuid             NOT NULL,
    task_id     uuid             NOT NULL,
    kind        task_event_kind  NOT NULL,
    actor_id    uuid             NOT NULL REFERENCES users (id),
    -- A line under the event: the admin's words, what was retaken.
    detail      text,
    created_at  timestamptz      NOT NULL DEFAULT now(),
    FOREIGN KEY (org_id, task_id) REFERENCES tasks (org_id, id) ON DELETE CASCADE
);
CREATE INDEX task_events_task ON task_events (task_id, created_at DESC);

-- Company scope only: each table shows and takes one company's rows.
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY customers_company ON customers TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tasks_company ON tasks TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

ALTER TABLE task_photo_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY task_photo_slots_company ON task_photo_slots TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

ALTER TABLE task_checklist_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY task_checklist_items_company ON task_checklist_items TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

ALTER TABLE task_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY task_events_company ON task_events TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
