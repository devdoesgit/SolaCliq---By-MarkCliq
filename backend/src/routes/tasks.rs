/*
    A worker's tasks (phase 8, #25–33)
    --------------------------------------------------------------------
    - GET  /orgs/{org_id}/tasks?view=today|upcoming|done   their lists
    - GET  .../tasks/{task_id}                             one task
    - POST .../tasks/{task_id}/photos                      a proof photo
    - PUT  .../tasks/{task_id}/checklist/{item_id}         tick an item
    - POST .../tasks/{task_id}/submit       (idem)         to the admin
    - POST .../tasks/{task_id}/problems     (idem)         report one
    - POST .../tasks/{task_id}/messages                    reply
    - GET  .../tasks/{task_id}/history                     the timeline
    - GET  /orgs/{org_id}/me/stats                         this month
    - workers only (`OrgMember<Workers>`), and only their own tasks:
      someone else's task is 404, as if it didn't exist
    - only assigned and returned tasks take changes; anything else is
      409 `task.locked`
    - "today" is today in India, as on the home screen
    - the admin's side (create, approve, return, cancel) comes with the
      admin website; until then the seed writes tasks
*/

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, Datelike, Duration, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath, ApiQuery},
    idempotency::{self, IdempotencyKey},
    india, notify,
    org::{OrgMember, Workers},
    page::{Cursor, Page, PageInfo},
    routes::uploads::{self, UploadPurpose},
    storage::Storage,
    validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_my_tasks))
        .routes(routes!(get_task))
        .routes(routes!(add_task_photo))
        .routes(routes!(set_task_checklist_item))
        .routes(routes!(submit_task))
        .routes(routes!(report_task_problem))
        .routes(routes!(send_task_message))
        .routes(routes!(get_task_history))
        .routes(routes!(get_my_stats))
}

const MAX_TEXT: usize = 500;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "task_status", rename_all = "snake_case")]
pub enum TaskStatus {
    Assigned,
    Submitted,
    Returned,
    Approved,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "task_problem_reason", rename_all = "snake_case")]
pub enum TaskProblemReason {
    CustomerAway,
    MaterialMissing,
    BadWeather,
    SiteNotReady,
    Safety,
    Other,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "task_event_kind", rename_all = "snake_case")]
pub enum TaskEventKind {
    Assigned,
    PhotosUploaded,
    Submitted,
    Resubmitted,
    Returned,
    Approved,
    ProblemReported,
    Rescheduled,
    Reassigned,
    Cancelled,
    Message,
}

// Someone shown on a task: the admin, or the caller (`you`).
#[derive(Debug, Serialize, ToSchema)]
pub struct Person {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<String>,
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    pub you: bool,
}

impl Person {
    // The company's side: only admins assign, return, approve and cancel.
    pub fn admin(name: String) -> Self {
        Person {
            name,
            role: Some("Admin".into()),
            you: false,
        }
    }
}

