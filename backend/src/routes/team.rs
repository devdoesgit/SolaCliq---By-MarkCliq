/*
    The admin website's team page (phase 4)
    --------------------------------------------------------------------
    - GET    /orgs/{org_id}/members            list, newest first
    - POST   /orgs/{org_id}/members            add a worker or agent
    - DELETE /orgs/{org_id}/members/{user_id}  remove one
    - org admins only (`OrgMember<Admins>`), of an active company
    - customers are never listed here: they arrive through registration
      (phase 9) and have their own pages
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
    org::{Admins, OrgMember, PayType, Role},
    page::{Cursor, Page, PageInfo},
    validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_members, add_member))
        .routes(routes!(remove_member))
}

// The contract's `MemberStatus`.
#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum MemberStatus {
    // Added, but hasn't set a password yet.
    Invited,
    Active,
}

// The contract's `Member`: one row of the team page.
#[derive(Debug, Serialize, ToSchema)]
pub struct Member {
    pub user_id: Uuid,
    pub name: String,
    pub email: String,
    pub role: Role,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pay_type: Option<PayType>,
    pub status: MemberStatus,
    pub added_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct MemberPage {
    pub items: Vec<Member>,
    pub page: PageInfo,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct ListQuery {
    // Opaque cursor from the previous page's `next_cursor`.
    cursor: Option<String>,
    // Page size, 1 to 100; 25 when left out.
    limit: Option<i64>,
    // Only members with this role.
    role: Option<Role>,
}

// One row of the members query. `FromRow` maps columns to fields by name.
#[derive(sqlx::FromRow)]
struct MemberRow {
    membership_id: Uuid,
    user_id: Uuid,
    name: String,
    email: String,
    role: Role,
    pay_type: Option<PayType>,
    invited: bool,
    added_at: DateTime<Utc>,
}

impl From<MemberRow> for Member {
    fn from(r: MemberRow) -> Self {
        Member {
            user_id: r.user_id,
            name: r.name,
            email: r.email,
            role: r.role,
            pay_type: r.pay_type,
            status: if r.invited {
                MemberStatus::Invited
            } else {
                MemberStatus::Active
            },
            added_at: r.added_at,
        }
    }
}

/*
    The org's admin, workers and agents
    --------------------------------------------------------------------
    - newest first, by when they were added (or added back); paged as
      described in `page.rs`
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/members",
    operation_id = "listMembers",
    tag = "team",
    params(("org_id" = Uuid, Path, description = "The company."), ListQuery),
    responses(
        (status = 200, description = "One page of members, newest first.", body = MemberPage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_members(
    State(state): State<AppState>,
    member: OrgMember<Admins>,
    ApiQuery(query): ApiQuery<ListQuery>,
) -> ApiResult<Json<MemberPage>> {
    let page = Page::new(query.cursor.as_deref(), query.limit)?;

    // `$3::member_role IS NULL OR ...`: one query serves all roles and one.
    let mut rows: Vec<MemberRow> = sqlx::query_as(
        "SELECT m.id AS membership_id, u.id AS user_id, u.name, u.email,
                m.role, m.pay_type, u.password_hash IS NULL AS invited,
                m.created_at AS added_at
         FROM memberships m JOIN users u ON u.id = m.user_id
         WHERE m.org_id = $1
           AND m.removed_at IS NULL
           AND m.role <> 'customer'
           AND ($3::member_role IS NULL OR m.role = $3)
           AND ($4::timestamptz IS NULL OR (m.created_at, m.id) < ($4, $5))
         ORDER BY m.created_at DESC, m.id DESC
         LIMIT $2",
    )
    .bind(member.org_id)
    .bind(page.fetch())
    .bind(query.role)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&state.db)
    .await?;

    let page_info = page.finish(&mut rows, |r| Cursor {
        created_at: r.added_at,
        id: r.membership_id,
    });
    Ok(Json(MemberPage {
        items: rows.into_iter().map(Member::from).collect(),
        page: page_info,
    }))
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct AddMemberRequest {
    pub name: String,
    pub email: String,
    pub role: Role,
    // Agents only, and required for them.
    pub pay_type: Option<PayType>,
}

/*
    Add a worker or agent
    --------------------------------------------------------------------
    - email with no account: one is made with no password; they get an
      email saying how to set it up (log in → "Forgot password?" emails
      them a code; setting the password also verifies the email)
    - email with an account: only the membership is added, and they get
      a "you were added" email
    - someone removed earlier comes back on their old row, with the new
      role and pay type
    - one role per person per company: already a member → 409
    - the account and the membership are written in one transaction, and
      the email goes out only after it commits
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/members",
    operation_id = "addMember",
    tag = "team",
    params(("org_id" = Uuid, Path, description = "The company.")),
    request_body = AddMemberRequest,
    responses(
        (status = 201, description = "Added.", body = Member),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn add_member(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiJson(req): ApiJson<AddMemberRequest>,
) -> ApiResult<(StatusCode, Json<Member>)> {
    let input = validate_add(req)?;
    let mut tx = state.db.begin().await?;

    /*
        The account. ON CONFLICT DO NOTHING + RETURNING gives the id only
        when a row was inserted; otherwise the existing account is read.
        Two admins adding the same new email at once can't make two
        accounts: the email is UNIQUE
    */
    let created: Option<(Uuid,)> = sqlx::query_as(
        "INSERT INTO users (id, email, name) VALUES ($1, $2, $3)
         ON CONFLICT (email) DO NOTHING
         RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(&input.email)
    .bind(&input.name)
    .fetch_optional(&mut *tx)
    .await?;
    let new_account = created.is_some();
    let user_id = match created {
        Some((id,)) => id,
        None => {
            sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
                .bind(&input.email)
                .fetch_one(&mut *tx)
                .await?
        }
    };

    /*
        The membership
        - new: inserted
        - removed earlier: the same row comes back (role, pay type and
          added time reset)
        - still a member: the WHERE leaves it alone, RETURNING gives no
          row, and that is the 409
    */
    let row: Option<MemberRow> = sqlx::query_as(
        "WITH m AS (
             INSERT INTO memberships (id, user_id, org_id, role, pay_type)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (user_id, org_id) DO UPDATE
                SET role = EXCLUDED.role,
                    pay_type = EXCLUDED.pay_type,
                    created_at = now(),
                    removed_at = NULL
              WHERE memberships.removed_at IS NOT NULL
             RETURNING id, user_id, role, pay_type, created_at
         )
         SELECT m.id AS membership_id, u.id AS user_id, u.name, u.email,
                m.role, m.pay_type, u.password_hash IS NULL AS invited,
                m.created_at AS added_at
         FROM m JOIN users u ON u.id = m.user_id",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(admin.org_id)
    .bind(input.role)
    .bind(input.pay_type)
    .fetch_optional(&mut *tx)
    .await?;
    let Some(row) = row else {
        return Err(ApiError::new(
            StatusCode::CONFLICT,
            "member.already_in_org",
            "Already in this company",
        )
        .detail("This person is already a member. Remove them first to change their role."));
    };

    let org_name: String = sqlx::query_scalar("SELECT name FROM orgs WHERE id = $1")
        .bind(admin.org_id)
        .fetch_one(&mut *tx)
        .await?;
    tx.commit().await?;

    tracing::info!(org_id = %admin.org_id, %user_id, role = ?row.role, new_account, "member added");
    state
        .mailer
        .send(added_email(&input.email, &org_name, new_account));
    Ok((StatusCode::CREATED, Json(row.into())))
}

