/*
    A customer's own install (phase 10, F9, #43–44)
    --------------------------------------------------------------------
    - GET  /orgs/{org_id}/my-install                                where it stands
    - POST /orgs/{org_id}/my-install/payments/{payment_id}/claim    (idem) "I paid"
    - customers only (`OrgMember<Customers>`), their own install: the
      customer record their account is linked to (phase 9)
    - 404 `install.not_started` until the company has set it up
    - money never passes through the app: the customer pays by UPI or
      bank transfer, then claims; the company confirms on the website
    - the customer's home is built from the same `load` (home.rs)
    - spec: docs/features/F9-customer-install.md
*/

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath},
    idempotency::{self, IdempotencyKey},
    india,
    org::{Customers, OrgMember},
    stages,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(get_my_install))
        .routes(routes!(claim_install_payment))
}

/*
    PM Surya Ghar, the government's rooftop subsidy for homes, in paise:
    ₹30,000 per kW for the first 2 kW, ₹18,000 for the 3rd, ₹78,000 at
    most. The admin can change an install's figure (the website)
*/
pub fn pm_surya_ghar(kw: f64) -> i64 {
    let rupees = if kw <= 0.0 {
        0.0
    } else if kw <= 2.0 {
        30_000.0 * kw
    } else if kw <= 3.0 {
        60_000.0 + 18_000.0 * (kw - 2.0)
    } else {
        78_000.0
    };
    (rupees * 100.0).round() as i64
}

/*
    The default payment plan (provisional until the pilot vendor says):
    advance 30%, on installation 60%, on handover 10%. Whole rupees; the
    handover part takes what rounding leaves, so the parts add up to the
    total exactly. (label, when it falls due, paise)
*/
pub fn default_plan(total: i64) -> [(&'static str, &'static str, i64); 3] {
    let rupees = |share: i64| (total * share / 100) / 100 * 100;
    let advance = rupees(30);
    let installation = rupees(60);
    [
        ("Advance, 30%", "Before the survey", advance),
        (
            "On installation, 60%",
            "After panels are fixed",
            installation,
        ),
        (
            "On handover, 10%",
            "After net meter",
            total - advance - installation,
        ),
    ]
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "payment_status", rename_all = "snake_case")]
pub enum PaymentStatus {
    Due,
    // The customer says they paid; the company confirms.
    Claimed,
    Paid,
    // Not due yet.
    Later,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "payment_method", rename_all = "snake_case")]
pub enum PaymentMethod {
    Upi,
    BankTransfer,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum StageStatus {
    Done,
    Next,
    Upcoming,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct InstallStage {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
    pub status: StageStatus,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct InstallPayment {
    pub id: Uuid,
    pub label: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
    // Paise.
    pub amount: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub due_on: Option<NaiveDate>,
    pub status: PaymentStatus,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct VisitPerson {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct NextVisit {
    pub title: String,
    pub starts_at: DateTime<Utc>,
    pub person: VisitPerson,
}

// The contract's `Install`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Install {
    pub system_kw: f64,
    pub place: String,
    pub stage_index: i32,
    pub stage_count: i32,
    // Paise.
    pub total: i64,
    // PM Surya Ghar, paise.
    pub subsidy: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub handed_over_on: Option<NaiveDate>,
    // Pays the due payment through any UPI app.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub upi_uri: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_visit: Option<NextVisit>,
    pub stages: Vec<InstallStage>,
    pub payments: Vec<InstallPayment>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct PaymentClaim {
    pub method: PaymentMethod,
}

#[derive(Debug, Deserialize)]
struct PaymentPath {
    payment_id: Uuid,
}

fn not_started() -> ApiError {
    ApiError::new(
        StatusCode::NOT_FOUND,
        "install.not_started",
        "Your install is being set up",
    )
}

fn not_due() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "payment.not_due",
        "This payment isn't due",
    )
}

// "31 Oct".
fn day(d: NaiveDate) -> String {
    d.format("%-d %b").to_string()
}

/*
    Percent-encodes a UPI link's value (RFC 3986 unreserved kept), so a
    company name with spaces or "&" can't break the link
*/
fn encode(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' | b'@' => {
                (b as char).to_string()
            }
            _ => format!("%{b:02X}"),
        })
        .collect()
}

/*
    The standard UPI deep link: payee address, payee name, amount in
    rupees with paise, currency, and a note the company sees
*/
fn upi_uri(upi_id: &str, org_name: &str, paise: i64, note: &str) -> String {
    format!(
        "upi://pay?pa={}&pn={}&am={}.{:02}&cu=INR&tn={}",
        encode(upi_id),
        encode(org_name),
        paise / 100,
        paise % 100,
        encode(note)
    )
}

#[derive(sqlx::FromRow)]
struct InstallRow {
    install_id: Uuid,
    system_kw: Option<f64>,
    place: String,
    stage_index: Option<i32>,
    total: i64,
    subsidy: i64,
    handed_over_on: Option<NaiveDate>,
    org_name: String,
    upi_id: Option<String>,
    customer_id: Uuid,
}

