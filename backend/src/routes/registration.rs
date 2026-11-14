/*
    A solar company registers with SolaCliq (F2)
    --------------------------------------------------------------------
    - POST /org-registrations, public (no login)
    - flow:
        1. check every field; the GSTIN by format and checksum, with PAN
           and state taken from it
        2. one transaction: the company (pending), the owner's account
           (no password) and their org_admin membership
        3. email MarkCliq (REVIEW_EMAIL) to review it, and the owner that
           it arrived
    - a platform admin then approves or rejects it (`platform.rs`)
*/

use axum::{extract::State, http::StatusCode};
use serde::Deserialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, PRODUCT_NAME,
    error::{ApiError, ApiResult},
    extract::ApiJson,
    gstin::{self, Gstin},
    mail::Email,
    org::BusinessType,
    validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(register_org))
}

// The contract's `OrgRegistrationCreate`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct OrgRegistrationCreate {
    pub legal_name: String,
    // Shown in the app; the legal name when left out.
    pub trade_name: Option<String>,
    pub business_type: BusinessType,
    pub gstin: String,
    pub address_line_1: String,
    pub address_line_2: Option<String>,
    pub city: String,
    pub pin_code: String,
    pub owner_name: String,
    pub email: String,
    pub phone: String,
}

#[utoipa::path(
    post,
    path = "/org-registrations",
    operation_id = "registerOrg",
    tag = "onboarding",
    security(()),
    request_body = OrgRegistrationCreate,
    responses(
        (status = 202, description = "Saved as pending; MarkCliq reviews it."),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn register_org(
    State(state): State<AppState>,
    ApiJson(req): ApiJson<OrgRegistrationCreate>,
) -> ApiResult<StatusCode> {
    let r = validate_registration(req)?;
    let mut tx = state.db.begin().await?;

    /*
        A GSTIN can have one live registration. Checked first for a clear
        answer; the unique index (orgs_gstin_live) still decides if two
        registrations race, and `taken_on_conflict` maps that to the same
        409
    */
    let taken: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM orgs WHERE gstin = $1 AND status <> 'rejected')",
    )
    .bind(&r.gstin.number)
    .fetch_one(&mut *tx)
    .await?;
    if taken {
        return Err(gstin_taken());
    }

    /*
        The owner's account. An email that already has an account (they
        work with another company, say) keeps it as it is; otherwise a
        new one with no password, set up after approval
    */
    let created: Option<Uuid> = sqlx::query_scalar(
        "INSERT INTO users (id, email, name, phone) VALUES ($1, $2, $3, $4)
         ON CONFLICT (email) DO NOTHING
         RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(&r.email)
    .bind(&r.owner_name)
    .bind(&r.phone)
    .fetch_optional(&mut *tx)
    .await?;
    let owner_id = match created {
        Some(id) => id,
        None => {
            sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
                .bind(&r.email)
                .fetch_one(&mut *tx)
                .await?
        }
    };

    let org_id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO orgs (id, name, phone, status, legal_name, business_type,
                           gstin, pan, address_line_1, address_line_2, city,
                           state, pin_code)
         VALUES ($1, $2, $3, 'pending', $4, $5, $6, $7, $8, $9, $10, $11, $12)",
    )
    .bind(org_id)
    .bind(&r.name)
    .bind(&r.phone)
    .bind(&r.legal_name)
    .bind(r.business_type)
    .bind(&r.gstin.number)
    .bind(&r.gstin.pan)
    .bind(&r.address_line_1)
    .bind(&r.address_line_2)
    .bind(&r.city)
    .bind(r.gstin.state)
    .bind(&r.pin_code)
    .execute(&mut *tx)
    .await
    .map_err(taken_on_conflict)?;

    sqlx::query(
        "INSERT INTO memberships (id, user_id, org_id, role) VALUES ($1, $2, $3, 'org_admin')",
    )
    .bind(Uuid::now_v7())
    .bind(owner_id)
    .bind(org_id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;

    tracing::info!(%org_id, gstin = %r.gstin.number, "company registered; pending review");
    state
        .mailer
        .send(review_email(&state.review_email, org_id, &r));
    state.mailer.send(received_email(&r));
    Ok(StatusCode::ACCEPTED)
}

// A registration that passed every check, tidied.
struct ValidRegistration {
    // Shown in the app: the trade name, or the legal name.
    name: String,
    legal_name: String,
    business_type: BusinessType,
    gstin: Gstin,
    address_line_1: String,
    address_line_2: Option<String>,
    city: String,
    pin_code: String,
    owner_name: String,
    email: String,
    phone: String,
}

