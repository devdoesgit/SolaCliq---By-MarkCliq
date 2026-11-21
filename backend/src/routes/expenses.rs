/*
    A worker's or agent's own expenses (phase 8, F7, #34–37)
    --------------------------------------------------------------------
    - GET  /orgs/{org_id}/expenses                         theirs, newest first
    - POST /orgs/{org_id}/expenses               (idem)    log one
    - GET  /orgs/{org_id}/expenses/{expense_id}            one of theirs
    - PUT  /orgs/{org_id}/expenses/{expense_id}/receipt    a new receipt
    - workers and agents (`OrgMember<WorkersAndAgents>`), and only their
      own expenses: someone else's is 404
    - status: in_review → approved → paid, or needs_fix (the admin's
      note) → a new receipt → in_review. The admin's side (approve, send
      back, mark paid) comes with the admin website; the seed writes
      examples of each meanwhile
    - a receipt is an upload of this company (purpose `receipt`),
      checked in R2 before it's attached (`uploads::attach`)
*/

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, Duration, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, counter,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath, ApiQuery},
    idempotency::{self, IdempotencyKey},
    india,
    org::{OrgMember, WorkersAndAgents},
    page::{Cursor, Page, PageInfo},
    routes::uploads::{self, UploadPurpose},
    storage::Storage,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_my_expenses, create_expense))
        .routes(routes!(get_expense))
        .routes(routes!(replace_expense_receipt))
}

// Up to ₹10 lakh, in paise: a bigger amount is a typo.
const MAX_AMOUNT: i64 = 100_000_000;
const MAX_NOTE: usize = 200;
// How far back a day may be: older costs go to the admin directly.
const OLDEST_DAYS: i64 = 365;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "expense_category", rename_all = "snake_case")]
pub enum ExpenseCategory {
    Fuel,
    Material,
    Labour,
    Other,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "expense_status", rename_all = "snake_case")]
pub enum ExpenseStatus {
    InReview,
    Approved,
    NeedsFix,
    // Approved and paid out (with salary or cash).
    Paid,
}

// The contract's `TaskRef`: the task an expense was for.
#[derive(Debug, Serialize, ToSchema)]
pub struct ExpenseTask {
    pub id: Uuid,
    pub title: String,
    pub customer_name: String,
}