#[derive(sqlx::FromRow)]
struct PaymentRow {
    id: Uuid,
    label: String,
    detail: Option<String>,
    amount: i64,
    due_on: Option<NaiveDate>,
    status: PaymentStatus,
    claimed_at: Option<DateTime<Utc>>,
    paid_on: Option<NaiveDate>,
}

#[derive(sqlx::FromRow)]
struct VisitRow {
    title: String,
    due_at: DateTime<Utc>,
    worker: String,
    phone: Option<String>,
}

/*
    The caller's install in this company, whole; None before the company
    has set it up. Runs in the company's transaction
*/
pub async fn load(conn: &mut PgConnection, user_id: Uuid) -> ApiResult<Option<Install>> {
    let row: Option<InstallRow> = sqlx::query_as(
        "SELECT i.id AS install_id, c.system_kw, coalesce(c.city, c.address) AS place,
                c.stage_index, i.total, i.subsidy, i.handed_over_on,
                o.name AS org_name, o.upi_id, c.id AS customer_id
         FROM customers c
         JOIN installs i ON i.customer_id = c.id
         JOIN orgs o ON o.id = c.org_id
         WHERE c.user_id = $1
         ORDER BY c.created_at DESC LIMIT 1",
    )
    .bind(user_id)
    .fetch_optional(&mut *conn)
    .await?;
    let Some(i) = row else {
        return Ok(None);
    };

    let rows: Vec<PaymentRow> = sqlx::query_as(
        "SELECT id, label, detail, amount, due_on, status, claimed_at, paid_on
         FROM install_payments WHERE install_id = $1 ORDER BY position",
    )
    .bind(i.install_id)
    .fetch_all(&mut *conn)
    .await?;
    let visit: Option<VisitRow> = sqlx::query_as(
        "SELECT t.title, t.due_at, u.name AS worker, u.phone
         FROM tasks t JOIN users u ON u.id = t.assignee_id
         WHERE t.customer_id = $1 AND t.status IN ('assigned', 'returned')
         ORDER BY t.due_at LIMIT 1",
    )
    .bind(i.customer_id)
    .fetch_optional(&mut *conn)
    .await?;

    let names = stages::load(&mut *conn).await?;
    let count = stages::COUNT;
    let handed_over = i.handed_over_on.is_some();
    let current = if handed_over {
        count
    } else {
        i.stage_index.unwrap_or(1).clamp(1, count)
    };
    let visit_line = visit.as_ref().map(|v| {
        let at = v.due_at.with_timezone(&india::offset());
        let first = v.worker.split_whitespace().next().unwrap_or(&v.worker);
        format!("{} · {first}", at.format("%a %-d %b, %H:%M"))
    });
    let stages = names
        .names()
        .into_iter()
        .enumerate()
        .map(|(n, name)| {
            let index = n as i32 + 1;
            let status = if handed_over || index < current {
                StageStatus::Done
            } else if index == current {
                StageStatus::Next
            } else {
                StageStatus::Upcoming
            };
            let detail = match (status, index == count) {
                (StageStatus::Done, true) => i.handed_over_on.map(day),
                (StageStatus::Next, _) => visit_line.clone(),
                _ => None,
            };
            InstallStage {
                name,
                detail,
                status,
            }
        })
        .collect();

    let payments: Vec<InstallPayment> = rows
        .into_iter()
        .map(|p| InstallPayment {
            detail: match p.status {
                PaymentStatus::Due => p.due_on.map(|d| format!("Due {}", day(d))),
                PaymentStatus::Claimed => p.claimed_at.map(|at| {
                    format!(
                        "Sent {}, the company confirms",
                        day(at.with_timezone(&india::offset()).date_naive())
                    )
                }),
                PaymentStatus::Paid => p.paid_on.map(|d| format!("Paid {}", day(d))),
                PaymentStatus::Later => p.detail,
            },
            id: p.id,
            label: p.label,
            amount: p.amount,
            due_on: p.due_on,
            status: p.status,
        })
        .collect();

    let upi = match (
        &i.upi_id,
        payments.iter().find(|p| p.status == PaymentStatus::Due),
    ) {
        (Some(upi_id), Some(due)) => Some(upi_uri(upi_id, &i.org_name, due.amount, &due.label)),
        _ => None,
    };

    Ok(Some(Install {
        system_kw: i.system_kw.unwrap_or(0.0),
        place: i.place,
        stage_index: current,
        stage_count: count,
        total: i.total,
        subsidy: i.subsidy,
        handed_over_on: i.handed_over_on,
        upi_uri: upi,
        next_visit: visit.map(|v| NextVisit {
            title: v.title,
            starts_at: v.due_at,
            person: VisitPerson {
                name: v.worker,
                phone: v.phone,
            },
        }),
        stages,
        payments,
    }))
}

