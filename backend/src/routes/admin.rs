/*
    The company's side of every app flow (admin actions)
    --------------------------------------------------------------------
    - what the admin website calls: create and decide tasks, decide
      expenses, verify or reject customers, approve and pay commissions,
      ask for and confirm payments, hand over
    - the company's admin only (`OrgMember<Admins>`), in the company's
      row-level security scope: anything of another company is 404
    - each action writes the history and the notification the person on
      the other side sees, in the same transaction
    - a wrong state is 409 (`task.locked`, `expense.locked`,
      `registration.locked`, `payment.not_due`, `commission.locked`)
    - spec: docs/features/admin-actions.md
*/

use std::collections::BTreeSet;

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, Duration, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, counter,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath},
    idempotency::{self, IdempotencyKey},
    india,
    notify::{self, Kind, Links},
    org::{Admins, OrgMember},
    routes::{
        customers::KycKind,
        install::{default_plan, pm_surya_ghar},
        tasks::{TaskEventKind, TaskStatus, event},
    },
    stages,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(review_queue))
        .routes(routes!(create_task))
        .routes(routes!(approve_task))
        .routes(routes!(return_task))
        .routes(routes!(cancel_task))
        .routes(routes!(schedule_task))
        .routes(routes!(approve_expense))
        .routes(routes!(return_expense))
        .routes(routes!(reject_expense))
        .routes(routes!(pay_expense))
        .routes(routes!(verify_customer))
        .routes(routes!(reject_customer))
        .routes(routes!(return_customer_document))
        .routes(routes!(approve_commission))
        .routes(routes!(pay_commission))
        .routes(routes!(hand_over))
        .routes(routes!(request_payment))
        .routes(routes!(confirm_payment))
        .routes(routes!(payment_not_received))
}

const MAX_NOTE: usize = 500;
// ₹10 up to ₹10 crore, in paise: under ₹4 the 30% part rounds to ₹0.
const MIN_TOTAL: i64 = 1000;
const MAX_TOTAL: i64 = 10_000_000_000;

fn today() -> NaiveDate {
    india::date(Utc::now())
}

// "Thu 23 Oct, 10:00", in India.
fn when(at: DateTime<Utc>) -> String {
    at.with_timezone(&india::offset())
        .format("%a %-d %b, %H:%M")
        .to_string()
}

pub(crate) fn conflict(code: &'static str, title: &'static str) -> ApiError {
    ApiError::new(StatusCode::CONFLICT, code, title)
}

// Trimmed, 1 to 500 characters.
fn required_note(field: &str, value: &str) -> ApiResult<String> {
    let v = value.trim();
    if v.is_empty() || v.chars().count() > MAX_NOTE {
        return Err(
            ApiError::validation(Vec::new()).field(field, format!("1 to {MAX_NOTE} characters."))
        );
    }
    Ok(v.to_owned())
}

fn optional_note(field: &str, value: Option<&str>) -> ApiResult<Option<String>> {
    match value.map(str::trim).filter(|v| !v.is_empty()) {
        Some(v) => required_note(field, v).map(Some),
        None => Ok(None),
    }
}

// A system's price and its subsidy, in paise: at verifying and when corrected.
pub(crate) fn check_price(total: i64, subsidy: Option<i64>) -> ApiResult<()> {
    if !(MIN_TOTAL..=MAX_TOTAL).contains(&total) {
        return Err(ApiError::validation(Vec::new()).field("total", "₹10 up to ₹10 crore."));
    }
    if subsidy.is_some_and(|s| s < 0 || s > total) {
        return Err(ApiError::validation(Vec::new()).field("subsidy", "₹0 up to the total."));
    }
    Ok(())
}

// What actions answer with: the record's id and its reference, if any.
#[derive(Debug, Serialize, ToSchema)]
pub struct Done {
    pub id: Uuid,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reference: Option<String>,
}

/*
    Review queue
*/

#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct ReviewItem {
    pub id: Uuid,
    // TSK-, EXP- or SC- reference.
    pub reference: String,
    // What it is: "Panel installation", "Fuel · ₹1,240", a customer's name.
    pub title: String,
    // Who it's from: the worker, agent or customer.
    pub person: String,
    pub status: String,
    pub at: DateTime<Utc>,
    // Paise: what an expense, commission or payment is for.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<i64>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ReviewQueue {
    pub tasks: Vec<ReviewItem>,
    pub expenses: Vec<ReviewItem>,
    pub registrations: Vec<ReviewItem>,
    pub commissions: Vec<ReviewItem>,
    pub payments: Vec<ReviewItem>,
    // Landing-page leads nobody has yet (F20).
    pub leads: Vec<ReviewItem>,
}