// AddMemberRequest, checked and tidied.
struct ValidAdd {
    name: String,
    email: String,
    role: Role,
    pay_type: Option<PayType>,
}

/*
    Every problem at once, so the website can mark all bad fields. The
    role and pay-type rules have their own codes (the contract's), sent
    on their own once the fields are otherwise fine
*/
fn validate_add(req: AddMemberRequest) -> ApiResult<ValidAdd> {
    let name = req.name.trim().to_owned();
    let email = validate::normalize_email(&req.email);

    let mut errors = ApiError::validation(Vec::new());
    let mut bad = false;
    if name.is_empty() || name.chars().count() > 100 {
        errors = errors.field("name", "Enter their name (up to 100 characters).");
        bad = true;
    }
    if !validate::looks_like_email(&email) {
        errors = errors.field("email", "Enter a valid email address.");
        bad = true;
    }
    if bad {
        return Err(errors);
    }

    if !matches!(req.role, Role::Worker | Role::Agent) {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.role_not_allowed",
            "Add a worker or an agent",
        )
        .field("role", "Only workers and agents are added here."));
    }
    match (req.role, req.pay_type) {
        (Role::Agent, None) => Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.pay_type_required",
            "Choose how this agent is paid",
        )
        .field("pay_type", "Commission or salary.")),
        (Role::Worker, Some(_)) => Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.pay_type_not_allowed",
            "Only agents have a pay type",
        )
        .field("pay_type", "Leave this out for a worker.")),
        (role, pay_type) => Ok(ValidAdd {
            name,
            email,
            role,
            pay_type,
        }),
    }
}

