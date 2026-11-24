/*
    The admin website's team page (phase 4)
    --------------------------------------------------------------------
    - GET    /orgs/{org_id}/members            list, newest first
    - POST   /orgs/{org_id}/members            add a worker or agent
    - DELETE /orgs/{org_id}/members/{user_id}  remove one
    - PATCH  /orgs/{org_id}/members/{user_id}  change role or pay (F21)
    - POST   /orgs/{org_id}/members/{user_id}/invite  send it again
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
    mail::{
        Email,
        template::{self as t, Badge, EmailPage, Step, Tone},
    },
    org::{Admins, OrgMember, PayType, Role},
    page::{Cursor, Page, PageInfo},
    rate_limit::Rule,
    validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_members, add_member))
        .routes(routes!(remove_member, update_member))
        .routes(routes!(resend_invite))
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
    // Not yet approved or cancelled: they stay with them if they're removed.
    pub open_tasks: i64,
    // Those they registered that weren't turned down.
    pub customers: i64,
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
    open_tasks: i64,
    customers: i64,
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
            open_tasks: r.open_tasks,
            customers: r.customers,
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
    let mut tx = member.begin(&state.db).await?;

    // `$3::member_role IS NULL OR ...`: one query serves all roles and one.
    let mut rows: Vec<MemberRow> = sqlx::query_as(
        "SELECT m.id AS membership_id, u.id AS user_id, u.name, u.email,
                m.role, m.pay_type, u.password_hash IS NULL AS invited,
                m.created_at AS added_at,
                (SELECT count(*) FROM tasks t
                 WHERE t.org_id = m.org_id AND t.assignee_id = m.user_id
                   AND t.status NOT IN ('approved', 'cancelled')) AS open_tasks,
                (SELECT count(*) FROM customers c
                 WHERE c.org_id = m.org_id AND c.registered_by = m.user_id
                   AND c.kyc_status <> 'rejected') AS customers
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
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

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
    let mut tx = admin.begin(&state.db).await?;

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
                m.created_at AS added_at,
                (SELECT count(*) FROM tasks t
                 WHERE t.org_id = $3 AND t.assignee_id = m.user_id
                   AND t.status NOT IN ('approved', 'cancelled')) AS open_tasks,
                (SELECT count(*) FROM customers c
                 WHERE c.org_id = $3 AND c.registered_by = m.user_id
                   AND c.kyc_status <> 'rejected') AS customers
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
    state.mailer.send(added_email(
        &input.email,
        &org_name,
        input.role,
        new_account,
    ));
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
            "Add an EPC installer or a sales agent",
        )
        .field(
            "role",
            "Only EPC installers and sales agents are added here.",
        ));
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
    let mut tx = admin.begin(&state.db).await?;
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
    .execute(&mut *tx)
    .await?
    .rows_affected()
        == 1;

    if removed {
        crate::routes::leads::release(&mut tx, admin.org_id, user_id).await?;
        tx.commit().await?;
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
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
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
/*
    Editing a member (F21)
*/

// One member of this company, as the team page shows them; None if not one.
async fn load_member(
    conn: &mut sqlx::PgConnection,
    org_id: Uuid,
    user_id: Uuid,
) -> ApiResult<Option<MemberRow>> {
    Ok(sqlx::query_as(
        "SELECT m.id AS membership_id, u.id AS user_id, u.name, u.email,
                m.role, m.pay_type, u.password_hash IS NULL AS invited,
                m.created_at AS added_at,
                (SELECT count(*) FROM tasks t
                 WHERE t.org_id = m.org_id AND t.assignee_id = m.user_id
                   AND t.status NOT IN ('approved', 'cancelled')) AS open_tasks,
                (SELECT count(*) FROM customers c
                 WHERE c.org_id = m.org_id AND c.registered_by = m.user_id
                   AND c.kyc_status <> 'rejected') AS customers
         FROM memberships m JOIN users u ON u.id = m.user_id
         WHERE m.org_id = $1 AND m.user_id = $2
           AND m.removed_at IS NULL AND m.role <> 'customer'",
    )
    .bind(org_id)
    .bind(user_id)
    .fetch_optional(conn)
    .await?)
}

// The contract's `MemberUpdate`: a role between worker and agent, a pay type.
#[derive(Debug, Deserialize, ToSchema)]
pub struct MemberUpdate {
    pub role: Option<Role>,
    pub pay_type: Option<PayType>,
}

// "2 open tasks", "1 customer in review": what keeps a role from changing.
fn open_work(parts: &[(i64, &str, &str)]) -> Vec<String> {
    parts
        .iter()
        .filter(|(n, ..)| *n > 0)
        .map(|(n, one, many)| format!("{n} {}", if *n == 1 { one } else { many }))
        .collect()
}

