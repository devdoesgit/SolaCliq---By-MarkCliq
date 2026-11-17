/*
    Command-line tools (phase 4)
    --------------------------------------------------------------------
    - `cargo run -- seed`: an illustrative company with one person per
      role, Ravi's tasks and expenses (phase 8), the agents' customers
      (phase 9) and installs (phase 10), for trying the app and the
      website locally. Development only
    - `cargo run -- make-platform-admin <email>`: gives an account the
      MarkCliq platform admin role. Works in production; that's its job
*/

use chrono::{Duration, NaiveTime, TimeZone, Utc};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

use crate::{
    config::Environment,
    error::ApiError,
    org::{OrgStatus, PayType, Role},
    password, validate,
};

// The password of every seeded account that has one (printed by the seed).
pub const SEED_PASSWORD: &str = "sunlight1";

/*
    The seeded companies. Fixed ids, the same as the contract's examples,
    so running the seed twice updates them instead of adding copies
*/
const EXAMPLE_SOLAR: Uuid = Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000a1);
const DEMO_POWER: Uuid = Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000a3);

struct SeedOrg {
    id: Uuid,
    name: &'static str,
    phone: &'static str,
    status: OrgStatus,
    // Dummy, with a valid check character (PAN AAAAA000xA, Punjab).
    gstin: &'static str,
}

const ORGS: &[SeedOrg] = &[
    SeedOrg {
        id: EXAMPLE_SOLAR,
        name: "Example Solar (illustrative)",
        phone: "9814000000",
        status: OrgStatus::Active,
        gstin: "03AAAAA0000A1ZC",
    },
    // Suspended, to see the app's "company suspended" message.
    SeedOrg {
        id: DEMO_POWER,
        name: "Demo Power (illustrative)",
        phone: "9814000001",
        status: OrgStatus::Suspended,
        gstin: "03AAAAA0001A1ZB",
    },
];

// One seeded person and their memberships.
pub struct SeedPerson {
    pub email: &'static str,
    pub name: &'static str,
    // false: no password yet, so the team page shows them as invited.
    pub has_password: bool,
    memberships: &'static [(Uuid, Role, Option<PayType>)],
}

pub const PEOPLE: &[SeedPerson] = &[
    SeedPerson {
        email: "dev@example.com",
        name: "Dev Example (illustrative)",
        has_password: true,
        memberships: &[(EXAMPLE_SOLAR, Role::OrgAdmin, None)],
    },
    SeedPerson {
        email: "ravi@example.com",
        name: "Ravi Example (illustrative)",
        has_password: true,
        memberships: &[
            (EXAMPLE_SOLAR, Role::Worker, None),
            (DEMO_POWER, Role::Worker, None),
        ],
    },
    SeedPerson {
        email: "meena@example.com",
        name: "Meena Example (illustrative)",
        has_password: true,
        memberships: &[(EXAMPLE_SOLAR, Role::Agent, Some(PayType::Commission))],
    },
    SeedPerson {
        email: "aman@example.com",
        name: "Aman Example (illustrative)",
        has_password: true,
        memberships: &[(EXAMPLE_SOLAR, Role::Agent, Some(PayType::Salary))],
    },
    SeedPerson {
        email: "rajinder@example.com",
        name: "Rajinder Example (illustrative)",
        has_password: true,
        memberships: &[(EXAMPLE_SOLAR, Role::Customer, None)],
    },
    SeedPerson {
        email: "neha@example.com",
        name: "Neha Example (illustrative)",
        has_password: false,
        memberships: &[(EXAMPLE_SOLAR, Role::Worker, None)],
    },
];

