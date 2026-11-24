/*
    Customers an agent registers, and the documents a company holds
    (phase 9, F4, #38–42)
    --------------------------------------------------------------------
    - POST /orgs/{org_id}/customer-registrations    (idem)  register one
    - GET  /orgs/{org_id}/my-customers                      the agent's
    - GET  /orgs/{org_id}/my-customers/{customer_id}        one of them
    - PUT  .../my-customers/{customer_id}/documents/{kind}  a new copy
    - GET  /orgs/{org_id}/me/documents                      my documents
    - agents (`OrgMember<Agents>`) see only the customers they registered:
      anyone else's is 404
    - registering makes or links the customer's account and emails them
      (product.md, "How customers arrive"); the admin verifies, rejects
      or returns one document on the website
    - KYC files are uploads of this company (purpose `kyc`), checked in
      R2 before they're attached. No Aadhaar or PAN number is collected
    - spec: docs/features/F4-customer-registration.md
*/

use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState, PRODUCT_NAME, counter,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath},
    idempotency::{self, IdempotencyKey},
    india,
    mail::{
        Email,
        template::{self as t, Badge, EmailPage, Step, Tone},
    },
    notify,
    org::{Agents, OrgMember, PayType, Role, WorkersAndCustomers},
    routes::{
        quotes::RoofType,
        tasks::{Person, TaskNote},
        uploads::{self, UploadPurpose},
    },
    stages::{self, Stages},
    validate,
};

// Where the consent line in the welcome email points.
const PRIVACY_URL: &str = "https://solacliq.markcliq.com/privacy";

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(submit_customer_registration))
        .routes(routes!(list_my_customers))
        .routes(routes!(get_my_customer))
        .routes(routes!(replace_customer_document))
        .routes(routes!(list_my_documents))
}

// Up to 1000 kW: a bigger figure is a typo for a rooftop system.
const MAX_KW: f64 = 1000.0;
// Up to ₹10 lakh, in paise.
const MAX_COMMISSION: i64 = 100_000_000;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "connection_type", rename_all = "snake_case")]
pub enum ConnectionType {
    Residential,
    Commercial,
    Industrial,
}

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize, ToSchema, sqlx::Type,
)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "kyc_kind", rename_all = "snake_case")]
pub enum KycKind {
    Aadhaar,
    Pan,
    ElectricityBill,
    BankProof,
    RoofPhoto,
    LandDocument,
    Signature,
    NameChange,
}

impl KycKind {
    // How a person reads it: "Electricity bill".
    pub fn label(self) -> &'static str {
        match self {
            KycKind::Aadhaar => "Aadhaar",
            KycKind::Pan => "PAN",
            KycKind::ElectricityBill => "Electricity bill",
            KycKind::BankProof => "Bank proof",
            KycKind::RoofPhoto => "Roof photo",
            KycKind::LandDocument => "Land document",
            KycKind::Signature => "Signature",
            KycKind::NameChange => "Name change document",
        }
    }
}

// Always needed; bank proof too with the subsidy.
const REQUIRED: [KycKind; 5] = [
    KycKind::Aadhaar,
    KycKind::Pan,
    KycKind::ElectricityBill,
    KycKind::LandDocument,
    KycKind::Signature,
];

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "kyc_status", rename_all = "snake_case")]
pub enum KycStatus {
    InReview,
    NeedsFix,
    Approved,
    // The company decided not to take them up.
    Rejected,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "document_status", rename_all = "snake_case")]
pub enum DocumentStatus {
    Verified,
    InReview,
    NeedsFix,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "commission_status", rename_all = "snake_case")]
pub enum CommissionStatus {
    // Waiting for the admin.
    InReview,
    // Waits for the customer's advance.
    Approved,
    // The advance is paid.
    Payable,
    Paid,
}

/*
    Requests
*/

// A label on a file: an Aadhaar's two sides. Never required.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "document_side", rename_all = "snake_case")]
pub enum DocumentSide {
    Front,
    Back,
}

// The contract's `DocumentFile`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct DocumentFile {
    pub upload_id: Uuid,
    pub side: Option<DocumentSide>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct RegistrationDocument {
    pub kind: KycKind,
    // 1 to 5, in the order added.
    pub files: Vec<DocumentFile>,
}

// The contract's `CustomerRegistrationCreate`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct CustomerRegistrationCreate {
    pub name: String,
    pub phone: String,
    pub email: String,
    pub address: String,
    pub city: String,
    pub pin_code: String,
    pub state: String,
    pub discom: String,
    pub consumer_number: String,
    pub sanctioned_load_kw: f64,
    pub connection_type: ConnectionType,
    pub proposed_kw: f64,
    pub roof: RoofType,
    /*
        The site's position from the agent's phone, if they took it: both
        or neither. Stored as sent, never compared with anything
    */
    pub lat: Option<f64>,
    pub lng: Option<f64>,
    // Apply for PM Surya Ghar.
    pub subsidy: bool,
    pub documents: Vec<RegistrationDocument>,
    // The customer agreed to share these with the company. Must be true.
    pub consent: bool,
    // Commission agents only, paise.
    pub commission: Option<i64>,
    pub commission_note: Option<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct DocumentReplace {
    // 1 to 5: the whole new set.
    pub files: Vec<DocumentFile>,
}

