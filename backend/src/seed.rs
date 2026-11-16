/*
    Command-line tools (phase 4)
    --------------------------------------------------------------------
    - `cargo run -- seed`: an illustrative company with one person per
      role, and Ravi's tasks (phase 8), for trying the app and the
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