#[derive(Debug, thiserror::Error)]
pub enum SeedError {
    #[error("the seed only runs with APP_ENV=development")]
    NotDevelopment,
    #[error("database: {0}")]
    Db(#[from] sqlx::Error),
    #[error("hashing the seed password failed")]
    Hash,
}

impl From<ApiError> for SeedError {
    fn from(_: ApiError) -> Self {
        SeedError::Hash
    }
}

/*
    Writes the seed
    --------------------------------------------------------------------
    - refuses outside development, before touching anything
    - safe to run again: every write is an upsert. Seeded accounts get
      their password, name and role back; anything else is left alone
    - one transaction: it all lands or none of it does
*/
pub async fn run(db: &PgPool, env: Environment) -> Result<(), SeedError> {
    if env != Environment::Development {
        return Err(SeedError::NotDevelopment);
    }
    let hash = password::hash(SEED_PASSWORD.to_owned()).await?;
    let mut tx = db.begin().await?;

    for org in ORGS {
        sqlx::query(
            "INSERT INTO orgs (id, name, phone, status, gstin, pan, legal_name,
                               business_type, address_line_1, city, state, pin_code)
             VALUES ($1, $2, $3, $4, $5, substr($5, 3, 10), $2, 'private_limited',
                     'Plot 1, Industrial Area', 'Mohali', 'Punjab', '160062')
             ON CONFLICT (id) DO UPDATE
                SET name = EXCLUDED.name, phone = EXCLUDED.phone,
                    status = EXCLUDED.status, gstin = EXCLUDED.gstin,
                    pan = EXCLUDED.pan, updated_at = now()",
        )
        .bind(org.id)
        .bind(org.name)
        .bind(org.phone)
        .bind(org.status)
        .bind(org.gstin)
        .execute(&mut *tx)
        .await?;
    }

    for person in PEOPLE {
        let password_hash = person.has_password.then_some(&hash);
        let user_id: Uuid = sqlx::query_scalar(
            "INSERT INTO users (id, email, name, password_hash, email_verified_at)
             VALUES ($1, $2, $3, $4, CASE WHEN $4 IS NULL THEN NULL ELSE now() END)
             ON CONFLICT (email) DO UPDATE
                SET name = EXCLUDED.name,
                    password_hash = EXCLUDED.password_hash,
                    email_verified_at = EXCLUDED.email_verified_at,
                    updated_at = now()
             RETURNING id",
        )
        .bind(Uuid::now_v7())
        .bind(person.email)
        .bind(person.name)
        .bind(password_hash)
        .fetch_one(&mut *tx)
        .await?;

        for &(org_id, role, pay_type) in person.memberships {
            sqlx::query(
                "INSERT INTO memberships (id, user_id, org_id, role, pay_type)
                 VALUES ($1, $2, $3, $4, $5)
                 ON CONFLICT (user_id, org_id) DO UPDATE
                    SET role = EXCLUDED.role, pay_type = EXCLUDED.pay_type,
                        removed_at = NULL",
            )
            .bind(Uuid::now_v7())
            .bind(user_id)
            .bind(org_id)
            .bind(role)
            .bind(pay_type)
            .execute(&mut *tx)
            .await?;
        }
    }

    tasks(&mut tx).await?;
    expenses(&mut tx).await?;
    registrations(&mut tx).await?;
    installs(&mut tx).await?;
    tx.commit().await?;
    Ok(())
}

/*
    Ravi's tasks
    --------------------------------------------------------------------
    - what the admin website will make (phase 8 has no admin side yet):
      customers, and tasks for Ravi in Example Solar, assigned by Dev
    - due times are relative to today (Indian time), so "today" always
      has work in it
    - reset on every run: the seeded tasks are deleted (with their
      photos, checklist and history) and written fresh, so a run puts
      them back to the start
*/
struct SeedCustomer {
    id: Uuid,
    reference: &'static str,
    name: &'static str,
    phone: &'static str,
    address: &'static str,
    lat: f64,
    lng: f64,
    system_kw: f64,
}

const CUSTOMERS: &[SeedCustomer] = &[
    SeedCustomer {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000d1),
        reference: "SC-0101",
        name: "Ramesh Sahoo (illustrative)",
        phone: "9814022671",
        address: "Sector 70, Mohali",
        lat: 30.7046,
        lng: 76.7179,
        system_kw: 5.0,
    },
    SeedCustomer {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000d2),
        reference: "SC-0102",
        name: "Anil Mehta (illustrative)",
        phone: "9814022672",
        address: "Kharar",
        lat: 30.7460,
        lng: 76.6460,
        system_kw: 3.0,
    },
    SeedCustomer {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000d3),
        reference: "SC-0103",
        name: "Priya Nair (illustrative)",
        phone: "9814022673",
        address: "Phase 7, Mohali",
        lat: 30.7110,
        lng: 76.7300,
        system_kw: 4.0,
    },
];

struct SeedTask {
    id: Uuid,
    reference: &'static str,
    title: &'static str,
    customer: usize,
    stage: i32,
    status: &'static str,
    // Days from today, and the hour (Indian time).
    day: i64,
    hour: u32,
    admin_note: Option<&'static str>,
    // Returned or cancelled: the admin's words.
    outcome_note: Option<&'static str>,
    // (id, label, hint, retake)
    slots: &'static [(&'static str, &'static str, &'static str, bool)],
    checklist: &'static [(&'static str, &'static str)],
}

