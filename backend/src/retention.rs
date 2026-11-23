/*
    KYC retention (F18; decided 2026-11-17)
    --------------------------------------------------------------------
    - rejected 30 days ago: the customer, their documents and files
    - handed over a year ago: their documents and files; the rest stays
    - files leave R2 first, then the rows: a failure in between is found
      again the next hour, and deleting a missing file is fine
    - deletes only when the caller says so (`KYC_RETENTION=true`);
      otherwise it counts what is due
*/

use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{account, error::ApiResult, india, scope, storage::Storage};

#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct Report {
    pub due: usize,
    pub deleted: usize,
}

#[derive(sqlx::FromRow)]
struct Due {
    id: Uuid,
    rejected: bool,
    user_id: Option<Uuid>,
}

pub async fn run(db: &PgPool, storage: &Storage, delete: bool) -> ApiResult<Report> {
    let mut tx = scope::platform(db).await?;
    let orgs: Vec<Uuid> = sqlx::query_scalar("SELECT id FROM orgs")
        .fetch_all(&mut *tx)
        .await?;
    tx.commit().await?;

    let today = india::date(Utc::now());
    let mut report = Report::default();
    for org in orgs {
        let mut tx = scope::company(db, org).await?;
        let due: Vec<Due> = sqlx::query_as(
            "SELECT c.id, c.kyc_status = 'rejected' AS rejected, c.user_id
             FROM customers c LEFT JOIN installs i ON i.customer_id = c.id
             WHERE c.org_id = $1
               AND ((c.kyc_status = 'rejected' AND c.decided_at <= now() - interval '30 days'
                     AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.customer_id = c.id))
                 OR (i.handed_over_on + interval '1 year' <= $2
                     AND EXISTS (SELECT 1 FROM documents d WHERE d.customer_id = c.id)))",
        )
        .bind(org)
        .bind(today)
        .fetch_all(&mut *tx)
        .await?;
        tx.commit().await?;
        report.due += due.len();
        if !delete {
            continue;
        }
        for customer in due {
            match remove(db, storage, org, &customer).await {
                Ok(true) => report.deleted += 1,
                Ok(false) => {}
                Err(e) => {
                    tracing::warn!(error = ?e, customer_id = %customer.id, "deleting KYC");
                }
            }
        }
    }
    Ok(report)
}

// False when R2 wouldn't delete a file: nothing else is touched.
async fn remove(db: &PgPool, storage: &Storage, org: Uuid, due: &Due) -> ApiResult<bool> {
    let mut tx = scope::company(db, org).await?;
    let files: Vec<(Uuid, String)> = sqlx::query_as(
        "SELECT u.id, u.r2_key
         FROM documents d
         JOIN document_files f ON f.document_id = d.id
         JOIN uploads u ON u.id = f.upload_id
         WHERE d.org_id = $1 AND d.customer_id = $2",
    )
    .bind(org)
    .bind(due.id)
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

    for (_, key) in &files {
        if let Err(e) = storage.delete(key).await {
            tracing::warn!(error = %e, customer_id = %due.id, "deleting a KYC file");
            return Ok(false);
        }
    }

    let mut tx = scope::company(db, org).await?;
    let mut left = None;
    if due.rejected {
        sqlx::query("DELETE FROM notifications WHERE org_id = $1 AND customer_id = $2")
            .bind(org)
            .bind(due.id)
            .execute(&mut *tx)
            .await?;
        sqlx::query("DELETE FROM customers WHERE org_id = $1 AND id = $2")
            .bind(org)
            .bind(due.id)
            .execute(&mut *tx)
            .await?;
        if let Some(user) = due.user_id {
            let only_this: bool = sqlx::query_scalar(
                "SELECT EXISTS (SELECT 1 FROM memberships
                                WHERE org_id = $1 AND user_id = $2 AND role = 'customer')
                    AND NOT EXISTS (SELECT 1 FROM customers WHERE org_id = $1 AND user_id = $2)",
            )
            .bind(org)
            .bind(user)
            .fetch_one(&mut *tx)
            .await?;
            if only_this {
                account::leave(&mut tx, org, user).await?;
                left = Some(user);
            }
        }
    } else {
        sqlx::query("DELETE FROM documents WHERE org_id = $1 AND customer_id = $2")
            .bind(org)
            .bind(due.id)
            .execute(&mut *tx)
            .await?;
    }
    let uploads: Vec<Uuid> = files.iter().map(|f| f.0).collect();
    sqlx::query("DELETE FROM uploads WHERE org_id = $1 AND id = ANY($2)")
        .bind(org)
        .bind(&uploads)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;

    // An account made only for that registration and never set up.
    if let Some(user) = left {
        let mut tx = scope::person(db, user).await?;
        let unused: bool = sqlx::query_scalar(
            "SELECT password_hash IS NULL AND NOT is_platform_admin
                AND NOT EXISTS (SELECT 1 FROM memberships
                                WHERE user_id = $1 AND removed_at IS NULL)
             FROM users WHERE id = $1",
        )
        .bind(user)
        .fetch_one(&mut *tx)
        .await?;
        if unused {
            account::erase(&mut tx, user, false).await?;
        }
        tx.commit().await?;
    }
    tracing::info!(org_id = %org, customer_id = %due.id, rejected = due.rejected, "KYC deleted");
    Ok(true)
}