const MAX_FILES: usize = 5;

// One document's files: 1 to 5, none twice.
fn check_files(field: &str, files: &[DocumentFile]) -> ApiResult<()> {
    let distinct: std::collections::BTreeSet<Uuid> = files.iter().map(|f| f.upload_id).collect();
    if files.is_empty() || files.len() > MAX_FILES || distinct.len() != files.len() {
        return Err(ApiError::validation(Vec::new()).field(
            field,
            format!("1 to {MAX_FILES} different files a document."),
        ));
    }
    Ok(())
}

// Points a document at its files, already attached.
async fn add_files(
    conn: &mut PgConnection,
    org_id: Uuid,
    document_id: Uuid,
    files: &[DocumentFile],
) -> ApiResult<()> {
    for (position, f) in (1i16..).zip(files) {
        sqlx::query(
            "INSERT INTO document_files (org_id, document_id, upload_id, position, side)
             VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(org_id)
        .bind(document_id)
        .bind(f.upload_id)
        .bind(position)
        .bind(f.side)
        .execute(&mut *conn)
        .await?;
    }
    Ok(())
}

#[derive(Debug, Deserialize)]
struct CustomerPath {
    customer_id: Uuid,
}

#[derive(Debug, Deserialize)]
struct DocumentPath {
    customer_id: Uuid,
    kind: KycKind,
}

/*
    Responses
*/

#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum RegistrationStatus {
    Submitted,
    Verified,
    Rejected,
}