const INSTALL_SLOTS: &[(&str, &str, &str, bool)] = &[
    ("rails", "Rails", "Rails fixed to the structure", false),
    ("row", "Panel row", "The full row, from the front", false),
    (
        "clamp",
        "Clamp close-up",
        "Fit one clamp in the frame, bolt visible",
        false,
    ),
    ("clean", "Clean site", "Roof cleared of packaging", false),
];

const TASKS: &[SeedTask] = &[
    SeedTask {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a01),
        reference: "TSK-0418",
        title: "Panel installation",
        customer: 0,
        stage: 3,
        status: "assigned",
        day: 0,
        hour: 10,
        admin_note: Some("Use the new clamps from batch B."),
        outcome_note: None,
        slots: INSTALL_SLOTS,
        checklist: &[
            ("rails", "Mount rails on structure"),
            ("panels", "Fix 10 panels, 550 W each"),
            ("torque", "Check clamp torque"),
            ("clear", "Clear site and remove packaging"),
        ],
    },
    SeedTask {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a02),
        reference: "TSK-0415",
        title: "Earthing",
        customer: 1,
        stage: 4,
        status: "returned",
        day: -1,
        hour: 11,
        admin_note: None,
        outcome_note: Some("Earth pit photo is too dark. Take it again in daylight."),
        slots: &[
            (
                "pit",
                "Earth pit",
                "The pit with the electrode visible",
                true,
            ),
            (
                "strip",
                "Earthing strip",
                "Strip joined to the structure",
                false,
            ),
        ],
        checklist: &[
            ("pit", "Dig the earth pit"),
            ("strip", "Run the earthing strip"),
        ],
    },
    SeedTask {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a03),
        reference: "TSK-0420",
        title: "Wiring",
        customer: 2,
        stage: 5,
        status: "assigned",
        day: 0,
        hour: 14,
        admin_note: None,
        outcome_note: None,
        slots: &[
            (
                "dcdb",
                "DC box",
                "The DC distribution box, cover open",
                false,
            ),
            ("inverter", "Inverter", "Inverter mounted, cables in", false),
        ],
        checklist: &[
            ("cables", "Lay DC cables in conduit"),
            ("inverter", "Mount the inverter"),
        ],
    },
    SeedTask {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a04),
        reference: "TSK-0425",
        title: "Net meter",
        customer: 0,
        stage: 6,
        status: "assigned",
        day: 2,
        hour: 10,
        admin_note: None,
        outcome_note: None,
        slots: &[(
            "meter",
            "Net meter",
            "The new meter, its number readable",
            false,
        )],
        checklist: &[("meter", "Fit the net meter with the DISCOM")],
    },
    SeedTask {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a07),
        reference: "TSK-0402",
        title: "Structure",
        customer: 1,
        stage: 2,
        status: "cancelled",
        day: -3,
        hour: 9,
        admin_note: None,
        outcome_note: Some(
            "Customer postponed the install to December. No action needed from you.",
        ),
        slots: &[],
        checklist: &[],
    },
];

