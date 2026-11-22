/*
    Uploading a file (phase 7, #22)
    --------------------------------------------------------------------
    - POST /orgs/{org_id}/uploads: the server records the upload and
      signs a 15-minute URL; the app or website PUTs the file straight to
      R2 with it
    - then the record it's for (a task photo, a receipt, a KYC document)
      sends `upload_id`, and the file is attached there
    - a file belongs to the company in the path: it's named
      `orgs/<org_id>/<purpose>/<id>`, its row is company-scoped, and only
      that company's records can take it
    - jpeg, png or pdf, up to 10 MB (a KYC document 50 MB); the type and
      size are signed into the URL, so R2 refuses anything else
      (`storage.rs`)
    - each kind of file is for the roles that use it (`may_upload`):
      a customer can't ask for a KYC slot just to fill storage
    - `attach`: how a record takes an upload. It checks with R2 that the
      file arrived, whole, before the record points at it
    - `sweep`: uploads nothing attached within a day are deleted, file
      and row
*/

use axum::{Json, extract::State, http::StatusCode};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{PgConnection, PgPool};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::ApiJson,
    org::{OrgMember, Role, role_not_allowed},
    rate_limit::Rule,
    scope,
    storage::{self, Storage},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(create_upload))
}

/*
    Who may upload what
    --------------------------------------------------------------------
    - proof photos (and a problem's photo): installers
    - receipts: whoever logs expenses, installers and agents
    - KYC documents: agents, who register customers and fix them
    - the company's admin: any (the website, for staff ID documents);
      the company's logo is theirs alone
    - customers: none yet
*/
fn may_upload(role: Role, purpose: UploadPurpose) -> bool {
    match purpose {
        UploadPurpose::Proof => matches!(role, Role::Worker | Role::OrgAdmin),
        UploadPurpose::Receipt => matches!(role, Role::Worker | Role::Agent | Role::OrgAdmin),
        UploadPurpose::Kyc => matches!(role, Role::Agent | Role::OrgAdmin),
        UploadPurpose::Logo => role == Role::OrgAdmin,
    }
}

const MB: i64 = 1024 * 1024;

// Up to 10 MB: a phone photo, a receipt.
const MAX_MB: i64 = 10;

// A KYC document can be a long scan (owner, 2026-11-22).
const MAX_KYC_MB: i64 = 50;

// A logo is shown small and fetched by every member: up to 1 MB.
const MAX_LOGO_BYTES: i64 = MB;

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
    // The company's logo (F15): PNG or JPEG, up to 1 MB.
    Logo,
}

impl UploadPurpose {
    pub fn as_str(self) -> &'static str {
        match self {
            UploadPurpose::Receipt => "receipt",
            UploadPurpose::Kyc => "kyc",
            UploadPurpose::Proof => "proof",
            UploadPurpose::Logo => "logo",
        }
    }
}