/*
    Change a member's role or pay type
    --------------------------------------------------------------------
    - pay type: from now on. Commissions already entered stay as they are
    - role, between installer and agent: only with nothing open in the
      old role, so nothing is moved or lost unseen; the 409 says what
    - the membership row is locked, so two admins' edits can't cross
    - name, phone and email are the person's own (F21)
*/
#[utoipa::path(
    patch,
    path = "/orgs/{org_id}/members/{user_id}",
    operation_id = "updateMember",
    tag = "team",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("user_id" = Uuid, Path, description = "The member."),
    ),
    request_body = MemberUpdate,
    responses(
        (status = 200, description = "The member, changed.", body = Member),
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
async fn update_member(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<MemberPath>,
    ApiJson(req): ApiJson<MemberUpdate>,
) -> ApiResult<Json<Member>> {
    if matches!(req.role, Some(Role::OrgAdmin | Role::Customer)) {
        return Err(
            ApiError::validation(Vec::new()).field("role", "An EPC Installer or a Sales Agent.")
        );
    }
    let mut tx = admin.begin(&state.db).await?;
    let current: Option<(Role, Option<PayType>)> = sqlx::query_as(
        "SELECT role, pay_type FROM memberships
         WHERE org_id = $1 AND user_id = $2 AND removed_at IS NULL AND role <> 'customer'
         FOR UPDATE",
    )
    .bind(admin.org_id)
    .bind(path.user_id)
    .fetch_optional(&mut *tx)
    .await?;
    let Some((role, pay)) = current else {
        return Err(ApiError::not_found());
    };
    if role == Role::OrgAdmin {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.cannot_change_admin",
            "The admin's role can't change here",
        )
        .detail("To hand the company to someone else, contact MarkCliq."));
    }
    let new_role = req.role.unwrap_or(role);
    // Agents always have a pay type, workers never (the membership's check).
    let new_pay = match new_role {
        Role::Agent => Some(req.pay_type.or(pay).ok_or_else(|| {
            ApiError::validation(Vec::new()).field("pay_type", "Choose how they're paid.")
        })?),
        _ if req.pay_type.is_some() => {
            return Err(ApiError::validation(Vec::new())
                .field("pay_type", "Only Sales Agents have a pay type."));
        }
        _ => None,
    };

    if new_role != role {
        let blocking = if role == Role::Worker {
            let tasks: i64 = sqlx::query_scalar(
                "SELECT count(*) FROM tasks WHERE org_id = $1 AND assignee_id = $2
                   AND status IN ('assigned', 'submitted', 'returned')",
            )
            .bind(admin.org_id)
            .bind(path.user_id)
            .fetch_one(&mut *tx)
            .await?;
            open_work(&[(tasks, "open task", "open tasks")])
        } else {
            let (kyc, commissions, leads): (i64, i64, i64) = sqlx::query_as(
                "SELECT
                   (SELECT count(*) FROM customers WHERE org_id = $1 AND registered_by = $2
                      AND kyc_status IN ('in_review', 'needs_fix')),
                   (SELECT count(*) FROM customers WHERE org_id = $1 AND registered_by = $2
                      AND kyc_status <> 'rejected'
                      AND commission_status IN ('in_review', 'approved', 'payable')),
                   (SELECT count(*) FROM leads WHERE org_id = $1 AND agent_id = $2
                      AND status IN ('new', 'contacted'))",
            )
            .bind(admin.org_id)
            .bind(path.user_id)
            .fetch_one(&mut *tx)
            .await?;
            open_work(&[
                (kyc, "customer still in KYC", "customers still in KYC"),
                (
                    commissions,
                    "commission not yet paid",
                    "commissions not yet paid",
                ),
                (leads, "open lead", "open leads"),
            ])
        };
        if !blocking.is_empty() {
            return Err(ApiError::new(
                StatusCode::CONFLICT,
                "member.has_open_work",
                "They still have open work",
            )
            .detail(format!(
                "Finish or hand over first: {}.",
                blocking.join(", ")
            )));
        }
    }

    sqlx::query(
        "UPDATE memberships SET role = $3, pay_type = $4 WHERE org_id = $1 AND user_id = $2",
    )
    .bind(admin.org_id)
    .bind(path.user_id)
    .bind(new_role)
    .bind(new_pay)
    .execute(&mut *tx)
    .await?;
    let row = load_member(&mut tx, admin.org_id, path.user_id)
        .await?
        .ok_or_else(ApiError::not_found)?;
    tx.commit().await?;
    tracing::info!(
        org_id = %admin.org_id, user_id = %path.user_id, by = %admin.user_id,
        from = ?(role, pay), to = ?(new_role, new_pay), "member changed"
    );
    Ok(Json(row.into()))
}

