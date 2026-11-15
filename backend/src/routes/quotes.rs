/*
    Asking for a solar quote (phase 6)
    --------------------------------------------------------------------
    - POST /quote-requests: anyone logged in, from the Personal workspace
    - saves the lead with a general estimate, emails it to MarkCliq
      (REVIEW_EMAIL), and notifies the person that it was sent
    - safe to retry (Idempotency-Key)
*/

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, AuthUser},
    idempotency::{self, IdempotencyKey},
    mail::{
        Email,
        template::{self as t, Badge, EmailPage, Tone},
    },
    notify, validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(create_quote_request))
}

const REQUEST: &str = "POST /api/v1/quote-requests";

#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "quote_for", rename_all = "snake_case")]
pub enum QuoteFor {
    Home,
    Business,
    Farm,
}

// Monthly electricity bill, in rupees.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "bill_band", rename_all = "snake_case")]
pub enum BillBand {
    // Written out: snake_case alone would give `under1500`.
    #[serde(rename = "under_1500")]
    #[sqlx(rename = "under_1500")]
    Under1500,
    #[serde(rename = "from_1500_to_3000")]
    #[sqlx(rename = "from_1500_to_3000")]
    From1500To3000,
    #[serde(rename = "from_3000_to_6000")]
    #[sqlx(rename = "from_3000_to_6000")]
    From3000To6000,
    #[serde(rename = "over_6000")]
    #[sqlx(rename = "over_6000")]
    Over6000,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "roof_type", rename_all = "snake_case")]
pub enum RoofType {
    Rcc,
    TinShed,
    Other,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "quote_timeline", rename_all = "snake_case")]
pub enum QuoteTimeline {
    ThisMonth,
    #[serde(rename = "in_1_to_3_months")]
    #[sqlx(rename = "in_1_to_3_months")]
    In1To3Months,
    Exploring,
}

/*
    How the lead email names each choice: the words the app's quote form
    shows, not the code's names
*/
impl QuoteFor {
    fn label(self) -> &'static str {
        match self {
            QuoteFor::Home => "Home",
            QuoteFor::Business => "Business",
            QuoteFor::Farm => "Farm",
        }
    }
}

impl BillBand {
    fn label(self) -> &'static str {
        match self {
            BillBand::Under1500 => "Under ₹1,500",
            BillBand::From1500To3000 => "₹1,500 to ₹3,000",
            BillBand::From3000To6000 => "₹3,000 to ₹6,000",
            BillBand::Over6000 => "Over ₹6,000",
        }
    }
}

impl RoofType {
    fn label(self) -> &'static str {
        match self {
            RoofType::Rcc => "RCC (concrete)",
            RoofType::TinShed => "Tin shed",
            RoofType::Other => "Other",
        }
    }
}

impl QuoteTimeline {
    fn label(self) -> &'static str {
        match self {
            QuoteTimeline::ThisMonth => "This month",
            QuoteTimeline::In1To3Months => "1 to 3 months",
            QuoteTimeline::Exploring => "Just exploring",
        }
    }
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct QuoteRequestCreate {
    pub quote_for: QuoteFor,
    pub pin_code: String,
    pub city: String,
    pub bill_band: BillBand,
    pub roof: RoofType,
    pub timeline: QuoteTimeline,
    // Needed only when the account has no phone.
    pub phone: Option<String>,
    // Must be true: the person agrees to be contacted.
    pub share_consent: bool,
}

