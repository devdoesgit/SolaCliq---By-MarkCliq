/*
    The company's tasks, for its admin (W3)
    --------------------------------------------------------------------
    - whoever they're assigned to, removed installers' included, so
      those can be reassigned
    - proof is shown as sent: nothing here judges a photo or a position
*/

use axum::{Json, extract::State};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use super::{AdminFile, AdminStage, ERRORS};
use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiPath, ApiQuery},
    org::{Admins, OrgMember},
    page::{Cursor, Page, PageInfo},
    routes::{
        tasks::{
            ChecklistItem, ProofPhoto, ProofSlot, TaskEventKind, TaskProblemReason, TaskStatus,
        },
        uploads,
    },
    stages::{self, Stages},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_tasks))
        .routes(routes!(get_task))
}

#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AdminTaskView {
    // Assigned or returned.
    Open,
    // Each of those alone: the board's columns.
    Assigned,
    Returned,
    Submitted,
    // Open, with a reported problem.
    Problem,
    // Approved or cancelled.
    Done,
}

impl AdminTaskView {
    fn as_str(self) -> &'static str {
        match self {
            AdminTaskView::Open => "open",
            AdminTaskView::Assigned => "assigned",
            AdminTaskView::Returned => "returned",
            AdminTaskView::Submitted => "submitted",
            AdminTaskView::Problem => "problem",
            AdminTaskView::Done => "done",
        }
    }
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct TaskQuery {
    view: Option<AdminTaskView>,
    assignee_id: Option<Uuid>,
    customer_id: Option<Uuid>,
    cursor: Option<String>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct TaskPath {
    task_id: Uuid,
}

// The contract's `AdminTaskSummary`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminTaskSummary {
    pub id: Uuid,
    pub reference: String,
    pub title: String,
    pub status: TaskStatus,
    pub due_at: DateTime<Utc>,
    pub status_at: DateTime<Utc>,
    pub stage: AdminStage,
    pub customer_id: Uuid,
    pub customer_name: String,
    // The customer's city, or their address without one.
    pub place: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system_kw: Option<f64>,
    pub assignee_id: Uuid,
    pub assignee_name: String,
    // False once they were removed from the company.
    pub assignee_active: bool,
    pub has_problem: bool,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminTaskPage {
    pub items: Vec<AdminTaskSummary>,
    pub page: PageInfo,
}

#[derive(sqlx::FromRow)]
struct SummaryRow {
    id: Uuid,
    reference: String,
    title: String,
    status: TaskStatus,
    due_at: DateTime<Utc>,
    status_at: DateTime<Utc>,
    stage_index: i32,
    customer_id: Uuid,
    customer_name: String,
    place: String,
    system_kw: Option<f64>,
    assignee_id: Uuid,
    assignee_name: String,
    assignee_active: bool,
    has_problem: bool,
    created_at: DateTime<Utc>,
}

fn summary(r: SummaryRow, stages: &Stages) -> AdminTaskSummary {
    AdminTaskSummary {
        stage: AdminStage::at(r.stage_index, stages),
        id: r.id,
        reference: r.reference,
        title: r.title,
        status: r.status,
        due_at: r.due_at,
        status_at: r.status_at,
        customer_id: r.customer_id,
        customer_name: r.customer_name,
        place: r.place,
        system_kw: r.system_kw,
        assignee_id: r.assignee_id,
        assignee_name: r.assignee_name,
        assignee_active: r.assignee_active,
        has_problem: r.has_problem,
    }
}

#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct AdminTaskEvent {
    pub kind: TaskEventKind,
    pub actor_name: String,
    pub at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AdminTaskProblem {
    pub reason: TaskProblemReason,
    pub note: String,
    pub at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub photo: Option<AdminFile>,
}

// The contract's `AdminTask`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminTask {
    #[serde(flatten)]
    pub summary: AdminTaskSummary,
    pub address: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lng: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub worker_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub submitted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub returned_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cancelled_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub problem: Option<AdminTaskProblem>,
    pub photos: Vec<ProofSlot>,
    pub checklist: Vec<ChecklistItem>,
    // Newest first, the installer's replies among them.
    pub events: Vec<AdminTaskEvent>,
}

