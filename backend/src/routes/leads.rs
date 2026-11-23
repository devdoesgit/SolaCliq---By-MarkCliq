/*
    Landing-page leads (F20)
    --------------------------------------------------------------------
    - a company's landing page server sends each lead with the company's
      lead key (`POST /leads`). The key names its company, so the lead is
      saved in that company's scope, never by reading across companies
    - the key is `lead_<company id>_<64 hex>`; only its SHA-256 is kept.
      A new key replaces the old one at once
    - the admin works every lead: status, note, and handing it to one of
      the company's Sales Agents, who gets a push. The agent works the
      ones they have: status and note only
    - a lead is deleted only by the admin; an agent who leaves gives
      theirs back (`release`)
*/

use std::collections::BTreeMap;

use axum::{
    Json,
    extract::State,
    http::{HeaderMap, StatusCode},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath, ApiQuery, bearer_token},
    notify::{self, Kind, Links},
    org::{Admins, AdminsAndAgents, Agents, OrgMember, Role},
    page::{Cursor, Page, PageInfo},
    rate_limit::Rule,
    scope,
    session::{hash_token, new_token},
    validate,
};

const ERRORS: &str = "Error, as RFC 9457 problem details.";

const KEY_PREFIX: &str = "lead_";
const EXTRA_MOST: usize = 20;
const EXTRA_KEY_MAX: usize = 60;
const EXTRA_VALUE_MAX: usize = 200;

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(create_lead))
        .routes(routes!(list_leads))
        .routes(routes!(list_my_leads))
        .routes(routes!(get_lead, update_lead, delete_lead))
        .routes(routes!(get_lead_key, make_lead_key))
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "lead_status", rename_all = "snake_case")]
pub enum LeadStatus {
    New,
    Contacted,
    Won,
    Lost,
}

impl LeadStatus {
    fn label(self) -> &'static str {
        match self {
            LeadStatus::New => "New",
            LeadStatus::Contacted => "Contacted",
            LeadStatus::Won => "Won",
            LeadStatus::Lost => "Lost",
        }
    }
}

/*
    Receiving a lead
*/

// The contract's `LeadCreate`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct LeadCreate {
    pub external_id: Option<String>,
    pub name: String,
    pub phone: String,
    pub email: Option<String>,
    pub city: Option<String>,
    pub pin_code: Option<String>,
    pub monthly_bill: Option<String>,
    pub roof_type: Option<String>,
    pub message: Option<String>,
    pub source: Option<String>,
    pub campaign: Option<String>,
    pub page_url: Option<String>,
    pub extra: Option<BTreeMap<String, String>>,
    pub consent: bool,
}

// The contract's `LeadReceipt`.
#[derive(Debug, Serialize, ToSchema)]
pub struct LeadReceipt {
    pub id: Uuid,
}

fn bad_key() -> ApiError {
    ApiError::new(
        StatusCode::UNAUTHORIZED,
        "lead.bad_key",
        "That lead key isn't right",
    )
    .detail("Make a new lead key in Settings and put it on the landing page's server.")
}

// The company a key names, if it has the shape of one.
fn key_org(key: &str) -> Option<Uuid> {
    let rest = key.strip_prefix(KEY_PREFIX)?;
    let (org, secret) = rest.split_once('_')?;
    if org.len() != 32 || secret.len() != 64 || !secret.bytes().all(|b| b.is_ascii_hexdigit()) {
        return None;
    }
    Uuid::try_parse(org).ok()
}

/*
    "+91 98140-22671", "09814022671" and "919814022671" are all
    "9814022671"; None when what's left isn't an Indian mobile
*/
fn normalize_phone(raw: &str) -> Option<String> {
    let digits: String = raw.chars().filter(char::is_ascii_digit).collect();
    let ten = match digits.len() {
        10 => digits.as_str(),
        11 if digits.starts_with('0') => &digits[1..],
        12 if digits.starts_with("91") => &digits[2..],
        _ => return None,
    };
    validate::is_indian_mobile(ten).then(|| ten.to_owned())
}

// Trimmed; None when blank. A 422 on `field` when longer than `most`.
fn optional(field: &str, value: Option<&str>, most: usize) -> ApiResult<Option<String>> {
    let Some(v) = value.map(str::trim).filter(|v| !v.is_empty()) else {
        return Ok(None);
    };
    if v.chars().count() > most {
        return Err(
            ApiError::validation(Vec::new()).field(field, format!("Up to {most} characters."))
        );
    }
    Ok(Some(v.to_owned()))
}

