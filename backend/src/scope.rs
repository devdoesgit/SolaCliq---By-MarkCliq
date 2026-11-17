/*
    Whose rows a transaction is for (row-level security, phase 7)
    --------------------------------------------------------------------
    - the policies (migration ..._row_level_security.sql) show a query
      only the rows of the transaction's scope. A query with no scope
      gets no rows from orgs, memberships or notifications
    - one scope per transaction, never two: each starts a transaction,
      switches to `solacliq_app` and records the scope, all only until
      the transaction ends (`SET LOCAL`, `set_config(…, true)`), so the
      next request on the same connection starts with none
    - handlers reach these through the value their extractor gave them,
      so the scope is always the one that was just checked:
        - `OrgMember::begin`     → `company` (the company of the path)
        - `AuthUser::begin`      → `person`  (the logged-in person)
        - `PlatformAdmin::begin` → `platform`
      and the push worker (`push.rs`) → `push`
*/

use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

use crate::error::ApiResult;

pub type Tx = Transaction<'static, Postgres>;

// One company's rows. Also for writing a company's first rows (registration).
pub async fn company(db: &PgPool, org_id: Uuid) -> ApiResult<Tx> {
    begin(db, "app.org_id", &org_id.to_string()).await
}

// One person's own rows: their memberships and companies, their personal feed.
pub async fn person(db: &PgPool, user_id: Uuid) -> ApiResult<Tx> {
    begin(db, "app.user_id", &user_id.to_string()).await
}

/*
    Every company, for MarkCliq's platform admins. Handlers reach it only
    through `PlatformAdmin::begin`; public for the tests
*/
pub async fn platform(db: &PgPool) -> ApiResult<Tx> {
    begin(db, "app.platform", "on").await
}

/*
    The push worker: every person's notifications, to send and mark them
    handled (`push.rs`). Nothing else
*/
pub async fn push(db: &PgPool) -> ApiResult<Tx> {
    begin(db, "app.push", "on").await
}

async fn begin(db: &PgPool, setting: &'static str, value: &str) -> ApiResult<Tx> {
    let mut tx = db.begin().await?;
    /*
        The API's login is restricted already; this restricts the owner
        too, when a command or test runs as it
    */
    sqlx::query("SET LOCAL ROLE solacliq_app")
        .execute(&mut *tx)
        .await?;
    sqlx::query("SELECT set_config($1, $2, true)")
        .bind(setting)
        .bind(value)
        .execute(&mut *tx)
        .await?;
    Ok(tx)
}

/*
    Fail closed: the server refuses to start on a login that row-level
    security wouldn't restrict (main.rs). Ok: the login's name
    --------------------------------------------------------------------
    - a superuser, or a role with BYPASSRLS, skips every policy
    - a table's owner skips that table's policies
    - not a member of `solacliq_app`: the policies (and the table
      grants) are written for it
*/
pub async fn check_restricted(db: &PgPool) -> Result<String, Box<dyn std::error::Error>> {
    let (login, superuser, bypass, owns, member): (String, bool, bool, bool, bool) =
        sqlx::query_as(
            "SELECT r.rolname::text, r.rolsuper, r.rolbypassrls,
                    EXISTS (SELECT 1 FROM pg_tables
                            WHERE schemaname = 'public' AND tableowner = current_user),
                    pg_has_role(current_user, 'solacliq_app', 'MEMBER')
             FROM pg_roles r WHERE r.rolname = current_user",
        )
        .fetch_one(db)
        .await?;
    let why = if superuser {
        "is a superuser"
    } else if bypass {
        "has BYPASSRLS"
    } else if owns {
        "owns tables"
    } else if !member {
        "is not a member of solacliq_app"
    } else {
        return Ok(login);
    };
    Err(format!(
        "APP_DATABASE_URL logs in as {login}, which {why}; it must be the restricted \
         API login (docs/architecture.md, \"Row-level security\")"
    )
    .into())
}