// The contract's `TaskSummary`: one row of a list.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct TaskSummary {
    pub id: Uuid,
    pub reference: String,
    pub title: String,
    pub status: TaskStatus,
    pub due_at: DateTime<Utc>,
    pub customer_name: String,
    pub status_at: DateTime<Utc>,
    pub has_problem: bool,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskPage {
    pub items: Vec<TaskSummary>,
    pub page: PageInfo,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ProofPhoto {
    // Works for 15 minutes.
    pub url: String,
    pub taken_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lng: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub accuracy_m: Option<f64>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ProofSlot {
    pub id: String,
    pub label: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hint: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub photo: Option<ProofPhoto>,
    // The admin asked for this one again.
    pub retake: bool,
}

#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct ChecklistItem {
    pub id: String,
    pub text: String,
    pub done: bool,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskNote {
    pub text: String,
    pub by: Person,
    pub at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskProblem {
    pub reason: TaskProblemReason,
    pub note: String,
    pub at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskStage {
    pub index: i32,
    pub count: i32,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskCustomer {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system_kw: Option<f64>,
    pub address: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lng: Option<f64>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskApproval {
    pub by: Person,
    pub at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_task: Option<TaskSummary>,
}

// The contract's `Task`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Task {
    pub id: Uuid,
    pub reference: String,
    pub title: String,
    pub status: TaskStatus,
    pub due_at: DateTime<Utc>,
    pub stage: TaskStage,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub assigned_by: Option<Person>,
    pub customer: TaskCustomer,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<TaskNote>,
    pub photos: Vec<ProofSlot>,
    pub checklist: Vec<ChecklistItem>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub submitted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub worker_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub returned: Option<TaskNote>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub problem: Option<TaskProblem>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cancelled: Option<TaskNote>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub approved: Option<TaskApproval>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskEvent {
    pub kind: TaskEventKind,
    pub actor: Person,
    pub at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TaskHistory {
    pub events: Vec<TaskEvent>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct WorkerStats {
    pub tasks_this_month: i64,
    pub returned_this_month: i64,
    pub avg_minutes_on_site: i64,
}

/*
    Requests
*/

#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum TaskView {
    Today,
    Upcoming,
    Done,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct TaskListQuery {
    // today: due today, plus returned or on hold; upcoming: later; done: final.
    pub view: TaskView,
    // Opaque cursor from the previous page's `next_cursor`.
    pub cursor: Option<String>,
    // Page size, 1 to 100; 25 when left out.
    pub limit: Option<i64>,
}

// The `{task_id}` of the path; `{org_id}` is OrgMember's.
#[derive(Debug, Deserialize)]
struct TaskPath {
    task_id: Uuid,
}

#[derive(Debug, Deserialize)]
struct ChecklistPath {
    task_id: Uuid,
    item_id: String,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ProofPhotoCreate {
    pub slot_id: String,
    pub upload_id: Uuid,
    pub taken_at: DateTime<Utc>,
    pub lat: f64,
    pub lng: f64,
    pub accuracy_m: f64,
    // The phone reported a mocked (fake) location.
    #[serde(default)]
    pub mocked_location: bool,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ChecklistSet {
    pub done: bool,
}

#[derive(Debug, Default, Deserialize, ToSchema)]
pub struct TaskSubmit {
    // Optional note for the admin, up to 500 characters.
    pub note: Option<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct TaskProblemCreate {
    pub reason: TaskProblemReason,
    pub note: String,
    // An optional photo (purpose `proof`).
    pub upload_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct TaskMessage {
    pub text: String,
}

/*
    Errors
*/

fn locked() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "task.locked",
        "This task can't be changed now",
    )
}

// Up to 500 characters, trimmed; None when empty.
fn text(field: &str, value: Option<&str>) -> ApiResult<Option<String>> {
    let value = value.map(str::trim).filter(|v| !v.is_empty());
    if value.is_some_and(|v| v.chars().count() > MAX_TEXT) {
        return Err(
            ApiError::validation(Vec::new()).field(field, format!("Up to {MAX_TEXT} characters."))
        );
    }
    Ok(value.map(str::to_owned))
}

fn required_text(field: &str, value: &str) -> ApiResult<String> {
    text(field, Some(value))?
        .ok_or_else(|| ApiError::validation(Vec::new()).field(field, "Write a few words."))
}

/*
    Dates: "today" in India
*/

// When today ends in India (midnight starting tomorrow), in UTC.
fn end_of_today(now: DateTime<Utc>) -> DateTime<Utc> {
    india::midnight(india::date(now) + Duration::days(1))
}

// When this month began in India, in UTC.
fn start_of_month(now: DateTime<Utc>) -> DateTime<Utc> {
    let first = india::date(now)
        .with_day(1)
        .expect("every month has a first");
    india::midnight(first)
}

/*
    Reading a task
*/

// The list row's columns, then a fixed WHERE/ORDER: sqlx takes only literals.
macro_rules! select_summary {
    ($rest:literal) => {
        concat!(
            "SELECT t.id, t.reference, t.title, t.status, t.due_at,
                    c.name AS customer_name, t.status_at,
                    t.problem_at IS NOT NULL AS has_problem
             FROM tasks t JOIN customers c ON c.id = t.customer_id ",
            $rest
        )
    };
}

#[derive(sqlx::FromRow)]
struct TaskRow {
    id: Uuid,
    reference: String,
    title: String,
    status: TaskStatus,
    due_at: DateTime<Utc>,
    stage_index: i32,
    stage_count: i32,
    assigned_by: Option<String>,
    customer_name: String,
    system_kw: Option<f64>,
    address: String,
    phone: Option<String>,
    lat: Option<f64>,
    lng: Option<f64>,
    admin_note: Option<String>,
    admin_note_at: Option<DateTime<Utc>>,
    submitted_at: Option<DateTime<Utc>>,
    worker_note: Option<String>,
    returned_note: Option<String>,
    returned_by: Option<String>,
    returned_at: Option<DateTime<Utc>>,
    problem_reason: Option<TaskProblemReason>,
    problem_note: Option<String>,
    problem_at: Option<DateTime<Utc>>,
    cancelled_note: Option<String>,
    cancelled_by: Option<String>,
    cancelled_at: Option<DateTime<Utc>>,
    approved_by: Option<String>,
    approved_at: Option<DateTime<Utc>>,
    next_task_id: Option<Uuid>,
}

#[derive(sqlx::FromRow)]
struct SlotRow {
    slot_id: String,
    label: String,
    hint: Option<String>,
    retake: bool,
    r2_key: Option<String>,
    taken_at: Option<DateTime<Utc>>,
    lat: Option<f64>,
    lng: Option<f64>,
    accuracy_m: Option<f64>,
}

// A note with who wrote it and when, when all three are there.
fn note(text: Option<String>, by: Option<String>, at: Option<DateTime<Utc>>) -> Option<TaskNote> {
    Some(TaskNote {
        text: text?,
        by: Person::admin(by?),
        at: at?,
    })
}

/*
    One of the caller's tasks, whole: customer, photo slots (with 15-minute
    links), checklist and whatever the admin last said. 404 when it isn't
    theirs. Runs in the company's transaction
*/
async fn load(
    conn: &mut PgConnection,
    storage: Option<&Storage>,
    org_id: Uuid,
    user_id: Uuid,
    task_id: Uuid,
) -> ApiResult<Task> {
    let t: TaskRow = sqlx::query_as(
        "SELECT t.id, t.reference, t.title, t.status, t.due_at, t.stage_index,
                c.stage_count, ab.name AS assigned_by,
                c.name AS customer_name, c.system_kw, c.address, c.phone, c.lat, c.lng,
                t.admin_note, t.admin_note_at, t.submitted_at, t.worker_note,
                t.returned_note, rb.name AS returned_by, t.returned_at,
                t.problem_reason, t.problem_note, t.problem_at,
                t.cancelled_note, cb.name AS cancelled_by, t.cancelled_at,
                apb.name AS approved_by, t.approved_at, t.next_task_id
         FROM tasks t
         JOIN customers c ON c.id = t.customer_id
         LEFT JOIN users ab ON ab.id = t.assigned_by
         LEFT JOIN users rb ON rb.id = t.returned_by
         LEFT JOIN users cb ON cb.id = t.cancelled_by
         LEFT JOIN users apb ON apb.id = t.approved_by
         WHERE t.id = $1 AND t.assignee_id = $2",
    )
    .bind(task_id)
    .bind(user_id)
    .fetch_optional(&mut *conn)
    .await?
    .ok_or_else(ApiError::not_found)?;

    let slots: Vec<SlotRow> = sqlx::query_as(
        "SELECT s.slot_id, s.label, s.hint, s.retake, u.r2_key,
                s.taken_at, s.lat, s.lng, s.accuracy_m
         FROM task_photo_slots s LEFT JOIN uploads u ON u.id = s.upload_id
         WHERE s.task_id = $1 ORDER BY s.position",
    )
    .bind(task_id)
    .fetch_all(&mut *conn)
    .await?;
    let checklist: Vec<ChecklistItem> = sqlx::query_as(
        "SELECT item_id AS id, text, done FROM task_checklist_items
         WHERE task_id = $1 ORDER BY position",
    )
    .bind(task_id)
    .fetch_all(&mut *conn)
    .await?;

    // The next stage's task, when it's the caller's too.
    let next_task = match t.next_task_id {
        Some(next) => {
            sqlx::query_as(select_summary!("WHERE t.id = $1 AND t.assignee_id = $2"))
                .bind(next)
                .bind(user_id)
                .fetch_optional(&mut *conn)
                .await?
        }
        None => None,
    };

    let mut photos = Vec::with_capacity(slots.len());
    for s in slots {
        let photo = match (s.r2_key, s.taken_at) {
            (Some(key), Some(taken_at)) => Some(ProofPhoto {
                url: uploads::read_url(storage, org_id, &key)?,
                taken_at,
                lat: s.lat,
                lng: s.lng,
                accuracy_m: s.accuracy_m,
            }),
            _ => None,
        };
        photos.push(ProofSlot {
            photo,
            id: s.slot_id,
            label: s.label,
            hint: s.hint,
            retake: s.retake,
        });
    }

    Ok(Task {
        id: t.id,
        reference: t.reference,
        title: t.title,
        status: t.status,
        due_at: t.due_at,
        stage: TaskStage {
            index: t.stage_index,
            count: t.stage_count,
        },
        admin_note: note(t.admin_note, t.assigned_by.clone(), t.admin_note_at),
        assigned_by: t.assigned_by.map(Person::admin),
        customer: TaskCustomer {
            name: t.customer_name,
            system_kw: t.system_kw,
            address: t.address,
            phone: t.phone,
            lat: t.lat,
            lng: t.lng,
        },
        photos,
        checklist,
        submitted_at: t.submitted_at,
        worker_note: t.worker_note,
        returned: note(t.returned_note, t.returned_by, t.returned_at),
        problem: match (t.problem_reason, t.problem_note, t.problem_at) {
            (Some(reason), Some(note), Some(at)) => Some(TaskProblem { reason, note, at }),
            _ => None,
        },
        cancelled: note(t.cancelled_note, t.cancelled_by, t.cancelled_at),
        approved: match (t.approved_by, t.approved_at) {
            (Some(by), Some(at)) => Some(TaskApproval {
                by: Person::admin(by),
                at,
                next_task,
            }),
            _ => None,
        },
    })
}

/*
    The caller's task, locked for this transaction, and its status. 404
    when it isn't theirs; 409 `task.locked` unless it takes changes
*/
async fn editable(conn: &mut PgConnection, user_id: Uuid, task_id: Uuid) -> ApiResult<TaskStatus> {
    let status: TaskStatus = sqlx::query_scalar(
        "SELECT status FROM tasks WHERE id = $1 AND assignee_id = $2 FOR UPDATE",
    )
    .bind(task_id)
    .bind(user_id)
    .fetch_optional(&mut *conn)
    .await?
    .ok_or_else(ApiError::not_found)?;
    match status {
        TaskStatus::Assigned | TaskStatus::Returned => Ok(status),
        _ => Err(locked()),
    }
}

// One line in the task's history, in the caller's transaction.
pub(crate) async fn event(
    conn: &mut PgConnection,
    org_id: Uuid,
    task_id: Uuid,
    kind: TaskEventKind,
    actor_id: Uuid,
    detail: Option<&str>,
) -> ApiResult<()> {
    sqlx::query(
        "INSERT INTO task_events (id, org_id, task_id, kind, actor_id, detail)
         VALUES ($1, $2, $3, $4, $5, $6)",
    )
    .bind(Uuid::now_v7())
    .bind(org_id)
    .bind(task_id)
    .bind(kind)
    .bind(actor_id)
    .bind(detail)
    .execute(conn)
    .await?;
    Ok(())
}

// Tells the admins about a task: its title, the customer, then `more`.
async fn tell_admins(
    conn: &mut PgConnection,
    org_id: Uuid,
    task_id: Uuid,
    kind: notify::Kind,
    title: &str,
    more: Option<&str>,
) -> ApiResult<()> {
    let mut body: String = sqlx::query_scalar(
        "SELECT t.title || ' · ' || c.name
         FROM tasks t JOIN customers c ON c.id = t.customer_id WHERE t.id = $1",
    )
    .bind(task_id)
    .fetch_one(&mut *conn)
    .await?;
    if let Some(more) = more {
        body.push_str(&format!(": “{more}”"));
    }
    let links = notify::Links {
        task_id: Some(task_id),
        ..Default::default()
    };
    notify::add_for_admins(conn, org_id, kind, title, &body, links).await
}

/*
    #25 The caller's tasks
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/tasks",
    operation_id = "listMyTasks",
    tag = "tasks",
    params(("org_id" = Uuid, Path, description = "The company."), TaskListQuery),
    responses(
        (status = 200, description = "One page.", body = TaskPage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_my_tasks(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiQuery(q): ApiQuery<TaskListQuery>,
) -> ApiResult<Json<TaskPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let end_of_today = end_of_today(Utc::now());
    let mut tx = member.begin(&state.db).await?;

    /*
        - today: open work due by tonight (overdue too), plus anything
          returned or on hold whatever its date, in due order
        - upcoming: due after today, in due order
        - done: approved and cancelled, latest first
        A page ends at its last row's (due_at, id), or (status_at, id)
    */
    let query = match q.view {
        TaskView::Today => sqlx::query_as(select_summary!(
            "WHERE t.assignee_id = $1
               AND t.status IN ('assigned', 'returned', 'submitted')
               AND (t.due_at < $2 OR t.status = 'returned' OR t.problem_at IS NOT NULL)
               AND ($4::timestamptz IS NULL OR (t.due_at, t.id) > ($4, $5))
             ORDER BY t.due_at, t.id LIMIT $3"
        )),
        TaskView::Upcoming => sqlx::query_as(select_summary!(
            "WHERE t.assignee_id = $1
               AND t.status IN ('assigned', 'submitted')
               AND t.due_at >= $2 AND t.problem_at IS NULL
               AND ($4::timestamptz IS NULL OR (t.due_at, t.id) > ($4, $5))
             ORDER BY t.due_at, t.id LIMIT $3"
        )),
        TaskView::Done => sqlx::query_as(select_summary!(
            "WHERE t.assignee_id = $1
               AND t.status IN ('approved', 'cancelled')
               AND $2::timestamptz IS NOT NULL
               AND ($4::timestamptz IS NULL OR (t.status_at, t.id) < ($4, $5))
             ORDER BY t.status_at DESC, t.id DESC LIMIT $3"
        )),
    };
    let mut items: Vec<TaskSummary> = query
        .bind(member.user_id)
        .bind(end_of_today)
        .bind(page.fetch())
        .bind(page.after_time())
        .bind(page.after_id())
        .fetch_all(&mut *tx)
        .await?;
    tx.commit().await?;

    let view = q.view;
    let info = page.finish(&mut items, |t| Cursor {
        created_at: match view {
            TaskView::Done => t.status_at,
            _ => t.due_at,
        },
        id: t.id,
    });
    Ok(Json(TaskPage { items, page: info }))
}

/*
    #26 One task
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/tasks/{task_id}",
    operation_id = "getTask",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    responses(
        (status = 200, description = "The task.", body = Task),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_task(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiPath(path): ApiPath<TaskPath>,
) -> ApiResult<Json<Task>> {
    let mut tx = member.begin(&state.db).await?;
    let task = load(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        path.task_id,
    )
    .await?;
    tx.commit().await?;
    Ok(Json(task))
}

/*
    #27 A proof photo
    --------------------------------------------------------------------
    - the photo is already in R2 (`POST /uploads`, purpose `proof`);
      `uploads::attach` checks it arrived whole before the slot takes it
    - fills the slot, or replaces its photo (a retake clears `retake`)
    - where it was taken is stored as the phone sent it (position,
      accuracy, whether it said mocked). Nothing is compared or judged
      (owner, 2026-11-22), so `far`, `inaccurate` and `distance_m` in
      the table aren't written
    - the history gets one "photos uploaded" line per round of photos,
      not one per photo
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/photos",
    operation_id = "addTaskPhoto",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    request_body = ProofPhotoCreate,
    responses(
        (status = 200, description = "The task, updated.", body = Task),
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
async fn add_task_photo(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<ProofPhotoCreate>,
) -> ApiResult<Json<Task>> {
    let mut invalid = ApiError::validation(Vec::new());
    let mut bad = false;
    if !validate::is_lat(req.lat) {
        invalid = invalid.field("lat", "-90 to 90.");
        bad = true;
    }
    if !validate::is_lng(req.lng) {
        invalid = invalid.field("lng", "-180 to 180.");
        bad = true;
    }
    if !(req.accuracy_m.is_finite() && req.accuracy_m >= 0.0) {
        invalid = invalid.field("accuracy_m", "0 or more.");
        bad = true;
    }
    if bad {
        return Err(invalid);
    }

    let task_id = path.task_id;
    let mut tx = member.begin(&state.db).await?;
    editable(&mut tx, member.user_id, task_id).await?;

    let has_slot: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM task_photo_slots WHERE task_id = $1 AND slot_id = $2)",
    )
    .bind(task_id)
    .bind(&req.slot_id)
    .fetch_one(&mut *tx)
    .await?;
    if !has_slot {
        return Err(
            ApiError::validation(Vec::new()).field("slot_id", "This task has no such photo.")
        );
    }

    uploads::attach(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        req.upload_id,
        UploadPurpose::Proof,
        "upload_id",
    )
    .await?;

    sqlx::query(
        "UPDATE task_photo_slots
         SET upload_id = $3, taken_at = $4, lat = $5, lng = $6, accuracy_m = $7,
             mocked = $8, retake = false
         WHERE task_id = $1 AND slot_id = $2",
    )
    .bind(task_id)
    .bind(&req.slot_id)
    .bind(req.upload_id)
    .bind(req.taken_at)
    .bind(req.lat)
    .bind(req.lng)
    .bind(req.accuracy_m)
    .bind(req.mocked_location)
    .execute(&mut *tx)
    .await?;

    let last: Option<TaskEventKind> = sqlx::query_scalar(
        "SELECT kind FROM task_events WHERE task_id = $1 ORDER BY created_at DESC, id DESC LIMIT 1",
    )
    .bind(task_id)
    .fetch_optional(&mut *tx)
    .await?;
    if last != Some(TaskEventKind::PhotosUploaded) {
        event(
            &mut tx,
            member.org_id,
            task_id,
            TaskEventKind::PhotosUploaded,
            member.user_id,
            None,
        )
        .await?;
    }

    let task = load(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        task_id,
    )
    .await?;
    tx.commit().await?;
    Ok(Json(task))
}

/*
    #28 Tick or untick a checklist item
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/tasks/{task_id}/checklist/{item_id}",
    operation_id = "setTaskChecklistItem",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
        ("item_id" = String, Path, description = "The checklist item."),
    ),
    request_body = ChecklistSet,
    responses(
        (status = 200, description = "The task, updated.", body = Task),
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
async fn set_task_checklist_item(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiPath(path): ApiPath<ChecklistPath>,
    ApiJson(req): ApiJson<ChecklistSet>,
) -> ApiResult<Json<Task>> {
    let mut tx = member.begin(&state.db).await?;
    editable(&mut tx, member.user_id, path.task_id).await?;
    let changed = sqlx::query(
        "UPDATE task_checklist_items
         SET done = $3, done_at = CASE WHEN $3 THEN now() END
         WHERE task_id = $1 AND item_id = $2",
    )
    .bind(path.task_id)
    .bind(&path.item_id)
    .bind(req.done)
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if changed == 0 {
        return Err(ApiError::not_found());
    }
    let task = load(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        path.task_id,
    )
    .await?;
    tx.commit().await?;
    Ok(Json(task))
}

/*
    #29 Submit for approval
    --------------------------------------------------------------------
    - every slot needs a photo (retakes retaken) and every item a tick,
      else 422 `task.incomplete`
    - → submitted; photos lock until the admin approves or returns it.
      An open problem is closed: the work got done
    - history: "submitted", or "resubmitted" with what was retaken
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/submit",
    operation_id = "submitTask",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = TaskSubmit,
    responses(
        (status = 200, description = "Submitted.", body = Task),
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
async fn submit_task(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    key: IdempotencyKey,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<TaskSubmit>,
) -> ApiResult<Response> {
    let task_id = path.task_id;
    let request = format!("POST /api/v1/orgs/{}/tasks/{task_id}/submit", member.org_id);
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let note = text("note", req.note.as_deref())?;

    let mut tx = member.begin(&state.db).await?;
    let status = editable(&mut tx, member.user_id, task_id).await?;

    let (missing, unticked, photos): (i64, i64, i64) = sqlx::query_as(
        "SELECT
            (SELECT count(*) FROM task_photo_slots
             WHERE task_id = $1 AND (upload_id IS NULL OR retake)),
            (SELECT count(*) FROM task_checklist_items WHERE task_id = $1 AND NOT done),
            (SELECT count(*) FROM task_photo_slots WHERE task_id = $1)",
    )
    .bind(task_id)
    .fetch_one(&mut *tx)
    .await?;
    if missing > 0 || unticked > 0 {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "task.incomplete",
            "Some photos or checklist items are missing",
        )
        .detail(format!(
            "{missing} photo(s) and {unticked} checklist item(s) to go."
        )));
    }

    let (kind, detail) = if status == TaskStatus::Returned {
        let retaken: Vec<String> = sqlx::query_scalar(
            "SELECT s.label FROM task_photo_slots s JOIN tasks t ON t.id = s.task_id
             WHERE s.task_id = $1 AND s.taken_at > t.returned_at ORDER BY s.position",
        )
        .bind(task_id)
        .fetch_all(&mut *tx)
        .await?;
        let detail = if retaken.is_empty() {
            "Sent again".to_owned()
        } else {
            format!("{} retaken", retaken.join(", "))
        };
        (TaskEventKind::Resubmitted, detail)
    } else {
        let mut detail = format!("{photos} photos · checklist done");
        if note.is_some() {
            detail.push_str(" · note added");
        }
        (TaskEventKind::Submitted, detail)
    };

    sqlx::query(
        "UPDATE tasks
         SET status = 'submitted', status_at = now(), submitted_at = now(), worker_note = $2,
             problem_reason = NULL, problem_note = NULL, problem_at = NULL,
             problem_upload_id = NULL
         WHERE id = $1",
    )
    .bind(task_id)
    .bind(&note)
    .execute(&mut *tx)
    .await?;
    event(
        &mut tx,
        member.org_id,
        task_id,
        kind,
        member.user_id,
        Some(&detail),
    )
    .await?;

    tell_admins(
        &mut tx,
        member.org_id,
        task_id,
        crate::notify::Kind::TaskSubmitted,
        "Proof to check",
        None,
    )
    .await?;
    let task = load(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        task_id,
    )
    .await?;
    let body = serde_json::to_value(&task).map_err(|_| ApiError::internal())?;
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
    Ok((StatusCode::OK, Json(body)).into_response())
}

/*
    #30 Report a problem
    --------------------------------------------------------------------
    - on an assigned task: the task stays assigned with `problem` set
      ("On hold" in the app) until the admin reschedules, reassigns or
      cancels it. A second report replaces the first
    - an optional photo, attached like a proof photo
    - the admin sees it on the task and in its history; an admin feed
      for it comes with the admin website
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/problems",
    operation_id = "reportTaskProblem",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = TaskProblemCreate,
    responses(
        (status = 200, description = "Reported.", body = Task),
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
async fn report_task_problem(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    key: IdempotencyKey,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<TaskProblemCreate>,
) -> ApiResult<Response> {
    let task_id = path.task_id;
    let request = format!(
        "POST /api/v1/orgs/{}/tasks/{task_id}/problems",
        member.org_id
    );
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let note = required_text("note", &req.note)?;

    let mut tx = member.begin(&state.db).await?;
    if editable(&mut tx, member.user_id, task_id).await? != TaskStatus::Assigned {
        return Err(locked());
    }
    if let Some(upload_id) = req.upload_id {
        uploads::attach(
            &mut tx,
            state.storage.as_ref(),
            member.org_id,
            member.user_id,
            upload_id,
            UploadPurpose::Proof,
            "upload_id",
        )
        .await?;
    }
    sqlx::query(
        "UPDATE tasks
         SET problem_reason = $2, problem_note = $3, problem_at = now(), problem_upload_id = $4
         WHERE id = $1",
    )
    .bind(task_id)
    .bind(req.reason)
    .bind(&note)
    .bind(req.upload_id)
    .execute(&mut *tx)
    .await?;
    event(
        &mut tx,
        member.org_id,
        task_id,
        TaskEventKind::ProblemReported,
        member.user_id,
        Some(&note),
    )
    .await?;

    tell_admins(
        &mut tx,
        member.org_id,
        task_id,
        crate::notify::Kind::TaskProblem,
        "Problem reported",
        Some(&note),
    )
    .await?;
    let task = load(
        &mut tx,
        state.storage.as_ref(),
        member.org_id,
        member.user_id,
        task_id,
    )
    .await?;
    let body = serde_json::to_value(&task).map_err(|_| ApiError::internal())?;
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
    Ok((StatusCode::OK, Json(body)).into_response())
}

/*
    #31 Reply to the admin
    --------------------------------------------------------------------
    - goes into the task's history, where the admin reads it. Open tasks
      only (409 on approved or cancelled ones)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/tasks/{task_id}/messages",
    operation_id = "sendTaskMessage",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    request_body = TaskMessage,
    responses(
        (status = 204, description = "Sent."),
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
async fn send_task_message(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiPath(path): ApiPath<TaskPath>,
    ApiJson(req): ApiJson<TaskMessage>,
) -> ApiResult<StatusCode> {
    let text = required_text("text", &req.text)?;
    let mut tx = member.begin(&state.db).await?;
    let status: TaskStatus =
        sqlx::query_scalar("SELECT status FROM tasks WHERE id = $1 AND assignee_id = $2")
            .bind(path.task_id)
            .bind(member.user_id)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or_else(ApiError::not_found)?;
    if matches!(status, TaskStatus::Approved | TaskStatus::Cancelled) {
        return Err(locked());
    }
    event(
        &mut tx,
        member.org_id,
        path.task_id,
        TaskEventKind::Message,
        member.user_id,
        Some(&text),
    )
    .await?;
    tell_admins(
        &mut tx,
        member.org_id,
        path.task_id,
        crate::notify::Kind::TaskMessage,
        "Installer replied",
        Some(&text),
    )
    .await?;
    tx.commit().await?;
    Ok(StatusCode::NO_CONTENT)
}

#[derive(sqlx::FromRow)]
struct EventRow {
    kind: TaskEventKind,
    actor_id: Uuid,
    actor_name: String,
    created_at: DateTime<Utc>,
    detail: Option<String>,
}

/*
    #32 The task's history, newest first
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/tasks/{task_id}/history",
    operation_id = "getTaskHistory",
    tag = "tasks",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    responses(
        (status = 200, description = "The history.", body = TaskHistory),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_task_history(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
    ApiPath(path): ApiPath<TaskPath>,
) -> ApiResult<Json<TaskHistory>> {
    let mut tx = member.begin(&state.db).await?;
    let mine: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM tasks WHERE id = $1 AND assignee_id = $2)",
    )
    .bind(path.task_id)
    .bind(member.user_id)
    .fetch_one(&mut *tx)
    .await?;
    if !mine {
        return Err(ApiError::not_found());
    }
    let rows: Vec<EventRow> = sqlx::query_as(
        "SELECT e.kind, e.actor_id, u.name AS actor_name, e.created_at, e.detail
         FROM task_events e JOIN users u ON u.id = e.actor_id
         WHERE e.task_id = $1 ORDER BY e.created_at DESC, e.id DESC",
    )
    .bind(path.task_id)
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

    let events = rows
        .into_iter()
        .map(|e| TaskEvent {
            kind: e.kind,
            actor: if e.actor_id == member.user_id {
                Person {
                    name: e.actor_name,
                    role: None,
                    you: true,
                }
            } else {
                Person::admin(e.actor_name)
            },
            at: e.created_at,
            detail: e.detail,
        })
        .collect();
    Ok(Json(TaskHistory { events }))
}

/*
    #33 This month's work, for the profile
    --------------------------------------------------------------------
    - tasks: submitted this month (in India)
    - returned: times the admin sent one back this month
    - minutes on site: from a task's first photo to its submission,
      averaged over this month's; 0 with none yet
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/me/stats",
    operation_id = "getMyStats",
    tag = "tasks",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "This month.", body = WorkerStats),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_my_stats(
    State(state): State<AppState>,
    member: OrgMember<Workers>,
) -> ApiResult<Json<WorkerStats>> {
    let since = start_of_month(Utc::now());
    let mut tx = member.begin(&state.db).await?;
    let (tasks_this_month, returned_this_month, avg_minutes_on_site): (i64, i64, i64) =
        sqlx::query_as(
            "WITH mine AS (
                SELECT t.id, t.submitted_at,
                       (SELECT min(s.taken_at) FROM task_photo_slots s WHERE s.task_id = t.id)
                           AS first_photo
                FROM tasks t
                WHERE t.assignee_id = $1 AND t.submitted_at >= $2
                  AND t.status IN ('submitted', 'returned', 'approved')
             )
             SELECT
                (SELECT count(*) FROM mine),
                (SELECT count(*) FROM task_events e JOIN tasks t ON t.id = e.task_id
                 WHERE t.assignee_id = $1 AND e.kind = 'returned' AND e.created_at >= $2),
                coalesce((SELECT round(avg(extract(epoch FROM submitted_at - first_photo) / 60))
                          FROM mine WHERE first_photo IS NOT NULL), 0)::bigint",
        )
        .bind(member.user_id)
        .bind(since)
        .fetch_one(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(WorkerStats {
        tasks_this_month,
        returned_this_month,
        avg_minutes_on_site,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    #[test]
    fn today_ends_at_midnight_in_india() {
        // 20:00 UTC on 15 Nov is 01:30 on 16 Nov in India: today ends at
        // midnight starting 17 Nov there, 18:30 UTC on 16 Nov.
        let now = Utc.with_ymd_and_hms(2026, 11, 15, 20, 0, 0).unwrap();
        assert_eq!(
            end_of_today(now),
            Utc.with_ymd_and_hms(2026, 11, 16, 18, 30, 0).unwrap()
        );
    }

    #[test]
    fn the_month_starts_in_india() {
        // 19:00 UTC on 31 Oct is already 1 Nov in India.
        let now = Utc.with_ymd_and_hms(2026, 10, 31, 19, 0, 0).unwrap();
        assert_eq!(
            start_of_month(now),
            Utc.with_ymd_and_hms(2026, 10, 31, 18, 30, 0).unwrap()
        );
    }
}
