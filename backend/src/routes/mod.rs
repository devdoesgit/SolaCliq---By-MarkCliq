//! One module per area (see ../CLAUDE.md "Modules"). Each exposes a
//! `router()` that `router()` below merges; handlers carry `#[utoipa::path]`
//! so the spec is generated from them.

pub mod admin;
pub mod auth;
pub mod customers;
pub mod expenses;
pub mod health;
pub mod home;
pub mod install;
pub mod me;
pub mod notifications;
pub mod platform;
pub mod profile;
pub mod quotes;
pub mod registration;
pub mod tasks;
pub mod team;
pub mod uploads;

use utoipa_axum::router::OpenApiRouter;

use crate::{AppState, error::ApiError, openapi::ApiDoc};

pub fn router() -> OpenApiRouter<AppState> {
    use utoipa::OpenApi;
    OpenApiRouter::with_openapi(ApiDoc::openapi())
        .merge(health::router())
        .merge(auth::router())
        .merge(me::router())
        .merge(home::router())
        .merge(install::router())
        .merge(notifications::router())
        .merge(team::router())
        .merge(registration::router())
        .merge(admin::router())
        .merge(customers::router())
        .merge(expenses::router())
        .merge(platform::router())
        .merge(profile::router())
        .merge(quotes::router())
        .merge(tasks::router())
        .merge(uploads::router())
}

/// Any path no route matches.
pub async fn not_found() -> ApiError {
    ApiError::not_found()
}
