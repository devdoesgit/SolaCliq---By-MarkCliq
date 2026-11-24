/*
    The company's customers, for its admin (W2)
    --------------------------------------------------------------------
    - list: newest first, searched and filtered
    - detail: what the admin checks before verifying (every file), then
      the money
    - move stage, correct the price (owner, 2026-11-22)
*/

use axum::{Json, extract::State};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use super::{
    AdminFile, AdminStage, ERRORS,
    money::{self, AdminCommission, AdminPayment},
};
use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath, ApiQuery},
    notify::{self, Kind, Links},
    org::{Admins, OrgMember},
    page::{Cursor, Page, PageInfo},
    routes::{
        admin::{Done, check_price, conflict, registration_locked},
        customers::{ConnectionType, DocumentSide, DocumentStatus, KycKind, KycStatus},
        install::{PaymentStatus, default_plan, pm_surya_ghar},
        quotes::{RoofType, rupees},
    },
    stages::{self, Stages},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_customers))
        .routes(routes!(get_customer))
        .routes(routes!(set_stage))
        .routes(routes!(set_price))
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct CustomerQuery {
    // In the name, phone, email, reference or consumer number.
    q: Option<String>,
    kyc_status: Option<KycStatus>,
    stage: Option<i32>,
    cursor: Option<String>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct CustomerPath {
    customer_id: Uuid,
}

// The contract's `AdminCustomerSummary`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminCustomerSummary {
    pub id: Uuid,
    pub reference: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    pub place: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system_kw: Option<f64>,
    pub kyc_status: KycStatus,
    // Once verified.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stage: Option<AdminStage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_name: Option<String>,
    // Where the advance is, once there's a price.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub advance_status: Option<PaymentStatus>,
    // Paise: the agent's, as it stands.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub commission_amount: Option<i64>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminCustomerPage {
    pub items: Vec<AdminCustomerSummary>,
    pub page: PageInfo,
}

#[derive(sqlx::FromRow)]
struct SummaryRow {
    id: Uuid,
    reference: String,
    name: String,
    phone: Option<String>,
    place: String,
    system_kw: Option<f64>,
    kyc_status: KycStatus,
    stage_index: Option<i32>,
    agent_name: Option<String>,
    advance_status: Option<PaymentStatus>,
    commission_amount: Option<i64>,
    created_at: DateTime<Utc>,
}

fn summary(r: SummaryRow, stages: &Stages) -> AdminCustomerSummary {
    AdminCustomerSummary {
        stage: (r.kyc_status == KycStatus::Approved)
            .then(|| AdminStage::at(r.stage_index.unwrap_or(1), stages)),
        id: r.id,
        reference: r.reference,
        name: r.name,
        phone: r.phone,
        place: r.place,
        system_kw: r.system_kw,
        kyc_status: r.kyc_status,
        agent_name: r.agent_name,
        advance_status: r.advance_status,
        commission_amount: r.commission_amount,
        created_at: r.created_at,
    }
}

// The contract's `AdminDocument`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminDocument {
    pub kind: KycKind,
    pub title: String,
    pub status: DocumentStatus,
    pub files: Vec<AdminDocumentFile>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    pub updated_at: DateTime<Utc>,
}

#[derive(sqlx::FromRow)]
struct DocumentRow {
    kind: KycKind,
    status: DocumentStatus,
    admin_note: Option<String>,
    updated_at: DateTime<Utc>,
    r2_key: String,
    content_type: String,
    size_bytes: i64,
    side: Option<DocumentSide>,
}

// The contract's `AdminDocumentFile`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminDocumentFile {
    pub file: AdminFile,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub side: Option<DocumentSide>,
}

// The contract's `AdminPrice`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminPrice {
    pub total: i64,
    pub subsidy: i64,
    // No payment is paid yet.
    pub editable: bool,
}

// The contract's `AdminCustomer`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminCustomer {
    #[serde(flatten)]
    pub summary: AdminCustomerSummary,
    #[serde(flatten)]
    pub registration: Registration,
    // PM Surya Ghar's figure for the size, when they asked for it.
    pub suggested_subsidy: i64,
    pub documents: Vec<AdminDocument>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub price: Option<AdminPrice>,
    pub payments: Vec<AdminPayment>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub commission: Option<AdminCommission>,
}

// What the agent entered, and how it ended.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct Registration {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    pub address: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub city: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pin_code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub state: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub discom: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub consumer_number: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sanctioned_load_kw: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub connection_type: Option<ConnectionType>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub roof: Option<RoofType>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lng: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subsidy_requested: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub consent_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rejected_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub handed_over_on: Option<NaiveDate>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct StageSet {
    // 1 to 7.
    pub stage_index: i32,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct PriceSet {
    // Paise.
    pub total: i64,
    pub subsidy: i64,
}

