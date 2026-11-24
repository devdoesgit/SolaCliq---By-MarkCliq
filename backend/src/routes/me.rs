/*
    `GET /me`: who is logged in and which companies they belong to. The app
    calls it on start-up and builds every workspace from `memberships`.
    `POST /me/terms`: the person agrees to the current terms (F16).
*/

use axum::{
    Json,
    extract::State,
    http::{StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::ApiResult,
    extract::{ApiJson, AuthUser},
    org::{OrgStatus, PayType, Role},
    rate_limit::ClientIp,
    routes::uploads,
    storage::Storage,
    terms::{self, Agreement, Document, Source, TermsStatus},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(get_me))
        .routes(routes!(accept_terms))
        .routes(routes!(delete_account))
}

/*
    The contract's `Me`. `Serialize` turns it into JSON; field names stay
    as written (snake_case), which is what the contract uses.
*/
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
    /*
        Which version of the terms the person agreed to, and which is in
        force. The app shows "Before you start" while they differ
    */
    pub terms: TermsStatus,
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

/*
    The signed-in person and their memberships

    Used by both apps on start-up to restore the session.
*/
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
    let terms = terms::status(&mut *db.acquire().await?, user_id).await?;

    Ok(Me {
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        email_verified: u.email_verified,
        is_platform_admin: u.is_platform_admin,
        memberships: memberships(db, storage, user_id).await?,
        terms,
    })
}

/// The contract's `AcceptTermsRequest`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct AcceptTermsRequest {
    pub version: i32,
}

/*
    Agree to the current Terms of Use and Privacy Policy (F16)
    --------------------------------------------------------------------
    - for accounts someone else made (team members, customers an agent
      registered), and for everyone after TERMS_VERSION goes up
    - only the version in force (422 `terms.required` otherwise)
    - a new row each time, even agreeing to the same version twice: the
      history is the proof, and a repeat does no harm
*/
#[utoipa::path(
    post,
    path = "/me/terms",
    operation_id = "acceptTerms",
    tag = "profile",
    request_body = AcceptTermsRequest,
    responses(
        (status = 204, description = "Recorded."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn accept_terms(
    State(state): State<AppState>,
    user: AuthUser,
    ip: ClientIp,
    ApiJson(req): ApiJson<AcceptTermsRequest>,
) -> ApiResult<StatusCode> {
    let version = terms::check_current(req.version)?;
    terms::record(
        &mut *state.db.acquire().await?,
        Agreement {
            user_id: user.user_id,
            document: Document::Terms,
            org_id: None,
            version,
            source: Source::App,
            ip: &ip,
        },
    )
    .await?;
    tracing::info!(user_id = %user.user_id, version, "terms agreed");
    Ok(StatusCode::NO_CONTENT)
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

// The contract's `AccountDelete`.
#[derive(Deserialize, ToSchema)]
pub struct AccountDelete {
    pub password: String,
}

/*
    The person deletes their account (F18)
    --------------------------------------------------------------------
    - the password again: a phone left unlocked mustn't be enough
    - what goes and what stays: `account.rs`
*/
#[utoipa::path(
    post,
    path = "/me/delete",
    operation_id = "deleteAccount",
    tag = "auth",
    request_body = AccountDelete,
    responses(
        (status = 204, description = "Deleted, and logged out everywhere."),
        (status = 400, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 503, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn delete_account(
    State(state): State<AppState>,
    user: AuthUser,
    ApiJson(req): ApiJson<AccountDelete>,
) -> ApiResult<Response> {
    crate::account::delete(&state, user.user_id, req.password).await?;
    let mut res: Response = StatusCode::NO_CONTENT.into_response();
    let headers = res.headers_mut();
    use crate::{
        extract::{REFRESH_COOKIE, SESSION_COOKIE},
        routes::auth::{clear_cookie, refresh_path},
    };
    headers.append(header::SET_COOKIE, clear_cookie(SESSION_COOKIE, "/"));
    headers.append(
        header::SET_COOKIE,
        clear_cookie(REFRESH_COOKIE, &refresh_path()),
    );
    Ok(res)
}
