/*
    The person's own details and settings (phase 6)
    --------------------------------------------------------------------
    - GET/PUT /me/details: phone, address, emergency contact, payout bank.
      Shared by every company the person works with
    - GET/PUT /me/settings: notifications, the same on every phone
      they sign in on. English only: no language setting
    - GET /me/notifications: their own feed (Personal workspace)
*/

use axum::{Json, extract::State};
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, bank,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiQuery, AuthUser},
    notify::{self, NotificationPage},
    page::Page,
    validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(get_details, update_details))
        .routes(routes!(get_settings, update_settings))
        .routes(routes!(my_notifications))
        .routes(routes!(read_my_notifications))
}

/*
    The contract's `PayoutBank`. In a PUT, `account_number` and `ifsc`
    come in; in a response, `account_last4` and `bank_name` go out
*/
#[derive(Debug, Default, Serialize, Deserialize, ToSchema)]
pub struct PayoutBank {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub holder: Option<String>,
    #[serde(default, skip_serializing)]
    pub account_number: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none", skip_deserializing)]
    pub account_last4: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ifsc: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none", skip_deserializing)]
    pub bank_name: Option<String>,
}

// The contract's `PersonalDetails`. In a PUT, a field left out stays as it is.
#[derive(Debug, Default, Serialize, Deserialize, ToSchema)]
pub struct PersonalDetails {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub address: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub emergency_contact: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub bank: Option<PayoutBank>,
}

#[derive(sqlx::FromRow)]
struct DetailsRow {
    phone: Option<String>,
    address: Option<String>,
    emergency_contact: Option<String>,
    bank_holder: Option<String>,
    bank_ifsc: Option<String>,
    bank_name: Option<String>,
    bank_last4: Option<String>,
}

async fn load_details(db: &sqlx::PgPool, user_id: Uuid) -> ApiResult<PersonalDetails> {
    // LEFT JOIN: a person who never saved details still has a phone, maybe.
    let r: DetailsRow = sqlx::query_as(
        "SELECT u.phone, d.address, d.emergency_contact, d.bank_holder,
                d.bank_ifsc, d.bank_name, d.bank_last4
         FROM users u LEFT JOIN user_details d ON d.user_id = u.id
         WHERE u.id = $1",
    )
    .bind(user_id)
    .fetch_one(db)
    .await?;
    let bank = r.bank_last4.is_some().then_some(PayoutBank {
        holder: r.bank_holder,
        account_number: None,
        account_last4: r.bank_last4,
        ifsc: r.bank_ifsc,
        bank_name: r.bank_name,
    });
    Ok(PersonalDetails {
        phone: r.phone,
        address: r.address,
        emergency_contact: r.emergency_contact,
        bank,
    })
}

