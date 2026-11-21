/*
    Attendance (F17)
    --------------------------------------------------------------------
    - installers and salaried sales mark their own working day: a start
      tap and, later, an end tap. The company's admin only reads them
    - a tap's time is the server's when it arrives; a tap sent late from
      offline keeps the phone's time and is marked `sent_late`
    - one day per person per India date; a day ends on its own date
    - no location, no photo (docs/data-policy.md, "Attendance")
    - company-scoped by row-level security, like expenses
*/

CREATE TABLE attendance_days (
    id               uuid         PRIMARY KEY,
    org_id           uuid         NOT NULL REFERENCES orgs (id),
    user_id          uuid         NOT NULL REFERENCES users (id),
    -- The India date the day started on.
    work_date        date         NOT NULL,

    -- The start's time: the server's, or the phone's when sent late.
    started_at       timestamptz  NOT NULL,
    -- What the phone said at the tap, kept as sent.
    start_phone_at   timestamptz  NOT NULL,
    start_sent_late  boolean      NOT NULL,

    -- The end, all three set together or none.
    ended_at         timestamptz,
    end_phone_at     timestamptz,
    end_sent_late    boolean,

    created_at       timestamptz  NOT NULL DEFAULT now(),

    UNIQUE (org_id, user_id, work_date),
    CHECK ((ended_at IS NULL) = (end_phone_at IS NULL)
       AND (ended_at IS NULL) = (end_sent_late IS NULL)),
    CHECK (ended_at IS NULL OR ended_at >= started_at)
);
-- The admin's day and month views.
CREATE INDEX attendance_days_date ON attendance_days (org_id, work_date);

ALTER TABLE attendance_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY attendance_days_company ON attendance_days TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