/*
    #43 The caller's install
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/my-install",
    operation_id = "getMyInstall",
    tag = "install",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The install.", body = Install),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_my_install(
    State(state): State<AppState>,
    member: OrgMember<Customers>,
) -> ApiResult<Json<Install>> {
    let mut tx = member.begin(&state.db).await?;
    let install = load(&mut tx, member.user_id).await?;
    tx.commit().await?;
    install.map(Json).ok_or_else(not_started)
}

/*
    #44 "I paid"
    --------------------------------------------------------------------
    - after paying by UPI or bank transfer, outside the app
    - only a `due` payment of the caller's own install (409
      `payment.not_due`; 404 for anyone else's)
    - → `claimed`; the company confirms it on the website
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/my-install/payments/{payment_id}/claim",
    operation_id = "claimInstallPayment",
    tag = "install",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("payment_id" = Uuid, Path, description = "The payment."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = PaymentClaim,
    responses(
        (status = 200, description = "The install, with the payment claimed.", body = Install),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn claim_install_payment(
    State(state): State<AppState>,
    member: OrgMember<Customers>,
    key: IdempotencyKey,
    ApiPath(path): ApiPath<PaymentPath>,
    ApiJson(req): ApiJson<PaymentClaim>,
) -> ApiResult<Response> {
    let request = format!(
        "POST /api/v1/orgs/{}/my-install/payments/{}/claim",
        member.org_id, path.payment_id
    );
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let mut tx = member.begin(&state.db).await?;
    let status: PaymentStatus = sqlx::query_scalar(
        "SELECT p.status FROM install_payments p
         JOIN installs i ON i.id = p.install_id
         JOIN customers c ON c.id = i.customer_id
         WHERE p.id = $1 AND c.user_id = $2
         FOR UPDATE OF p",
    )
    .bind(path.payment_id)
    .bind(member.user_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(ApiError::not_found)?;
    if status != PaymentStatus::Due {
        return Err(not_due());
    }
    sqlx::query(
        "UPDATE install_payments
         SET status = 'claimed', claimed_at = now(), claimed_method = $2
         WHERE id = $1",
    )
    .bind(path.payment_id)
    .bind(req.method)
    .execute(&mut *tx)
    .await?;

    let (customer_id, about): (Uuid, String) = sqlx::query_as(
        "SELECT c.id, c.name || ' · ' || p.label
         FROM install_payments p JOIN installs i ON i.id = p.install_id
         JOIN customers c ON c.id = i.customer_id
         WHERE p.id = $1",
    )
    .bind(path.payment_id)
    .fetch_one(&mut *tx)
    .await?;
    crate::notify::add_for_admins(
        &mut tx,
        member.org_id,
        crate::notify::Kind::PaymentClaimed,
        "Payment to confirm",
        &about,
        crate::notify::Links {
            customer_id: Some(customer_id),
            ..Default::default()
        },
    )
    .await?;

    let install = load(&mut tx, member.user_id)
        .await?
        .ok_or_else(ApiError::internal)?;
    let body = serde_json::to_value(&install).map_err(|_| ApiError::internal())?;
    if !idempotency::save(
        &mut tx,
        member.user_id,
        key,
        &request,
        StatusCode::OK,
        &body,
    )
    .await?
    {
        drop(tx);
        return idempotency::replay(&state.db, member.user_id, key, &request)
            .await?
            .ok_or_else(ApiError::internal);
    }
    tx.commit().await?;
    tracing::info!(org_id = %member.org_id, payment_id = %path.payment_id, method = ?req.method, "payment claimed");
    Ok((StatusCode::OK, Json(body)).into_response())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn subsidy_follows_the_government_table() {
        assert_eq!(pm_surya_ghar(1.0), 3_000_000);
        assert_eq!(pm_surya_ghar(2.0), 6_000_000);
        assert_eq!(pm_surya_ghar(2.5), 6_900_000);
        assert_eq!(pm_surya_ghar(3.0), 7_800_000);
        assert_eq!(pm_surya_ghar(10.0), 7_800_000, "capped");
        assert_eq!(pm_surya_ghar(0.0), 0);
    }

    #[test]
    fn the_plan_adds_up_to_the_total() {
        // ₹2,85,000: ₹85,500 + ₹1,71,000 + ₹28,500.
        let plan = default_plan(28_500_000);
        assert_eq!(plan.map(|(_, _, p)| p), [8_550_000, 17_100_000, 2_850_000]);
        // An odd total: rounding goes to the last part, nothing is lost.
        let plan = default_plan(28_500_150);
        assert_eq!(plan.iter().map(|(_, _, p)| p).sum::<i64>(), 28_500_150);
        assert!(plan.iter().all(|(_, _, p)| *p > 0));
    }

    #[test]
    fn the_upi_link_is_encoded() {
        assert_eq!(
            upi_uri(
                "examplesolar@okhdfc",
                "Example Solar & Co",
                8_550_050,
                "Advance, 30%"
            ),
            "upi://pay?pa=examplesolar@okhdfc&pn=Example%20Solar%20%26%20Co&am=85500.50&cu=INR&tn=Advance%2C%2030%25"
        );
    }
}
