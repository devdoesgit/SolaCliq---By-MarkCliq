//! One module per area (see ../CLAUDE.md "Modules"). Each exposes a
//! `router()` that `router()` below merges; handlers carry `#[utoipa::path]`
//! so the spec is generated from them.

pub mod auth;
pub mod health;
pub mod me;

use utoipa_axum::router::OpenApiRouter;

use crate::{AppState, error::ApiError, openapi::ApiDoc};

pub fn router() -> OpenApiRouter<AppState> {
    use utoipa::OpenApi;
    OpenApiRouter::with_openapi(ApiDoc::openapi())
        .merge(health::router())
        .merge(auth::router())
        .merge(me::router())
}

/// Any path no route matches.
pub async fn not_found() -> ApiError {
    ApiError::not_found()
}
