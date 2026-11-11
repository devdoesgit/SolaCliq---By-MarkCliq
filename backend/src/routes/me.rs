//! `GET /me`: who is logged in and which companies they belong to. The app
//! calls it on start-up and builds every workspace from `memberships`.

use axum::{Json, extract::State};
use serde::Serialize;
use sqlx::PgPool;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{AppState, error::ApiResult, extract::AuthUser};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(get_me))
}

/// The contract's `Me`. `Serialize` turns it into JSON; field names stay
/// as written (snake_case), which is what the contract uses.
#[derive(Debug, Serialize, ToSchema)]
pub struct Me {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    /// Left out of the JSON when there is none, as the contract expects.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    pub email_verified: bool,
    pub is_platform_admin: bool,
    pub memberships: Vec<Membership>,
}

/// One (company, role) the person has. Each is a workspace in the app.
#[derive(Debug, Serialize, ToSchema)]
pub struct Membership {
    pub org: OrgSummary,
    pub role: Role,
    /// Agents only.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pay_type: Option<PayType>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct OrgSummary {
    pub id: Uuid,
    pub name: String,
    pub status: OrgStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum OrgStatus {
    Pending,
    Active,
    Suspended,
}

#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    OrgAdmin,
    Worker,
    Agent,
    Customer,
}

#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum PayType {
    Commission,
    Salary,
}

/// The signed-in person and their memberships
///
/// Used by both apps on start-up to restore the session.
#[utoipa::path(
    get,
    path = "/me",
    operation_id = "getMe",
    tag = "auth",
    responses(
        (status = 200, description = "The current user.", body = Me),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_me(State(state): State<AppState>, user: AuthUser) -> ApiResult<Json<Me>> {
    Ok(Json(load(&state.db, user.user_id).await?))
}

/// The row this reads. `FromRow` maps columns to fields by name.
#[derive(sqlx::FromRow)]
struct UserRow {
    id: Uuid,
    name: String,
    email: String,
    phone: Option<String>,
    email_verified: bool,
    is_platform_admin: bool,
}

/// Builds `Me` for a user. Shared with login, which returns the same shape.
pub async fn load(db: &PgPool, user_id: Uuid) -> ApiResult<Me> {
    // fetch_one fails with RowNotFound (→ 404) if the account is gone.
    let u: UserRow = sqlx::query_as(
        "SELECT id, name, email, phone,
                email_verified_at IS NOT NULL AS email_verified,
                is_platform_admin
         FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(db)
    .await?;

    Ok(Me {
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        email_verified: u.email_verified,
        is_platform_admin: u.is_platform_admin,
        // Companies arrive in phase 4 (orgs and memberships tables).
        memberships: Vec::new(),
    })
}