// A lead as it's saved, checked and trimmed.
#[derive(Debug, PartialEq)]
struct Clean {
    external_id: Option<String>,
    name: String,
    phone: String,
    email: Option<String>,
    city: Option<String>,
    pin_code: Option<String>,
    monthly_bill: Option<String>,
    roof_type: Option<String>,
    message: Option<String>,
    source: String,
    campaign: Option<String>,
    page_url: Option<String>,
    extra: BTreeMap<String, String>,
}

fn clean(req: LeadCreate) -> ApiResult<Clean> {
    if !req.consent {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "lead.consent_required",
            "The person must agree to be contacted",
        )
        .detail("Send `consent: true` only when the form's box was ticked."));
    }
    let name = optional("name", Some(&req.name), 100)?
        .ok_or_else(|| ApiError::validation(Vec::new()).field("name", "Required."))?;
    let phone = normalize_phone(&req.phone).ok_or_else(|| {
        ApiError::validation(Vec::new()).field("phone", "An Indian mobile number, 10 digits.")
    })?;
    let email =
        optional("email", req.email.as_deref(), 254)?.map(|e| validate::normalize_email(&e));
    if email
        .as_deref()
        .is_some_and(|e| !validate::looks_like_email(e))
    {
        return Err(ApiError::validation(Vec::new()).field("email", "Not an email address."));
    }
    let pin_code = optional("pin_code", req.pin_code.as_deref(), 6)?;
    if pin_code
        .as_deref()
        .is_some_and(|p| !validate::is_pin_code(p))
    {
        return Err(ApiError::validation(Vec::new()).field("pin_code", "Six digits."));
    }
    let mut extra = BTreeMap::new();
    for (k, v) in req.extra.unwrap_or_default() {
        let (k, v) = (k.trim(), v.trim());
        if k.is_empty() || v.is_empty() {
            continue;
        }
        if k.chars().count() > EXTRA_KEY_MAX || v.chars().count() > EXTRA_VALUE_MAX {
            return Err(ApiError::validation(Vec::new()).field(
                "extra",
                format!(
                    "Questions up to {EXTRA_KEY_MAX} characters, answers up to {EXTRA_VALUE_MAX}."
                ),
            ));
        }
        extra.insert(k.to_owned(), v.to_owned());
    }
    if extra.len() > EXTRA_MOST {
        return Err(
            ApiError::validation(Vec::new()).field("extra", format!("Up to {EXTRA_MOST} answers."))
        );
    }
    Ok(Clean {
        external_id: optional("external_id", req.external_id.as_deref(), 100)?,
        name,
        phone,
        email,
        city: optional("city", req.city.as_deref(), 60)?,
        pin_code,
        monthly_bill: optional("monthly_bill", req.monthly_bill.as_deref(), 40)?,
        roof_type: optional("roof_type", req.roof_type.as_deref(), 40)?,
        message: optional("message", req.message.as_deref(), 1000)?,
        source: optional("source", req.source.as_deref(), 60)?
            .unwrap_or_else(|| "Landing page".into()),
        campaign: optional("campaign", req.campaign.as_deref(), 100)?,
        page_url: optional("page_url", req.page_url.as_deref(), 500)?,
        extra,
    })
}