async fn tasks(tx: &mut PgConnection) -> Result<(), SeedError> {
    let ids: Vec<Uuid> = TASKS.iter().map(|t| t.id).collect();
    // Expenses logged against these tasks go with them (seeded or not).
    sqlx::query("DELETE FROM expenses WHERE task_id = ANY($1)")
        .bind(&ids)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM tasks WHERE id = ANY($1)")
        .bind(&ids)
        .execute(&mut *tx)
        .await?;

    for c in CUSTOMERS {
        sqlx::query(
            "INSERT INTO customers (id, org_id, reference, name, phone, address, lat, lng, system_kw)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (id) DO UPDATE
                SET name = EXCLUDED.name, phone = EXCLUDED.phone, address = EXCLUDED.address,
                    lat = EXCLUDED.lat, lng = EXCLUDED.lng, system_kw = EXCLUDED.system_kw",
        )
        .bind(c.id)
        .bind(EXAMPLE_SOLAR)
        .bind(c.reference)
        .bind(c.name)
        .bind(c.phone)
        .bind(c.address)
        .bind(c.lat)
        .bind(c.lng)
        .bind(c.system_kw)
        .execute(&mut *tx)
        .await?;
    }

    let (ravi, dev): (Uuid, Uuid) = sqlx::query_as(
        "SELECT (SELECT id FROM users WHERE email = 'ravi@example.com'),
                (SELECT id FROM users WHERE email = 'dev@example.com')",
    )
    .fetch_one(&mut *tx)
    .await?;
    let india = chrono::FixedOffset::east_opt(5 * 3600 + 30 * 60).expect("a valid offset");
    let today = Utc::now().with_timezone(&india).date_naive();

    for t in TASKS {
        let due_at = india
            .from_local_datetime(
                &(today + Duration::days(t.day))
                    .and_time(NaiveTime::from_hms_opt(t.hour, 0, 0).expect("an hour")),
            )
            .single()
            .expect("India has no clock changes")
            .with_timezone(&Utc);
        let assigned_at = due_at - Duration::days(1);
        let outcome_at = Utc::now() - Duration::hours(2);
        let returned = t.status == "returned";
        let cancelled = t.status == "cancelled";
        sqlx::query(
            "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index,
                                assignee_id, assigned_by, due_at, status, status_at,
                                admin_note, admin_note_at, created_at,
                                submitted_at, returned_note, returned_by, returned_at,
                                cancelled_note, cancelled_by, cancelled_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::task_status,
                     CASE WHEN $10 = 'assigned' THEN $11 ELSE $14 END,
                     $12, CASE WHEN $12 IS NULL THEN NULL ELSE $11 END, $11,
                     CASE WHEN $15 THEN $14 - interval '1 hour' END,
                     CASE WHEN $15 THEN $13 END, CASE WHEN $15 THEN $8 END,
                     CASE WHEN $15 THEN $14 END,
                     CASE WHEN $16 THEN $13 END, CASE WHEN $16 THEN $8 END,
                     CASE WHEN $16 THEN $14 END)",
        )
        .bind(t.id)
        .bind(EXAMPLE_SOLAR)
        .bind(CUSTOMERS[t.customer].id)
        .bind(t.reference)
        .bind(t.title)
        .bind(t.stage)
        .bind(ravi)
        .bind(dev)
        .bind(due_at)
        .bind(t.status)
        .bind(assigned_at)
        .bind(t.admin_note)
        .bind(t.outcome_note)
        .bind(outcome_at)
        .bind(returned)
        .bind(cancelled)
        .execute(&mut *tx)
        .await?;

        for (position, &(slot_id, label, hint, retake)) in t.slots.iter().enumerate() {
            sqlx::query(
                "INSERT INTO task_photo_slots (org_id, task_id, slot_id, position, label, hint, retake)
                 VALUES ($1, $2, $3, $4, $5, $6, $7)",
            )
            .bind(EXAMPLE_SOLAR)
            .bind(t.id)
            .bind(slot_id)
            .bind(position as i32)
            .bind(label)
            .bind(hint)
            .bind(retake)
            .execute(&mut *tx)
            .await?;
        }
        for (position, &(item_id, text)) in t.checklist.iter().enumerate() {
            sqlx::query(
                "INSERT INTO task_checklist_items (org_id, task_id, item_id, position, text, done)
                 VALUES ($1, $2, $3, $4, $5, $6)",
            )
            .bind(EXAMPLE_SOLAR)
            .bind(t.id)
            .bind(item_id)
            .bind(position as i32)
            .bind(text)
            .bind(returned)
            .execute(&mut *tx)
            .await?;
        }

        // The history so far: assigned, then the admin's decision.
        let mut events = vec![("assigned", dev, assigned_at, None)];
        if returned {
            events.push(("submitted", ravi, outcome_at - Duration::hours(1), None));
            events.push(("returned", dev, outcome_at, t.outcome_note));
        }
        if cancelled {
            events.push(("cancelled", dev, outcome_at, t.outcome_note));
        }
        for (kind, actor, at, detail) in events {
            sqlx::query(
                "INSERT INTO task_events (id, org_id, task_id, kind, actor_id, detail, created_at)
                 VALUES ($1, $2, $3, $4::task_event_kind, $5, $6, $7)",
            )
            .bind(Uuid::now_v7())
            .bind(EXAMPLE_SOLAR)
            .bind(t.id)
            .bind(kind)
            .bind(actor)
            .bind(detail)
            .bind(at)
            .execute(&mut *tx)
            .await?;
        }
    }
    Ok(())
}