// The contract's `Expense`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Expense {
    pub id: Uuid,
    pub reference: String,
    // Paise.
    pub amount: i64,
    pub category: ExpenseCategory,
    pub note: String,
    // YYYY-MM-DD.
    pub spent_on: NaiveDate,
    pub status: ExpenseStatus,
    pub has_receipt: bool,
    // Why it needs a fix.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<String>,
    // Who decided, once someone has.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub task: Option<ExpenseTask>,
    // Works for 15 minutes.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub receipt_url: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ExpensePage {
    pub items: Vec<Expense>,
    pub page: PageInfo,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ExpenseCreate {
    // Paise, 1 to 100000000 (₹10 lakh).
    pub amount: i64,
    pub category: ExpenseCategory,
    // Up to 200 characters.
    pub note: String,
    // YYYY-MM-DD: not in the future, not over a year ago.
    pub spent_on: NaiveDate,
    pub receipt_upload_id: Option<Uuid>,
    // The caller's own task it was spent on.
    pub task_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ReceiptReplace {
    pub upload_id: Uuid,
    // Up to 200 characters, for the admin.
    pub note: Option<String>,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct ExpenseListQuery {
    // Opaque cursor from the previous page's `next_cursor`.
    pub cursor: Option<String>,
    // Page size, 1 to 100; 25 when left out.
    pub limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct ExpensePath {
    expense_id: Uuid,
}

// An expense that isn't waiting for a new receipt.
fn not_returned() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "expense.locked",
        "Only an expense sent back for a fix takes a new receipt",
    )
}

// Trimmed, up to 200 characters.
fn note(field: &str, value: &str) -> ApiResult<String> {
    let value = value.trim();
    if value.chars().count() > MAX_NOTE {
        return Err(
            ApiError::validation(Vec::new()).field(field, format!("Up to {MAX_NOTE} characters."))
        );
    }
    Ok(value.to_owned())
}

// The request's own checks, before any database work.
fn check(req: &ExpenseCreate, today: NaiveDate) -> ApiResult<String> {
    let mut errors = ApiError::validation(Vec::new());
    let mut bad = false;
    if !(1..=MAX_AMOUNT).contains(&req.amount) {
        errors = errors.field("amount", "₹0.01 to ₹10,00,000.");
        bad = true;
    }
    if req.spent_on > today {
        errors = errors.field("spent_on", "Not a day in the future.");
        bad = true;
    } else if req.spent_on < today - Duration::days(OLDEST_DAYS) {
        errors = errors.field("spent_on", "Within the last year.");
        bad = true;
    }
    if bad {
        return Err(errors);
    }
    note("note", &req.note)
}

macro_rules! select_expense {
    ($rest:literal) => {
        concat!(
            "SELECT e.id, e.reference, e.amount, e.category, e.note, e.spent_on, e.status,
                    e.admin_note, d.name AS admin_name, e.created_at,
                    t.id AS task_id, t.title AS task_title, c.name AS task_customer,
                    u.r2_key AS receipt_key
             FROM expenses e
             LEFT JOIN users d ON d.id = e.decided_by
             LEFT JOIN tasks t ON t.id = e.task_id
             LEFT JOIN customers c ON c.id = t.customer_id
             LEFT JOIN uploads u ON u.id = e.receipt_upload_id ",
            $rest
        )
    };
}

#[derive(sqlx::FromRow)]
struct Row {
    id: Uuid,
    reference: String,
    amount: i64,
    category: ExpenseCategory,
    note: String,
    spent_on: NaiveDate,
    status: ExpenseStatus,
    admin_note: Option<String>,
    admin_name: Option<String>,
    created_at: DateTime<Utc>,
    task_id: Option<Uuid>,
    task_title: Option<String>,
    task_customer: Option<String>,
    receipt_key: Option<String>,
}

impl Row {
    fn into_expense(self, storage: Option<&Storage>, org_id: Uuid) -> ApiResult<Expense> {
        let receipt_url = self
            .receipt_key
            .as_deref()
            .map(|key| uploads::read_url(storage, org_id, key))
            .transpose()?;
        Ok(Expense {
            id: self.id,
            reference: self.reference,
            amount: self.amount,
            category: self.category,
            note: self.note,
            spent_on: self.spent_on,
            status: self.status,
            has_receipt: receipt_url.is_some(),
            // The admin's reason matters only while it's being fixed.
            admin_note: self
                .admin_note
                .filter(|_| self.status == ExpenseStatus::NeedsFix),
            admin_name: self.admin_name,
            task: match (self.task_id, self.task_title, self.task_customer) {
                (Some(id), Some(title), Some(customer_name)) => Some(ExpenseTask {
                    id,
                    title,
                    customer_name,
                }),
                _ => None,
            },
            receipt_url,
        })
    }
}

// One of the caller's expenses; 404 when it isn't theirs.
async fn load(
    conn: &mut PgConnection,
    storage: Option<&Storage>,
    member: &OrgMember<WorkersAndAgents>,
    expense_id: Uuid,
) -> ApiResult<Expense> {
    let row: Row = sqlx::query_as(select_expense!("WHERE e.id = $1 AND e.owner_id = $2"))
        .bind(expense_id)
        .bind(member.user_id)
        .fetch_optional(&mut *conn)
        .await?
        .ok_or_else(ApiError::not_found)?;
    row.into_expense(storage, member.org_id)
}

/*
    #34 The caller's expenses, newest first
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/expenses",
    operation_id = "listMyExpenses",
    tag = "expenses",
    params(("org_id" = Uuid, Path, description = "The company."), ExpenseListQuery),
    responses(
        (status = 200, description = "One page.", body = ExpensePage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_my_expenses(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    ApiQuery(q): ApiQuery<ExpenseListQuery>,
) -> ApiResult<Json<ExpensePage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = member.begin(&state.db).await?;
    let mut rows: Vec<Row> = sqlx::query_as(select_expense!(
        "WHERE e.owner_id = $1
           AND ($3::timestamptz IS NULL OR (e.created_at, e.id) < ($3, $4))
         ORDER BY e.created_at DESC, e.id DESC LIMIT $2"
    ))
    .bind(member.user_id)
    .bind(page.fetch())
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

    let info = page.finish(&mut rows, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    let items = rows
        .into_iter()
        .map(|r| r.into_expense(state.storage.as_ref(), member.org_id))
        .collect::<ApiResult<_>>()?;
    Ok(Json(ExpensePage { items, page: info }))
}

/*
    #35 Log an expense
    --------------------------------------------------------------------
    - amount in paise (1 to ₹10 lakh), a category, a note (may be empty),
      the day (India; not in the future, not over a year ago)
    - optional receipt: an upload of this company, checked in R2
    - optional task: one of the caller's own tasks here, else 422
    - numbered EXP-0001 per company; goes to the admin as `in_review`
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/expenses",
    operation_id = "createExpense",
    tag = "expenses",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = ExpenseCreate,
    responses(
        (status = 201, description = "Sent.", body = Expense),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn create_expense(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<ExpenseCreate>,
) -> ApiResult<Response> {
    let request = format!("POST /api/v1/orgs/{}/expenses", member.org_id);
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let note = check(&req, india::date(Utc::now()))?;

    let mut tx = member.begin(&state.db).await?;
    if let Some(task_id) = req.task_id {
        let mine: bool = sqlx::query_scalar(
            "SELECT EXISTS (SELECT 1 FROM tasks WHERE id = $1 AND assignee_id = $2)",
        )
        .bind(task_id)
        .bind(member.user_id)
        .fetch_one(&mut *tx)
        .await?;
        if !mine {
            return Err(ApiError::validation(Vec::new()).field("task_id", "Not one of your tasks."));
        }
    }
    if let Some(upload_id) = req.receipt_upload_id {
        uploads::attach(
            &mut tx,
            state.storage.as_ref(),
            member.org_id,
            member.user_id,
            upload_id,
            UploadPurpose::Receipt,
            "receipt_upload_id",
        )
        .await?;
    }

    let id = Uuid::now_v7();
    let reference = counter::next(&mut tx, member.org_id, "EXP").await?;
    sqlx::query(
        "INSERT INTO expenses (id, org_id, reference, owner_id, amount, category, note,
                               spent_on, receipt_upload_id, task_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
    )
    .bind(id)
    .bind(member.org_id)
    .bind(&reference)
    .bind(member.user_id)
    .bind(req.amount)
    .bind(req.category)
    .bind(&note)
    .bind(req.spent_on)
    .bind(req.receipt_upload_id)
    .bind(req.task_id)
    .execute(&mut *tx)
    .await?;

    let expense = load(&mut tx, state.storage.as_ref(), &member, id).await?;
    let body = serde_json::to_value(&expense).map_err(|_| ApiError::internal())?;
    if !idempotency::save(
        &mut tx,
        member.user_id,
        key,
        &request,
        StatusCode::CREATED,
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
    Ok((StatusCode::CREATED, Json(body)).into_response())
}

/*
    #36 One of the caller's expenses
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/expenses/{expense_id}",
    operation_id = "getExpense",
    tag = "expenses",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    responses(
        (status = 200, description = "The expense.", body = Expense),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_expense(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    ApiPath(path): ApiPath<ExpensePath>,
) -> ApiResult<Json<Expense>> {
    let mut tx = member.begin(&state.db).await?;
    let expense = load(&mut tx, state.storage.as_ref(), &member, path.expense_id).await?;
    tx.commit().await?;
    Ok(Json(expense))
}

/*
    #37 A new receipt for an expense sent back
    --------------------------------------------------------------------
    - only while `needs_fix` (409 `expense.locked` otherwise); goes back
      to the admin as `in_review`
    - the earlier receipt stays in R2 with its upload, as a record of
      what was sent; the note goes to the admin with it
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/expenses/{expense_id}/receipt",
    operation_id = "replaceExpenseReceipt",
    tag = "expenses",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    request_body = ReceiptReplace,
    responses(
        (status = 200, description = "Back with the admin.", body = Expense),
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
async fn replace_expense_receipt(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    ApiPath(path): ApiPath<ExpensePath>,
    ApiJson(req): ApiJson<ReceiptReplace>,
) -> ApiResult<Json<Expense>> {
    let fix_note = note("note", req.note.as_deref().unwrap_or_default())?;
    let mut tx = member.begin(&state.db).await?;
    let status: ExpenseStatus = sqlx::query_scalar(
        "SELECT status FROM expenses WHERE id = $1 AND owner_id = $2 FOR UPDATE",
    )
    .bind(path.expense_id)
    .bind(member.user_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(ApiError::not_found)?;
    if status != ExpenseStatus::NeedsFix {
        return Err(not_returned());
    }
    uploads::attach(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        req.upload_id,
        UploadPurpose::Receipt,
        "upload_id",
    )
    .await?;
    sqlx::query(
        "UPDATE expenses
         SET receipt_upload_id = $2, fix_note = NULLIF($3, ''), status = 'in_review',
             status_at = now()
         WHERE id = $1",
    )
    .bind(path.expense_id)
    .bind(req.upload_id)
    .bind(&fix_note)
    .execute(&mut *tx)
    .await?;
    let expense = load(&mut tx, state.storage.as_ref(), &member, path.expense_id).await?;
    tx.commit().await?;
    Ok(Json(expense))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn create(amount: i64, spent_on: NaiveDate) -> ExpenseCreate {
        ExpenseCreate {
            amount,
            category: ExpenseCategory::Fuel,
            note: " Diesel ".into(),
            spent_on,
            receipt_upload_id: None,
            task_id: None,
        }
    }

    #[test]
    fn the_day_is_indian_and_not_in_the_future() {
        // 20:00 UTC on 16 Nov is already 17 Nov in India.
        let today = india::date(Utc.with_ymd_and_hms(2026, 11, 16, 20, 0, 0).unwrap());
        assert_eq!(today, NaiveDate::from_ymd_opt(2026, 11, 17).unwrap());
        assert!(check(&create(100, today), today).is_ok());
        assert!(check(&create(100, today + Duration::days(1)), today).is_err());
        assert!(check(&create(100, today - Duration::days(366)), today).is_err());
    }

    #[test]
    fn amounts_are_bounded_and_notes_trimmed() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 17).unwrap();
        assert_eq!(check(&create(100, today), today).unwrap(), "Diesel");
        assert!(check(&create(0, today), today).is_err());
        assert!(check(&create(MAX_AMOUNT + 1, today), today).is_err());
        assert!(check(&create(MAX_AMOUNT, today), today).is_ok());
    }
}
