/*
    The phone's push token (F12)
    --------------------------------------------------------------------
    - PUT /me/device: saves the Firebase token for the caller's session
      (one login on one phone), for the push worker (`push.rs`)
    - replaces this session's earlier token, and takes the token from
      any other session that had it: pushes go to whoever logged in on
      that phone last
    - app sessions only: the website gets 403 `auth.app_only`
    - no unregister call: a revoked session (log out, password reset)
      gets no pushes
*/

use axum::{extract::State, http::StatusCode};
use serde::Deserialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, AuthUser},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(register_device))
}

#[derive(Debug, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum Platform {
    // iOS joins later, with an APNs key.
    Android,
}

#[derive(Debug, Deserialize, ToSchema)]
#[schema(example = json!({"token": "fGx1…(illustrative)", "platform": "android"}))]
pub struct DeviceRegistration {
    // The FCM registration token.
    #[schema(min_length = 1, max_length = 4096)]
    pub token: String,
    pub platform: Platform,
}

#[utoipa::path(
    put,
    path = "/me/device",
    operation_id = "registerMyDevice",
    tag = "notifications",
    request_body = DeviceRegistration,
    responses(
        (status = 204, description = "Saved."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn register_device(
    State(state): State<AppState>,
    user: AuthUser,
    ApiJson(body): ApiJson<DeviceRegistration>,
) -> ApiResult<StatusCode> {
    let token = body.token.trim();
    if token.is_empty() || token.len() > 4096 {
        return Err(ApiError::validation(vec![]).field("token", "Send the Firebase token"));
    }
    let Platform::Android = body.platform;

    let mut tx = state.db.begin().await?;
    let client: String = sqlx::query_scalar("SELECT client FROM sessions WHERE id = $1")
        .bind(user.session_id)
        .fetch_one(&mut *tx)
        .await?;
    if client != "app" {
        return Err(ApiError::new(
            StatusCode::FORBIDDEN,
            "auth.app_only",
            "Only the app can do this",
        ));
    }
    // This session's earlier token, if it had another one.
    sqlx::query("DELETE FROM devices WHERE session_id = $1 AND token <> $2")
        .bind(user.session_id)
        .bind(token)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "INSERT INTO devices (token, session_id, user_id, platform)
         VALUES ($1, $2, $3, 'android')
         ON CONFLICT (token) DO UPDATE
         SET session_id = $2, user_id = $3, platform = 'android', updated_at = now()",
    )
    .bind(token)
    .bind(user.session_id)
    .bind(user.user_id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(StatusCode::NO_CONTENT)
}
