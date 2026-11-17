/*
    A customer's install and its payment plan (phase 10, F9)
    --------------------------------------------------------------------
    - one install per customer, made when the company takes them on
      (the admin website; the seed now): the price, the PM Surya Ghar
      subsidy, the handover date
    - its payments, in plan order: due → claimed (the customer says
      they paid, by UPI or bank transfer) → paid (the company confirms on
      the website); `later` ones aren't due yet
    - the company's UPI id, for the "Pay by UPI" link
    - the stage and the next visit come from `customers` and `tasks`
    - company-scoped by row-level security
*/

-- e.g. examplesolar@okhdfc; set on the website's settings page.
ALTER TABLE orgs ADD COLUMN upi_id text;

CREATE TYPE payment_status AS ENUM ('due', 'claimed', 'paid', 'later');
CREATE TYPE payment_method AS ENUM ('upi', 'bank_transfer');

CREATE TABLE installs (
    id              uuid        PRIMARY KEY,
    org_id          uuid        NOT NULL REFERENCES orgs (id),
    customer_id     uuid        NOT NULL,
    -- Paise.
    total           bigint      NOT NULL CHECK (total > 0),
    subsidy         bigint      NOT NULL DEFAULT 0 CHECK (subsidy >= 0),
    handed_over_on  date,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (org_id, id),
    UNIQUE (customer_id),
    FOREIGN KEY (org_id, customer_id) REFERENCES customers (org_id, id) ON DELETE CASCADE
);

CREATE TABLE install_payments (
    id              uuid            PRIMARY KEY,
    org_id          uuid            NOT NULL,
    install_id      uuid            NOT NULL,
    position        integer         NOT NULL,
    -- "Advance, 30%".
    label           text            NOT NULL,
    -- When a later one falls due: "After panels are fixed".
    detail          text,
    amount          bigint          NOT NULL CHECK (amount > 0),
    due_on          date,
    status          payment_status  NOT NULL DEFAULT 'later',
    claimed_at      timestamptz,
    claimed_method  payment_method,
    paid_on         date,
    created_at      timestamptz     NOT NULL DEFAULT now(),
    UNIQUE (install_id, position),
    FOREIGN KEY (org_id, install_id) REFERENCES installs (org_id, id) ON DELETE CASCADE
);

ALTER TABLE installs ENABLE ROW LEVEL SECURITY;
CREATE POLICY installs_company ON installs TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

ALTER TABLE install_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY install_payments_company ON install_payments TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());