// The contract's `CustomerRegistration`.
#[derive(Debug, Serialize, ToSchema)]
pub struct CustomerRegistration {
    pub id: Uuid,
    // SC-0001.
    pub reference: String,
    pub status: RegistrationStatus,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct Commission {
    // Paise: what the agent gets.
    pub amount: i64,
    // What the agent asked, when the admin changed it.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proposed_amount: Option<i64>,
    pub status: CommissionStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub admin_note: Option<TaskNote>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub payable_since: Option<NaiveDate>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub paid_on: Option<NaiveDate>,
}

// The contract's `CustomerSummary`.
#[derive(Debug, Serialize, ToSchema)]
pub struct CustomerSummary {
    pub id: Uuid,
    pub name: String,
    pub system_kw: f64,
    pub place: String,
    pub kyc_status: KycStatus,
    // One line on where it stands.
    pub detail: String,
    pub sent_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub commission: Option<Commission>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct CustomerList {
    pub items: Vec<CustomerSummary>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct CustomerStage {
    pub index: i32,
    pub count: i32,
    pub label: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ReturnedDocument {
    pub kind: KycKind,
    pub title: String,
    pub note: TaskNote,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct DocumentsSummary {
    pub status: DocumentStatus,
    pub detail: String,
}

// The contract's `CustomerDetail`.
#[derive(Debug, Serialize, ToSchema)]
pub struct CustomerDetail {
    #[serde(flatten)]
    pub summary: CustomerSummary,
    pub phone: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stage: Option<CustomerStage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub returned: Option<ReturnedDocument>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub documents: Option<DocumentsSummary>,
}

// The contract's `MyDocument`.
#[derive(Debug, Serialize, ToSchema)]
pub struct MyDocument {
    pub kind: KycKind,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
    pub status: DocumentStatus,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct MyDocumentList {
    pub items: Vec<MyDocument>,
    // The agent who collected a customer's KYC.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub uploaded_by: Option<String>,
}

/*
    Errors
*/

fn duplicate(detail: String) -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "registration.duplicate",
        "This customer is already registered here",
    )
    .detail(detail)
}

fn locked() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "registration.locked",
        "Only the document the admin sent back can be replaced",
    )
}

// Postgres refused a duplicate key (two registrations at once).
fn unique_violation(e: &sqlx::Error) -> bool {
    e.as_database_error()
        .and_then(|d| d.code())
        .is_some_and(|c| c == "23505")
}

/*
    Checking a registration
*/

// The request, checked and tidied.
struct Valid {
    name: String,
    phone: String,
    email: String,
    address: String,
    city: String,
    pin_code: String,
    state: String,
    discom: String,
    consumer_number: String,
    commission_note: Option<String>,
}

// Trimmed text of 1 to `max` characters, or a field error.
fn field(
    errors: &mut Vec<(&'static str, String)>,
    name: &'static str,
    value: &str,
    max: usize,
) -> String {
    let value = value.trim();
    if value.is_empty() || value.chars().count() > max {
        errors.push((name, format!("1 to {max} characters.")));
    }
    value.to_owned()
}

/*
    Every field problem at once (so the app can mark them all), then the
    rules with their own codes: documents, then commission
*/
fn check(req: &CustomerRegistrationCreate, pay_type: Option<PayType>) -> ApiResult<Valid> {
    let mut errors = Vec::new();
    let name = field(&mut errors, "name", &req.name, 100);
    let phone = req.phone.trim().to_owned();
    if !validate::is_indian_mobile(&phone) {
        errors.push(("phone", "A 10-digit mobile number.".into()));
    }
    let email = validate::normalize_email(&req.email);
    if !validate::looks_like_email(&email) {
        errors.push(("email", "A valid email address.".into()));
    }
    let address = field(&mut errors, "address", &req.address, 200);
    let city = field(&mut errors, "city", &req.city, 80);
    let pin_code = req.pin_code.trim().to_owned();
    if !validate::is_pin_code(&pin_code) {
        errors.push(("pin_code", "A 6-digit PIN code.".into()));
    }
    let state = field(&mut errors, "state", &req.state, 60);
    let discom = field(&mut errors, "discom", &req.discom, 80);
    let consumer_number = field(&mut errors, "consumer_number", &req.consumer_number, 30);
    for (name, kw) in [
        ("sanctioned_load_kw", req.sanctioned_load_kw),
        ("proposed_kw", req.proposed_kw),
    ] {
        if !(kw > 0.0 && kw <= MAX_KW) {
            errors.push((name, format!("More than 0, up to {MAX_KW} kW.")));
        }
    }
    match (req.lat, req.lng) {
        (None, None) => {}
        (Some(_), None) => errors.push(("lng", "Send it with lat.".into())),
        (None, Some(_)) => errors.push(("lat", "Send it with lng.".into())),
        (Some(lat), Some(lng)) => {
            if !validate::is_lat(lat) {
                errors.push(("lat", "-90 to 90.".into()));
            }
            if !validate::is_lng(lng) {
                errors.push(("lng", "-180 to 180.".into()));
            }
        }
    }
    if !req.consent {
        errors.push(("consent", "The customer has to agree.".into()));
    }
    let commission_note = req
        .commission_note
        .as_deref()
        .map(str::trim)
        .filter(|n| !n.is_empty())
        .map(str::to_owned);
    if commission_note
        .as_ref()
        .is_some_and(|n| n.chars().count() > 200)
    {
        errors.push(("commission_note", "Up to 200 characters.".into()));
    }
    if let Some(c) = req.commission
        && !(0..=MAX_COMMISSION).contains(&c)
    {
        errors.push(("commission", "₹0 to ₹10,00,000.".into()));
    }
    if !errors.is_empty() {
        let mut e = ApiError::validation(Vec::new());
        for (name, message) in errors {
            e = e.field(name, message);
        }
        return Err(e);
    }

    let mut kinds = std::collections::BTreeSet::new();
    for d in &req.documents {
        check_files("documents", &d.files)?;
        if !kinds.insert(d.kind) {
            return Err(ApiError::validation(Vec::new())
                .field("documents", format!("{} is there twice.", d.kind.label())));
        }
    }
    if let Some(missing) = REQUIRED.iter().find(|k| !kinds.contains(k)) {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "registration.document_required",
            "A required document is missing",
        )
        .detail(format!("{} is required.", missing.label())));
    }
    if req.subsidy && !kinds.contains(&KycKind::BankProof) {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "registration.bank_proof_required",
            "The subsidy needs bank proof",
        )
        .detail("Add the bank proof, or turn the subsidy off."));
    }
    if req.commission.is_some() && pay_type != Some(PayType::Commission) {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "registration.commission_not_allowed",
            "Only commission agents enter a commission",
        ));
    }

    Ok(Valid {
        name,
        phone,
        email,
        address,
        city,
        pin_code,
        state,
        discom,
        consumer_number,
        commission_note,
    })
}

/*
    Reading customers
*/

macro_rules! select_customer {
    ($rest:literal) => {
        concat!(
            "SELECT c.id, c.name, c.phone, coalesce(c.system_kw, 0) AS system_kw,
                    coalesce(c.city, c.address) AS place, c.kyc_status, c.created_at,
                    c.stage_index, c.rejected_note,
                    c.commission, c.commission_proposed, c.commission_status,
                    c.commission_admin_note, ca.name AS commission_admin_name,
                    c.commission_admin_at, c.commission_payable_since, c.commission_paid_on,
                    f.kind AS fix_kind, f.admin_note AS fix_note,
                    fa.name AS fix_by, f.admin_note_at AS fix_at,
                    (SELECT count(*) FROM documents d WHERE d.customer_id = c.id) AS doc_count,
                    (SELECT count(*) FROM documents d
                     WHERE d.customer_id = c.id AND d.status = 'verified') AS doc_verified
             FROM customers c
             LEFT JOIN users ca ON ca.id = c.commission_admin_by
             LEFT JOIN LATERAL (
                 SELECT kind, admin_note, admin_note_by, admin_note_at FROM documents
                 WHERE customer_id = c.id AND status = 'needs_fix'
                 ORDER BY admin_note_at DESC NULLS LAST LIMIT 1
             ) f ON true
             LEFT JOIN users fa ON fa.id = f.admin_note_by ",
            $rest
        )
    };
}

