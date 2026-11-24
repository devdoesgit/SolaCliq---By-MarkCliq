/*
    References people read out: EXP-0001 (phase 8)
    --------------------------------------------------------------------
    - numbered per company and series, from `org_counters`
    - taken inside the record's own transaction: the counter row stays
      locked until it commits, so two records made at once get different
      numbers, and a rolled-back one gives its number back
*/

use sqlx::PgConnection;
use uuid::Uuid;

use crate::error::ApiResult;

// The next reference in a company's series, e.g. ("EXP", 7) → "EXP-0007".
pub async fn next(conn: &mut PgConnection, org_id: Uuid, series: &str) -> ApiResult<String> {
    let value: i32 = sqlx::query_scalar(
        "INSERT INTO org_counters (org_id, series, value) VALUES ($1, $2, 1)
         ON CONFLICT (org_id, series) DO UPDATE SET value = org_counters.value + 1
         RETURNING value",
    )
    .bind(org_id)
    .bind(series)
    .fetch_one(conn)
    .await?;
    Ok(format!("{series}-{value:04}"))
}
