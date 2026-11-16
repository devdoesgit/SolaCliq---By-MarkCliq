/*
    Uploading a file (phase 7, #22)
    --------------------------------------------------------------------
    - POST /uploads: the server records the upload and signs a 15-minute
      URL; the app or website PUTs the file straight to R2 with it
    - then the record it's for (a task photo, a receipt, a KYC document)
      sends `upload_id`, and the file is attached there
    - jpeg, png or pdf, up to 10 MB; the type and size are signed into
      the URL, so R2 refuses anything else (`storage.rs`)
*/

use axum::{Json, extract::State, http::StatusCode};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, AuthUser},
    rate_limit::Rule,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(create_upload))
}

// Up to 10 MB: a phone photo, a scanned document.
const MAX_BYTES: i64 = 10 * 1024 * 1024;

// The file types the app and website send.
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
pub enum ContentType {
    #[serde(rename = "image/jpeg")]
    Jpeg,
    #[serde(rename = "image/png")]
    Png,
    #[serde(rename = "application/pdf")]
    Pdf,
}

impl ContentType {
    fn as_str(self) -> &'static str {
        match self {
            ContentType::Jpeg => "image/jpeg",
            ContentType::Png => "image/png",
            ContentType::Pdf => "application/pdf",
        }
    }
}

// What the file is for; the record that uses it checks it matches.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "upload_purpose", rename_all = "snake_case")]
pub enum UploadPurpose {
    Receipt,
    Kyc,
    // A task's photo from the live camera.
    Proof,
}

impl UploadPurpose {
    fn as_str(self) -> &'static str {
        match self {
            UploadPurpose::Receipt => "receipt",
            UploadPurpose::Kyc => "kyc",
            UploadPurpose::Proof => "proof",
        }
    }
}

// The contract's `UploadCreate`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct UploadCreate {
    pub content_type: ContentType,
    // The file's exact size in bytes, 1 to 10485760.
    pub size_bytes: i64,
    pub purpose: UploadPurpose,
}

// The contract's `Upload`: PUT the file to `url` with `headers`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Upload {
    pub upload_id: Uuid,
    pub url: String,
    // Always PUT.
    pub method: &'static str,
    pub headers: std::collections::BTreeMap<&'static str, String>,
    pub expires_at: DateTime<Utc>,
}

#[utoipa::path(
    post,
    path = "/uploads",
    operation_id = "createUpload",
    tag = "uploads",
    request_body = UploadCreate,
    responses(
        (status = 201, description = "Ready for the file.", body = Upload),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 503, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn create_upload(
    State(state): State<AppState>,
    user: AuthUser,
    ApiJson(req): ApiJson<UploadCreate>,
) -> ApiResult<(StatusCode, Json<Upload>)> {
    if !(1..=MAX_BYTES).contains(&req.size_bytes) {
        return Err(ApiError::validation(Vec::new()).field("size_bytes", "Up to 10 MB."));
    }
    let Some(storage) = &state.storage else {
        return Err(ApiError::new(
            StatusCode::SERVICE_UNAVAILABLE,
            "upload.unavailable",
            "Uploads aren't set up on this server",
        ));
    };
    state
        .limits
        .check(Rule::UploadByUser, &user.user_id.to_string())?;

    let id = Uuid::now_v7();
    let key = format!("{}/{id}", req.purpose.as_str());
    sqlx::query(
        "INSERT INTO uploads (id, owner_id, purpose, content_type, size_bytes, r2_key)
         VALUES ($1, $2, $3, $4, $5, $6)",
    )
    .bind(id)
    .bind(user.user_id)
    .bind(req.purpose)
    .bind(req.content_type.as_str())
    .bind(req.size_bytes)
    .bind(&key)
    .execute(&state.db)
    .await?;

    let put = storage.put_url(&key, req.content_type.as_str(), req.size_bytes, Utc::now());
    Ok((
        StatusCode::CREATED,
        Json(Upload {
            upload_id: id,
            url: put.url,
            method: "PUT",
            headers: put.headers.into_iter().collect(),
            expires_at: put.expires_at,
        }),
    ))
}