#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
pub struct QuoteEstimate {
    pub kw_min: i32,
    pub kw_max: i32,
    pub price_min: i64,
    pub price_max: i64,
    pub subsidy_max: i64,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct QuoteRequest {
    pub id: Uuid,
    // Always `open` when made.
    pub status: &'static str,
    pub created_at: DateTime<Utc>,
    pub estimate: QuoteEstimate,
}

/*
    The general estimate (owner's decision, 2026-11-15: general figures,
    not any vendor's prices). Change the numbers here
    --------------------------------------------------------------------
    - system size from the monthly bill
    - price: ₹55,000 to ₹65,000 per kW
    - subsidy (PM Surya Ghar, homes only): ₹30,000 per kW for the first
      2 kW, ₹18,000 for the 3rd, ₹78,000 at most
    - money in paise
*/
const PRICE_PER_KW_MIN: i64 = 55_000 * 100;
const PRICE_PER_KW_MAX: i64 = 65_000 * 100;

pub fn estimate(quote_for: QuoteFor, bill: BillBand) -> QuoteEstimate {
    let (kw_min, kw_max) = match bill {
        BillBand::Under1500 => (1, 2),
        BillBand::From1500To3000 => (2, 3),
        BillBand::From3000To6000 => (3, 5),
        BillBand::Over6000 => (5, 10),
    };
    let subsidy_max = match quote_for {
        QuoteFor::Home => match kw_max {
            1 => 30_000,
            2 => 60_000,
            _ => 78_000,
        },
        QuoteFor::Business | QuoteFor::Farm => 0,
    } * 100;
    QuoteEstimate {
        kw_min,
        kw_max,
        price_min: i64::from(kw_min) * PRICE_PER_KW_MIN,
        price_max: i64::from(kw_max) * PRICE_PER_KW_MAX,
        subsidy_max,
    }
}

#[utoipa::path(
    post,
    path = "/quote-requests",
    operation_id = "createQuoteRequest",
    tag = "quotes",
    params(("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry.")),
    request_body = QuoteRequestCreate,
    responses(
        (status = 201, description = "Sent.", body = QuoteRequest),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn create_quote_request(
    State(state): State<AppState>,
    user: AuthUser,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<QuoteRequestCreate>,
) -> ApiResult<Response> {
    if let Some(done) = idempotency::replay(&state.db, user.user_id, key, REQUEST).await? {
        return Ok(done);
    }

    if !req.share_consent {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "quote.consent_required",
            "Agree to be contacted",
        )
        .field("share_consent", "MarkCliq needs your OK to call you."));
    }
    let pin_code = req.pin_code.trim().to_owned();
    let city = req.city.trim().to_owned();
    let mut errors: Vec<(&str, &str)> = Vec::new();
    if !validate::is_pin_code(&pin_code) {
        errors.push(("pin_code", "Enter the 6-digit PIN code."));
    }
    if city.is_empty() || city.chars().count() > 80 {
        errors.push(("city", "Enter the city."));
    }
    let given_phone = req
        .phone
        .as_deref()
        .map(|p| p.chars().filter(|c| !c.is_whitespace()).collect::<String>())
        .filter(|p| !p.is_empty());
    if given_phone
        .as_deref()
        .is_some_and(|p| !validate::is_indian_mobile(p))
    {
        errors.push(("phone", "Enter a 10-digit mobile number, without +91."));
    }
    if !errors.is_empty() {
        return Err(errors
            .into_iter()
            .fold(ApiError::validation(Vec::new()), |e, (f, m)| e.field(f, m)));
    }

    let (name, email, account_phone): (String, String, Option<String>) =
        sqlx::query_as("SELECT name, email, phone FROM users WHERE id = $1")
            .bind(user.user_id)
            .fetch_one(&state.db)
            .await?;
    // The account's number first: it's the one the person keeps.
    let Some(phone) = account_phone.or(given_phone) else {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "quote.phone_required",
            "Add a phone number",
        )
        .field("phone", "MarkCliq calls you on it."));
    };

    let estimate = estimate(req.quote_for, req.bill_band);
    let quote = QuoteRequest {
        id: Uuid::now_v7(),
        status: "open",
        created_at: Utc::now(),
        estimate,
    };

    let mut tx = state.db.begin().await?;
    sqlx::query(
        "INSERT INTO quote_requests (id, user_id, quote_for, pin_code, city, bill_band,
                                     roof, timeline, phone, kw_min, kw_max, price_min,
                                     price_max, subsidy_max, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)",
    )
    .bind(quote.id)
    .bind(user.user_id)
    .bind(req.quote_for)
    .bind(&pin_code)
    .bind(&city)
    .bind(req.bill_band)
    .bind(req.roof)
    .bind(req.timeline)
    .bind(&phone)
    .bind(estimate.kw_min)
    .bind(estimate.kw_max)
    .bind(estimate.price_min)
    .bind(estimate.price_max)
    .bind(estimate.subsidy_max)
    .bind(quote.created_at)
    .execute(&mut *tx)
    .await?;
    notify::add_personal(
        &mut tx,
        user.user_id,
        notify::Kind::QuoteShared,
        "Quote request sent",
        &format!("MarkCliq will call you about solar in {city}"),
    )
    .await?;

    let body = serde_json::to_value(&quote).map_err(|_| ApiError::internal())?;
    if !idempotency::save(
        &mut tx,
        user.user_id,
        key,
        REQUEST,
        StatusCode::CREATED,
        &body,
    )
    .await?
    {
        // A retry with this key finished first: answer as it did.
        drop(tx);
        return idempotency::replay(&state.db, user.user_id, key, REQUEST)
            .await?
            .ok_or_else(ApiError::internal);
    }
    tx.commit().await?;

    tracing::info!(quote_id = %quote.id, %pin_code, "quote requested");
    state.mailer.send(lead_email(
        &state.review_email,
        &name,
        &email,
        &phone,
        &req,
        &pin_code,
        &city,
        &estimate,
    ));
    Ok((StatusCode::CREATED, Json(body)).into_response())
}