#[derive(sqlx::FromRow)]
struct Row {
    id: Uuid,
    name: String,
    phone: Option<String>,
    system_kw: f64,
    place: String,
    kyc_status: KycStatus,
    created_at: DateTime<Utc>,
    stage_index: Option<i32>,
    rejected_note: Option<String>,
    commission: Option<i64>,
    commission_proposed: Option<i64>,
    commission_status: Option<CommissionStatus>,
    commission_admin_note: Option<String>,
    commission_admin_name: Option<String>,
    commission_admin_at: Option<DateTime<Utc>>,
    commission_payable_since: Option<NaiveDate>,
    commission_paid_on: Option<NaiveDate>,
    fix_kind: Option<KycKind>,
    fix_note: Option<String>,
    fix_by: Option<String>,
    fix_at: Option<DateTime<Utc>>,
    doc_count: i64,
    doc_verified: i64,
}

impl Row {
    // The one line under a customer, by where they stand.
    fn detail(&self, now: DateTime<Utc>, stages: &Stages) -> String {
        match self.kyc_status {
            KycStatus::InReview => {
                let sent = self.created_at.with_timezone(&india::offset()).date_naive();
                if sent == now.with_timezone(&india::offset()).date_naive() {
                    "Sent today".into()
                } else {
                    format!("Sent {}", sent.format("%-d %b"))
                }
            }
            KycStatus::NeedsFix => match (self.fix_kind, &self.fix_note) {
                (Some(kind), Some(note)) => format!("{}: {note}", kind.label()),
                (Some(kind), None) => format!("{} to fix", kind.label()),
                _ => "A document to fix".into(),
            },
            KycStatus::Approved => self
                .stage_index
                .and_then(|i| stages.line(i))
                .unwrap_or_else(|| "Approved".into()),
            KycStatus::Rejected => self
                .rejected_note
                .clone()
                .unwrap_or_else(|| "The company won't go ahead with this customer.".into()),
        }
    }

    fn commission(&self) -> Option<Commission> {
        Some(Commission {
            amount: self.commission?,
            proposed_amount: self.commission_proposed,
            status: self.commission_status?,
            admin_note: match (
                &self.commission_admin_note,
                &self.commission_admin_name,
                self.commission_admin_at,
            ) {
                (Some(text), Some(by), Some(at)) => Some(TaskNote {
                    text: text.clone(),
                    by: Person::admin(by.clone()),
                    at,
                }),
                _ => None,
            },
            payable_since: self.commission_payable_since,
            paid_on: self.commission_paid_on,
        })
    }

    fn summary(&self, now: DateTime<Utc>, stages: &Stages) -> CustomerSummary {
        CustomerSummary {
            id: self.id,
            name: self.name.clone(),
            system_kw: self.system_kw,
            place: self.place.clone(),
            kyc_status: self.kyc_status,
            detail: self.detail(now, stages),
            sent_at: self.created_at,
            commission: self.commission(),
        }
    }

    fn into_detail(self, now: DateTime<Utc>, stages: &Stages) -> CustomerDetail {
        let stage = match (self.kyc_status, self.stage_index) {
            (KycStatus::Approved, Some(index)) => Some(CustomerStage {
                index,
                count: stages::COUNT,
                label: stages.name_at(index).to_owned(),
            }),
            _ => None,
        };
        let returned = match (self.fix_kind, &self.fix_note, &self.fix_by, self.fix_at) {
            (Some(kind), Some(text), Some(by), Some(at)) => Some(ReturnedDocument {
                kind,
                title: kind.label().into(),
                note: TaskNote {
                    text: text.clone(),
                    by: Person::admin(by.clone()),
                    at,
                },
            }),
            _ => None,
        };
        // Not taken up: nothing is being checked any more.
        let documents = (self.doc_count > 0 && self.kyc_status != KycStatus::Rejected).then(|| {
            let (status, detail) = if self.fix_kind.is_some() {
                (DocumentStatus::NeedsFix, "1 to fix".to_owned())
            } else if self.doc_verified == self.doc_count {
                (
                    DocumentStatus::Verified,
                    format!("All {} verified", self.doc_count),
                )
            } else {
                (
                    DocumentStatus::InReview,
                    format!("{} with the admin", self.doc_count - self.doc_verified),
                )
            };
            DocumentsSummary { status, detail }
        });
        CustomerDetail {
            summary: self.summary(now, stages),
            phone: self.phone.clone().unwrap_or_default(),
            stage,
            returned,
            documents,
        }
    }
}

