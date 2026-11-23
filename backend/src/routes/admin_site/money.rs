/*
    Expenses, commissions and payments, for the company's admin (W4)
    --------------------------------------------------------------------
    - every state is listed: an approved expense is how one gets paid,
      a `later` payment is how the next one gets asked for
    - of a payee's bank account only `bank_last4` is read. The encrypted
      number isn't selected, so it can't leak from here
*/

use axum::{Json, extract::State};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use super::{AdminFile, ERRORS};
use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiPath, ApiQuery},
    org::{Admins, OrgMember},
    page::{Cursor, Page, PageInfo},
    routes::{
        customers::CommissionStatus,
        expenses::{ExpenseCategory, ExpenseStatus, ExpenseTask},
        install::{PaymentMethod, PaymentStatus},
    },
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_expenses))
        .routes(routes!(get_expense))
        .routes(routes!(list_commissions))
        .routes(routes!(list_payments))
}

/*
    Expenses
*/

#[derive(Debug, Deserialize, IntoParams)]
pub struct ExpenseQuery {
    status: Option<ExpenseStatus>,
    cursor: Option<String>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct ExpensePath {
    expense_id: Uuid,
}

// The contract's `AdminExpenseSummary`.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct AdminExpenseSummary {
    pub id: Uuid,
    pub reference: String,
    pub owner_name: String,
    // Paise.
    pub amount: i64,
    pub category: ExpenseCategory,
    pub note: String,
    pub spent_on: NaiveDate,
    pub status: ExpenseStatus,
    pub has_receipt: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminExpensePage {
    pub items: Vec<AdminExpenseSummary>,
    pub page: PageInfo,
}

// The contract's `AdminExpense`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminExpense {
    #[serde(flatten)]
    pub summary: AdminExpenseSummary,
    pub status_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub receipt: Option<AdminFile>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<String>,
    // The sender's note with a replaced receipt.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fix_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub task: Option<ExpenseTask>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payout_last4: Option<String>,
}