/*
    Everything waiting for the admin, oldest first
    --------------------------------------------------------------------
    - tasks: submitted, a problem, or a reply: the installer's message
      is the latest thing that happened on an open task
    - expenses in review, or approved and still to pay
    - registrations in review (sent back, they wait for the agent)
    - commissions to approve or pay, payments the customer says they made
    - new leads not yet handed to an agent (F20)
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/review",
    operation_id = "getReviewQueue",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "What's waiting.", body = ReviewQueue),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn review_queue(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<Json<ReviewQueue>> {
    let mut tx = admin.begin(&state.db).await?;
    let tasks = sqlx::query_as(
        "SELECT t.id, t.reference, t.title || ' · ' || c.name AS title, u.name AS person,
                CASE WHEN t.status = 'submitted' THEN 'submitted'
                     WHEN t.problem_at IS NOT NULL AND t.status = 'assigned' THEN 'problem'
                     ELSE 'reply' END AS status,
                CASE WHEN t.status = 'submitted' THEN t.status_at
                     ELSE coalesce(t.problem_at, last.created_at, t.status_at) END AS at,
                NULL::bigint AS amount
         FROM tasks t
         JOIN customers c ON c.id = t.customer_id
         JOIN users u ON u.id = t.assignee_id
         LEFT JOIN LATERAL (
             SELECT kind, actor_id, created_at FROM task_events
             WHERE task_id = t.id ORDER BY created_at DESC, id DESC LIMIT 1
         ) last ON true
         WHERE t.status = 'submitted'
            OR (t.status = 'assigned' AND t.problem_at IS NOT NULL)
            OR (t.status IN ('assigned', 'returned')
                AND last.kind = 'message' AND last.actor_id = t.assignee_id)
         ORDER BY at",
    )
    .fetch_all(&mut *tx)
    .await?;
    let expenses = sqlx::query_as(
        "SELECT e.id, e.reference, initcap(e.category::text) || ' · ' || e.note AS title,
                u.name AS person, e.status::text AS status, e.status_at AS at, e.amount
         FROM expenses e JOIN users u ON u.id = e.owner_id
         WHERE e.status IN ('in_review', 'approved') ORDER BY e.status_at",
    )
    .fetch_all(&mut *tx)
    .await?;
    let registrations = sqlx::query_as(
        "SELECT c.id, c.reference, c.name AS title, coalesce(u.name, '') AS person,
                c.kyc_status::text AS status, c.created_at AS at, NULL::bigint AS amount
         FROM customers c LEFT JOIN users u ON u.id = c.registered_by
         WHERE c.kyc_status = 'in_review' ORDER BY c.created_at",
    )
    .fetch_all(&mut *tx)
    .await?;
    let commissions = sqlx::query_as(
        "SELECT c.id, c.reference, c.name AS title, coalesce(u.name, '') AS person,
                c.commission_status::text AS status, c.created_at AS at,
                c.commission AS amount
         FROM customers c LEFT JOIN users u ON u.id = c.registered_by
         WHERE c.commission_status IN ('in_review', 'payable') AND c.kyc_status = 'approved'
         ORDER BY c.created_at",
    )
    .fetch_all(&mut *tx)
    .await?;
    let payments = sqlx::query_as(
        "SELECT p.id, c.reference, p.label AS title, c.name AS person,
                p.status::text AS status, p.claimed_at AS at, p.amount
         FROM install_payments p JOIN installs i ON i.id = p.install_id
         JOIN customers c ON c.id = i.customer_id
         WHERE p.status = 'claimed' ORDER BY p.claimed_at",
    )
    .fetch_all(&mut *tx)
    .await?;
    let leads = sqlx::query_as(
        "SELECT id, '' AS reference, name AS title, source AS person, 'new' AS status,
                created_at AS at, NULL::bigint AS amount
         FROM leads WHERE status = 'new' AND agent_id IS NULL ORDER BY created_at",
    )
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Json(ReviewQueue {
        tasks,
        expenses,
        registrations,
        commissions,
        payments,
        leads,
    }))
}

/*
    Tasks
*/

