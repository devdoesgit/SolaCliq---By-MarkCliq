/*
    The company's settings (W4)
    --------------------------------------------------------------------
    - the UPI id its customers pay to. Without one the app shows no
      "Pay by UPI" button
    - the company's stage names come along (F19), so the website keeps
      no copy of them
*/

use axum::{Json, extract::State};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use super::ERRORS;
use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::ApiJson,
    org::{Admins, OrgMember},
    stages, validate,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(get_settings, set_settings))
}

// The contract's `AdminSettings`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminSettings {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub upi_id: Option<String>,
    // The company's stage names (F19).
    pub stages: Vec<String>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct AdminSettingsSet {
    // Empty or null removes it.
    pub upi_id: Option<String>,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/admin/settings",
    operation_id = "adminGetSettings",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The settings.", body = AdminSettings),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn get_settings(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
) -> ApiResult<Json<AdminSettings>> {
    let mut tx = admin.begin(&state.db).await?;
    let upi: Option<String> = sqlx::query_scalar("SELECT upi_id FROM orgs WHERE id = $1")
        .bind(admin.org_id)
        .fetch_one(&mut *tx)
        .await?;
    let stages = stages::load(&mut tx).await?.names();
    tx.commit().await?;
    Ok(Json(AdminSettings {
        upi_id: upi,
        stages,
    }))
}

#[utoipa::path(
    put,
    path = "/orgs/{org_id}/admin/settings",
    operation_id = "adminSetSettings",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company.")),
    request_body = AdminSettingsSet,
    responses(
        (status = 200, description = "Saved.", body = AdminSettings),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn set_settings(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiJson(req): ApiJson<AdminSettingsSet>,
) -> ApiResult<Json<AdminSettings>> {
    let upi = req
        .upi_id
        .as_deref()
        .map(str::trim)
        .filter(|v| !v.is_empty());
    if upi.is_some_and(|v| !validate::is_upi_id(v)) {
        return Err(
            ApiError::validation(Vec::new()).field("upi_id", "Enter a UPI id like name@bank.")
        );
    }
    let mut tx = admin.begin(&state.db).await?;
    sqlx::query("UPDATE orgs SET upi_id = $2, updated_at = now() WHERE id = $1")
        .bind(admin.org_id)
        .bind(upi)
        .execute(&mut *tx)
        .await?;
    let stages = stages::load(&mut tx).await?.names();
    tx.commit().await?;
    // Money goes to this id: who changed it is worth a line.
    tracing::info!(org_id = %admin.org_id, by = %admin.user_id, set = upi.is_some(), "UPI id changed");
    Ok(Json(AdminSettings {
        upi_id: upi.map(str::to_owned),
        stages,
    }))
}