#[utoipa::path(
    post,
    path = "/leads",
    operation_id = "createLead",
    tag = "leads",
    security(("leadKey" = [])),
    request_body = LeadCreate,
    responses(
        (status = 200, description = "Already sent (same `external_id`).", body = LeadReceipt),
        (status = 201, description = "Saved.", body = LeadReceipt),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 429, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn create_lead(
    State(state): State<AppState>,
    headers: HeaderMap,
    ApiJson(req): ApiJson<LeadCreate>,
) -> ApiResult<(StatusCode, Json<LeadReceipt>)> {
    let key = bearer_token(&headers).ok_or_else(bad_key)?;
    let org_id = key_org(key).ok_or_else(bad_key)?;
    state.limits.check(Rule::LeadByOrg, &org_id.to_string())?;

    let mut tx = scope::company(&state.db, org_id).await?;
    let stored: Option<Vec<u8>> =
        sqlx::query_scalar("SELECT key_hash FROM lead_keys WHERE org_id = $1")
            .bind(org_id)
            .fetch_optional(&mut *tx)
            .await?;
    if stored.as_deref() != Some(hash_token(key).as_slice()) {
        return Err(bad_key());
    }
    // Checked after the key, so a wrong key learns nothing about the body.
    let lead = clean(req)?;

    let id: Option<Uuid> = sqlx::query_scalar(
        "INSERT INTO leads (id, org_id, external_id, name, phone, email, city, pin_code,
                            monthly_bill, roof_type, message, source, campaign, page_url, extra)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
         ON CONFLICT (org_id, external_id) DO NOTHING
         RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(org_id)
    .bind(&lead.external_id)
    .bind(&lead.name)
    .bind(&lead.phone)
    .bind(&lead.email)
    .bind(&lead.city)
    .bind(&lead.pin_code)
    .bind(&lead.monthly_bill)
    .bind(&lead.roof_type)
    .bind(&lead.message)
    .bind(&lead.source)
    .bind(&lead.campaign)
    .bind(&lead.page_url)
    .bind(sqlx::types::Json(&lead.extra))
    .fetch_optional(&mut *tx)
    .await?;
    sqlx::query("UPDATE lead_keys SET last_used_at = now() WHERE org_id = $1")
        .bind(org_id)
        .execute(&mut *tx)
        .await?;

    let Some(id) = id else {
        // Sent before: the first one, unchanged.
        let first: Uuid =
            sqlx::query_scalar("SELECT id FROM leads WHERE org_id = $1 AND external_id = $2")
                .bind(org_id)
                .bind(&lead.external_id)
                .fetch_one(&mut *tx)
                .await?;
        tx.commit().await?;
        return Ok((StatusCode::OK, Json(LeadReceipt { id: first })));
    };
    let body = [
        Some(lead.name.as_str()),
        lead.city.as_deref(),
        Some(lead.source.as_str()),
    ]
    .into_iter()
    .flatten()
    .collect::<Vec<_>>()
    .join(" · ");
    notify::add_for_admins(
        &mut tx,
        org_id,
        Kind::LeadNew,
        "New lead",
        &body,
        Links {
            lead_id: Some(id),
            ..Links::default()
        },
    )
    .await?;
    tx.commit().await?;
    tracing::info!(%org_id, lead_id = %id, "lead received");
    Ok((StatusCode::CREATED, Json(LeadReceipt { id })))
}

/*
    Working leads
*/

// The contract's `LeadSummary`.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct LeadSummary {
    pub id: Uuid,
    pub name: String,
    pub phone: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub city: Option<String>,
    pub source: String,
    pub status: LeadStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_id: Option<Uuid>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_name: Option<String>,
    #[sqlx(rename = "created_at")]
    pub received_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct LeadPage {
    pub items: Vec<LeadSummary>,
    pub page: PageInfo,
}

// The contract's `Lead`.
#[derive(Debug, Serialize, ToSchema, sqlx::FromRow)]
pub struct Lead {
    #[serde(flatten)]
    #[sqlx(flatten)]
    pub summary: LeadSummary,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pin_code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub monthly_bill: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub roof_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub campaign: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub page_url: Option<String>,
    #[schema(value_type = BTreeMap<String, String>)]
    pub extra: sqlx::types::Json<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    pub updated_at: DateTime<Utc>,
}

// The summary's columns, with the agent's name.
macro_rules! select_lead {
    ($rest:literal) => {
        concat!(
            "SELECT l.id, l.name, l.phone, l.city, l.source, l.status, l.agent_id,
                    a.name AS agent_name, l.created_at, l.email, l.pin_code, l.monthly_bill,
                    l.roof_type, l.message, l.campaign, l.page_url, l.extra, l.note, l.updated_at
             FROM leads l LEFT JOIN users a ON a.id = l.agent_id ",
            $rest
        )
    };
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct LeadQuery {
    status: Option<LeadStatus>,
    agent_id: Option<Uuid>,
    q: Option<String>,
    cursor: Option<String>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct MyLeadQuery {
    status: Option<LeadStatus>,
    cursor: Option<String>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct LeadPath {
    lead_id: Uuid,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/leads",
    operation_id = "listLeads",
    tag = "leads",
    params(("org_id" = Uuid, Path, description = "The company."), LeadQuery),
    responses(
        (status = 200, description = "One page.", body = LeadPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_leads(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<LeadQuery>,
) -> ApiResult<Json<LeadPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let words = q.q.as_deref().map(str::trim).filter(|w| !w.is_empty());
    if words.is_some_and(|w| w.chars().count() > 100) {
        return Err(ApiError::validation(Vec::new()).field("q", "Up to 100 characters."));
    }
    let mut tx = admin.begin(&state.db).await?;
    let mut items: Vec<LeadSummary> = sqlx::query_as(
        "SELECT l.id, l.name, l.phone, l.city, l.source, l.status, l.agent_id,
                a.name AS agent_name, l.created_at
         FROM leads l LEFT JOIN users a ON a.id = l.agent_id
         WHERE l.org_id = $1
           AND ($3::lead_status IS NULL OR l.status = $3)
           AND ($4::uuid IS NULL OR l.agent_id = $4)
           AND ($5::text IS NULL
                OR strpos(lower(l.name), lower($5)) > 0
                OR strpos(l.phone, $5) > 0
                OR strpos(lower(coalesce(l.email, '')), lower($5)) > 0
                OR strpos(lower(coalesce(l.city, '')), lower($5)) > 0)
           AND ($6::timestamptz IS NULL OR (l.created_at, l.id) < ($6, $7))
         ORDER BY l.created_at DESC, l.id DESC LIMIT $2",
    )
    .bind(admin.org_id)
    .bind(page.fetch())
    .bind(q.status)
    .bind(q.agent_id)
    .bind(words)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    let info = page.finish(&mut items, |r| Cursor {
        created_at: r.received_at,
        id: r.id,
    });
    Ok(Json(LeadPage { items, page: info }))
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/leads/mine",
    operation_id = "listMyLeads",
    tag = "leads",
    params(("org_id" = Uuid, Path, description = "The company."), MyLeadQuery),
    responses(
        (status = 200, description = "One page.", body = LeadPage),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_my_leads(
    State(state): State<AppState>,
    agent: OrgMember<Agents>,
    ApiQuery(q): ApiQuery<MyLeadQuery>,
) -> ApiResult<Json<LeadPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = agent.begin(&state.db).await?;
    let mut items: Vec<LeadSummary> = sqlx::query_as(
        "SELECT l.id, l.name, l.phone, l.city, l.source, l.status, l.agent_id,
                a.name AS agent_name, l.created_at
         FROM leads l LEFT JOIN users a ON a.id = l.agent_id
         WHERE l.org_id = $1 AND l.agent_id = $3
           AND ($4::lead_status IS NULL OR l.status = $4)
           AND ($5::timestamptz IS NULL OR (l.created_at, l.id) < ($5, $6))
         ORDER BY l.created_at DESC, l.id DESC LIMIT $2",
    )
    .bind(agent.org_id)
    .bind(page.fetch())
    .bind(agent.user_id)
    .bind(q.status)
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;
    let info = page.finish(&mut items, |r| Cursor {
        created_at: r.received_at,
        id: r.id,
    });
    Ok(Json(LeadPage { items, page: info }))
}

// A lead the caller may see: any for an admin, their own for an agent.
async fn load(
    conn: &mut PgConnection,
    member: &OrgMember<AdminsAndAgents>,
    lead_id: Uuid,
    lock: bool,
) -> ApiResult<Lead> {
    let lead: Lead = if lock {
        sqlx::query_as(select_lead!(
            "WHERE l.org_id = $1 AND l.id = $2 FOR UPDATE OF l"
        ))
    } else {
        sqlx::query_as(select_lead!("WHERE l.org_id = $1 AND l.id = $2"))
    }
    .bind(member.org_id)
    .bind(lead_id)
    .fetch_optional(conn)
    .await?
    .ok_or_else(ApiError::not_found)?;
    if member.role != Role::OrgAdmin && lead.summary.agent_id != Some(member.user_id) {
        return Err(ApiError::not_found());
    }
    Ok(lead)
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/leads/{lead_id}",
    operation_id = "getLead",
    tag = "leads",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("lead_id" = Uuid, Path, description = "The lead."),
    ),
    responses(
        (status = 200, description = "The lead.", body = Lead),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_lead(
    State(state): State<AppState>,
    member: OrgMember<AdminsAndAgents>,
    ApiPath(path): ApiPath<LeadPath>,
) -> ApiResult<Json<Lead>> {
    let mut tx = member.begin(&state.db).await?;
    let lead = load(&mut tx, &member, path.lead_id, false).await?;
    tx.commit().await?;
    Ok(Json(lead))
}

// The contract's `LeadUpdate`. `agent_id`: absent leaves it, null clears it.
#[derive(Debug, Deserialize, ToSchema)]
pub struct LeadUpdate {
    pub status: Option<LeadStatus>,
    pub note: Option<String>,
    #[serde(default, deserialize_with = "present")]
    #[schema(value_type = Option<Uuid>)]
    pub agent_id: Option<Option<Uuid>>,
}

// Tells a sent `null` (Some(None)) from a missing field (None).
fn present<'de, D>(d: D) -> Result<Option<Option<Uuid>>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    Option::<Uuid>::deserialize(d).map(Some)
}

#[utoipa::path(
    patch,
    path = "/orgs/{org_id}/leads/{lead_id}",
    operation_id = "updateLead",
    tag = "leads",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("lead_id" = Uuid, Path, description = "The lead."),
    ),
    request_body = LeadUpdate,
    responses(
        (status = 200, description = "The lead, changed.", body = Lead),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn update_lead(
    State(state): State<AppState>,
    member: OrgMember<AdminsAndAgents>,
    ApiPath(path): ApiPath<LeadPath>,
    ApiJson(req): ApiJson<LeadUpdate>,
) -> ApiResult<Json<Lead>> {
    if req.agent_id.is_some() && member.role != Role::OrgAdmin {
        return Err(ApiError::new(
            StatusCode::FORBIDDEN,
            "lead.admin_only",
            "Only the admin hands out leads",
        ));
    }
    let note = match req.note.as_deref().map(str::trim) {
        Some(n) if n.chars().count() > 1000 => {
            return Err(ApiError::validation(Vec::new()).field("note", "Up to 1,000 characters."));
        }
        other => other,
    };

    let mut tx = member.begin(&state.db).await?;
    let before = load(&mut tx, &member, path.lead_id, true).await?;
    if let Some(Some(agent)) = req.agent_id {
        let is_agent: bool = sqlx::query_scalar(
            "SELECT EXISTS (SELECT 1 FROM memberships
                            WHERE org_id = $1 AND user_id = $2
                              AND role = 'agent' AND removed_at IS NULL)",
        )
        .bind(member.org_id)
        .bind(agent)
        .fetch_one(&mut *tx)
        .await?;
        if !is_agent {
            return Err(ApiError::new(
                StatusCode::UNPROCESSABLE_ENTITY,
                "lead.not_an_agent",
                "Leads go to Sales Agents",
            )
            .detail("Choose a Sales Agent of this company."));
        }
    }
    let agent = req.agent_id.unwrap_or(before.summary.agent_id);
    sqlx::query(
        "UPDATE leads
         SET status = coalesce($3, status),
             note = CASE WHEN $4::text IS NULL THEN note ELSE nullif($4, '') END,
             agent_id = $5,
             updated_at = now()
         WHERE org_id = $1 AND id = $2",
    )
    .bind(member.org_id)
    .bind(path.lead_id)
    .bind(req.status)
    .bind(note)
    .bind(agent)
    .execute(&mut *tx)
    .await?;
    if let Some(agent) = agent.filter(|a| Some(*a) != before.summary.agent_id) {
        let body = [
            Some(before.summary.name.as_str()),
            before.summary.city.as_deref(),
        ]
        .into_iter()
        .flatten()
        .collect::<Vec<_>>()
        .join(" · ");
        notify::add(
            &mut tx,
            member.org_id,
            agent,
            Kind::LeadAssigned,
            "New lead for you",
            &format!("{body} · call them"),
            Links {
                lead_id: Some(path.lead_id),
                ..Links::default()
            },
        )
        .await?;
    }
    // An agent can't hand it on, so they can still read it here.
    let lead = load(&mut tx, &member, path.lead_id, false).await?;
    tx.commit().await?;
    tracing::info!(
        org_id = %member.org_id, lead_id = %path.lead_id, by = %member.user_id,
        status = lead.summary.status.label(), "lead changed"
    );
    Ok(Json(lead))
}

#[utoipa::path(
    delete,
    path = "/orgs/{org_id}/leads/{lead_id}",
    operation_id = "deleteLead",
    tag = "leads",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("lead_id" = Uuid, Path, description = "The lead."),
    ),
    responses(
        (status = 204, description = "Deleted."),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn delete_lead(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<LeadPath>,
) -> ApiResult<StatusCode> {
    let mut tx = admin.begin(&state.db).await?;
    // Its notifications go with it (ON DELETE CASCADE).
    let gone = sqlx::query("DELETE FROM leads WHERE org_id = $1 AND id = $2")
        .bind(admin.org_id)
        .bind(path.lead_id)
        .execute(&mut *tx)
        .await?
        .rows_affected();
    if gone == 0 {
        return Err(ApiError::not_found());
    }
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, lead_id = %path.lead_id, by = %admin.user_id, "lead deleted");
    Ok(StatusCode::NO_CONTENT)
}

/*
    An agent leaving the company gives their leads back to the admin, so
    none stays with someone who can't see it
*/
pub async fn release(conn: &mut PgConnection, org_id: Uuid, user_id: Uuid) -> ApiResult<()> {
    sqlx::query(
        "UPDATE leads SET agent_id = NULL, updated_at = now()
         WHERE org_id = $1 AND agent_id = $2",
    )
    .bind(org_id)
    .bind(user_id)
    .execute(conn)
    .await?;
    Ok(())
}

/*
    The lead key
*/

// The contract's `LeadKeyInfo`.
#[derive(Debug, Serialize, ToSchema)]
pub struct LeadKeyInfo {
    pub set: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub made_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_used_at: Option<DateTime<Utc>>,
}

// The contract's `LeadKeyNew`.
#[derive(Debug, Serialize, ToSchema)]
pub struct LeadKeyNew {
    pub key: String,
    pub made_at: DateTime<Utc>,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/lead-key",
    operation_id = "adminGetLeadKey",
    tag = "leads",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "Whether a key is set.", body = LeadKeyInfo),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_lead_key(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<Json<LeadKeyInfo>> {
    let mut tx = admin.begin(&state.db).await?;
    let row: Option<(DateTime<Utc>, Option<DateTime<Utc>>)> =
        sqlx::query_as("SELECT made_at, last_used_at FROM lead_keys WHERE org_id = $1")
            .bind(admin.org_id)
            .fetch_optional(&mut *tx)
            .await?;
    tx.commit().await?;
    Ok(Json(LeadKeyInfo {
        set: row.is_some(),
        made_at: row.map(|r| r.0),
        last_used_at: row.and_then(|r| r.1),
    }))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/admin/lead-key",
    operation_id = "adminMakeLeadKey",
    tag = "leads",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 201, description = "The new key, shown once.", body = LeadKeyNew),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn make_lead_key(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<(StatusCode, Json<LeadKeyNew>)> {
    let key = format!("{KEY_PREFIX}{}_{}", admin.org_id.simple(), new_token()?);
    let mut tx = admin.begin(&state.db).await?;
    let made_at: DateTime<Utc> = sqlx::query_scalar(
        "INSERT INTO lead_keys (org_id, key_hash, made_by) VALUES ($1, $2, $3)
         ON CONFLICT (org_id) DO UPDATE
         SET key_hash = $2, made_by = $3, made_at = now(), last_used_at = NULL
         RETURNING made_at",
    )
    .bind(admin.org_id)
    .bind(hash_token(&key))
    .bind(admin.user_id)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, by = %admin.user_id, "lead key made");
    Ok((StatusCode::CREATED, Json(LeadKeyNew { key, made_at })))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phones_come_to_ten_digits() {
        for raw in [
            "9814022671",
            "+91 98140-22671",
            "09814022671",
            "919814022671",
        ] {
            assert_eq!(normalize_phone(raw).as_deref(), Some("9814022671"), "{raw}");
        }
        for raw in ["12345", "1814022671", "+1 415 555 0100", ""] {
            assert!(normalize_phone(raw).is_none(), "{raw}");
        }
    }

    #[test]
    fn a_key_names_its_company() {
        let org = Uuid::now_v7();
        let key = format!("lead_{}_{}", org.simple(), "a".repeat(64));
        assert_eq!(key_org(&key), Some(org));
        assert!(key_org("lead_nope").is_none());
        assert!(key_org(&format!("lead_{}_{}", org.simple(), "z".repeat(64))).is_none());
        assert!(key_org(&format!("sess_{}_{}", org.simple(), "a".repeat(64))).is_none());
    }
}