#[utoipa::path(
    get,
    path = "/me/details",
    operation_id = "getMyDetails",
    tag = "profile",
    responses(
        (status = 200, description = "The details.", body = PersonalDetails),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_details(
    State(state): State<AppState>,
    user: AuthUser,
) -> ApiResult<Json<PersonalDetails>> {
    Ok(Json(load_details(&state.db, user.user_id).await?))
}

/*
    Change details or the payout bank
    --------------------------------------------------------------------
    - send only what changes; a blank text field clears it
    - a bank needs `account_number` and `ifsc` together; the number is
      encrypted and only its last 4 digits are kept readable
    - one transaction: the phone (on users) and the rest (user_details)
      change together or not at all
*/
#[utoipa::path(
    put,
    path = "/me/details",
    operation_id = "updateMyDetails",
    tag = "profile",
    request_body = PersonalDetails,
    responses(
        (status = 200, description = "Saved.", body = PersonalDetails),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn update_details(
    State(state): State<AppState>,
    user: AuthUser,
    ApiJson(req): ApiJson<PersonalDetails>,
) -> ApiResult<Json<PersonalDetails>> {
    let phone = req.phone.as_deref().map(clean);
    let address = req.address.as_deref().map(clean);
    let emergency = req.emergency_contact.as_deref().map(clean);

    let mut errors: Vec<(&str, &str)> = Vec::new();
    if let Some(Some(p)) = &phone {
        let digits: String = p.chars().filter(|c| !c.is_whitespace()).collect();
        if !validate::is_indian_mobile(&digits) {
            errors.push(("phone", "Enter a 10-digit mobile number, without +91."));
        }
    }
    if address.as_ref().is_some_and(|a| too_long(a, 200)) {
        errors.push(("address", "Up to 200 characters."));
    }
    if emergency.as_ref().is_some_and(|e| too_long(e, 120)) {
        errors.push(("emergency_contact", "Up to 120 characters."));
    }
    let bank = match &req.bank {
        None => None,
        Some(b) => match check_bank(b) {
            Ok(bank) => Some(bank),
            Err(e) => {
                errors.extend(e);
                None
            }
        },
    };
    if !errors.is_empty() {
        return Err(errors
            .into_iter()
            .fold(ApiError::validation(Vec::new()), |e, (f, m)| e.field(f, m)));
    }

    let mut tx = state.db.begin().await?;
    if let Some(phone) = &phone {
        let digits = phone
            .as_deref()
            .map(|p| p.chars().filter(|c| !c.is_whitespace()).collect::<String>());
        sqlx::query("UPDATE users SET phone = $2, updated_at = now() WHERE id = $1")
            .bind(user.user_id)
            .bind(digits)
            .execute(&mut *tx)
            .await?;
    }

    /*
        One upsert for the rest. `$n_set` says whether the field was sent:
        a field not sent keeps its stored value (the CASE), a sent blank
        clears it
    */
    let encrypted = match &bank {
        Some(b) => Some(state.bank_key.encrypt(&b.account_number)?),
        None => None,
    };
    sqlx::query(
        "INSERT INTO user_details (user_id, address, emergency_contact, bank_holder,
                                   bank_ifsc, bank_name, bank_last4, bank_account_enc)
         VALUES ($1, $3, $5, $7, $8, $9, $10, $11)
         ON CONFLICT (user_id) DO UPDATE SET
            address = CASE WHEN $2 THEN EXCLUDED.address ELSE user_details.address END,
            emergency_contact = CASE WHEN $4 THEN EXCLUDED.emergency_contact
                                     ELSE user_details.emergency_contact END,
            bank_holder = CASE WHEN $6 THEN EXCLUDED.bank_holder ELSE user_details.bank_holder END,
            bank_ifsc = CASE WHEN $6 THEN EXCLUDED.bank_ifsc ELSE user_details.bank_ifsc END,
            bank_name = CASE WHEN $6 THEN EXCLUDED.bank_name ELSE user_details.bank_name END,
            bank_last4 = CASE WHEN $6 THEN EXCLUDED.bank_last4 ELSE user_details.bank_last4 END,
            bank_account_enc = CASE WHEN $6 THEN EXCLUDED.bank_account_enc
                                    ELSE user_details.bank_account_enc END,
            updated_at = now()",
    )
    .bind(user.user_id)
    .bind(address.is_some())
    .bind(address.flatten())
    .bind(emergency.is_some())
    .bind(emergency.flatten())
    .bind(bank.is_some())
    .bind(bank.as_ref().and_then(|b| b.holder.clone()))
    .bind(bank.as_ref().map(|b| b.ifsc.clone()))
    .bind(bank.as_ref().map(|b| bank::bank_name(&b.ifsc)))
    .bind(bank.as_ref().map(|b| b.last4()))
    .bind(encrypted)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;

    Ok(Json(load_details(&state.db, user.user_id).await?))
}

// Trimmed; None when blank (the field is cleared).
fn clean(value: &str) -> Option<String> {
    let v = value.trim();
    (!v.is_empty()).then(|| v.to_owned())
}

fn too_long(value: &Option<String>, max: usize) -> bool {
    value.as_ref().is_some_and(|v| v.chars().count() > max)
}

// A bank that passed its checks.
struct NewBank {
    holder: Option<String>,
    account_number: String,
    ifsc: String,
}

impl NewBank {
    fn last4(&self) -> String {
        self.account_number[self.account_number.len() - 4..].to_owned()
    }
}

fn check_bank(b: &PayoutBank) -> Result<NewBank, Vec<(&'static str, &'static str)>> {
    let mut errors = Vec::new();
    let holder = b.holder.as_deref().and_then(clean);
    let number: String = b
        .account_number
        .as_deref()
        .unwrap_or("")
        .chars()
        .filter(|c| !c.is_whitespace())
        .collect();
    let ifsc = b.ifsc.as_deref().unwrap_or("").trim().to_uppercase();
    if holder.as_ref().is_some_and(|h| h.chars().count() > 100) {
        errors.push(("bank.holder", "Up to 100 characters."));
    }
    if !(6..=18).contains(&number.len()) || !number.chars().all(|c| c.is_ascii_digit()) {
        errors.push((
            "bank.account_number",
            "Enter the account number: 6 to 18 digits.",
        ));
    }
    if !bank::is_ifsc(&ifsc) {
        errors.push((
            "bank.ifsc",
            "Enter the 11-character IFSC, like HDFC0001234.",
        ));
    }
    if errors.is_empty() {
        Ok(NewBank {
            holder,
            account_number: number,
            ifsc,
        })
    } else {
        Err(errors)
    }
}

// The contract's `Settings`.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct Settings {
    // Push notifications for new work, approvals and returns.
    pub push: bool,
    // A daily WhatsApp summary at 8 pm.
    pub whatsapp: bool,
    pub sound: bool,
}

