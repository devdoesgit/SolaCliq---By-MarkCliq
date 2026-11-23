/*
    The website's first screen, and the totals over its money lists
    --------------------------------------------------------------------
    - the admin design's Overview (canvas page "v2 · 5 Admin web")
    - read only, worked out on each read: nothing stored, nothing cached
    - money is paise; a month and a week are India's
*/

use axum::{Json, extract::State};
use chrono::{Datelike, Days, NaiveDate, Utc};
use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use super::ERRORS;
use crate::{
    AppState,
    error::ApiResult,
    india,
    org::{Admins, OrgMember},
    stages,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(get_overview))
}

const WEEKS: u64 = 4;

#[derive(Debug, Serialize, ToSchema)]
pub struct FinishedWeek {
    // Its first day; the last week ends today.
    pub from: NaiveDate,
    pub count: i64,
}

#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct CommissionTotals {
    pub in_review: i64,
    // Approved, waiting for the customer's advance.
    pub waiting: i64,
    pub payable: i64,
    pub paid_this_month: i64,
}

// The contract's `AdminOverview`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminOverview {
    pub today: NaiveDate,
    // Verified, not handed over.
    pub installs_running: i64,
    // Of those, how many at each stage, first to last.
    pub by_stage: Vec<i64>,
    pub collected_this_month: i64,
    // Asked for, or said paid and not confirmed.
    pub to_collect: i64,
    pub finished_by_week: Vec<FinishedWeek>,
    pub commissions: CommissionTotals,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/overview",
    operation_id = "adminGetOverview",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The totals.", body = AdminOverview),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_overview(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<Json<AdminOverview>> {
    let org = admin.org_id;
    let today = india::date(Utc::now());
    let month = today.with_day(1).unwrap_or(today);
    let first = today - Days::new(7 * WEEKS - 1);
    let mut tx = admin.begin(&state.db).await?;

    let staged: Vec<(i32, i64)> = sqlx::query_as(
        "SELECT coalesce(c.stage_index, 1), count(*)
         FROM customers c LEFT JOIN installs i ON i.customer_id = c.id
         WHERE c.org_id = $1 AND c.kyc_status = 'approved' AND i.handed_over_on IS NULL
         GROUP BY 1",
    )
    .bind(org)
    .fetch_all(&mut *tx)
    .await?;
    let (collected, to_collect): (i64, i64) = sqlx::query_as(
        "SELECT coalesce(sum(amount) FILTER (WHERE status = 'paid' AND paid_on >= $2), 0)::bigint,
                coalesce(sum(amount) FILTER (WHERE status IN ('due', 'claimed')), 0)::bigint
         FROM install_payments WHERE org_id = $1",
    )
    .bind(org)
    .bind(month)
    .fetch_one(&mut *tx)
    .await?;
    let finished: Vec<(i32, i64)> = sqlx::query_as(
        "SELECT (handed_over_on - $2::date) / 7, count(*)
         FROM installs
         WHERE org_id = $1 AND handed_over_on BETWEEN $2 AND $3
         GROUP BY 1",
    )
    .bind(org)
    .bind(first)
    .bind(today)
    .fetch_all(&mut *tx)
    .await?;
    let commissions: CommissionTotals = sqlx::query_as(
        "SELECT coalesce(sum(commission) FILTER (WHERE commission_status = 'in_review'), 0)::bigint AS in_review,
                coalesce(sum(commission) FILTER (WHERE commission_status = 'approved'), 0)::bigint AS waiting,
                coalesce(sum(commission) FILTER (WHERE commission_status = 'payable'), 0)::bigint AS payable,
                coalesce(sum(commission) FILTER (WHERE commission_status = 'paid'
                                                   AND commission_paid_on >= $2), 0)::bigint AS paid_this_month
         FROM customers WHERE org_id = $1 AND kyc_status <> 'rejected'",
    )
    .bind(org)
    .bind(month)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;

    let count_at = |rows: &[(i32, i64)], at: i32| -> i64 {
        rows.iter().filter(|r| r.0 == at).map(|r| r.1).sum()
    };
    Ok(Json(AdminOverview {
        today,
        installs_running: staged.iter().map(|r| r.1).sum(),
        by_stage: (1..=stages::COUNT)
            .map(|stage| count_at(&staged, stage))
            .collect(),
        collected_this_month: collected,
        to_collect,
        finished_by_week: (0..WEEKS)
            .map(|week| FinishedWeek {
                from: first + Days::new(7 * week),
                count: count_at(&finished, week as i32),
            })
            .collect(),
        commissions,
    }))
}