#[derive(sqlx::FromRow)]
struct DetailRow {
    address: String,
    phone: Option<String>,
    lat: Option<f64>,
    lng: Option<f64>,
    admin_note: Option<String>,
    worker_note: Option<String>,
    submitted_at: Option<DateTime<Utc>>,
    returned_note: Option<String>,
    cancelled_note: Option<String>,
    problem_reason: Option<TaskProblemReason>,
    problem_note: Option<String>,
    problem_at: Option<DateTime<Utc>>,
    problem_key: Option<String>,
    problem_type: Option<String>,
    problem_size: Option<i64>,
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

macro_rules! select_summary {
    ($rest:literal) => {
        concat!(
            "SELECT t.id, t.reference, t.title, t.status, t.due_at, t.status_at, t.stage_index,
                    c.id AS customer_id, c.name AS customer_name,
                    coalesce(c.city, c.address) AS place, c.system_kw,
                    t.assignee_id, w.name AS assignee_name,
                    EXISTS (SELECT 1 FROM memberships m
                            WHERE m.org_id = t.org_id AND m.user_id = t.assignee_id
                              AND m.role = 'worker' AND m.removed_at IS NULL) AS assignee_active,
                    (t.problem_at IS NOT NULL
                     AND t.status IN ('assigned', 'returned')) AS has_problem,
                    t.created_at
             FROM tasks t
             JOIN customers c ON c.id = t.customer_id
             JOIN users w ON w.id = t.assignee_id ",
            $rest
        )
    };
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/tasks",
    operation_id = "adminListTasks",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), TaskQuery),
    responses(
        (status = 200, description = "One page.", body = AdminTaskPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_tasks(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<TaskQuery>,
) -> ApiResult<Json<AdminTaskPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = admin.begin(&state.db).await?;
    let mut rows: Vec<SummaryRow> = sqlx::query_as(select_summary!(
        "WHERE t.org_id = $1
           AND CASE $3::text
                 WHEN 'open' THEN t.status IN ('assigned', 'returned')
                 WHEN 'assigned' THEN t.status = 'assigned'
                 WHEN 'returned' THEN t.status = 'returned'
                 WHEN 'submitted' THEN t.status = 'submitted'
                 WHEN 'problem' THEN t.status IN ('assigned', 'returned')
                                     AND t.problem_at IS NOT NULL
                 WHEN 'done' THEN t.status IN ('approved', 'cancelled')
                 ELSE true
               END
           AND ($4::uuid IS NULL OR t.assignee_id = $4)
           AND ($5::uuid IS NULL OR t.customer_id = $5)
           AND ($6::timestamptz IS NULL OR (t.created_at, t.id) < ($6, $7))
         ORDER BY t.created_at DESC, t.id DESC LIMIT $2"
    ))
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.view.map(AdminTaskView::as_str))
    .bind(q.assignee_id)
    .bind(q.customer_id)
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
    Ok(Json(AdminTaskPage {
        items: rows.into_iter().map(|r| summary(r, &stages)).collect(),
        page: info,
    }))
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/tasks/{task_id}",
    operation_id = "adminGetTask",
    tag = "admin",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("task_id" = Uuid, Path, description = "The task."),
    ),
    responses(
        (status = 200, description = "The task.", body = AdminTask),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_task(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<TaskPath>,
) -> ApiResult<Json<AdminTask>> {
    let (org_id, id) = (admin.org_id, path.task_id);
    let storage = state.storage.as_ref();
    let mut tx = admin.begin(&state.db).await?;
    let row_summary: SummaryRow =
        sqlx::query_as(select_summary!("WHERE t.org_id = $1 AND t.id = $2"))
            .bind(org_id)
            .bind(id)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or_else(ApiError::not_found)?;
    let t: DetailRow = sqlx::query_as(
        "SELECT c.address, c.phone, c.lat, c.lng, t.admin_note, t.worker_note, t.submitted_at,
                t.returned_note, t.cancelled_note, t.problem_reason, t.problem_note, t.problem_at,
                u.r2_key AS problem_key, u.content_type AS problem_type,
                u.size_bytes AS problem_size
         FROM tasks t
         JOIN customers c ON c.id = t.customer_id
         LEFT JOIN uploads u ON u.id = t.problem_upload_id
         WHERE t.org_id = $1 AND t.id = $2",
    )
    .bind(org_id)
    .bind(id)
    .fetch_one(&mut *tx)
    .await?;
    let slots: Vec<SlotRow> = sqlx::query_as(
        "SELECT s.slot_id, s.label, s.hint, s.retake, u.r2_key,
                s.taken_at, s.lat, s.lng, s.accuracy_m
         FROM task_photo_slots s LEFT JOIN uploads u ON u.id = s.upload_id
         WHERE s.org_id = $1 AND s.task_id = $2 ORDER BY s.position",
    )
    .bind(org_id)
    .bind(id)
    .fetch_all(&mut *tx)
    .await?;
    let checklist: Vec<ChecklistItem> = sqlx::query_as(
        "SELECT item_id AS id, text, done FROM task_checklist_items
         WHERE org_id = $1 AND task_id = $2 ORDER BY position",
    )
    .bind(org_id)
    .bind(id)
    .fetch_all(&mut *tx)
    .await?;
    let events: Vec<AdminTaskEvent> = sqlx::query_as(
        "SELECT e.kind, u.name AS actor_name, e.created_at AS at, e.detail
         FROM task_events e JOIN users u ON u.id = e.actor_id
         WHERE e.org_id = $1 AND e.task_id = $2 ORDER BY e.created_at DESC, e.id DESC",
    )
    .bind(org_id)
    .bind(id)
    .fetch_all(&mut *tx)
    .await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;

    let problem = match (t.problem_reason, t.problem_note, t.problem_at) {
        (Some(reason), Some(note), Some(at)) => Some(AdminTaskProblem {
            reason,
            note,
            at,
            photo: match (t.problem_key, t.problem_type, t.problem_size) {
                (Some(key), Some(kind), Some(size)) => {
                    Some(AdminFile::sign(storage, org_id, &key, kind, size)?)
                }
                _ => None,
            },
        }),
        _ => None,
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
    Ok(Json(AdminTask {
        summary: summary(row_summary, &stages),
        address: t.address,
        phone: t.phone,
        lat: t.lat,
        lng: t.lng,
        admin_note: t.admin_note,
        worker_note: t.worker_note,
        submitted_at: t.submitted_at,
        returned_note: t.returned_note,
        cancelled_note: t.cancelled_note,
        problem,
        photos,
        checklist,
        events,
    }))
}
