/*
    Companies and membership (phase 4)
    --------------------------------------------------------------------
    - the enums shared by `/me`, the team endpoints and the database
    - `OrgMember`: the check every `/orgs/{org_id}/...` handler starts
      with. It answers 403 before the handler runs unless the caller is
      a member of that company, the company is active, and their role is
      one the endpoint allows
*/

use std::marker::PhantomData;

use axum::{
    extract::{FromRequestParts, RawPathParams},
    http::{StatusCode, request::Parts},
};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use crate::{AppState, error::ApiError, extract::AuthUser};

/*
    The three enums
    --------------------------------------------------------------------
    - serde: snake_case in JSON (`org_admin`), as the contract writes them
    - sqlx::Type: read and written as the Postgres enums of the same name
      (see the phase 4 migration), so a typo can't reach the database
*/
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "org_status", rename_all = "snake_case")]
pub enum OrgStatus {
    Pending,
    Active,
    Suspended,
    Rejected,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "member_role", rename_all = "snake_case")]
pub enum Role {
    OrgAdmin,
    Worker,
    Agent,
    Customer,
}

// The company's legal form, from its registration.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "business_type", rename_all = "snake_case")]
pub enum BusinessType {
    Proprietorship,
    Partnership,
    Llp,
    PrivateLimited,
    PublicLimited,
    Other,
}

// Agents only: whether they earn a commission per customer or a salary.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "pay_type", rename_all = "snake_case")]
pub enum PayType {
    Commission,
    Salary,
}

/*
    Which roles an endpoint is for
    --------------------------------------------------------------------
    - a handler names the set in its argument's type, e.g.
      `member: OrgMember<Admins>`, so the rule sits in the signature and
      can't be forgotten in the body
    - add a set here when an endpoint needs a new one
*/
pub trait Roles {
    const ALLOWED: &'static [Role];
}

// Any member of the company.
pub struct AnyRole;
impl Roles for AnyRole {
    const ALLOWED: &'static [Role] = &[Role::OrgAdmin, Role::Worker, Role::Agent, Role::Customer];
}

// The company's admin only (the website's team page).
pub struct Admins;
impl Roles for Admins {
    const ALLOWED: &'static [Role] = &[Role::OrgAdmin];
}

/*
    The caller's membership in the `{org_id}` of the path
    --------------------------------------------------------------------
    - put `member: OrgMember<SomeRoles>` in a handler's arguments; the
      handler only runs when every check passes
    - checks, in order:
        1. logged in (AuthUser), else 401
        2. a member, not removed, else 403 `org.not_member`. An org that
           doesn't exist gets the same answer, so ids can't be probed
        3. the company is active, else 403 `org.pending`,
           `org.suspended` or `org.rejected`; `/me` still lists it, so
           the app shows a message instead of the company's data
        4. their role is in `R::ALLOWED`, else 403 `org.role_not_allowed`
    - `PhantomData<R>`: R is only a type-level label (which roles); it
      holds no value
*/
#[derive(Debug, Clone, Copy)]
pub struct OrgMember<R = AnyRole> {
    pub user_id: Uuid,
    pub org_id: Uuid,
    pub role: Role,
    pub pay_type: Option<PayType>,
    roles: PhantomData<R>,
}

impl<R: Roles + Send + Sync> FromRequestParts<AppState> for OrgMember<R> {
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, ApiError> {
        let user = AuthUser::from_request_parts(parts, state).await?;
        let org_id = org_id_from_path(parts).await?;

        let row: Option<(Role, Option<PayType>, OrgStatus)> = sqlx::query_as(
            "SELECT m.role, m.pay_type, o.status
             FROM memberships m JOIN orgs o ON o.id = m.org_id
             WHERE m.org_id = $1 AND m.user_id = $2 AND m.removed_at IS NULL",
        )
        .bind(org_id)
        .bind(user.user_id)
        .fetch_optional(&state.db)
        .await?;

        let Some((role, pay_type, status)) = row else {
            return Err(not_member());
        };
        match status {
            OrgStatus::Active => {}
            OrgStatus::Pending => return Err(org_pending()),
            OrgStatus::Suspended => return Err(org_suspended()),
            OrgStatus::Rejected => return Err(org_rejected()),
        }
        if !R::ALLOWED.contains(&role) {
            return Err(role_not_allowed());
        }
        Ok(OrgMember {
            user_id: user.user_id,
            org_id,
            role,
            pay_type,
            roles: PhantomData,
        })
    }
}

/*
    The `{org_id}` path segment
    --------------------------------------------------------------------
    - read by name from all of the path's parameters, so it works on
      `/orgs/{org_id}` and `/orgs/{org_id}/members/{user_id}` alike
    - not a UUID: no such company, so the same 403 as a non-member
*/
async fn org_id_from_path(parts: &mut Parts) -> Result<Uuid, ApiError> {
    let params = RawPathParams::from_request_parts(parts, &())
        .await
        .map_err(|_| not_member())?;
    params
        .iter()
        .find(|(name, _)| *name == "org_id")
        .and_then(|(_, value)| Uuid::parse_str(value).ok())
        .ok_or_else(not_member)
}

pub fn not_member() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "org.not_member",
        "You're not part of this company",
    )
}

fn org_pending() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "org.pending",
        "This company is waiting for approval",
    )
}

fn org_suspended() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "org.suspended",
        "This company is suspended",
    )
    .detail("Contact the company for more information.")
}

fn org_rejected() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "org.rejected",
        "This company's registration was not approved",
    )
}

fn role_not_allowed() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "org.role_not_allowed",
        "Your role can't do this",
    )
}

/*
    A MarkCliq platform admin (`users.is_platform_admin`)
    --------------------------------------------------------------------
    - put `admin: PlatformAdmin` in a `/platform/...` handler's arguments
    - not logged in → 401; logged in but not a platform admin → 403
      `platform.not_admin`
    - the flag is read on every request, so taking it away works at once
*/
#[derive(Debug, Clone, Copy)]
pub struct PlatformAdmin {
    pub user_id: Uuid,
}

impl FromRequestParts<AppState> for PlatformAdmin {
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, ApiError> {
        let user = AuthUser::from_request_parts(parts, state).await?;
        let is_admin: bool =
            sqlx::query_scalar("SELECT is_platform_admin FROM users WHERE id = $1")
                .bind(user.user_id)
                .fetch_one(&state.db)
                .await?;
        if !is_admin {
            return Err(ApiError::new(
                StatusCode::FORBIDDEN,
                "platform.not_admin",
                "For MarkCliq platform admins only",
            ));
        }
        Ok(PlatformAdmin {
            user_id: user.user_id,
        })
    }
}