// The contract's `UploadCreate`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct UploadCreate {
    pub content_type: ContentType,
    // The file's exact size in bytes: 1 to 10 MB, or 50 MB for `kyc`.
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
    path = "/orgs/{org_id}/uploads",
    operation_id = "createUpload",
    tag = "uploads",
    params(("org_id" = Uuid, Path, description = "The company the file is for.")),
    request_body = UploadCreate,
    responses(
        (status = 201, description = "Ready for the file.", body = Upload),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
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
    member: OrgMember,
    ApiJson(req): ApiJson<UploadCreate>,
) -> ApiResult<(StatusCode, Json<Upload>)> {
    let max_mb = match req.purpose {
        UploadPurpose::Kyc => MAX_KYC_MB,
        _ => MAX_MB,
    };
    if !(1..=max_mb * MB).contains(&req.size_bytes) {
        return Err(
            ApiError::validation(Vec::new()).field("size_bytes", format!("Up to {max_mb} MB."))
        );
    }
    if !may_upload(member.role, req.purpose) {
        return Err(role_not_allowed());
    }
    if req.purpose == UploadPurpose::Logo {
        if matches!(req.content_type, ContentType::Pdf) {
            return Err(ApiError::validation(Vec::new())
                .field("content_type", "A logo is a PNG or JPEG image."));
        }
        if req.size_bytes > MAX_LOGO_BYTES {
            return Err(
                ApiError::validation(Vec::new()).field("size_bytes", "A logo is up to 1 MB.")
            );
        }
    }
    let Some(storage) = &state.storage else {
        return Err(unavailable());
    };
    state
        .limits
        .check(Rule::UploadByUser, &member.user_id.to_string())?;

    let id = Uuid::now_v7();
    let key = storage::file_key(member.org_id, req.purpose.as_str(), id);
    let put = storage
        .put_url(
            member.org_id,
            &key,
            req.content_type.as_str(),
            req.size_bytes,
            Utc::now(),
        )
        .map_err(refused)?;

    let mut tx = member.begin(&state.db).await?;
    sqlx::query(
        "INSERT INTO uploads (id, org_id, owner_id, purpose, content_type, size_bytes, r2_key)
         VALUES ($1, $2, $3, $4, $5, $6, $7)",
    )
    .bind(id)
    .bind(member.org_id)
    .bind(member.user_id)
    .bind(req.purpose)
    .bind(req.content_type.as_str())
    .bind(req.size_bytes)
    .bind(&key)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;

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

// The signing guard refused: a bug, never the caller's doing.
fn refused(e: storage::StorageError) -> ApiError {
    tracing::error!(error = %e, "signing a file URL");
    ApiError::internal()
}

/*
    A 15-minute link to read one of `org_id`'s files, for a record being
    shown. Empty when uploads aren't set up (development without R2)
*/
pub fn read_url(storage: Option<&Storage>, org_id: Uuid, key: &str) -> ApiResult<String> {
    match storage {
        Some(s) => s.get_url(org_id, key, Utc::now()).map_err(refused),
        None => Ok(String::new()),
    }
}

fn unavailable() -> ApiError {
    ApiError::new(
        StatusCode::SERVICE_UNAVAILABLE,
        "upload.unavailable",
        "Uploads aren't set up on this server",
    )
}

/*
    Attach an upload to a record
    --------------------------------------------------------------------
    - inside the record's company transaction: the upload must be this
      company's (`org_id`, and row-level security too), the caller's,
      for this purpose, and not used yet, else 422 on `field`
    - then R2 is asked whether the file is there and its size matches
      what was signed. An upload that never finished (bad network, app
      closed) is 422 too, so a record never points at a missing file
    - marks it used, so one file belongs to one record
    - returns the file's key in the bucket
*/
pub async fn attach(
    conn: &mut PgConnection,
    storage: Option<&Storage>,
    org_id: Uuid,
    user_id: Uuid,
    upload_id: Uuid,
    purpose: UploadPurpose,
    field: &str,
) -> ApiResult<String> {
    let storage = storage.ok_or_else(unavailable)?;
    let row: Option<(String, i64)> = sqlx::query_as(
        "SELECT r2_key, size_bytes FROM uploads
         WHERE id = $1 AND org_id = $2 AND owner_id = $3 AND purpose = $4
           AND used_at IS NULL
         FOR UPDATE",
    )
    .bind(upload_id)
    .bind(org_id)
    .bind(user_id)
    .bind(purpose)
    .fetch_optional(&mut *conn)
    .await?;
    let Some((key, size)) = row else {
        return Err(ApiError::validation(Vec::new()).field(field, "Upload the file again."));
    };

    let stored = storage.size(&key).await.map_err(|e| {
        tracing::error!(error = %e, "checking an upload in R2");
        unavailable()
    })?;
    if stored != Some(size) {
        return Err(ApiError::validation(Vec::new())
            .field(field, "The file didn't finish uploading. Try again."));
    }

    sqlx::query("UPDATE uploads SET used_at = now() WHERE id = $1")
        .bind(upload_id)
        .execute(&mut *conn)
        .await?;
    Ok(key)
}

// An upload unused this long is abandoned (the app took it, then gave up).
const ABANDONED_AFTER: chrono::Duration = chrono::Duration::hours(24);

/*
    Delete abandoned uploads
    --------------------------------------------------------------------
    - files nothing attached within a day: the R2 file first, then the
      row, so a failure leaves the row to try again on the next sweep
    - every company's: it runs in the platform scope, which may read and
      delete uploads but not write them
    - a batch at a time; returns how many went. The server runs it every
      hour (main.rs)
*/
pub async fn sweep(db: &PgPool, storage: &Storage) -> ApiResult<usize> {
    let mut tx = scope::platform(db).await?;
    let stale: Vec<(Uuid, String)> = sqlx::query_as(
        "SELECT id, r2_key FROM uploads
         WHERE used_at IS NULL AND created_at < $1
         ORDER BY created_at LIMIT 500",
    )
    .bind(Utc::now() - ABANDONED_AFTER)
    .fetch_all(&mut *tx)
    .await?;
    tx.commit().await?;

    let mut deleted = 0;
    for (id, key) in stale {
        if let Err(e) = storage.delete(&key).await {
            tracing::warn!(error = %e, %key, "deleting an abandoned upload");
            continue;
        }
        let mut tx = scope::platform(db).await?;
        sqlx::query("DELETE FROM uploads WHERE id = $1 AND used_at IS NULL")
            .bind(id)
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;
        deleted += 1;
    }
    Ok(deleted)
}
