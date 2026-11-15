/*
    MarkCliq's side: reviewing and managing companies (F2)
    --------------------------------------------------------------------
    - GET  /platform/orgs                 every company (?status=pending
                                          is the review queue)
    - GET  /platform/orgs/{org_id}        one company's details
    - POST /platform/orgs/{org_id}/status approve, reject, suspend,
                                          reactivate
    - platform admins only (`PlatformAdmin`); make one with
      `cargo run -- make-platform-admin <email>`
*/

use axum::{Json, extract::State, http::StatusCode};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, PRODUCT_NAME,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath, ApiQuery},
    mail::{Email, template::Message},
    org::{BusinessType, OrgStatus, PlatformAdmin},
    page::{Cursor, Page, PageInfo},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_orgs))
        .routes(routes!(get_org))
        .routes(routes!(set_status))
}

// The contract's `PlatformOrg`.
#[derive(Debug, Serialize, ToSchema)]
pub struct PlatformOrg {
    pub id: Uuid,
    pub name: String,
    pub legal_name: String,
    pub business_type: BusinessType,
    pub gstin: String,
    pub pan: String,
    pub address_line_1: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub address_line_2: Option<String>,
    pub city: String,
    pub state: String,
    pub pin_code: String,
    pub phone: String,
    pub status: OrgStatus,
    // The company's admin; none only if they were removed.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub owner: Option<Owner>,
    pub created_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reviewed_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub review_note: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct Owner {
    pub user_id: Uuid,
    pub name: String,
    pub email: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct PlatformOrgPage {
    pub items: Vec<PlatformOrg>,
    pub page: PageInfo,
}

// One row of `SELECT_ORG`. `FromRow` maps columns to fields by name.
#[derive(sqlx::FromRow)]
struct OrgRow {
    id: Uuid,
    name: String,
    legal_name: String,
    business_type: BusinessType,
    gstin: String,
    pan: String,
    address_line_1: String,
    address_line_2: Option<String>,
    city: String,
    state: String,
    pin_code: String,
    phone: String,
    status: OrgStatus,
    created_at: DateTime<Utc>,
    reviewed_at: Option<DateTime<Utc>>,
    review_note: Option<String>,
    owner_id: Option<Uuid>,
    owner_name: Option<String>,
    owner_email: Option<String>,
    owner_phone: Option<String>,
}

impl From<OrgRow> for PlatformOrg {
    fn from(r: OrgRow) -> Self {
        let owner = match (r.owner_id, r.owner_name, r.owner_email) {
            (Some(user_id), Some(name), Some(email)) => Some(Owner {
                user_id,
                name,
                email,
                phone: r.owner_phone,
            }),
            _ => None,
        };
        PlatformOrg {
            id: r.id,
            name: r.name,
            legal_name: r.legal_name,
            business_type: r.business_type,
            gstin: r.gstin,
            pan: r.pan,
            address_line_1: r.address_line_1,
            address_line_2: r.address_line_2,
            city: r.city,
            state: r.state,
            pin_code: r.pin_code,
            phone: r.phone,
            status: r.status,
            owner,
            created_at: r.created_at,
            reviewed_at: r.reviewed_at,
            review_note: r.review_note,
        }
    }
}

/*
    A company with its admin. Each query below adds its own WHERE;
    LEFT JOIN keeps companies that have no admin.
    A macro, not a const: `concat!` joins it to each query at compile
    time, so every query stays a fixed string (sqlx refuses SQL built at
    run time, as a guard against injection)
*/
macro_rules! select_org {
    () => {
        "SELECT o.id, o.name, o.legal_name, o.business_type, o.gstin, o.pan,
                o.address_line_1, o.address_line_2, o.city, o.state, o.pin_code,
                o.phone, o.status, o.created_at, o.reviewed_at, o.review_note,
                u.id AS owner_id, u.name AS owner_name, u.email AS owner_email,
                u.phone AS owner_phone
         FROM orgs o
         LEFT JOIN memberships m
                ON m.org_id = o.id AND m.role = 'org_admin' AND m.removed_at IS NULL
         LEFT JOIN users u ON u.id = m.user_id"
    };
}

async fn load(db: &sqlx::PgPool, org_id: Uuid) -> ApiResult<PlatformOrg> {
    let row: OrgRow = sqlx::query_as(concat!(select_org!(), " WHERE o.id = $1"))
        .bind(org_id)
        .fetch_optional(db)
        .await?
        .ok_or_else(ApiError::not_found)?;
    Ok(row.into())
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct ListQuery {
    // Only companies with this status (`pending` for the review queue).
    status: Option<OrgStatus>,
    // Opaque cursor from the previous page's `next_cursor`.
    cursor: Option<String>,
    // Page size, 1 to 100; 25 when left out.
    limit: Option<i64>,
}

// Every company, newest first, paged as in `page.rs`.
#[utoipa::path(
    get,
    path = "/platform/orgs",
    operation_id = "listPlatformOrgs",
    tag = "platform",
    params(ListQuery),
    responses(
        (status = 200, description = "One page of companies.", body = PlatformOrgPage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_orgs(
    State(state): State<AppState>,
    _admin: PlatformAdmin,
    ApiQuery(query): ApiQuery<ListQuery>,
) -> ApiResult<Json<PlatformOrgPage>> {
    let page = Page::new(query.cursor.as_deref(), query.limit)?;
    let mut rows: Vec<OrgRow> = sqlx::query_as(concat!(
        select_org!(),
        " WHERE ($2::org_status IS NULL OR o.status = $2)
           AND ($3::timestamptz IS NULL OR (o.created_at, o.id) < ($3, $4))
         ORDER BY o.created_at DESC, o.id DESC
         LIMIT $1"
    ))
    .bind(page.fetch())
    .bind(query.status)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&state.db)
    .await?;

    let page_info = page.finish(&mut rows, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    Ok(Json(PlatformOrgPage {
        items: rows.into_iter().map(PlatformOrg::from).collect(),
        page: page_info,
    }))
}

#[utoipa::path(
    get,
    path = "/platform/orgs/{org_id}",
    operation_id = "getPlatformOrg",
    tag = "platform",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The company.", body = PlatformOrg),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_org(
    State(state): State<AppState>,
    _admin: PlatformAdmin,
    ApiPath(org_id): ApiPath<Uuid>,
) -> ApiResult<Json<PlatformOrg>> {
    Ok(Json(load(&state.db, org_id).await?))
}

// The statuses a platform admin can set (`pending` is only ever the start).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum NewStatus {
    Active,
    Rejected,
    Suspended,
}

impl NewStatus {
    fn status(self) -> OrgStatus {
        match self {
            NewStatus::Active => OrgStatus::Active,
            NewStatus::Rejected => OrgStatus::Rejected,
            NewStatus::Suspended => OrgStatus::Suspended,
        }
    }

    /*
        Where each status can be set from
        - active: approving a pending company, or reactivating a
          suspended one
        - rejected: only a pending company (an approved one is suspended)
        - suspended: only an active company
    */
    fn allowed_from(self) -> &'static [OrgStatus] {
        match self {
            NewStatus::Active => &[OrgStatus::Pending, OrgStatus::Suspended],
            NewStatus::Rejected => &[OrgStatus::Pending],
            NewStatus::Suspended => &[OrgStatus::Active],
        }
    }
}

// The contract's `OrgStatusChange`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct OrgStatusChange {
    pub status: NewStatus,
    // Required to reject; emailed to the owner.
    pub note: Option<String>,
}

/*
    Approve, reject, suspend or reactivate
    --------------------------------------------------------------------
    - the move must be allowed (`NewStatus::allowed_from`), else 409
    - the check is the UPDATE's WHERE, so two admins acting at once can't
      both move the same company
    - records who decided, when, and the note
    - emails the owner when a pending company is approved or rejected;
      MarkCliq reaches out itself about suspensions
*/
#[utoipa::path(
    post,
    path = "/platform/orgs/{org_id}/status",
    operation_id = "setPlatformOrgStatus",
    tag = "platform",
    params(("org_id" = Uuid, Path, description = "The company.")),
    request_body = OrgStatusChange,
    responses(
        (status = 200, description = "The company, with its new status.", body = PlatformOrg),
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
async fn set_status(
    State(state): State<AppState>,
    admin: PlatformAdmin,
    ApiPath(org_id): ApiPath<Uuid>,
    ApiJson(req): ApiJson<OrgStatusChange>,
) -> ApiResult<Json<PlatformOrg>> {
    let note = req
        .note
        .map(|n| n.trim().to_owned())
        .filter(|n| !n.is_empty());
    if note.as_ref().is_some_and(|n| n.chars().count() > 1000) {
        return Err(ApiError::validation(Vec::new()).field("note", "Up to 1000 characters."));
    }
    if req.status == NewStatus::Rejected && note.is_none() {
        return Err(ApiError::validation(Vec::new())
            .field("note", "Say why it was rejected; the owner gets this note."));
    }

    // RETURNING the old status: the UPDATE sees the row before it changes.
    let previous: Option<OrgStatus> = sqlx::query_scalar(
        "UPDATE orgs o
         SET status = $2, review_note = $3, reviewed_at = now(),
             reviewed_by = $4, updated_at = now()
         FROM orgs before
         WHERE o.id = $1 AND before.id = o.id AND o.status = ANY($5)
         RETURNING before.status",
    )
    .bind(org_id)
    .bind(req.status.status())
    .bind(&note)
    .bind(admin.user_id)
    .bind(req.status.allowed_from())
    .fetch_optional(&state.db)
    .await?;

    let Some(previous) = previous else {
        // Nothing changed: the company is missing (404) or the move isn't allowed (409).
        let current = load(&state.db, org_id).await?;
        return Err(ApiError::new(
            StatusCode::CONFLICT,
            "org.status_change_not_allowed",
            "That status change isn't allowed",
        )
        .detail(format!(
            "The company is {:?}; it can't become {:?} from there.",
            current.status,
            req.status.status()
        )));
    };

    let org = load(&state.db, org_id).await?;
    tracing::info!(%org_id, from = ?previous, to = ?org.status, by = %admin.user_id, "company status changed");
    if previous == OrgStatus::Pending
        && let Some(owner) = &org.owner
    {
        state.mailer.send(decision_email(
            owner,
            &org.name,
            req.status,
            note.as_deref(),
        ));
    }
    Ok(Json(org))
}

// To the owner, when their registration is approved or rejected.
fn decision_email(owner: &Owner, org_name: &str, status: NewStatus, note: Option<&str>) -> Email {
    let (subject, heading, before, details, after) = if status == NewStatus::Active {
        (
            format!("{org_name} is approved on {PRODUCT_NAME}"),
            "You're approved".to_owned(),
            format!("Good news: {org_name} is approved and live on {PRODUCT_NAME}."),
            Vec::new(),
            "Log in with this email address. If you haven't set a password yet, \
             tap \"Log in\", then \"Forgot password?\", and we'll email you a \
             code to set one."
                .to_owned(),
        )
    } else {
        (
            format!("About {org_name}'s registration on {PRODUCT_NAME}"),
            "Registration not approved".to_owned(),
            format!("We couldn't approve {org_name}'s registration on {PRODUCT_NAME}."),
            vec![("Reason", note.unwrap_or("not given").to_owned())],
            "You can register again with the details corrected, or reply to \
             this email if you have questions."
                .to_owned(),
        )
    };
    Message {
        heading,
        before: vec![before],
        details,
        after: vec![after],
        sign_off: true,
        reason: Some(format!(
            "You're receiving this email because you registered {org_name} on {PRODUCT_NAME}."
        )),
    }
    .email(&owner.email, subject)
}