macro_rules! select_summary {
    ($rest:literal) => {
        concat!(
            "SELECT c.id, c.reference, c.name, c.phone, coalesce(c.city, c.address) AS place,
                    c.system_kw, c.kyc_status, c.stage_index, a.name AS agent_name, c.created_at,
                    c.commission AS commission_amount,
                    (SELECT p.status FROM install_payments p
                     JOIN installs i ON i.id = p.install_id
                     WHERE i.customer_id = c.id AND p.position = 0) AS advance_status
             FROM customers c LEFT JOIN users a ON a.id = c.registered_by ",
            $rest
        )
    };
}

/*
    `q` is matched as typed (strpos, not LIKE: no wildcards to escape)
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/customers",
    operation_id = "adminListCustomers",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), CustomerQuery),
    responses(
        (status = 200, description = "One page.", body = AdminCustomerPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_customers(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<CustomerQuery>,
) -> ApiResult<Json<AdminCustomerPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let search = q.q.as_deref().map(str::trim).filter(|s| !s.is_empty());
    let mut tx = admin.begin(&state.db).await?;
    let mut rows: Vec<SummaryRow> = sqlx::query_as(select_summary!(
        "WHERE c.org_id = $1
           AND ($3::kyc_status IS NULL OR c.kyc_status = $3)
           AND ($4::int IS NULL
                OR (c.kyc_status = 'approved' AND coalesce(c.stage_index, 1) = $4))
           AND ($5::text IS NULL
                OR strpos(lower(concat_ws(chr(10), c.name, c.phone, c.email, c.reference,
                                          c.consumer_number)), lower($5)) > 0)
           AND ($6::timestamptz IS NULL OR (c.created_at, c.id) < ($6, $7))
         ORDER BY c.created_at DESC, c.id DESC LIMIT $2"
    ))
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.kyc_status)
    .bind(q.stage)
    .bind(search)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;

    let info = page.finish(&mut rows, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    Ok(Json(AdminCustomerPage {
        items: rows.into_iter().map(|r| summary(r, &stages)).collect(),
        page: info,
    }))
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/customers/{customer_id}",
    operation_id = "adminGetCustomer",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    responses(
        (status = 200, description = "The customer.", body = AdminCustomer),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_customer(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
) -> ApiResult<Json<AdminCustomer>> {
    let (org_id, id) = (admin.org_id, path.customer_id);
    let mut tx = admin.begin(&state.db).await?;
    let row_summary: SummaryRow =
        sqlx::query_as(select_summary!("WHERE c.org_id = $1 AND c.id = $2"))
            .bind(org_id)
            .bind(id)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or_else(ApiError::not_found)?;
    let registration: Registration = sqlx::query_as(
        "SELECT c.email, c.address, c.city, c.pin_code, c.state, c.discom, c.consumer_number,
                c.sanctioned_load_kw, c.connection_type, c.roof, c.lat, c.lng,
                c.subsidy AS subsidy_requested, c.consent_at, c.rejected_note, i.handed_over_on
         FROM customers c LEFT JOIN installs i ON i.customer_id = c.id
         WHERE c.org_id = $1 AND c.id = $2",
    )
    .bind(org_id)
    .bind(id)
    .fetch_one(&mut *tx)
    .await?;
    let files: Vec<DocumentRow> = sqlx::query_as(
        "SELECT d.kind, d.status, d.admin_note, d.updated_at,
                u.r2_key, u.content_type, u.size_bytes, f.side
         FROM documents d
         JOIN document_files f ON f.document_id = d.id AND f.replaced_at IS NULL
         JOIN uploads u ON u.id = f.upload_id
         WHERE d.org_id = $1 AND d.customer_id = $2
         ORDER BY d.kind, f.position",
    )
    .bind(org_id)
    .bind(id)
    .fetch_all(&mut *tx)
    .await?;
    let price: Option<(i64, i64)> = sqlx::query_as(
        "SELECT total, subsidy FROM installs WHERE org_id = $1 AND customer_id = $2",
    )
    .bind(org_id)
    .bind(id)
    .fetch_optional(&mut *tx)
    .await?;
    let payments = money::payments_of(&mut tx, org_id, id).await?;
    let commission = money::commission_of(&mut tx, org_id, id).await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;

    let suggested_subsidy = match (registration.subsidy_requested, row_summary.system_kw) {
        (Some(true), Some(kw)) => pm_surya_ghar(kw),
        _ => 0,
    };
    let mut documents: Vec<AdminDocument> = Vec::new();
    for d in files {
        let file = AdminDocumentFile {
            file: AdminFile::sign(
                state.storage.as_ref(),
                org_id,
                &d.r2_key,
                d.content_type,
                d.size_bytes,
            )?,
            side: d.side,
        };
        // Sorted by kind, so a document's files follow each other.
        match documents.last_mut() {
            Some(last) if last.kind == d.kind => last.files.push(file),
            _ => documents.push(AdminDocument {
                kind: d.kind,
                title: d.kind.label().to_owned(),
                status: d.status,
                // The reason matters only while it's being fixed.
                note: d
                    .admin_note
                    .filter(|_| d.status == DocumentStatus::NeedsFix),
                updated_at: d.updated_at,
                files: vec![file],
            }),
        }
    }
    let editable = payments.iter().all(|p| p.status != PaymentStatus::Paid);
    Ok(Json(AdminCustomer {
        summary: summary(row_summary, &stages),
        registration,
        suggested_subsidy,
        documents,
        price: price.map(|(total, subsidy)| AdminPrice {
            total,
            subsidy,
            editable,
        }),
        payments,
        commission,
    }))
}

/*
    Move stage: either way, as a correction or a step that needed no
    installer. Not after handover, which is the last word
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/admin/customers/{customer_id}/stage",
    operation_id = "adminSetCustomerStage",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    request_body = StageSet,
    responses(
        (status = 200, description = "Moved.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn set_stage(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
    ApiJson(req): ApiJson<StageSet>,
) -> ApiResult<Json<Done>> {
    let count = stages::COUNT;
    if !(1..=count).contains(&req.stage_index) {
        return Err(ApiError::validation(Vec::new()).field("stage_index", format!("1 to {count}.")));
    }
    let mut tx = admin.begin(&state.db).await?;
    let status: KycStatus = sqlx::query_scalar(
        "SELECT kyc_status FROM customers WHERE org_id = $1 AND id = $2 FOR UPDATE",
    )
    .bind(admin.org_id)
    .bind(path.customer_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(ApiError::not_found)?;
    // Read after the lock, which handover takes first as well.
    let handed_over: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM installs
                        WHERE org_id = $1 AND customer_id = $2 AND handed_over_on IS NOT NULL)",
    )
    .bind(admin.org_id)
    .bind(path.customer_id)
    .fetch_one(&mut *tx)
    .await?;
    if status != KycStatus::Approved || handed_over {
        return Err(registration_locked());
    }
    sqlx::query("UPDATE customers SET stage_index = $3 WHERE org_id = $1 AND id = $2")
        .bind(admin.org_id)
        .bind(path.customer_id)
        .bind(req.stage_index)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, customer_id = %path.customer_id,
                   by = %admin.user_id, stage = req.stage_index, "stage moved");
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

/*
    Correct the price (owner: until the advance is paid)
    --------------------------------------------------------------------
    - no payment paid yet, else 409 `price.locked`: a paid amount is a
      record of money that moved
    - the parts are worked out again with the default plan
    - a claimed payment goes back to due: the claim was for another
      amount, and confirming it would record money nobody sent
    - the payments are locked before anything is read, as confirming
      one does, so the two can't cross
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/admin/customers/{customer_id}/price",
    operation_id = "adminSetCustomerPrice",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    request_body = PriceSet,
    responses(
        (status = 200, description = "Changed.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn set_price(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
    ApiJson(req): ApiJson<PriceSet>,
) -> ApiResult<Json<Done>> {
    check_price(req.total, Some(req.subsidy))?;
    let mut tx = admin.begin(&state.db).await?;
    let customer: Option<Uuid> =
        sqlx::query_scalar("SELECT user_id FROM customers WHERE org_id = $1 AND id = $2")
            .bind(admin.org_id)
            .bind(path.customer_id)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or_else(ApiError::not_found)?;
    let parts: Vec<(Uuid, i64, PaymentStatus, Option<NaiveDate>)> = sqlx::query_as(
        "SELECT p.id, p.amount, p.status, p.due_on
         FROM install_payments p JOIN installs i ON i.id = p.install_id
         WHERE p.org_id = $1 AND i.customer_id = $2
         ORDER BY p.position FOR UPDATE OF p",
    )
    .bind(admin.org_id)
    .bind(path.customer_id)
    .fetch_all(&mut *tx)
    .await?;
    let plan = default_plan(req.total);
    // No install, another plan, or money already in.
    if parts.len() != plan.len() || parts.iter().any(|p| p.2 == PaymentStatus::Paid) {
        return Err(conflict("price.locked", "The price can't be changed now"));
    }

    sqlx::query(
        "UPDATE installs SET total = $3, subsidy = $4 WHERE org_id = $1 AND customer_id = $2",
    )
    .bind(admin.org_id)
    .bind(path.customer_id)
    .bind(req.total)
    .bind(req.subsidy)
    .execute(&mut *tx)
    .await?;
    for ((id, old, status, due_on), (_, _, amount)) in parts.into_iter().zip(plan) {
        sqlx::query(
            "UPDATE install_payments
             SET amount = $2,
                 status = CASE WHEN status = 'claimed' THEN 'due' ELSE status END,
                 claimed_at = NULL, claimed_method = NULL
             WHERE id = $1",
        )
        .bind(id)
        .bind(amount)
        .execute(&mut *tx)
        .await?;
        let asked = matches!(status, PaymentStatus::Due | PaymentStatus::Claimed);
        if let (Some(user), true, true) = (customer, asked, old != amount) {
            let amount = rupees(amount);
            let body = match due_on {
                Some(day) => format!("{amount} by {}", day.format("%-d %b")),
                None => amount,
            };
            notify::add(
                &mut tx,
                admin.org_id,
                user,
                Kind::PaymentDue,
                "Amount changed",
                &body,
                Links::default(),
            )
            .await?;
        }
    }
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, customer_id = %path.customer_id,
                   by = %admin.user_id, "price changed");
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}