/*
    Every problem at once, so the form can mark all bad fields. A bad
    GSTIN on its own gets its own code (`org.gstin_invalid`), which the
    app shows under the GSTIN field
*/
fn validate_registration(req: OrgRegistrationCreate) -> ApiResult<ValidRegistration> {
    let legal_name = req.legal_name.trim().to_owned();
    let trade_name = optional(req.trade_name);
    let address_line_1 = req.address_line_1.trim().to_owned();
    let address_line_2 = optional(req.address_line_2);
    let city = req.city.trim().to_owned();
    let pin_code = req.pin_code.trim().to_owned();
    let owner_name = req.owner_name.trim().to_owned();
    let email = validate::normalize_email(&req.email);
    let phone: String = req.phone.chars().filter(|c| !c.is_whitespace()).collect();

    // (field, message) for every field that's wrong.
    let mut errors: Vec<(&str, &str)> = Vec::new();
    if !within(&legal_name, 150) {
        errors.push((
            "legal_name",
            "Enter the legal name, as on the GST certificate.",
        ));
    }
    if trade_name
        .as_deref()
        .is_some_and(|t| t.chars().count() > 150)
    {
        errors.push(("trade_name", "Up to 150 characters."));
    }
    if !within(&address_line_1, 200) {
        errors.push(("address_line_1", "Enter the address."));
    }
    if address_line_2
        .as_deref()
        .is_some_and(|a| a.chars().count() > 200)
    {
        errors.push(("address_line_2", "Up to 200 characters."));
    }
    if !within(&city, 80) {
        errors.push(("city", "Enter the city."));
    }
    if !is_pin_code(&pin_code) {
        errors.push(("pin_code", "Enter the 6-digit PIN code."));
    }
    if !within(&owner_name, 100) {
        errors.push(("owner_name", "Enter your name."));
    }
    if !validate::looks_like_email(&email) {
        errors.push(("email", "Enter a valid email address."));
    }
    if !validate::is_indian_mobile(&phone) {
        errors.push(("phone", "Enter a 10-digit mobile number, without +91."));
    }

    let gstin = gstin::parse(&req.gstin);
    let gstin = match (gstin, errors.is_empty()) {
        (Some(g), true) => g,
        (None, true) => {
            return Err(ApiError::new(
                StatusCode::UNPROCESSABLE_ENTITY,
                "org.gstin_invalid",
                "That GSTIN isn't valid",
            )
            .field(
                "gstin",
                "Check the 15-character GSTIN on your GST certificate.",
            ));
        }
        (gstin, false) => {
            if gstin.is_none() {
                errors.push(("gstin", "Check the 15-character GSTIN."));
            }
            return Err(errors
                .into_iter()
                .fold(ApiError::validation(Vec::new()), |e, (f, m)| e.field(f, m)));
        }
    };

    Ok(ValidRegistration {
        name: trade_name.unwrap_or_else(|| legal_name.clone()),
        legal_name,
        business_type: req.business_type,
        gstin,
        address_line_1,
        address_line_2,
        city,
        pin_code,
        owner_name,
        email,
        phone,
    })
}

// Trimmed; a blank value means it was left out.
fn optional(value: Option<String>) -> Option<String> {
    value.map(|v| v.trim().to_owned()).filter(|v| !v.is_empty())
}

// Not blank, and at most `max` characters.
fn within(value: &str, max: usize) -> bool {
    !value.is_empty() && value.chars().count() <= max
}

// `^[1-9][0-9]{5}$`: Indian PIN codes don't start with 0.
fn is_pin_code(pin: &str) -> bool {
    pin.len() == 6 && !pin.starts_with('0') && pin.chars().all(|c| c.is_ascii_digit())
}

fn gstin_taken() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "org.gstin_taken",
        "This GSTIN is already registered",
    )
    .detail("A company with this GSTIN is already on SolaCliq or waiting for review. Contact MarkCliq if this is a mistake.")
}

// The unique GSTIN index refused the insert: same answer as the check.
fn taken_on_conflict(e: sqlx::Error) -> ApiError {
    let is_gstin = e
        .as_database_error()
        .and_then(|d| d.constraint())
        .is_some_and(|c| c == "orgs_gstin_live");
    if is_gstin { gstin_taken() } else { e.into() }
}

// To MarkCliq: everything needed to review and call them.
fn review_email(to: &str, org_id: Uuid, r: &ValidRegistration) -> Email {
    let address = match &r.address_line_2 {
        Some(line2) => format!("{}, {line2}", r.address_line_1),
        None => r.address_line_1.clone(),
    };
    Email {
        to: to.to_owned(),
        subject: format!("New company to review: {}", r.name),
        body: format!(
            "A company registered on {PRODUCT_NAME} and is waiting for review.\n\n\
             Company: {} ({})\n\
             Legal name: {}\n\
             Business type: {:?}\n\
             GSTIN: {} (PAN {}, {})\n\
             Address: {address}, {} {}\n\n\
             Owner: {}\n\
             Email: {}\n\
             Phone: +91 {}\n\n\
             Company id: {org_id}\n\
             Approve or reject: POST /api/v1/platform/orgs/{org_id}/status",
            r.name,
            r.gstin.state,
            r.legal_name,
            r.business_type,
            r.gstin.number,
            r.gstin.pan,
            r.gstin.state,
            r.city,
            r.pin_code,
            r.owner_name,
            r.email,
            r.phone,
        ),
    }
}

// To the owner: it arrived, and what happens next.
fn received_email(r: &ValidRegistration) -> Email {
    Email {
        to: r.email.clone(),
        subject: format!("We received {}'s registration", r.name),
        body: format!(
            "Thanks for registering {} on {PRODUCT_NAME}.\n\n\
             The MarkCliq team checks every company before it goes live. \
             We'll call you on +91 {} and email you here once it's approved.",
            r.name, r.phone
        ),
    }
}