/*
    Ravi's expenses
    --------------------------------------------------------------------
    - one of each state the admin website will set: with the admin, sent
      back with a note, approved, paid. Reset on every run, like the tasks
    - no receipt files: the app's "upload new receipt" adds a real one
    - the EXP counter moves past them, so the app's next is EXP-0005
*/
struct SeedExpense {
    id: Uuid,
    reference: &'static str,
    amount: i64,
    category: &'static str,
    note: &'static str,
    days_ago: i64,
    status: &'static str,
    admin_note: Option<&'static str>,
    // The seeded task it was for (TASKS index).
    task: Option<usize>,
}

const EXPENSES: &[SeedExpense] = &[
    SeedExpense {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000f1),
        reference: "EXP-0001",
        amount: 124_000,
        category: "fuel",
        note: "Diesel for site van",
        days_ago: 0,
        status: "in_review",
        admin_note: None,
        task: Some(0),
    },
    SeedExpense {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000f3),
        reference: "EXP-0002",
        amount: 20_000,
        category: "other",
        note: "Food",
        days_ago: 3,
        status: "needs_fix",
        admin_note: Some("Receipt photo is unreadable. Upload a clearer one or add a note."),
        task: Some(1),
    },
    SeedExpense {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000f2),
        reference: "EXP-0003",
        amount: 86_000,
        category: "material",
        note: "MC4 connectors",
        days_ago: 3,
        status: "approved",
        admin_note: None,
        task: None,
    },
    SeedExpense {
        id: Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000f4),
        reference: "EXP-0004",
        amount: 110_000,
        category: "fuel",
        note: "Kharar site",
        days_ago: 5,
        status: "paid",
        admin_note: None,
        task: None,
    },
];

async fn expenses(tx: &mut PgConnection) -> Result<(), SeedError> {
    let ids: Vec<Uuid> = EXPENSES.iter().map(|e| e.id).collect();
    sqlx::query("DELETE FROM expenses WHERE id = ANY($1)")
        .bind(&ids)
        .execute(&mut *tx)
        .await?;
    let india = chrono::FixedOffset::east_opt(5 * 3600 + 30 * 60).expect("a valid offset");
    let today = Utc::now().with_timezone(&india).date_naive();

    for e in EXPENSES {
        sqlx::query(
            "INSERT INTO expenses (id, org_id, reference, owner_id, amount, category, note,
                                   spent_on, status, admin_note, decided_by, task_id, created_at)
             SELECT $1, $2, $3, r.id, $4, $5::expense_category, $6, $7, $8::expense_status, $9,
                    CASE WHEN $8 = 'in_review' THEN NULL ELSE d.id END, $10,
                    now() - make_interval(days => $11)
             FROM users r, users d
             WHERE r.email = 'ravi@example.com' AND d.email = 'dev@example.com'",
        )
        .bind(e.id)
        .bind(EXAMPLE_SOLAR)
        .bind(e.reference)
        .bind(e.amount)
        .bind(e.category)
        .bind(e.note)
        .bind(today - Duration::days(e.days_ago))
        .bind(e.status)
        .bind(e.admin_note)
        .bind(e.task.map(|i| TASKS[i].id))
        .bind(e.days_ago as i32)
        .execute(&mut *tx)
        .await?;
    }
    sqlx::query(
        "INSERT INTO org_counters (org_id, series, value) VALUES ($1, 'EXP', $2)
         ON CONFLICT (org_id, series)
            DO UPDATE SET value = GREATEST(org_counters.value, EXCLUDED.value)",
    )
    .bind(EXAMPLE_SOLAR)
    .bind(EXPENSES.len() as i32)
    .execute(&mut *tx)
    .await?;
    Ok(())
}