/*
    The `{user_id}` of `/orgs/{org_id}/members/{user_id}`, read by name.
    `{org_id}` is OrgMember's job, so it is left out (serde skips it)
*/
#[derive(Debug, Deserialize)]
struct MemberPath {
    user_id: Uuid,
}

/*
    Remove a worker or agent
    --------------------------------------------------------------------
    - soft delete: `removed_at` is set and the row stays, so their past
      work keeps pointing at them
    - their very next request to this company gets 403 `org.not_member`,
      because OrgMember reads the membership on every request; their
      sessions stay, as they may belong to other companies
    - the admin can't be removed (422); someone not in the company (or
      already removed) is 404
*/
#[utoipa::path(
    delete,
    path = "/orgs/{org_id}/members/{user_id}",
    operation_id = "removeMember",
    tag = "team",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("user_id" = Uuid, Path, description = "The person to remove."),
    ),
    responses(
        (status = 204, description = "Removed."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn remove_member(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<MemberPath>,
) -> ApiResult<StatusCode> {
    let user_id = path.user_id;
    /*
        The admin check is part of the UPDATE, so the row can't change
        between checking and removing. When nothing was removed, a second
        read tells "the admin" (422) from "not a member" (404)
    */
    let removed = sqlx::query(
        "UPDATE memberships SET removed_at = now()
         WHERE org_id = $1 AND user_id = $2
           AND removed_at IS NULL AND role <> 'org_admin'",
    )
    .bind(admin.org_id)
    .bind(user_id)
    .execute(&state.db)
    .await?
    .rows_affected()
        == 1;

    if removed {
        tracing::info!(org_id = %admin.org_id, %user_id, by = %admin.user_id, "member removed");
        return Ok(StatusCode::NO_CONTENT);
    }

    let is_admin: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM memberships
                        WHERE org_id = $1 AND user_id = $2
                          AND removed_at IS NULL AND role = 'org_admin')",
    )
    .bind(admin.org_id)
    .bind(user_id)
    .fetch_one(&state.db)
    .await?;
    if is_admin {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.cannot_remove_admin",
            "The company's admin can't be removed",
        ));
    }
    Err(ApiError::not_found())
}

/*
    The email a new member gets
    - a new account: how to set it up (no code here: the code comes when
      they ask for it, so it can't expire in the inbox)
    - an existing account: that they were added
*/
fn added_email(to: &str, org_name: &str, new_account: bool) -> Email {
    let (subject, after) = if new_account {
        (
            format!("{org_name} added you on {PRODUCT_NAME}"),
            format!(
                "To set up your account, open the {PRODUCT_NAME} app, tap \
                 \"Log in\", then \"Forgot password?\", and enter this email \
                 address. We'll email you a code to set your password."
            ),
        )
    } else {
        (
            format!("You've been added to {org_name}"),
            format!("Log in as usual: {org_name} now appears in your workspaces."),
        )
    };
    Message {
        heading: format!("You're on {org_name}'s team"),
        before: vec![format!(
            "{org_name} added you to their team on {PRODUCT_NAME}."
        )],
        details: Vec::new(),
        after: vec![after],
        sign_off: true,
        reason: Some(format!(
            "You're receiving this email because {org_name} added this address to \
             their team. If you don't know them, ignore this email."
        )),
    }
    .email(to, subject)
}
