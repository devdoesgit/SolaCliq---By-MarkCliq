//! `GET /me`: who is logged in and which companies they belong to. The app
//! calls it on start-up and builds every workspace from `memberships`.

use axum::{Json, extract::State};
use serde::Serialize;
use sqlx::PgPool;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::ApiResult,
    extract::AuthUser,
    org::{OrgStatus, PayType, Role},
    routes::uploads,
    storage::Storage,
};

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

/*
    One (company, role) the person has. Each is a workspace in the app.
    Companies that are pending or suspended are listed too, so the app can
    say so; removed memberships are not
*/
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
    /*
        The company's logo (F15): a 15-minute link to the PNG or JPEG.
        Left out when the company has none (the app shows initials). The
        path part stays the same until the logo changes, so the app can
        cache the image by it
    */
    #[serde(skip_serializing_if = "Option::is_none")]
    pub logo_url: Option<String>,
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
    Ok(Json(
        load(&state.db, state.storage.as_ref(), user.user_id).await?,
    ))
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
pub async fn load(db: &PgPool, storage: Option<&Storage>, user_id: Uuid) -> ApiResult<Me> {
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
        memberships: memberships(db, storage, user_id).await?,
    })
}

// One row of the memberships query below.
#[derive(sqlx::FromRow)]
struct MembershipRow {
    org_id: Uuid,
    org_name: String,
    org_status: OrgStatus,
    org_phone: Option<String>,
    org_logo_key: Option<String>,
    role: Role,
    pay_type: Option<PayType>,
}

/*
    The person's companies, oldest membership first (the app opens the
    first one when nothing was chosen before). Removed ones are skipped.
    In the person's scope: `user_id` comes from their session, or from
    the password login just checked
*/
async fn memberships(
    db: &PgPool,
    storage: Option<&Storage>,
    user_id: Uuid,
) -> ApiResult<Vec<Membership>> {
    let mut tx = crate::scope::person(db, user_id).await?;
    let rows: Vec<MembershipRow> = sqlx::query_as(
        "SELECT o.id AS org_id, o.name AS org_name, o.status AS org_status,
                o.phone AS org_phone, o.logo_key AS org_logo_key, m.role, m.pay_type
         FROM memberships m JOIN orgs o ON o.id = m.org_id
         WHERE m.user_id = $1 AND m.removed_at IS NULL
         ORDER BY m.created_at, m.id",
    )
    .bind(user_id)
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

    rows.into_iter()
        .map(|r| {
            // No link when uploads aren't set up (development without R2).
            let logo_url = match &r.org_logo_key {
                Some(key) => {
                    Some(uploads::read_url(storage, r.org_id, key)?).filter(|url| !url.is_empty())
                }
                None => None,
            };
            Ok(Membership {
                org: OrgSummary {
                    id: r.org_id,
                    name: r.org_name,
                    status: r.org_status,
                    phone: r.org_phone,
                    logo_url,
                },
                role: r.role,
                pay_type: r.pay_type,
            })
        })
        .collect()
}