/*
    The agents' customers (phase 9)
    --------------------------------------------------------------------
    - Meena (commission) and Aman (salary) each have customers in every
      state the admin website will set: with the admin, a document sent
      back, approved at a stage, not taken up
    - Rajinder (the seeded customer) is one of Meena's, approved, so his
      Documents screen has his KYC
    - each document points at an upload row with no file behind it: the
      app never shows KYC images, and `used_at` keeps the sweep off them
    - reset on every run; the SC counter moves past them
*/
struct SeedCustomerReg {
    n: u128,
    reference: &'static str,
    name: &'static str,
    email: &'static str,
    phone: &'static str,
    city: &'static str,
    kw: f64,
    agent: &'static str,
    status: &'static str,
    days_ago: i32,
    stage: Option<i32>,
    // (paise, status)
    commission: Option<(i64, &'static str)>,
    // The document sent back, and why.
    fix: Option<(&'static str, &'static str)>,
    rejected_note: Option<&'static str>,
}

const REGISTRATIONS: &[SeedCustomerReg] = &[
    SeedCustomerReg {
        n: 1,
        reference: "SC-0001",
        name: "Rajinder Kaur (illustrative)",
        email: "rajinder@example.com",
        phone: "9814033001",
        city: "Mohali",
        kw: 5.0,
        agent: "meena@example.com",
        status: "approved",
        days_ago: 20,
        stage: Some(2),
        commission: Some((500_000, "payable")),
        fix: None,
        rejected_note: None,
    },
    SeedCustomerReg {
        n: 2,
        reference: "SC-0002",
        name: "Sunita Rao (illustrative)",
        email: "sunita@example.com",
        phone: "9814033002",
        city: "Kharar",
        kw: 3.0,
        agent: "meena@example.com",
        status: "needs_fix",
        days_ago: 4,
        stage: None,
        commission: Some((300_000, "in_review")),
        fix: Some((
            "electricity_bill",
            "Bill photo is blurry. Take it again in daylight.",
        )),
        rejected_note: None,
    },
    SeedCustomerReg {
        n: 3,
        reference: "SC-0003",
        name: "Arjun Mehra (illustrative)",
        email: "arjun@example.com",
        phone: "9814033003",
        city: "Zirakpur",
        kw: 4.0,
        agent: "meena@example.com",
        status: "in_review",
        days_ago: 0,
        stage: None,
        commission: Some((450_000, "in_review")),
        fix: None,
        rejected_note: None,
    },
    SeedCustomerReg {
        n: 4,
        reference: "SC-0004",
        name: "Harpal Singh (illustrative)",
        email: "harpal@example.com",
        phone: "9814033004",
        city: "Kurali",
        kw: 3.0,
        agent: "meena@example.com",
        status: "rejected",
        days_ago: 12,
        stage: None,
        commission: None,
        fix: None,
        rejected_note: Some("The roof is shaded most of the day."),
    },
    SeedCustomerReg {
        n: 5,
        reference: "SC-0005",
        name: "Kiran Patel (illustrative)",
        email: "kiran@example.com",
        phone: "9814033005",
        city: "Mohali",
        kw: 6.0,
        agent: "aman@example.com",
        status: "in_review",
        days_ago: 1,
        stage: None,
        commission: None,
        fix: None,
        rejected_note: None,
    },
    SeedCustomerReg {
        n: 6,
        reference: "SC-0006",
        name: "Gurpreet Kaur (illustrative)",
        email: "gurpreet@example.com",
        phone: "9814033006",
        city: "Panchkula",
        kw: 5.0,
        agent: "aman@example.com",
        status: "approved",
        days_ago: 30,
        stage: Some(5),
        commission: None,
        fix: None,
        rejected_note: None,
    },
];

const SEED_KYC: [&str; 5] = [
    "aadhaar",
    "pan",
    "electricity_bill",
    "land_document",
    "signature",
];

// Fixed ids per customer (…c1, …c2) and per document upload (…c101…).
fn reg_id(n: u128) -> Uuid {
    Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000000c0 + n)
}
fn reg_upload_id(n: u128, k: usize) -> Uuid {
    Uuid::from_u128(0x01928f6e_0000_7000_8000_00000000c000 + n * 0x10 + k as u128)
}