// To MarkCliq: the lead, with what they need to call.
#[allow(clippy::too_many_arguments)]
fn lead_email(
    to: &str,
    name: &str,
    email: &str,
    phone: &str,
    req: &QuoteRequestCreate,
    pin_code: &str,
    city: &str,
    e: &QuoteEstimate,
) -> Email {
    let estimate = format!(
        "{} to {} kW, {} to {}, subsidy up to {}",
        e.kw_min,
        e.kw_max,
        rupees(e.price_min),
        rupees(e.price_max),
        rupees(e.subsidy_max)
    );
    let rows = [
        ("Name", name.to_owned()),
        ("Phone", format!("+91 {phone}")),
        ("Email", email.to_owned()),
        ("For", req.quote_for.label().to_owned()),
        ("Where", format!("{city} {pin_code}")),
        ("Monthly bill", req.bill_band.label().to_owned()),
        ("Roof", req.roof.label().to_owned()),
        ("When", req.timeline.label().to_owned()),
        ("Estimate shown", estimate),
    ];
    let text_rows: String = rows
        .iter()
        .map(|(label, value)| format!("{label}: {value}\n"))
        .collect();
    let intro = format!("{name} asked for a solar quote. Call them soon: leads cool fast.");
    Email {
        to: to.to_owned(),
        subject: format!("New solar quote request: {city}"),
        body: format!("{intro}\n\n{text_rows}"),
        html: Some(t::page(EmailPage {
            preheader: Some(&format!(
                "{name} \u{b7} +91 {phone} \u{b7} {city} \u{b7} bill {}",
                req.bill_band.label()
            )),
            sun_dot: false,
            badge: Some(Badge {
                glyph: "&#9728;",
                tone: Tone::Sun,
            }),
            heading: "New quote request",
            card: [
                t::para(&intro),
                t::button(&format!("tel:+91{phone}"), &format!("Call +91 {phone}")),
                t::figure(
                    "Estimate shown to them",
                    &format!("{} to {} kW", e.kw_min, e.kw_max),
                    &format!(
                        "{} to {} \u{b7} subsidy up to {}",
                        rupees(e.price_min),
                        rupees(e.price_max),
                        rupees(e.subsidy_max)
                    ),
                ),
                t::details(&rows[2..8]),
            ]
            .concat(),
            note: None,
        })),
    }
}

/*
    Paise as whole rupees, grouped the Indian way: 19_500_000 paise is
    "₹1,95,000" (the last three digits, then pairs)
*/
fn rupees(paise: i64) -> String {
    let digits = (paise / 100).to_string();
    let (rest, last3) = digits.split_at(digits.len().saturating_sub(3));
    let mut groups: Vec<&str> = Vec::new();
    let mut rest = rest;
    while rest.len() > 2 {
        let (head, pair) = rest.split_at(rest.len() - 2);
        groups.push(pair);
        rest = head;
    }
    if !rest.is_empty() {
        groups.push(rest);
    }
    groups.reverse();
    groups.push(last3);
    format!("₹{}", groups.join(","))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rupees_are_grouped_the_indian_way() {
        assert_eq!(rupees(0), "₹0");
        assert_eq!(rupees(999 * 100), "₹999");
        assert_eq!(rupees(1_000 * 100), "₹1,000");
        assert_eq!(rupees(78_000 * 100), "₹78,000");
        assert_eq!(rupees(195_000 * 100), "₹1,95,000");
        assert_eq!(rupees(650_000 * 100), "₹6,50,000");
        assert_eq!(rupees(12_345_678 * 100), "₹1,23,45,678");
    }

    #[test]
    fn the_lead_email_reads_like_the_form() {
        let req = QuoteRequestCreate {
            quote_for: QuoteFor::Home,
            pin_code: "160062".into(),
            city: "Mohali".into(),
            bill_band: BillBand::From1500To3000,
            roof: RoofType::Rcc,
            timeline: QuoteTimeline::In1To3Months,
            phone: None,
            share_consent: true,
        };
        let e = estimate(req.quote_for, req.bill_band);
        let body = lead_email(
            "r@example.com",
            "Asha",
            "asha@example.com",
            "9814022671",
            &req,
            "160062",
            "Mohali",
            &e,
        )
        .body;
        assert!(body.contains("For: Home\n"));
        assert!(body.contains("Monthly bill: ₹1,500 to ₹3,000\n"));
        assert!(body.contains("Roof: RCC (concrete)\n"));
        assert!(body.contains("When: 1 to 3 months\n"));
        assert!(body.contains(
            "Estimate shown: 2 to 3 kW, ₹1,10,000 to ₹1,95,000, subsidy up to ₹78,000\n"
        ));
    }

    #[test]
    fn the_estimate_follows_the_bill_and_the_subsidy_rules() {
        let e = estimate(QuoteFor::Home, BillBand::From3000To6000);
        assert_eq!((e.kw_min, e.kw_max), (3, 5));
        assert_eq!(e.price_min, 3 * 55_000 * 100);
        assert_eq!(e.price_max, 5 * 65_000 * 100);
        assert_eq!(e.subsidy_max, 78_000 * 100);

        assert_eq!(
            estimate(QuoteFor::Home, BillBand::Under1500).subsidy_max,
            60_000 * 100
        );
        assert_eq!(
            estimate(QuoteFor::Business, BillBand::Over6000).subsidy_max,
            0
        );
    }
}