// One of the agent's customers; 404 when it isn't theirs.
async fn load(
    conn: &mut PgConnection,
    agent_id: Uuid,
    customer_id: Uuid,
) -> ApiResult<CustomerDetail> {
    let row: Row = sqlx::query_as(select_customer!("WHERE c.id = $1 AND c.registered_by = $2"))
        .bind(customer_id)
        .bind(agent_id)
        .fetch_optional(&mut *conn)
        .await?
        .ok_or_else(ApiError::not_found)?;
    let stages = stages::load(conn).await?;
    Ok(row.into_detail(Utc::now(), &stages))
}

/*
    #39 Register a customer
    --------------------------------------------------------------------
    1. the fields, documents and commission (`check`)
    2. not already a customer here (same email, phone or consumer number)
    3. each document: an upload of this company, the agent's, in R2
    4. the customer record (SC-0001), its documents and commission
    5. the customer's account: made, or the existing one linked (an
       unverified one has no password: only the email's owner can set
       one, with an emailed code), and a `customer` membership
    6. after the commit, the email to the customer
    Safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/customer-registrations",
    operation_id = "submitCustomerRegistration",
    tag = "customers",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = CustomerRegistrationCreate,
    responses(
        (status = 201, description = "With the admin.", body = CustomerRegistration),
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
async fn submit_customer_registration(
    State(state): State<AppState>,
    agent: OrgMember<Agents>,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<CustomerRegistrationCreate>,
) -> ApiResult<Response> {
    let request = format!("POST /api/v1/orgs/{}/customer-registrations", agent.org_id);
    if let Some(done) = idempotency::replay(&state.db, agent.user_id, key, &request).await? {
        return Ok(done);
    }
    let v = check(&req, agent.pay_type)?;
    let mut tx = agent.begin(&state.db).await?;

    // 2. Already a customer here: who registered them, and when.
    let existing: Option<(String, Option<String>, DateTime<Utc>)> = sqlx::query_as(
        "SELECT c.reference, u.name, c.created_at FROM customers c
         LEFT JOIN users u ON u.id = c.registered_by
         WHERE c.email = $1 OR c.phone = $2 OR c.consumer_number = $3
         ORDER BY c.created_at LIMIT 1",
    )
    .bind(&v.email)
    .bind(&v.phone)
    .bind(&v.consumer_number)
    .fetch_optional(&mut *tx)
    .await?;
    if let Some((reference, by, at)) = existing {
        let by = by.unwrap_or_else(|| "The company".into());
        let on = at.with_timezone(&india::offset()).format("%-d %b %Y");
        return Err(duplicate(format!(
            "{by} registered this customer on {on} ({reference})."
        )));
    }

    // 3. The documents' files.
    for f in req.documents.iter().flat_map(|d| &d.files) {
        uploads::attach(
            &mut tx,
            state.storage.as_ref(),
            agent.org_id,
            agent.user_id,
            f.upload_id,
            UploadPurpose::Kyc,
            "documents",
        )
        .await?;
    }

    // 5 (first: the record points at it). The account.
    let created: Option<Uuid> = sqlx::query_scalar(
        "INSERT INTO users (id, email, name, phone) VALUES ($1, $2, $3, $4)
         ON CONFLICT (email) DO NOTHING RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(&v.email)
    .bind(&v.name)
    .bind(&v.phone)
    .fetch_optional(&mut *tx)
    .await?;
    let (user_id, set_up) = match created {
        Some(id) => (id, true),
        None => {
            // Unverified accounts have no password (the database's CHECK).
            let (id, verified): (Uuid, bool) = sqlx::query_as(
                "SELECT id, email_verified_at IS NOT NULL FROM users WHERE email = $1",
            )
            .bind(&v.email)
            .fetch_one(&mut *tx)
            .await?;
            (id, !verified)
        }
    };
    let joined: Option<Uuid> = sqlx::query_scalar(
        "INSERT INTO memberships (id, user_id, org_id, role)
         VALUES ($1, $2, $3, 'customer')
         ON CONFLICT (user_id, org_id) DO UPDATE
            SET role = 'customer', pay_type = NULL, created_at = now(), removed_at = NULL
          WHERE memberships.removed_at IS NOT NULL
         RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(agent.org_id)
    .fetch_optional(&mut *tx)
    .await?;
    if joined.is_none() {
        let role: Role =
            sqlx::query_scalar("SELECT role FROM memberships WHERE user_id = $1 AND org_id = $2")
                .bind(user_id)
                .bind(agent.org_id)
                .fetch_one(&mut *tx)
                .await?;
        return Err(duplicate(format!(
            "This email already belongs to someone in your company ({}).",
            match role {
                Role::OrgAdmin => "an admin",
                Role::Worker => "an EPC installer",
                Role::Agent => "a sales agent",
                Role::Customer => "a customer",
            }
        )));
    }

    // 4. The customer, documents and commission.
    let id = Uuid::now_v7();
    let reference = counter::next(&mut tx, agent.org_id, "SC").await?;
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, address, system_kw,
                                registered_by, user_id, email, city, pin_code, state, discom,
                                consumer_number, sanctioned_load_kw, connection_type, roof,
                                subsidy, consent_at, kyc_status,
                                commission, commission_note, commission_status, lat, lng)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17,
                 $18, $19, now(), 'in_review', $20, $21,
                 CASE WHEN $20::bigint IS NULL THEN NULL ELSE 'in_review'::commission_status END,
                 $22, $23)",
    )
    .bind(id)
    .bind(agent.org_id)
    .bind(&reference)
    .bind(&v.name)
    .bind(&v.phone)
    .bind(&v.address)
    .bind(req.proposed_kw)
    .bind(agent.user_id)
    .bind(user_id)
    .bind(&v.email)
    .bind(&v.city)
    .bind(&v.pin_code)
    .bind(&v.state)
    .bind(&v.discom)
    .bind(&v.consumer_number)
    .bind(req.sanctioned_load_kw)
    .bind(req.connection_type)
    .bind(req.roof)
    .bind(req.subsidy)
    .bind(req.commission)
    .bind(&v.commission_note)
    .bind(req.lat)
    .bind(req.lng)
    .execute(&mut *tx)
    .await
    .map_err(|e| {
        // Another registration of the same customer got in first.
        if unique_violation(&e) {
            duplicate("Someone registered this customer a moment ago.".into())
        } else {
            e.into()
        }
    })?;
    for d in &req.documents {
        let document_id = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO documents (id, org_id, customer_id, kind, uploaded_by)
             VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(document_id)
        .bind(agent.org_id)
        .bind(id)
        .bind(d.kind)
        .bind(agent.user_id)
        .execute(&mut *tx)
        .await?;
        add_files(&mut tx, agent.org_id, document_id, &d.files).await?;
    }

    let (org_name, agent_name): (String, String) =
        sqlx::query_as("SELECT o.name, u.name FROM orgs o, users u WHERE o.id = $1 AND u.id = $2")
            .bind(agent.org_id)
            .bind(agent.user_id)
            .fetch_one(&mut *tx)
            .await?;

    notify::add_for_admins(
        &mut tx,
        agent.org_id,
        notify::Kind::KycSubmitted,
        "KYC to check",
        &format!("{} · from {agent_name}", v.name),
        notify::Links {
            customer_id: Some(id),
            ..Default::default()
        },
    )
    .await?;
    let body = serde_json::to_value(CustomerRegistration {
        id,
        reference: reference.clone(),
        status: RegistrationStatus::Submitted,
    })
    .map_err(|_| ApiError::internal())?;
    if !idempotency::save(
        &mut tx,
        agent.user_id,
        key,
        &request,
        StatusCode::CREATED,
        &body,
    )
    .await?
    {
        drop(tx);
        return idempotency::replay(&state.db, agent.user_id, key, &request)
            .await?
            .ok_or_else(ApiError::internal);
    }
    tx.commit().await?;

    tracing::info!(org_id = %agent.org_id, customer_id = %id, %reference, "customer registered");
    state.mailer.send(welcome_email(&Welcome {
        to: &v.email,
        name: &v.name,
        org_name: &org_name,
        agent_name: &agent_name,
        kw: req.proposed_kw,
        address: &format!("{}, {}", v.address, v.city),
        set_up,
    }));
    Ok((StatusCode::CREATED, Json(body)).into_response())
}

/*
    #40 The agent's customers, newest first: all of them (the app sums
    Earnings from this list)
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/my-customers",
    operation_id = "listMyCustomers",
    tag = "customers",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The customers.", body = CustomerList),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_my_customers(
    State(state): State<AppState>,
    agent: OrgMember<Agents>,
) -> ApiResult<Json<CustomerList>> {
    let mut tx = agent.begin(&state.db).await?;
    let rows: Vec<Row> = sqlx::query_as(select_customer!(
        "WHERE c.registered_by = $1 ORDER BY c.created_at DESC, c.id DESC"
    ))
    .bind(agent.user_id)
    .fetch_all(&mut *tx)
    .await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;
    let now = Utc::now();
    Ok(Json(CustomerList {
        items: rows.iter().map(|r| r.summary(now, &stages)).collect(),
    }))
}

/*
    #41 One of the agent's customers
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/my-customers/{customer_id}",
    operation_id = "getMyCustomer",
    tag = "customers",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
    ),
    responses(
        (status = 200, description = "The customer.", body = CustomerDetail),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 404, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn get_my_customer(
    State(state): State<AppState>,
    agent: OrgMember<Agents>,
    ApiPath(path): ApiPath<CustomerPath>,
) -> ApiResult<Json<CustomerDetail>> {
    let mut tx = agent.begin(&state.db).await?;
    let customer = load(&mut tx, agent.user_id, path.customer_id).await?;
    tx.commit().await?;
    Ok(Json(customer))
}

/*
    #42 A new copy of the document the admin sent back
    --------------------------------------------------------------------
    - only that one (409 `registration.locked` otherwise); its 1 to 5
      files are uploads of this company, checked in R2, and replace the
      whole set
    - the document goes back to `in_review`, and the customer too once
      nothing else is waiting for a fix. The earlier files stay in R2,
      linked as replaced
*/
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/my-customers/{customer_id}/documents/{kind}",
    operation_id = "replaceCustomerDocument",
    tag = "customers",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("customer_id" = Uuid, Path, description = "The customer."),
        ("kind" = KycKind, Path, description = "The document sent back."),
    ),
    request_body = DocumentReplace,
    responses(
        (status = 200, description = "With the admin again.", body = CustomerDetail),
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
async fn replace_customer_document(
    State(state): State<AppState>,
    agent: OrgMember<Agents>,
    ApiPath(path): ApiPath<DocumentPath>,
    ApiJson(req): ApiJson<DocumentReplace>,
) -> ApiResult<Json<CustomerDetail>> {
    let mut tx = agent.begin(&state.db).await?;
    let mine: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM customers WHERE id = $1 AND registered_by = $2)",
    )
    .bind(path.customer_id)
    .bind(agent.user_id)
    .fetch_one(&mut *tx)
    .await?;
    if !mine {
        return Err(ApiError::not_found());
    }
    let document: Option<(Uuid, DocumentStatus)> = sqlx::query_as(
        "SELECT id, status FROM documents WHERE customer_id = $1 AND kind = $2 FOR UPDATE",
    )
    .bind(path.customer_id)
    .bind(path.kind)
    .fetch_optional(&mut *tx)
    .await?;
    let Some((document_id, DocumentStatus::NeedsFix)) = document else {
        return Err(locked());
    };
    check_files("files", &req.files)?;
    for f in &req.files {
        uploads::attach(
            &mut tx,
            state.storage.as_ref(),
            agent.org_id,
            agent.user_id,
            f.upload_id,
            UploadPurpose::Kyc,
            "files",
        )
        .await?;
    }
    sqlx::query(
        "UPDATE document_files SET replaced_at = now()
         WHERE org_id = $1 AND document_id = $2 AND replaced_at IS NULL",
    )
    .bind(agent.org_id)
    .bind(document_id)
    .execute(&mut *tx)
    .await?;
    add_files(&mut tx, agent.org_id, document_id, &req.files).await?;
    sqlx::query(
        "UPDATE documents SET status = 'in_review', uploaded_by = $2, updated_at = now()
         WHERE id = $1",
    )
    .bind(document_id)
    .bind(agent.user_id)
    .execute(&mut *tx)
    .await?;
    let fixed = sqlx::query(
        "UPDATE customers SET kyc_status = 'in_review'
         WHERE id = $1 AND kyc_status = 'needs_fix'
           AND NOT EXISTS (SELECT 1 FROM documents
                           WHERE customer_id = $1 AND status = 'needs_fix')",
    )
    .bind(path.customer_id)
    .execute(&mut *tx)
    .await?
    .rows_affected()
        > 0;
    if fixed {
        // The last document sent back is in: it's the admin's again.
        let name: String = sqlx::query_scalar("SELECT name FROM customers WHERE id = $1")
            .bind(path.customer_id)
            .fetch_one(&mut *tx)
            .await?;
        notify::add_for_admins(
            &mut tx,
            agent.org_id,
            notify::Kind::KycSubmitted,
            "KYC fixed",
            &name,
            notify::Links {
                customer_id: Some(path.customer_id),
                ..Default::default()
            },
        )
        .await?;
    }
    let customer = load(&mut tx, agent.user_id, path.customer_id).await?;
    tx.commit().await?;
    Ok(Json(customer))
}