// Until the person saves their own.
const DEFAULT_SETTINGS: Settings = Settings {
    push: true,
    whatsapp: false,
    sound: true,
};

#[utoipa::path(
    get,
    path = "/me/settings",
    operation_id = "getMySettings",
    tag = "profile",
    responses(
        (status = 200, description = "The settings.", body = Settings),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_settings(State(state): State<AppState>, user: AuthUser) -> ApiResult<Json<Settings>> {
    let saved: Option<Settings> =
        sqlx::query_as("SELECT push, whatsapp, sound FROM user_settings WHERE user_id = $1")
            .bind(user.user_id)
            .fetch_optional(&state.db)
            .await?;
    Ok(Json(saved.unwrap_or(DEFAULT_SETTINGS)))
}

// The whole object, every time.
#[utoipa::path(
    put,
    path = "/me/settings",
    operation_id = "updateMySettings",
    tag = "profile",
    request_body = Settings,
    responses(
        (status = 200, description = "Saved.", body = Settings),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn update_settings(
    State(state): State<AppState>,
    user: AuthUser,
    ApiJson(s): ApiJson<Settings>,
) -> ApiResult<Json<Settings>> {
    sqlx::query(
        "INSERT INTO user_settings (user_id, push, whatsapp, sound)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id) DO UPDATE SET push = $2, whatsapp = $3, sound = $4",
    )
    .bind(user.user_id)
    .bind(s.push)
    .bind(s.whatsapp)
    .bind(s.sound)
    .execute(&state.db)
    .await?;
    Ok(Json(s))
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct FeedQuery {
    // Opaque cursor from the previous page's `next_cursor`.
    pub cursor: Option<String>,
    // Page size, 1 to 100; 25 when left out.
    pub limit: Option<i64>,
}

#[utoipa::path(
    get,
    path = "/me/notifications",
    operation_id = "listMyNotifications",
    tag = "notifications",
    params(FeedQuery),
    responses(
        (status = 200, description = "One page.", body = NotificationPage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn my_notifications(
    State(state): State<AppState>,
    user: AuthUser,
    ApiQuery(q): ApiQuery<FeedQuery>,
) -> ApiResult<Json<NotificationPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    Ok(Json(
        notify::page(&mut *state.db.acquire().await?, user.user_id, None, page).await?,
    ))
}

#[utoipa::path(
    post,
    path = "/me/notifications/read",
    operation_id = "markMyNotificationsRead",
    tag = "notifications",
    responses(
        (status = 204, description = "Done."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn read_my_notifications(
    State(state): State<AppState>,
    user: AuthUser,
) -> ApiResult<axum::http::StatusCode> {
    notify::read_all(&mut *state.db.acquire().await?, user.user_id, None).await?;
    Ok(axum::http::StatusCode::NO_CONTENT)
}