/*
    Send a member's invite again
    --------------------------------------------------------------------
    - only while they have no password: the email says how to set one
    - 3 an hour per address: it's an email to someone else's inbox
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/members/{user_id}/invite",
    operation_id = "resendInvite",
    tag = "team",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("user_id" = Uuid, Path, description = "The member."),
    ),
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
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn resend_invite(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<MemberPath>,
) -> ApiResult<StatusCode> {
    let mut tx = admin.begin(&state.db).await?;
    let row = load_member(&mut tx, admin.org_id, path.user_id)
        .await?
        .ok_or_else(ApiError::not_found)?;
    let org_name: String = sqlx::query_scalar("SELECT name FROM orgs WHERE id = $1")
        .bind(admin.org_id)
        .fetch_one(&mut *tx)
        .await?;
    tx.commit().await?;
    if !row.invited {
        return Err(ApiError::new(
            StatusCode::CONFLICT,
            "member.already_set_up",
            "They've already set up their account",
        )
        .detail("They can log in, or use \"Forgot password?\" in the app."));
    }
    state.limits.check(Rule::InviteByEmail, &row.email)?;
    state
        .mailer
        .send(added_email(&row.email, &org_name, row.role, true));
    tracing::info!(org_id = %admin.org_id, user_id = %path.user_id, "invite sent again");
    Ok(StatusCode::NO_CONTENT)
}

fn added_email(to: &str, org_name: &str, role: Role, new_account: bool) -> Email {
    let role_label = match role {
        Role::OrgAdmin => "Admin",
        Role::Worker => "EPC Installer",
        Role::Agent => "Sales Agent",
        Role::Customer => "Customer",
    };
    // "an EPC installer": the article follows the sound, not the letter.
    let a_role = match role {
        Role::OrgAdmin => "an admin",
        Role::Worker => "an EPC installer",
        Role::Agent => "a sales agent",
        Role::Customer => "a customer",
    };
    let intro = format!("{org_name} added you to their team on {PRODUCT_NAME} as {a_role}.");
    let note = format!(
        "You're receiving this email because {org_name} added this address to \
         their team. If you don't know them, ignore this email."
    );
    let open = "Get it from your company if it isn't on your phone yet.";
    let forgot = format!("Enter this email address: {to}");
    let set = "Enter the 6-digit code we email you, and choose a password.";
    let (subject, heading, badge, preheader, body_text, card_end) = if new_account {
        (
            format!("{org_name} added you on {PRODUCT_NAME}"),
            format!("Welcome to {org_name}"),
            Badge {
                glyph: "&#128075;",
                tone: Tone::Sun,
            },
            format!("{org_name} added you as {a_role}. Set up your account in 3 steps."),
            format!(
                "Set up your account:\n\
                 1. Open the {PRODUCT_NAME} app. {open}\n\
                 2. Tap \"Log in\", then \"Forgot password?\". {forgot}\n\
                 3. Set your password. {set}"
            ),
            [
                t::eyebrow("Set up in 3 steps"),
                t::steps(&[
                    (Step::Now, &format!("Open the {PRODUCT_NAME} app"), open),
                    (
                        Step::Later,
                        "Tap \"Log in\", then \"Forgot password?\"",
                        &forgot,
                    ),
                    (Step::Later, "Set your password", set),
                ]),
            ]
            .concat(),
        )
    } else {
        let line = format!("Log in as usual: {org_name} is in your workspaces now.");
        (
            format!("You've been added to {org_name}"),
            format!("You're on {org_name}'s team"),
            Badge {
                glyph: "&#43;",
                tone: Tone::Success,
            },
            format!("{org_name} added you as {a_role}. It's in your workspaces now."),
            line.clone(),
            t::para(&line),
        )
    };
    Email {
        to: to.to_owned(),
        subject,
        body: format!(
            "{intro}\n\n{body_text}\n\n{}\n\n{note}\n",
            t::sign_off_text()
        ),
        html: Some(t::page(EmailPage {
            preheader: Some(&preheader),
            sun_dot: false,
            badge: Some(badge),
            heading: &heading,
            card: [
                t::para(&intro),
                t::company(
                    org_name,
                    &format!("on {PRODUCT_NAME}"),
                    role_label,
                    Tone::Ink,
                ),
                card_end,
                t::sign_off(),
            ]
            .concat(),
            note: Some(&note),
        })),
    }
}
