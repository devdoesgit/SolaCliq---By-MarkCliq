//! SolaCliq API. `app` builds the router; `main.rs` wires config, the
//! database and the server around it, so tests can build the same router.

pub mod config;
pub mod error;
pub mod extract;
pub mod openapi;
pub mod password;
pub mod routes;
pub mod session;

use std::time::Duration;

use axum::{Router, http::StatusCode};
use sqlx::PgPool;
use tower_http::{
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};

/// Shared by every handler.
#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    /// See `Config::cookie_secure`.
    pub cookie_secure: bool,
    /// See `Config::session_lifetimes`.
    pub lifetimes: session::Lifetimes,
}

/// Every endpoint is under this prefix (`solacliq.markcliq.com/api/v1`).
pub const API_PREFIX: &str = "/api/v1";

pub fn app(state: AppState) -> Router {
    let (api, spec) = routes::router().split_for_parts();

    Router::new()
        .nest(API_PREFIX, api)
        .merge(openapi::docs(spec))
        .fallback(routes::not_found)
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        .layer(TraceLayer::new_for_http())
        .layer(PropagateRequestIdLayer::x_request_id())
        .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
        .with_state(state)
}
