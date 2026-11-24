/*
    Deleting a person's account (F18)
    --------------------------------------------------------------------
    - the row stays, emptied: a company's records (tasks, expenses,
      attendance, installs) point at it and are that company's
    - the name stays only for someone who was in a company, as it is on
      those records
    - one scope per transaction: each company first, then the account.
      Stopped halfway, deleting again finishes it
*/

use axum::http::StatusCode;
use sqlx::PgConnection;
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    password,
    rate_limit::Rule,
    scope,
};

pub async fn delete(state: &AppState, user_id: Uuid, given: String) -> ApiResult<()> {
    let (email, hash, platform): (String, Option<String>, bool) =
        sqlx::query_as("SELECT email, password_hash, is_platform_admin FROM users WHERE id = $1")
            .bind(user_id)
            .fetch_one(&state.db)
            .await?;
    // The same bucket as log in: this is another place to guess a password.
    state.limits.check(Rule::LoginByEmail, &email)?;
    if given.chars().count() > 128 || !password::verify(given, hash).await? {
        return Err(ApiError::new(
            StatusCode::BAD_REQUEST,
            "account.password_incorrect",
            "That password isn't right",
        ));
    }
    if platform {
        return Err(ApiError::new(
            StatusCode::CONFLICT,
            "account.platform_admin",
            "A MarkCliq admin's account is closed by MarkCliq",
        ));
    }

    let mut tx = scope::person(&state.db, user_id).await?;
    let orgs: Vec<Uuid> = sqlx::query_scalar("SELECT org_id FROM memberships WHERE user_id = $1")
        .bind(user_id)
        .fetch_all(&mut *tx)
        .await?;
    tx.commit().await?;

    // All of them before any change, so a refusal leaves everything as it was.
    for &org in &orgs {
        let mut tx = scope::company(&state.db, org).await?;
        keeps_an_admin(&mut tx, org, user_id).await?;
        tx.commit().await?;
    }
    for &org in &orgs {
        let mut tx = scope::company(&state.db, org).await?;
        keeps_an_admin(&mut tx, org, user_id).await?;
        leave(&mut tx, org, user_id).await?;
        tx.commit().await?;
    }

    let mut tx = scope::person(&state.db, user_id).await?;
    erase(&mut tx, user_id, !orgs.is_empty()).await?;
    tx.commit().await?;
    tracing::info!(%user_id, "account deleted");
    Ok(())
}

// 409 when they're the last admin. Locks the admins: two leaving at once queue.
async fn keeps_an_admin(conn: &mut PgConnection, org: Uuid, user_id: Uuid) -> ApiResult<()> {
    let rejected: bool =
        sqlx::query_scalar("SELECT status::text = 'rejected' FROM orgs WHERE id = $1")
            .bind(org)
            .fetch_one(&mut *conn)
            .await?;
    let admins: Vec<Uuid> = sqlx::query_scalar(
        "SELECT user_id FROM memberships
         WHERE org_id = $1 AND role = 'org_admin' AND removed_at IS NULL
         FOR UPDATE",
    )
    .bind(org)
    .fetch_all(conn)
    .await?;
    if !rejected && admins == [user_id] {
        return Err(ApiError::new(
            StatusCode::CONFLICT,
            "account.last_admin",
            "You're your company's only admin",
        ));
    }
    Ok(())
}

// Ends one membership, with that company's notifications to them.
pub(crate) async fn leave(conn: &mut PgConnection, org: Uuid, user_id: Uuid) -> ApiResult<()> {
    sqlx::query(
        "UPDATE memberships SET removed_at = now()
         WHERE org_id = $1 AND user_id = $2 AND removed_at IS NULL",
    )
    .bind(org)
    .bind(user_id)
    .execute(&mut *conn)
    .await?;
    sqlx::query("DELETE FROM notifications WHERE org_id = $1 AND user_id = $2")
        .bind(org)
        .bind(user_id)
        .execute(&mut *conn)
        .await?;
    crate::routes::leads::release(conn, org, user_id).await?;
    Ok(())
}

// Empties the account, in the person's own scope.
pub(crate) async fn erase(
    conn: &mut PgConnection,
    user_id: Uuid,
    keep_name: bool,
) -> ApiResult<()> {
    sqlx::query("DELETE FROM signups WHERE email = (SELECT email FROM users WHERE id = $1)")
        .bind(user_id)
        .execute(&mut *conn)
        .await?;
    for delete in [
        "DELETE FROM devices WHERE user_id = $1",
        "DELETE FROM sessions WHERE user_id = $1",
        "DELETE FROM email_codes WHERE user_id = $1",
        "DELETE FROM user_details WHERE user_id = $1",
        "DELETE FROM user_settings WHERE user_id = $1",
        "DELETE FROM quote_requests WHERE user_id = $1",
        "DELETE FROM idempotency_keys WHERE user_id = $1",
        "DELETE FROM notifications WHERE user_id = $1 AND org_id IS NULL",
        "DELETE FROM agreements WHERE user_id = $1",
    ] {
        sqlx::query(delete)
            .bind(user_id)
            .execute(&mut *conn)
            .await?;
    }
    sqlx::query(
        "UPDATE users
         SET email = 'deleted+' || id::text || '@deleted.invalid',
             name = CASE WHEN $2 THEN name ELSE 'Deleted account' END,
             phone = NULL, password_hash = NULL, email_verified_at = NULL, updated_at = now()
         WHERE id = $1",
    )
    .bind(user_id)
    .bind(keep_name)
    .execute(conn)
    .await?;
    Ok(())
}