#[derive(sqlx::FromRow)]
struct DocRow {
    kind: KycKind,
    status: DocumentStatus,
    admin_note: Option<String>,
    updated_at: DateTime<Utc>,
}

/*
    #38 The caller's documents this company holds
    --------------------------------------------------------------------
    - a customer: their KYC, with the agent who collected it
    - a worker: their own ID documents (the admin website adds them;
      none until then)
    - `detail`: the admin's note while one needs a fix, else when it was
      sent
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/me/documents",
    operation_id = "listMyDocuments",
    tag = "profile",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The documents.", body = MyDocumentList),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn list_my_documents(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndCustomers>,
) -> ApiResult<Json<MyDocumentList>> {
    let mut tx = member.begin(&state.db).await?;
    let (rows, uploaded_by): (Vec<DocRow>, Option<String>) = match member.role {
        Role::Customer => {
            let customer: Option<(Uuid, Option<String>)> = sqlx::query_as(
                "SELECT c.id, u.name FROM customers c LEFT JOIN users u ON u.id = c.registered_by
                 WHERE c.user_id = $1 ORDER BY c.created_at DESC LIMIT 1",
            )
            .bind(member.user_id)
            .fetch_optional(&mut *tx)
            .await?;
            match customer {
                Some((customer_id, agent)) => (
                    sqlx::query_as(
                        "SELECT kind, status, admin_note, updated_at FROM documents
                         WHERE customer_id = $1 ORDER BY kind",
                    )
                    .bind(customer_id)
                    .fetch_all(&mut *tx)
                    .await?,
                    agent,
                ),
                None => (Vec::new(), None),
            }
        }
        _ => (
            sqlx::query_as(
                "SELECT kind, status, admin_note, updated_at FROM documents
                 WHERE user_id = $1 ORDER BY kind",
            )
            .bind(member.user_id)
            .fetch_all(&mut *tx)
            .await?,
            None,
        ),
    };
    tx.commit().await?;

    let items = rows
        .into_iter()
        .map(|d| MyDocument {
            kind: d.kind,
            detail: Some(match (d.status, d.admin_note) {
                (DocumentStatus::NeedsFix, Some(note)) => note,
                _ => format!(
                    "Sent {}",
                    d.updated_at
                        .with_timezone(&india::offset())
                        .format("%-d %b %Y")
                ),
            }),
            status: d.status,
        })
        .collect();
    Ok(Json(MyDocumentList { items, uploaded_by }))
}

/*
    The customer's email
*/

