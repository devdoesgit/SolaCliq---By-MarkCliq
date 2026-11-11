use axum::{Json, extract::State, http::StatusCode};
use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use crate::AppState;

#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ServiceStatus {
    Ok,
    Degraded,
}

#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum DatabaseStatus {
    Ok,
    Unavailable,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct Health {
    pub status: ServiceStatus,
    /// Backend build version.
    #[schema(examples("0.1.0"))]
    pub version: &'static str,
    pub database: DatabaseStatus,
}

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(get_health))
}

/// Service health
///
/// Whether the API and its database are up. Needs no authentication.
/// 503 with the same body when the database can't be reached.
#[utoipa::path(
    get,
    path = "/health",
    operation_id = "getHealth",
    tag = "system",
    security(()),
    responses(
        (status = 200, description = "The API is up.", body = Health),
        (status = 503, description = "The API is up but the database is unavailable.", body = Health),
    ),
)]
async fn get_health(State(state): State<AppState>) -> (StatusCode, Json<Health>) {
    let db_up = sqlx::query("SELECT 1").execute(&state.db).await.is_ok();
    let (code, status, database) = if db_up {
        (StatusCode::OK, ServiceStatus::Ok, DatabaseStatus::Ok)
    } else {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            ServiceStatus::Degraded,
            DatabaseStatus::Unavailable,
        )
    };
    (
        code,
        Json(Health {
            status,
            version: env!("CARGO_PKG_VERSION"),
            database,
        }),
    )
}
