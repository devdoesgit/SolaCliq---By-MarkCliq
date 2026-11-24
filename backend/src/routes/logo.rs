/*
    The company's logo (F15)
    --------------------------------------------------------------------
    - PUT /orgs/{org_id}/logo: the company's admin sets the logo from an
      upload of purpose `logo` (PNG or JPEG, up to 1 MB). Checked in R2
      before it's taken (`uploads::attach`)
    - DELETE /orgs/{org_id}/logo: back to the initials
    - the logo it replaces is deleted, row and file: a company has one
      logo, and nothing else points at the old one
    - members read it through `/me` (`OrgSummary.logo_url`), a signed
      link like every file: the bucket stays private
    - spec: docs/features/F15-company-logo.md
*/

use axum::{extract::State, http::StatusCode};
use serde::Deserialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::ApiResult,
    extract::ApiJson,
    org::{Admins, OrgMember},
    routes::uploads::{self, UploadPurpose},
    scope::Tx,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(set_logo, remove_logo))
}

// The contract's `LogoSet`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct LogoSet {
    // An upload of purpose `logo` by this admin, not used yet.
    pub upload_id: Uuid,
}

/// Set the company's logo
///
/// The company's admin only. Replaces the current logo, if any.
#[utoipa::path(
    put,
    path = "/orgs/{org_id}/logo",
    operation_id = "setOrgLogo",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    request_body = LogoSet,
    responses(
        (status = 204, description = "The logo is set."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 503, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn set_logo(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiJson(req): ApiJson<LogoSet>,
) -> ApiResult<StatusCode> {
    let mut tx = admin.begin(&state.db).await?;
    let key = uploads::attach(
        &mut tx,
        state.storage.as_ref(),
        admin.org_id,
        admin.user_id,
        req.upload_id,
        UploadPurpose::Logo,
        "upload_id",
    )
    .await?;
    let old = replace(&mut tx, admin.org_id, Some(&key)).await?;
    tx.commit().await?;
    delete_file(&state, old).await;
    Ok(StatusCode::NO_CONTENT)
}

/// Remove the company's logo
///
/// The company's admin only. The app shows the company's initials again.
#[utoipa::path(
    delete,
    path = "/orgs/{org_id}/logo",
    operation_id = "removeOrgLogo",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 204, description = "No logo now."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn remove_logo(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<StatusCode> {
    let mut tx = admin.begin(&state.db).await?;
    let old = replace(&mut tx, admin.org_id, None).await?;
    tx.commit().await?;
    delete_file(&state, old).await;
    Ok(StatusCode::NO_CONTENT)
}

/*
    Points the company at `key` (or none), and drops the old logo's
    upload row in the same transaction. Returns the old file's key, to
    delete from R2 once this has committed
*/
async fn replace(tx: &mut Tx, org_id: Uuid, key: Option<&str>) -> ApiResult<Option<String>> {
    let old: Option<String> =
        sqlx::query_scalar("SELECT logo_key FROM orgs WHERE id = $1 FOR UPDATE")
            .bind(org_id)
            .fetch_one(&mut **tx)
            .await?;
    sqlx::query("UPDATE orgs SET logo_key = $2, updated_at = now() WHERE id = $1")
        .bind(org_id)
        .bind(key)
        .execute(&mut **tx)
        .await?;
    if let Some(old) = &old {
        sqlx::query("DELETE FROM uploads WHERE org_id = $1 AND r2_key = $2")
            .bind(org_id)
            .bind(old)
            .execute(&mut **tx)
            .await?;
    }
    Ok(old)
}

/*
    Best effort: the change is already saved, so a failure here only
    leaves an unused file in the company's folder; it's logged
*/
async fn delete_file(state: &AppState, key: Option<String>) {
    if let (Some(storage), Some(key)) = (&state.storage, key)
        && let Err(e) = storage.delete(&key).await
    {
        tracing::warn!(error = %e, %key, "deleting a replaced logo");
    }
}