#[derive(sqlx::FromRow)]
struct ExpenseRow {
    #[sqlx(flatten)]
    summary: AdminExpenseSummary,
    status_at: DateTime<Utc>,
    admin_note: Option<String>,
    fix_note: Option<String>,
    admin_name: Option<String>,
    task_id: Option<Uuid>,
    task_title: Option<String>,
    task_customer: Option<String>,
    receipt_key: Option<String>,
    receipt_type: Option<String>,
    receipt_size: Option<i64>,
    payout_last4: Option<String>,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/expenses",
    operation_id = "adminListExpenses",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), ExpenseQuery),
    responses(
        (status = 200, description = "One page.", body = AdminExpensePage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_expenses(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<ExpenseQuery>,
) -> ApiResult<Json<AdminExpensePage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = admin.begin(&state.db).await?;
    let mut items: Vec<AdminExpenseSummary> = sqlx::query_as(
        "SELECT e.id, e.reference, o.name AS owner_name, e.amount, e.category, e.note,
                e.spent_on, e.status, e.receipt_upload_id IS NOT NULL AS has_receipt, e.created_at
         FROM expenses e JOIN users o ON o.id = e.owner_id
         WHERE e.org_id = $1
           AND ($3::expense_status IS NULL OR e.status = $3)
           AND ($4::timestamptz IS NULL OR (e.created_at, e.id) < ($4, $5))
         ORDER BY e.created_at DESC, e.id DESC LIMIT $2",
    )
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.status)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    let info = page.finish(&mut items, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    Ok(Json(AdminExpensePage { items, page: info }))
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/expenses/{expense_id}",
    operation_id = "adminGetExpense",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    responses(
        (status = 200, description = "The expense.", body = AdminExpense),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_expense(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<ExpensePath>,
) -> ApiResult<Json<AdminExpense>> {
    let mut tx = admin.begin(&state.db).await?;
    let r: ExpenseRow = sqlx::query_as(
        "SELECT e.id, e.reference, o.name AS owner_name, e.amount, e.category, e.note,
                e.spent_on, e.status, e.receipt_upload_id IS NOT NULL AS has_receipt, e.created_at,
                e.status_at, e.admin_note, e.fix_note, d.name AS admin_name,
                t.id AS task_id, t.title AS task_title, c.name AS task_customer,
                u.r2_key AS receipt_key, u.content_type AS receipt_type,
                u.size_bytes AS receipt_size, b.bank_last4 AS payout_last4
         FROM expenses e
         JOIN users o ON o.id = e.owner_id
         LEFT JOIN users d ON d.id = e.decided_by
         LEFT JOIN tasks t ON t.id = e.task_id
         LEFT JOIN customers c ON c.id = t.customer_id
         LEFT JOIN uploads u ON u.id = e.receipt_upload_id
         LEFT JOIN user_details b ON b.user_id = e.owner_id
         WHERE e.org_id = $1 AND e.id = $2",
    )
    .bind(admin.org_id)
    .bind(path.expense_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(ApiError::not_found)?;
    tx.commit().await?;

    let receipt = match (r.receipt_key, r.receipt_type, r.receipt_size) {
        (Some(key), Some(kind), Some(size)) => Some(AdminFile::sign(
            state.storage.as_ref(),
            admin.org_id,
            &key,
            kind,
            size,
        )?),
        _ => None,
    };
    let task = match (r.task_id, r.task_title, r.task_customer) {
        (Some(id), Some(title), Some(customer_name)) => Some(ExpenseTask {
            id,
            title,
            customer_name,
        }),
        _ => None,
    };
    Ok(Json(AdminExpense {
        summary: r.summary,
        status_at: r.status_at,
        receipt,
        admin_note: r.admin_note,
        fix_note: r.fix_note,
        admin_name: r.admin_name,
        task,
        payout_last4: r.payout_last4,
    }))
}

/*
    Commissions: one per customer, so the customer's id is the key
*/

#[derive(Debug, Deserialize, IntoParams)]
pub struct CommissionQuery {
    status: Option<CommissionStatus>,
    cursor: Option<String>,
    limit: Option<i64>,
}

// The contract's `AdminCommission`.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct AdminCommission {
    pub customer_id: Uuid,
    pub customer_name: String,
    pub customer_reference: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_name: Option<String>,
    // Paise: as approved, or as asked until then.
    pub amount: i64,
    // What the agent asked, when the admin changed it.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proposed_amount: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<String>,
    pub status: CommissionStatus,
    pub advance_paid: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payable_since: Option<NaiveDate>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub paid_on: Option<NaiveDate>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payout_last4: Option<String>,
    // For paging.
    #[serde(skip)]
    created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminCommissionPage {
    pub items: Vec<AdminCommission>,
    pub page: PageInfo,
}

macro_rules! select_commission {
    ($rest:literal) => {
        concat!(
            "SELECT c.id AS customer_id, c.name AS customer_name,
                    c.reference AS customer_reference, a.name AS agent_name,
                    c.commission AS amount, c.commission_proposed AS proposed_amount,
                    c.commission_note AS note, c.commission_admin_note AS admin_note,
                    c.commission_status AS status,
                    EXISTS (SELECT 1 FROM install_payments p
                            JOIN installs i ON i.id = p.install_id
                            WHERE i.customer_id = c.id AND p.position = 0
                              AND p.status = 'paid') AS advance_paid,
                    c.commission_payable_since AS payable_since,
                    c.commission_paid_on AS paid_on,
                    b.bank_last4 AS payout_last4, c.created_at
             FROM customers c
             LEFT JOIN users a ON a.id = c.registered_by
             LEFT JOIN user_details b ON b.user_id = c.registered_by
             WHERE c.org_id = $1 AND c.commission IS NOT NULL ",
            $rest
        )
    };
}

pub(super) async fn commission_of(
    conn: &mut PgConnection,
    org_id: Uuid,
    customer_id: Uuid,
) -> ApiResult<Option<AdminCommission>> {
    Ok(sqlx::query_as(select_commission!("AND c.id = $2"))
        .bind(org_id)
        .bind(customer_id)
        .fetch_optional(conn)
        .await?)
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/commissions",
    operation_id = "adminListCommissions",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), CommissionQuery),
    responses(
        (status = 200, description = "One page.", body = AdminCommissionPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_commissions(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<CommissionQuery>,
) -> ApiResult<Json<AdminCommissionPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = admin.begin(&state.db).await?;
    let mut items: Vec<AdminCommission> = sqlx::query_as(select_commission!(
        "AND c.kyc_status <> 'rejected'
         AND ($3::commission_status IS NULL OR c.commission_status = $3)
         AND ($4::timestamptz IS NULL OR (c.created_at, c.id) < ($4, $5))
         ORDER BY c.created_at DESC, c.id DESC LIMIT $2"
    ))
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.status)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    let info = page.finish(&mut items, |r| Cursor {
        created_at: r.created_at,
        id: r.customer_id,
    });
    Ok(Json(AdminCommissionPage { items, page: info }))
}

/*
    Customers' payments
*/

#[derive(Debug, Deserialize, IntoParams)]
pub struct PaymentQuery {
    status: Option<PaymentStatus>,
    cursor: Option<String>,
    limit: Option<i64>,
}

// The contract's `AdminPayment`.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct AdminPayment {
    pub id: Uuid,
    pub customer_id: Uuid,
    pub customer_name: String,
    pub customer_reference: String,
    pub label: String,
    // Paise.
    pub amount: i64,
    pub status: PaymentStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub due_on: Option<NaiveDate>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claimed_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claimed_method: Option<PaymentMethod>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub paid_on: Option<NaiveDate>,
    // For paging.
    #[serde(skip)]
    created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminPaymentPage {
    pub items: Vec<AdminPayment>,
    pub page: PageInfo,
}

macro_rules! select_payment {
    ($rest:literal) => {
        concat!(
            "SELECT p.id, c.id AS customer_id, c.name AS customer_name,
                    c.reference AS customer_reference, p.label, p.amount, p.status,
                    p.due_on, p.claimed_at, p.claimed_method, p.paid_on, p.created_at
             FROM install_payments p
             JOIN installs i ON i.id = p.install_id
             JOIN customers c ON c.id = i.customer_id
             WHERE p.org_id = $1 ",
            $rest
        )
    };
}

pub(super) async fn payments_of(
    conn: &mut PgConnection,
    org_id: Uuid,
    customer_id: Uuid,
) -> ApiResult<Vec<AdminPayment>> {
    Ok(
        sqlx::query_as(select_payment!("AND c.id = $2 ORDER BY p.position"))
            .bind(org_id)
            .bind(customer_id)
            .fetch_all(conn)
            .await?,
    )
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/payments",
    operation_id = "adminListPayments",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), PaymentQuery),
    responses(
        (status = 200, description = "One page.", body = AdminPaymentPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_payments(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<PaymentQuery>,
) -> ApiResult<Json<AdminPaymentPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = admin.begin(&state.db).await?;
    let mut items: Vec<AdminPayment> = sqlx::query_as(select_payment!(
        "AND ($3::payment_status IS NULL OR p.status = $3)
         AND ($4::timestamptz IS NULL OR (p.created_at, p.id) < ($4, $5))
         ORDER BY p.created_at DESC, p.id DESC LIMIT $2"
    ))
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.status)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    let info = page.finish(&mut items, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    Ok(Json(AdminPaymentPage { items, page: info }))
}