#[derive(Debug, Deserialize, ToSchema)]
pub struct SlotCreate {
    // Short and unique on the task: "clamp".
    pub id: String,
    pub label: String,
    pub hint: Option<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ChecklistCreate {
    pub id: String,
    pub text: String,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct TaskCreate {
    pub customer_id: Uuid,
    pub title: String,
    // The install stage this task finishes, 1 to 7.
    pub stage_index: i32,
    // A worker of this company.
    pub assignee_id: Uuid,
    pub due_at: DateTime<Utc>,
    pub admin_note: Option<String>,
    #[serde(default)]
    pub photos: Vec<SlotCreate>,
    #[serde(default)]
    pub checklist: Vec<ChecklistCreate>,
}

#[derive(Debug, Deserialize)]
struct TaskPath {
    task_id: Uuid,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct NoteBody {
    pub note: String,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct TaskReturn {
    pub note: String,
    // The photo slots to take again.
    #[serde(default)]
    pub retake: Vec<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct TaskSchedule {
    pub due_at: DateTime<Utc>,
    // Another worker of this company, to move the task to.
    pub assignee_id: Option<Uuid>,
}

// Ids and labels for slots and checklist items: unique, short, present.
fn check_parts(task: &TaskCreate) -> ApiResult<()> {
    let bad = |field: &str, msg: &str| Err(ApiError::validation(Vec::new()).field(field, msg));
    let title = task.title.trim();
    if title.is_empty() || title.chars().count() > 100 {
        return bad("title", "1 to 100 characters.");
    }
    if !(1..=stages::COUNT).contains(&task.stage_index) {
        return bad("stage_index", "1 to 7.");
    }
    let mut ids = BTreeSet::new();
    for s in &task.photos {
        let id = s.id.trim();
        if id.is_empty() || id.len() > 40 || !ids.insert(id) {
            return bad("photos", "Each photo needs its own short id.");
        }
        if s.label.trim().is_empty() || s.label.chars().count() > 80 {
            return bad("photos", "Each photo needs a label (up to 80 characters).");
        }
    }
    let mut ids = BTreeSet::new();
    for c in &task.checklist {
        let id = c.id.trim();
        if id.is_empty() || id.len() > 40 || !ids.insert(id) {
            return bad("checklist", "Each item needs its own short id.");
        }
        if c.text.trim().is_empty() || c.text.chars().count() > 200 {
            return bad(
                "checklist",
                "Each item needs its text (up to 200 characters).",
            );
        }
    }
    Ok(())
}

// A worker of this company, still in it: their name. 422 on `field` otherwise.
async fn worker(conn: &mut PgConnection, user_id: Uuid, field: &str) -> ApiResult<String> {
    sqlx::query_scalar(
        "SELECT u.name FROM memberships m JOIN users u ON u.id = m.user_id
         WHERE m.user_id = $1 AND m.role = 'worker' AND m.removed_at IS NULL",
    )
    .bind(user_id)
    .fetch_optional(conn)
    .await?
    .ok_or_else(|| {
        ApiError::validation(Vec::new()).field(field, "Choose an installer of this company.")
    })
}

// A task of this company, locked: (status, worker, title, customer, customer's account).
async fn lock_task(
    conn: &mut PgConnection,
    task_id: Uuid,
) -> ApiResult<(TaskStatus, Uuid, String, String, Option<Uuid>, i32, Uuid)> {
    sqlx::query_as(
        "SELECT t.status, t.assignee_id, t.title, c.name, c.user_id, t.stage_index, c.id
         FROM tasks t JOIN customers c ON c.id = t.customer_id
         WHERE t.id = $1 FOR UPDATE OF t",
    )
    .bind(task_id)
    .fetch_optional(conn)
    .await?
    .ok_or_else(ApiError::not_found)
}

fn task_locked() -> ApiError {
    conflict("task.locked", "This task can't be changed now")
}

const ERRORS: &str = "Error, as RFC 9457 problem details.";

// Safe to retry (Idempotency-Key): a double click makes one task.
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks",
    operation_id = "createTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = TaskCreate,
    responses(
        (status = 201, description = "Assigned.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn create_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<TaskCreate>,
) -> ApiResult<Response> {
    let request = format!("POST /api/v1/orgs/{}/tasks", admin.org_id);
    if let Some(done) = idempotency::replay(&state.db, admin.user_id, key, &request).await? {
        return Ok(done);
    }
    check_parts(&req)?;
    let note = optional_note("admin_note", req.admin_note.as_deref())?;
    let mut tx = admin.begin(&state.db).await?;
    let (customer, customer_user): (String, Option<Uuid>) = sqlx::query_as(
        "SELECT name, user_id FROM customers WHERE id = $1 AND kyc_status = 'approved'",
    )
    .bind(req.customer_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(|| {
        ApiError::validation(Vec::new()).field("customer_id", "Choose an approved customer.")
    })?;
    worker(&mut tx, req.assignee_id, "assignee_id").await?;

    let id = Uuid::now_v7();
    let reference = counter::next(&mut tx, admin.org_id, "TSK").await?;
    let title = req.title.trim().to_owned();
    sqlx::query(
        "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index, assignee_id,
                            assigned_by, due_at, admin_note, admin_note_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CASE WHEN $10 IS NULL THEN NULL ELSE now() END)",
    )
    .bind(id)
    .bind(admin.org_id)
    .bind(req.customer_id)
    .bind(&reference)
    .bind(&title)
    .bind(req.stage_index)
    .bind(req.assignee_id)
    .bind(admin.user_id)
    .bind(req.due_at)
    .bind(&note)
    .execute(&mut *tx)
    .await?;
    for (position, s) in req.photos.iter().enumerate() {
        sqlx::query(
            "INSERT INTO task_photo_slots (org_id, task_id, slot_id, position, label, hint)
             VALUES ($1, $2, $3, $4, $5, $6)",
        )
        .bind(admin.org_id)
        .bind(id)
        .bind(s.id.trim())
        .bind(position as i32)
        .bind(s.label.trim())
        .bind(s.hint.as_deref().map(str::trim).filter(|h| !h.is_empty()))
        .execute(&mut *tx)
        .await?;
    }
    for (position, c) in req.checklist.iter().enumerate() {
        sqlx::query(
            "INSERT INTO task_checklist_items (org_id, task_id, item_id, position, text)
             VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(admin.org_id)
        .bind(id)
        .bind(c.id.trim())
        .bind(position as i32)
        .bind(c.text.trim())
        .execute(&mut *tx)
        .await?;
    }
    let due = when(req.due_at);
    event(
        &mut tx,
        admin.org_id,
        id,
        TaskEventKind::Assigned,
        admin.user_id,
        Some(&format!("Due {due}")),
    )
    .await?;
    let links = Links {
        task_id: Some(id),
        ..Links::default()
    };
    notify::add(
        &mut tx,
        admin.org_id,
        req.assignee_id,
        Kind::TaskAssigned,
        "New task assigned",
        &format!("{customer} · {title} · {due}"),
        links,
    )
    .await?;
    if let Some(customer_user) = customer_user {
        notify::add(
            &mut tx,
            admin.org_id,
            customer_user,
            Kind::VisitBooked,
            "Visit booked",
            &format!("{title} on {due}"),
            Links::default(),
        )
        .await?;
    }
    let done = Done {
        id,
        reference: Some(reference),
    };
    let body = serde_json::to_value(&done).map_err(|_| ApiError::internal())?;
    let status = StatusCode::CREATED;
    if !idempotency::save(&mut tx, admin.user_id, key, &request, status, &body).await? {
        drop(tx);
        return idempotency::replay(&state.db, admin.user_id, key, &request)
            .await?
            .ok_or_else(ApiError::internal);
    }
    tx.commit().await?;
    Ok((status, Json(body)).into_response())
}

/*
    A submitted task approved: the customer moves on to the next stage
    (the last stage waits for the handover action)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/approve",
    operation_id = "approveTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    responses(
        (status = 200, description = "Approved.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn approve_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<TaskPath>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    let (status, worker_id, title, customer, _, stage, customer_id) =
        lock_task(&mut tx, path.task_id).await?;
    if status != TaskStatus::Submitted {
        return Err(task_locked());
    }
    sqlx::query(
        "UPDATE tasks SET status = 'approved', status_at = now(), approved_by = $2,
                          approved_at = now()
         WHERE id = $1",
    )
    .bind(path.task_id)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    let count = stages::COUNT;
    let next = (stage + 1).min(count);
    let names = stages::load(&mut tx).await?;
    sqlx::query(
        "UPDATE customers SET stage_index = $2
         WHERE id = $1 AND coalesce(stage_index, 1) < $2",
    )
    .bind(customer_id)
    .bind(next)
    .execute(&mut *tx)
    .await?;
    let moved = format!("Moved to Stage {next}");
    event(
        &mut tx,
        admin.org_id,
        path.task_id,
        TaskEventKind::Approved,
        admin.user_id,
        Some(&moved),
    )
    .await?;
    notify::add(
        &mut tx,
        admin.org_id,
        worker_id,
        Kind::TaskApproved,
        &format!("Stage {stage} approved"),
        &format!("{customer} · {title} · moved to {}", names.name_at(next)),
        Links {
            task_id: Some(path.task_id),
            ..Links::default()
        },
    )
    .await?;
    tx.commit().await?;
    Ok(Json(Done {
        id: path.task_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/return",
    operation_id = "returnTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    request_body = TaskReturn,
    responses(
        (status = 200, description = "Sent back.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn return_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<TaskReturn>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    let mut tx = admin.begin(&state.db).await?;
    let (status, worker_id, title, customer, ..) = lock_task(&mut tx, path.task_id).await?;
    if status != TaskStatus::Submitted {
        return Err(task_locked());
    }
    for slot in &req.retake {
        let marked = sqlx::query(
            "UPDATE task_photo_slots SET retake = true WHERE task_id = $1 AND slot_id = $2",
        )
        .bind(path.task_id)
        .bind(slot)
        .execute(&mut *tx)
        .await?
        .rows_affected();
        if marked == 0 {
            return Err(
                ApiError::validation(Vec::new()).field("retake", "No such photo on this task.")
            );
        }
    }
    sqlx::query(
        "UPDATE tasks SET status = 'returned', status_at = now(), returned_note = $2,
                          returned_by = $3, returned_at = now()
         WHERE id = $1",
    )
    .bind(path.task_id)
    .bind(&note)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    event(
        &mut tx,
        admin.org_id,
        path.task_id,
        TaskEventKind::Returned,
        admin.user_id,
        Some(&note),
    )
    .await?;
    let headline = if req.retake.is_empty() {
        "Task sent back"
    } else {
        "Photo retake asked"
    };
    notify::add(
        &mut tx,
        admin.org_id,
        worker_id,
        Kind::TaskReturned,
        headline,
        &format!("{customer} · {title}: “{note}”"),
        Links {
            task_id: Some(path.task_id),
            ..Links::default()
        },
    )
    .await?;
    tx.commit().await?;
    Ok(Json(Done {
        id: path.task_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/cancel",
    operation_id = "cancelTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Cancelled.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn cancel_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    let mut tx = admin.begin(&state.db).await?;
    let (status, worker_id, title, customer, customer_user, ..) =
        lock_task(&mut tx, path.task_id).await?;
    if matches!(status, TaskStatus::Approved | TaskStatus::Cancelled) {
        return Err(task_locked());
    }
    sqlx::query(
        "UPDATE tasks SET status = 'cancelled', status_at = now(), cancelled_note = $2,
                          cancelled_by = $3, cancelled_at = now()
         WHERE id = $1",
    )
    .bind(path.task_id)
    .bind(&note)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    event(
        &mut tx,
        admin.org_id,
        path.task_id,
        TaskEventKind::Cancelled,
        admin.user_id,
        Some(&note),
    )
    .await?;
    notify::add(
        &mut tx,
        admin.org_id,
        worker_id,
        Kind::TaskCancelled,
        "Task cancelled",
        &format!("{customer} · {title} · {note}"),
        Links {
            task_id: Some(path.task_id),
            ..Links::default()
        },
    )
    .await?;
    if let Some(user) = customer_user {
        // Without the note: it's written for the installer.
        notify::add(
            &mut tx,
            admin.org_id,
            user,
            Kind::VisitBooked,
            "Visit cancelled",
            &title,
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.task_id,
        reference: None,
    }))
}

/*
    A new time, or another worker, for an open task. Closes a reported
    problem: the admin has decided what happens
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/tasks/{task_id}/schedule",
    operation_id = "scheduleTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    request_body = TaskSchedule,
    responses(
        (status = 200, description = "Rescheduled.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn schedule_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<TaskSchedule>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    let (status, old_worker, title, customer, customer_user, ..) =
        lock_task(&mut tx, path.task_id).await?;
    if !matches!(status, TaskStatus::Assigned | TaskStatus::Returned) {
        return Err(task_locked());
    }
    let old_due: DateTime<Utc> = sqlx::query_scalar("SELECT due_at FROM tasks WHERE id = $1")
        .bind(path.task_id)
        .fetch_one(&mut *tx)
        .await?;
    let new_worker = match req.assignee_id {
        Some(w) if w != old_worker => {
            worker(&mut tx, w, "assignee_id").await?;
            Some(w)
        }
        _ => None,
    };
    sqlx::query(
        "UPDATE tasks SET due_at = $2, assignee_id = coalesce($3, assignee_id),
                          problem_reason = NULL, problem_note = NULL, problem_at = NULL,
                          problem_upload_id = NULL
         WHERE id = $1",
    )
    .bind(path.task_id)
    .bind(req.due_at)
    .bind(new_worker)
    .execute(&mut *tx)
    .await?;
    let due = when(req.due_at);
    let links = Links {
        task_id: Some(path.task_id),
        ..Links::default()
    };
    match new_worker {
        Some(w) => {
            event(
                &mut tx,
                admin.org_id,
                path.task_id,
                TaskEventKind::Reassigned,
                admin.user_id,
                Some(&format!("Due {due}")),
            )
            .await?;
            notify::add(
                &mut tx,
                admin.org_id,
                w,
                Kind::TaskAssigned,
                "New task assigned",
                &format!("{customer} · {title} · {due}"),
                links,
            )
            .await?;
            notify::add(
                &mut tx,
                admin.org_id,
                old_worker,
                Kind::TaskCancelled,
                "Task moved",
                &format!("{customer} · {title} · given to another installer"),
                links,
            )
            .await?;
        }
        None => {
            event(
                &mut tx,
                admin.org_id,
                path.task_id,
                TaskEventKind::Rescheduled,
                admin.user_id,
                Some(&format!("Due {due}")),
            )
            .await?;
            notify::add(
                &mut tx,
                admin.org_id,
                old_worker,
                Kind::TaskRescheduled,
                "Task rescheduled",
                &format!("{customer} · {title} moved to {due}"),
                links,
            )
            .await?;
        }
    }
    // A new installer at the same time is nothing to the customer.
    if let Some(user) = customer_user
        && when(old_due) != due
    {
        notify::add(
            &mut tx,
            admin.org_id,
            user,
            Kind::VisitBooked,
            "Visit moved",
            &format!("{title} is now on {due}"),
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.task_id,
        reference: None,
    }))
}

/*
    Expenses
*/

#[derive(Debug, Deserialize)]
struct ExpensePath {
    expense_id: Uuid,
}

/*
    Moves an expense from `from` to `to` and tells its owner. 404 when
    it isn't the company's, 409 `expense.locked` from any other state
*/
// One expense decision: from which state, to which, and what the owner is told.
struct ExpenseMove<'a> {
    from: &'a [&'a str],
    to: &'a str,
    note: Option<&'a str>,
    kind: Kind,
    title: &'a str,
}

async fn decide_expense(
    state: &AppState,
    admin: &OrgMember<Admins>,
    expense_id: Uuid,
    m: ExpenseMove<'_>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    let (status, owner, reference, amount): (String, Uuid, String, i64) = sqlx::query_as(
        "SELECT status::text, owner_id, reference, amount FROM expenses WHERE id = $1 FOR UPDATE",
    )
    .bind(expense_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(ApiError::not_found)?;
    if !m.from.contains(&status.as_str()) {
        return Err(conflict(
            "expense.locked",
            "This expense can't move to that state now",
        ));
    }
    sqlx::query(
        "UPDATE expenses SET status = $2::expense_status, status_at = now(), decided_by = $3,
                             admin_note = coalesce($4, admin_note)
         WHERE id = $1",
    )
    .bind(expense_id)
    .bind(m.to)
    .bind(admin.user_id)
    .bind(m.note)
    .execute(&mut *tx)
    .await?;
    let amount = crate::routes::quotes::rupees(amount);
    let body = match m.note {
        Some(n) => format!("{reference} · {amount}: “{n}”"),
        None => format!("{reference} · {amount}"),
    };
    notify::add(
        &mut tx,
        admin.org_id,
        owner,
        m.kind,
        m.title,
        &body,
        Links {
            expense_id: Some(expense_id),
            ..Links::default()
        },
    )
    .await?;
    tx.commit().await?;
    Ok(Json(Done {
        id: expense_id,
        reference: Some(reference),
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/expenses/{expense_id}/approve",
    operation_id = "approveExpense",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    responses(
        (status = 200, description = "Approved.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn approve_expense(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<ExpensePath>,
) -> ApiResult<Json<Done>> {
    decide_expense(
        &state,
        &admin,
        path.expense_id,
        ExpenseMove {
            from: &["in_review"],
            to: "approved",
            note: None,
            kind: Kind::ExpenseApproved,
            title: "Expense approved",
        },
    )
    .await
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/expenses/{expense_id}/return",
    operation_id = "returnExpense",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Sent back.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn return_expense(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<ExpensePath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    decide_expense(
        &state,
        &admin,
        path.expense_id,
        ExpenseMove {
            from: &["in_review"],
            to: "needs_fix",
            note: Some(&note),
            kind: Kind::ExpenseReturned,
            title: "Expense sent back",
        },
    )
    .await
}

// Not accepted, with the reason. Final.
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/expenses/{expense_id}/reject",
    operation_id = "rejectExpense",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Done.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn reject_expense(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<ExpensePath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    decide_expense(
        &state,
        &admin,
        path.expense_id,
        ExpenseMove {
            from: &["in_review", "needs_fix"],
            to: "rejected",
            note: Some(&note),
            kind: Kind::ExpenseReturned,
            title: "Expense not accepted",
        },
    )
    .await
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/expenses/{expense_id}/paid",
    operation_id = "payExpense",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("expense_id" = Uuid, Path, description = "The expense."),
    ),
    responses(
        (status = 200, description = "Paid.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn pay_expense(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<ExpensePath>,
) -> ApiResult<Json<Done>> {
    decide_expense(
        &state,
        &admin,
        path.expense_id,
        ExpenseMove {
            from: &["approved"],
            to: "paid",
            note: None,
            kind: Kind::ExpensePaid,
            title: "Expense paid",
        },
    )
    .await
}

/*
    Customers
*/

#[derive(Debug, Deserialize)]
struct CustomerPath {
    customer_id: Uuid,
}

#[derive(Debug, Deserialize)]
struct CustomerDocumentPath {
    customer_id: Uuid,
    kind: KycKind,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct CustomerVerify {
    // The system's price, paise.
    pub total: i64,
    // PM Surya Ghar, paise; left out: from the government table when the
    // customer asked for it, else 0.
    pub subsidy: Option<i64>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct CommissionDecision {
    // A new amount, paise; left out: the agent's stands.
    pub amount: Option<i64>,
    pub note: Option<String>,
}

#[derive(sqlx::FromRow)]
struct CustomerRow {
    name: String,
    kyc_status: String,
    registered_by: Option<Uuid>,
    user_id: Option<Uuid>,
    subsidy: Option<bool>,
    system_kw: Option<f64>,
    commission: Option<i64>,
    commission_status: Option<String>,
}

async fn lock_customer(conn: &mut PgConnection, customer_id: Uuid) -> ApiResult<CustomerRow> {
    sqlx::query_as(
        "SELECT name, kyc_status::text, registered_by, user_id, subsidy, system_kw,
                commission, commission_status::text
         FROM customers WHERE id = $1 FOR UPDATE",
    )
    .bind(customer_id)
    .fetch_optional(conn)
    .await?
    .ok_or_else(ApiError::not_found)
}

pub(crate) fn registration_locked() -> ApiError {
    conflict(
        "registration.locked",
        "This customer can't be changed that way now",
    )
}

fn customer_links(customer_id: Uuid) -> Links {
    Links {
        customer_id: Some(customer_id),
        ..Links::default()
    }
}

/*
    Verify a registration: KYC approved, every document verified, stage
    1, and the install with the default plan (advance due in 7 days).
    The agent and the customer are told
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/verify",
    operation_id = "verifyCustomer",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    request_body = CustomerVerify,
    responses(
        (status = 200, description = "Verified, install set up.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn verify_customer(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
    ApiJson(req): ApiJson<CustomerVerify>,
) -> ApiResult<Json<Done>> {
    check_price(req.total, req.subsidy)?;
    let mut tx = admin.begin(&state.db).await?;
    let c = lock_customer(&mut tx, path.customer_id).await?;
    let fixing: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM documents WHERE customer_id = $1 AND status = 'needs_fix')",
    )
    .bind(path.customer_id)
    .fetch_one(&mut *tx)
    .await?;
    if c.kyc_status != "in_review" || fixing {
        return Err(registration_locked());
    }
    let subsidy = req.subsidy.unwrap_or_else(|| {
        if c.subsidy == Some(true) {
            pm_surya_ghar(c.system_kw.unwrap_or(0.0))
        } else {
            0
        }
    });
    sqlx::query(
        "UPDATE customers SET kyc_status = 'approved', stage_index = 1, decided_by = $2,
                              decided_at = now()
         WHERE id = $1",
    )
    .bind(path.customer_id)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "UPDATE documents SET status = 'verified', updated_at = now() WHERE customer_id = $1",
    )
    .bind(path.customer_id)
    .execute(&mut *tx)
    .await?;
    let install = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO installs (id, org_id, customer_id, total, subsidy) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(install)
    .bind(admin.org_id)
    .bind(path.customer_id)
    .bind(req.total)
    .bind(subsidy)
    .execute(&mut *tx)
    .await?;
    let advance_due = today() + Duration::days(7);
    for (position, (label, detail, amount)) in default_plan(req.total).into_iter().enumerate() {
        sqlx::query(
            "INSERT INTO install_payments (id, org_id, install_id, position, label, detail,
                                           amount, due_on, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7,
                     CASE WHEN $4 = 0 THEN $8 END,
                     CASE WHEN $4 = 0 THEN 'due' ELSE 'later' END::payment_status)",
        )
        .bind(Uuid::now_v7())
        .bind(admin.org_id)
        .bind(install)
        .bind(position as i32)
        .bind(label)
        .bind(detail)
        .bind(amount)
        .bind(advance_due)
        .execute(&mut *tx)
        .await?;
    }
    let links = customer_links(path.customer_id);
    if let Some(agent) = c.registered_by {
        notify::add(
            &mut tx,
            admin.org_id,
            agent,
            Kind::KycApproved,
            "KYC approved",
            &format!("{} · install starts with the site survey", c.name),
            links,
        )
        .await?;
    }
    if let Some(customer) = c.user_id {
        notify::add(
            &mut tx,
            admin.org_id,
            customer,
            Kind::DocumentsVerified,
            "Documents verified",
            "Your install is set up. Follow each stage in the app.",
            Links::default(),
        )
        .await?;
        let (_, _, advance) = default_plan(req.total)[0];
        notify::add(
            &mut tx,
            admin.org_id,
            customer,
            Kind::PaymentDue,
            "Advance due",
            &format!(
                "{} by {}",
                crate::routes::quotes::rupees(advance),
                advance_due.format("%-d %b")
            ),
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/reject",
    operation_id = "rejectCustomer",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Not taken up.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn reject_customer(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    let mut tx = admin.begin(&state.db).await?;
    let c = lock_customer(&mut tx, path.customer_id).await?;
    if !matches!(c.kyc_status.as_str(), "in_review" | "needs_fix") {
        return Err(registration_locked());
    }
    sqlx::query(
        "UPDATE customers SET kyc_status = 'rejected', rejected_note = $2, decided_by = $3,
                              decided_at = now()
         WHERE id = $1",
    )
    .bind(path.customer_id)
    .bind(&note)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    if let Some(agent) = c.registered_by {
        notify::add(
            &mut tx,
            admin.org_id,
            agent,
            Kind::KycReturned,
            "Not taken up",
            &format!("{}: “{note}”", c.name),
            customer_links(path.customer_id),
        )
        .await?;
    }
    if let Some(customer) = c.user_id {
        notify::add(
            &mut tx,
            admin.org_id,
            customer,
            Kind::RegistrationClosed,
            "Registration not taken up",
            &format!("“{note}”"),
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/documents/{kind}/return",
    operation_id = "returnCustomerDocument",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
        ("kind" = KycKind, Path, description = "The document to send back."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Sent back to the agent.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn return_customer_document(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerDocumentPath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    let mut tx = admin.begin(&state.db).await?;
    let c = lock_customer(&mut tx, path.customer_id).await?;
    if !matches!(c.kyc_status.as_str(), "in_review" | "needs_fix") {
        return Err(registration_locked());
    }
    let returned = sqlx::query(
        "UPDATE documents SET status = 'needs_fix', admin_note = $3, admin_note_by = $4,
                              admin_note_at = now(), updated_at = now()
         WHERE customer_id = $1 AND kind = $2 AND status = 'in_review'",
    )
    .bind(path.customer_id)
    .bind(path.kind)
    .bind(&note)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if returned == 0 {
        return Err(registration_locked());
    }
    sqlx::query("UPDATE customers SET kyc_status = 'needs_fix' WHERE id = $1")
        .bind(path.customer_id)
        .execute(&mut *tx)
        .await?;
    if let Some(agent) = c.registered_by {
        notify::add(
            &mut tx,
            admin.org_id,
            agent,
            Kind::KycReturned,
            &format!("{} sent back", path.kind.label()),
            &format!("{}: “{note}”", c.name),
            customer_links(path.customer_id),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

// Is the customer's first payment (the advance) paid?
async fn advance_paid(conn: &mut PgConnection, customer_id: Uuid) -> ApiResult<bool> {
    Ok(sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM install_payments p JOIN installs i ON i.id = p.install_id
                        WHERE i.customer_id = $1 AND p.position = 0 AND p.status = 'paid')",
    )
    .bind(customer_id)
    .fetch_one(conn)
    .await?)
}

/*
    Approve an agent's commission, as asked or changed (the agent's
    figure is kept). Payable at once if the advance is already paid
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/commission",
    operation_id = "approveCommission",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    request_body = CommissionDecision,
    responses(
        (status = 200, description = "Approved.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn approve_commission(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
    ApiJson(req): ApiJson<CommissionDecision>,
) -> ApiResult<Json<Done>> {
    if req.amount.is_some_and(|a| !(0..=100_000_000).contains(&a)) {
        return Err(ApiError::validation(Vec::new()).field("amount", "₹0 to ₹10,00,000."));
    }
    let note = optional_note("note", req.note.as_deref())?;
    let mut tx = admin.begin(&state.db).await?;
    let c = lock_customer(&mut tx, path.customer_id).await?;
    let (Some(asked), Some("in_review")) = (c.commission, c.commission_status.as_deref()) else {
        return Err(conflict(
            "commission.locked",
            "There's no commission to approve",
        ));
    };
    if c.kyc_status == "rejected" {
        return Err(conflict(
            "commission.locked",
            "The customer wasn't taken up",
        ));
    }
    let changed = req.amount.is_some_and(|a| a != asked);
    let payable = advance_paid(&mut tx, path.customer_id).await?;
    sqlx::query(
        "UPDATE customers
         SET commission = coalesce($2, commission),
             commission_proposed = CASE WHEN $3 THEN commission END,
             commission_status = CASE WHEN $4 THEN 'payable' ELSE 'approved' END::commission_status,
             commission_payable_since = CASE WHEN $4 THEN $7::date END,
             commission_admin_note = $5,
             commission_admin_by = CASE WHEN $5 IS NULL THEN NULL ELSE $6 END,
             commission_admin_at = CASE WHEN $5 IS NULL THEN NULL ELSE now() END
         WHERE id = $1",
    )
    .bind(path.customer_id)
    .bind(req.amount)
    .bind(changed)
    .bind(payable)
    .bind(&note)
    .bind(admin.user_id)
    .bind(today())
    .execute(&mut *tx)
    .await?;
    if let Some(agent) = c.registered_by {
        let amount = crate::routes::quotes::rupees(req.amount.unwrap_or(asked));
        if changed {
            notify::add(
                &mut tx,
                admin.org_id,
                agent,
                Kind::CommissionChanged,
                "Commission changed",
                &format!("{} · {amount}", c.name),
                customer_links(path.customer_id),
            )
            .await?;
        }
        if payable {
            notify::add(
                &mut tx,
                admin.org_id,
                agent,
                Kind::CommissionPayable,
                "Commission payable",
                &format!("{} · {amount}", c.name),
                customer_links(path.customer_id),
            )
            .await?;
        }
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/commission/paid",
    operation_id = "payCommission",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    responses(
        (status = 200, description = "Paid out.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn pay_commission(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    let c = lock_customer(&mut tx, path.customer_id).await?;
    if c.commission_status.as_deref() != Some("payable") {
        return Err(conflict(
            "commission.locked",
            "This commission isn't payable",
        ));
    }
    sqlx::query(
        "UPDATE customers SET commission_status = 'paid', commission_paid_on = $2
         WHERE id = $1",
    )
    .bind(path.customer_id)
    .bind(today())
    .execute(&mut *tx)
    .await?;
    if let (Some(agent), Some(amount)) = (c.registered_by, c.commission) {
        notify::add(
            &mut tx,
            admin.org_id,
            agent,
            Kind::CommissionPaid,
            "Commission paid",
            &format!("{} · {}", c.name, crate::routes::quotes::rupees(amount)),
            customer_links(path.customer_id),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customers/{customer_id}/handover",
    operation_id = "handOver",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    responses(
        (status = 200, description = "Handed over.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn hand_over(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<CustomerPath>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    lock_customer(&mut tx, path.customer_id).await?;
    let done = sqlx::query(
        "UPDATE installs SET handed_over_on = $2
         WHERE customer_id = $1 AND handed_over_on IS NULL",
    )
    .bind(path.customer_id)
    .bind(today())
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if done == 0 {
        return Err(registration_locked());
    }
    sqlx::query("UPDATE customers SET stage_index = $2 WHERE id = $1")
        .bind(path.customer_id)
        .bind(stages::COUNT)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(Done {
        id: path.customer_id,
        reference: None,
    }))
}

/*
    Payments
*/

#[derive(Debug, Deserialize)]
struct PaymentPath {
    payment_id: Uuid,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct PaymentRequest {
    // YYYY-MM-DD, today or later.
    pub due_on: NaiveDate,
}

// A payment of this company, locked: (status, position, label, amount, customer, its account).
async fn lock_payment(
    conn: &mut PgConnection,
    payment_id: Uuid,
) -> ApiResult<(String, i32, String, i64, Uuid, Option<Uuid>)> {
    sqlx::query_as(
        "SELECT p.status::text, p.position, p.label, p.amount, c.id, c.user_id
         FROM install_payments p JOIN installs i ON i.id = p.install_id
         JOIN customers c ON c.id = i.customer_id
         WHERE p.id = $1 FOR UPDATE OF p",
    )
    .bind(payment_id)
    .fetch_optional(conn)
    .await?
    .ok_or_else(ApiError::not_found)
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/payments/{payment_id}/request",
    operation_id = "requestPayment",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("payment_id" = Uuid, Path, description = "The payment."),
    ),
    request_body = PaymentRequest,
    responses(
        (status = 200, description = "Due.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn request_payment(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<PaymentPath>,
    ApiJson(req): ApiJson<PaymentRequest>,
) -> ApiResult<Json<Done>> {
    if req.due_on < today() {
        return Err(ApiError::validation(Vec::new()).field("due_on", "Today or later."));
    }
    let mut tx = admin.begin(&state.db).await?;
    let (status, _, label, amount, _, customer) = lock_payment(&mut tx, path.payment_id).await?;
    if status != "later" {
        return Err(conflict(
            "payment.not_due",
            "This payment is already asked for",
        ));
    }
    sqlx::query("UPDATE install_payments SET status = 'due', due_on = $2 WHERE id = $1")
        .bind(path.payment_id)
        .bind(req.due_on)
        .execute(&mut *tx)
        .await?;
    if let Some(customer) = customer {
        notify::add(
            &mut tx,
            admin.org_id,
            customer,
            Kind::PaymentDue,
            &format!("{} due", label.split(',').next().unwrap_or(&label)),
            &format!(
                "{} by {}",
                crate::routes::quotes::rupees(amount),
                req.due_on.format("%-d %b")
            ),
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.payment_id,
        reference: None,
    }))
}

/*
    The company received a payment (claimed in the app, or due and paid
    at the office). The advance makes an approved commission payable
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/payments/{payment_id}/confirm",
    operation_id = "confirmPayment",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("payment_id" = Uuid, Path, description = "The payment."),
    ),
    responses(
        (status = 200, description = "Paid.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn confirm_payment(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<PaymentPath>,
) -> ApiResult<Json<Done>> {
    let mut tx = admin.begin(&state.db).await?;
    let (status, position, _, _, customer_id, _) = lock_payment(&mut tx, path.payment_id).await?;
    if !matches!(status.as_str(), "claimed" | "due") {
        return Err(conflict("payment.not_due", "This payment isn't waiting"));
    }
    sqlx::query("UPDATE install_payments SET status = 'paid', paid_on = $2 WHERE id = $1")
        .bind(path.payment_id)
        .bind(today())
        .execute(&mut *tx)
        .await?;
    if position == 0 {
        let c = lock_customer(&mut tx, customer_id).await?;
        if c.commission_status.as_deref() == Some("approved") {
            sqlx::query(
                "UPDATE customers SET commission_status = 'payable',
                                      commission_payable_since = $2
                 WHERE id = $1",
            )
            .bind(customer_id)
            .bind(today())
            .execute(&mut *tx)
            .await?;
            if let (Some(agent), Some(amount)) = (c.registered_by, c.commission) {
                notify::add(
                    &mut tx,
                    admin.org_id,
                    agent,
                    Kind::CommissionPayable,
                    "Commission payable",
                    &format!("{} · {}", c.name, crate::routes::quotes::rupees(amount)),
                    customer_links(customer_id),
                )
                .await?;
            }
        }
    }
    tx.commit().await?;
    Ok(Json(Done {
        id: path.payment_id,
        reference: None,
    }))
}

/*
    The customer said they paid, and the money isn't there
    --------------------------------------------------------------------
    - back to due, so they can pay or say so again
    - they're told why
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/payments/{payment_id}/not-received",
    operation_id = "paymentNotReceived",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("payment_id" = Uuid, Path, description = "The payment."),
    ),
    request_body = NoteBody,
    responses(
        (status = 200, description = "Done.", body = Done),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 409, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn payment_not_received(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<PaymentPath>,
    ApiJson(req): ApiJson<NoteBody>,
) -> ApiResult<Json<Done>> {
    let note = required_note("note", &req.note)?;
    let mut tx = admin.begin(&state.db).await?;
    let (status, _, label, amount, _, customer_user) =
        lock_payment(&mut tx, path.payment_id).await?;
    if status != "claimed" {
        return Err(conflict("payment.not_due", "This payment wasn't claimed"));
    }
    sqlx::query(
        "UPDATE install_payments SET status = 'due', claimed_at = NULL, claimed_method = NULL
         WHERE id = $1",
    )
    .bind(path.payment_id)
    .execute(&mut *tx)
    .await?;
    if let Some(customer) = customer_user {
        notify::add(
            &mut tx,
            admin.org_id,
            customer,
            Kind::PaymentDue,
            "Payment not received",
            &format!(
                "{label} · {}: “{note}”",
                crate::routes::quotes::rupees(amount)
            ),
            Links::default(),
        )
        .await?;
    }
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, payment_id = %path.payment_id, "payment not received");
    Ok(Json(Done {
        id: path.payment_id,
        reference: None,
    }))
}