async fn registrations(tx: &mut PgConnection) -> Result<(), SeedError> {
    let ids: Vec<Uuid> = REGISTRATIONS.iter().map(|c| reg_id(c.n)).collect();
    let uploads: Vec<Uuid> = REGISTRATIONS
        .iter()
        .flat_map(|c| (0..SEED_KYC.len()).map(move |k| reg_upload_id(c.n, k)))
        .collect();
    // Their visit task first (it points at the customer), then the customers:
    // documents and installs go with them (ON DELETE CASCADE), then the uploads.
    sqlx::query("DELETE FROM tasks WHERE id = $1")
        .bind(RAJINDER_VISIT)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM customers WHERE id = ANY($1)")
        .bind(&ids)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM uploads WHERE id = ANY($1)")
        .bind(&uploads)
        .execute(&mut *tx)
        .await?;

    for c in REGISTRATIONS {
        let id = reg_id(c.n);
        let commission = c.commission.map(|(amount, _)| amount);
        let commission_status = c.commission.map(|(_, status)| status);
        sqlx::query(
            "INSERT INTO customers (id, org_id, reference, name, phone, email, address, city,
                                    pin_code, state, discom, consumer_number, sanctioned_load_kw,
                                    connection_type, roof, subsidy, consent_at, system_kw,
                                    registered_by, user_id, kyc_status, stage_index, decided_by,
                                    decided_at, rejected_note, commission, commission_status,
                                    commission_payable_since, created_at)
             SELECT $1, $2, $3, $4, $5, $6, 'House ' || $13::text || ', Main Road', $7, '160062',
                    'Punjab', 'PSPCL', 'C-' || $5, 5, 'residential', 'rcc', false,
                    now() - make_interval(days => $9), $8,
                    a.id, (SELECT id FROM users WHERE email = $6), $10::kyc_status, $11,
                    CASE WHEN $10 IN ('approved', 'rejected') THEN d.id END,
                    CASE WHEN $10 IN ('approved', 'rejected') THEN now() - interval '1 day' END,
                    $12, $14, $15::commission_status,
                    CASE WHEN $15 = 'payable' THEN current_date - 3 END,
                    now() - make_interval(days => $9)
             FROM users a, users d
             WHERE a.email = $16 AND d.email = 'dev@example.com'",
        )
        .bind(id)
        .bind(EXAMPLE_SOLAR)
        .bind(c.reference)
        .bind(c.name)
        .bind(c.phone)
        .bind(c.email)
        .bind(c.city)
        .bind(c.kw)
        .bind(c.days_ago)
        .bind(c.status)
        .bind(c.stage)
        .bind(c.rejected_note)
        .bind(c.n as i32)
        .bind(commission)
        .bind(commission_status)
        .bind(c.agent)
        .execute(&mut *tx)
        .await?;

        for (k, kind) in SEED_KYC.iter().enumerate() {
            let upload = reg_upload_id(c.n, k);
            sqlx::query(
                "INSERT INTO uploads (id, org_id, owner_id, purpose, content_type, size_bytes,
                                      r2_key, used_at)
                 SELECT $1, $2, id, 'kyc', 'image/jpeg', 1000,
                        'orgs/' || $2::text || '/kyc/' || $1::text, now()
                 FROM users WHERE email = $3",
            )
            .bind(upload)
            .bind(EXAMPLE_SOLAR)
            .bind(c.agent)
            .execute(&mut *tx)
            .await?;
            let (status, note) = match (c.fix, c.status) {
                (Some((fix_kind, note)), _) if fix_kind == *kind => ("needs_fix", Some(note)),
                (_, "approved") => ("verified", None),
                _ => ("in_review", None),
            };
            sqlx::query(
                "INSERT INTO documents (id, org_id, customer_id, kind, upload_id, status,
                                        admin_note, admin_note_by, admin_note_at, uploaded_by,
                                        created_at, updated_at)
                 SELECT $1, $2, $3, $4::kyc_kind, $5, $6::document_status, $7,
                        CASE WHEN $7 IS NULL THEN NULL ELSE d.id END,
                        CASE WHEN $7 IS NULL THEN NULL ELSE now() - interval '1 day' END, a.id,
                        c.created_at, c.created_at
                 FROM users a, users d, customers c
                 WHERE a.email = $8 AND d.email = 'dev@example.com' AND c.id = $3",
            )
            .bind(Uuid::now_v7())
            .bind(EXAMPLE_SOLAR)
            .bind(id)
            .bind(*kind)
            .bind(upload)
            .bind(status)
            .bind(note)
            .bind(c.agent)
            .execute(&mut *tx)
            .await?;
        }
    }
    sqlx::query(
        "INSERT INTO org_counters (org_id, series, value) VALUES ($1, 'SC', $2)
         ON CONFLICT (org_id, series)
            DO UPDATE SET value = GREATEST(org_counters.value, EXCLUDED.value)",
    )
    .bind(EXAMPLE_SOLAR)
    .bind(REGISTRATIONS.len() as i32)
    .execute(&mut *tx)
    .await?;
    Ok(())
}

/*
    Installs (phase 10)
    --------------------------------------------------------------------
    - the two approved customers: Rajinder (Meena's, stage 2) and Gurpreet
      (Aman's, stage 5). Price ₹57,000 a kW, the PM Surya Ghar subsidy
      from the table, the default plan
    - Rajinder: advance paid, the installation payment due, and his next
      visit (a Structure task for Ravi tomorrow), so Track and Payments
      have everything to show and claim
    - Example Solar gets an illustrative UPI id, for "Pay by UPI"
*/
const RAJINDER_VISIT: Uuid = Uuid::from_u128(0x01928f6e_0000_7000_8000_000000000a08);

