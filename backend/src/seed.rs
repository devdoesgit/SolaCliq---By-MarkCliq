/*
    Command-line tools (phase 4)
    --------------------------------------------------------------------
    - `cargo run -- seed`: an illustrative company with one person per
      role, for trying the app and the website locally. Development only
    - `cargo run -- make-platform-admin <email>`: gives an account the
      MarkCliq platform admin role. Works in production; that's its job
*/

use sqlx::PgPool;
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

    tx.commit().await?;
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