struct Welcome<'a> {
    to: &'a str,
    name: &'a str,
    org_name: &'a str,
    agent_name: &'a str,
    kw: f64,
    address: &'a str,
    // No password yet (new, or an unverified account): the setup steps.
    set_up: bool,
}

/*
    Who registered them, what was registered, and how to set up the app
    to follow the install. Sent at once, before the admin verifies:
    the customer hears it from the company, not first from a stranger
*/
fn welcome_email(w: &Welcome) -> Email {
    let first = w.name.split_whitespace().next().unwrap_or(w.name);
    let kw = format!("{} kW", trim_kw(w.kw));
    let intro = format!(
        "Hi {first}, {} from {} registered you for a solar installation on {PRODUCT_NAME}.",
        w.agent_name, w.org_name
    );
    let what = format!("{kw} rooftop system at {}.", w.address);
    let next = format!(
        "{} checks your documents next; you'll see each stage of your install in the app.",
        w.org_name
    );
    let note = format!(
        "You're receiving this email because {} registered this address for an \
         installation. If you didn't ask for one, ignore this email or call them.",
        w.org_name
    );
    let consent = format!(
        "{} told us you agreed to share your details and documents with {}. The company \
         keeps them to install your system and claim the subsidy. How {PRODUCT_NAME} handles \
         them: {PRIVACY_URL}. If you didn't agree, tell the company or write to \
         info@markcliq.com.",
        w.agent_name, w.org_name
    );
    let open = "Install it from the link your installer shares, if it isn't on your phone.";
    let forgot = format!("Enter this email address: {}", w.to);
    let set = "Enter the 6-digit code we email you, and choose a password.";
    let (steps_text, steps_html) = if w.set_up {
        (
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
        let line = format!("Log in as usual: {} is in your workspaces now.", w.org_name);
        (line.clone(), t::para(&line))
    };
    Email {
        to: w.to.to_owned(),
        subject: format!("{} registered you for solar on {PRODUCT_NAME}", w.org_name),
        body: format!(
            "{intro}\n\n{what}\n{next}\n\n{consent}\n\n{steps_text}\n\n{}\n\n{note}\n",
            t::sign_off_text()
        ),
        html: Some(t::page(EmailPage {
            preheader: Some(&format!(
                "{kw} at {}. Follow your install in the app.",
                w.address
            )),
            sun_dot: false,
            badge: Some(Badge {
                glyph: "&#9728;",
                tone: Tone::Sun,
            }),
            heading: &format!("Your solar with {}", w.org_name),
            card: [
                t::para(&intro),
                t::details(&[
                    ("System", kw.clone()),
                    ("Site", w.address.to_owned()),
                    ("Registered by", w.agent_name.to_owned()),
                ]),
                t::para(&next),
                t::para(&consent),
                steps_html,
                t::sign_off(),
            ]
            .concat(),
            note: Some(&note),
        })),
    }
}

// 5 → "5", 3.5 → "3.5".
fn trim_kw(kw: f64) -> String {
    let s = format!("{kw:.2}");
    s.trim_end_matches('0').trim_end_matches('.').to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kw_reads_plainly() {
        assert_eq!(trim_kw(5.0), "5");
        assert_eq!(trim_kw(3.5), "3.5");
        assert_eq!(trim_kw(4.25), "4.25");
    }

    #[test]
    fn the_email_explains_setup_to_a_new_customer() {
        let w = Welcome {
            to: "rajinder@example.com",
            name: "Rajinder Kaur",
            org_name: "Example Solar",
            agent_name: "Meena",
            kw: 5.0,
            address: "Sector 70, Mohali",
            set_up: true,
        };
        let e = welcome_email(&w);
        assert!(e.body.starts_with("Hi Rajinder, Meena from Example Solar"));
        assert!(e.body.contains("5 kW rooftop system at Sector 70, Mohali"));
        assert!(e.body.contains("Forgot password?"));
        let e = welcome_email(&Welcome { set_up: false, ..w });
        assert!(!e.body.contains("Forgot password?"));
    }
}