async fn installs(tx: &mut PgConnection) -> Result<(), SeedError> {
    use crate::routes::install::{default_plan, pm_surya_ghar};

    sqlx::query("UPDATE orgs SET upi_id = 'examplesolar@okhdfc' WHERE id = $1")
        .bind(EXAMPLE_SOLAR)
        .execute(&mut *tx)
        .await?;

    let india = chrono::FixedOffset::east_opt(5 * 3600 + 30 * 60).expect("a valid offset");
    let today = Utc::now().with_timezone(&india).date_naive();
    // (customer n, statuses of the three payments)
    for (n, statuses) in [(1, ["paid", "due", "later"]), (6, ["paid", "paid", "due"])] {
        let c = REGISTRATIONS
            .iter()
            .find(|c| c.n == n)
            .expect("a seeded customer");
        let total = (c.kw * 5_700_000.0) as i64;
        let install = Uuid::from_u128(0x01928f6e_0000_7000_8000_0000000001e0 + n);
        sqlx::query(
            "INSERT INTO installs (id, org_id, customer_id, total, subsidy)
             VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(install)
        .bind(EXAMPLE_SOLAR)
        .bind(reg_id(n))
        .bind(total)
        .bind(pm_surya_ghar(c.kw))
        .execute(&mut *tx)
        .await?;
        for (position, ((label, detail, amount), status)) in
            default_plan(total).into_iter().zip(statuses).enumerate()
        {
            sqlx::query(
                "INSERT INTO install_payments (id, org_id, install_id, position, label, detail,
                                               amount, due_on, status, paid_on)
                 VALUES ($1, $2, $3, $4, $5, $6, $7,
                         CASE WHEN $8 = 'due' THEN $9::date END, $8::payment_status,
                         CASE WHEN $8 = 'paid' THEN $10::date END)",
            )
            .bind(Uuid::from_u128(
                0x01928f6e_0000_7000_8000_000000000200 + n * 0x10 + position as u128,
            ))
            .bind(EXAMPLE_SOLAR)
            .bind(install)
            .bind(position as i32)
            .bind(label)
            .bind(detail)
            .bind(amount)
            .bind(status)
            .bind(today + Duration::days(7))
            .bind(today - Duration::days(15))
            .execute(&mut *tx)
            .await?;
        }
    }

    // Rajinder's next visit: Structure (stage 2), Ravi, tomorrow 10:00.
    let due_at = india
        .from_local_datetime(
            &(today + Duration::days(1))
                .and_time(NaiveTime::from_hms_opt(10, 0, 0).expect("10:00")),
        )
        .single()
        .expect("India has no clock changes")
        .with_timezone(&Utc);
    sqlx::query(
        "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index, assignee_id,
                            assigned_by, due_at)
         SELECT $1, $2, $3, 'TSK-0430', 'Structure', 2, r.id, d.id, $4
         FROM users r, users d WHERE r.email = 'ravi@example.com' AND d.email = 'dev@example.com'",
    )
    .bind(RAJINDER_VISIT)
    .bind(EXAMPLE_SOLAR)
    .bind(reg_id(1))
    .bind(due_at)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO task_photo_slots (org_id, task_id, slot_id, position, label, hint)
         VALUES ($1, $2, 'frame', 0, 'Structure frame', 'The whole frame, bolted down')",
    )
    .bind(EXAMPLE_SOLAR)
    .bind(RAJINDER_VISIT)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "INSERT INTO task_checklist_items (org_id, task_id, item_id, position, text)
         VALUES ($1, $2, 'level', 0, 'Level and bolt the frame')",
    )
    .bind(EXAMPLE_SOLAR)
    .bind(RAJINDER_VISIT)
    .execute(&mut *tx)
    .await?;
    Ok(())
}

/*
    Makes the account with this email a platform admin. false when no
    account has it (the caller says so and exits with an error)
*/
pub async fn make_platform_admin(db: &PgPool, email: &str) -> Result<bool, sqlx::Error> {
    let updated = sqlx::query(
        "UPDATE users SET is_platform_admin = true, updated_at = now() WHERE email = $1",
    )
    .bind(validate::normalize_email(email))
    .execute(db)
    .await?
    .rows_affected();
    Ok(updated == 1)
}
