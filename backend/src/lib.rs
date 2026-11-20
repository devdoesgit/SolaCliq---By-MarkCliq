//! SolaCliq API. `app` builds the router; `main.rs` wires config, the
//! database and the server around it, so tests can build the same router.

pub mod bank;
pub mod codes;
pub mod config;
pub mod counter;
pub mod error;
pub mod extract;
pub mod google;
pub mod gstin;
pub mod idempotency;
pub mod mail;
pub mod notify;
pub mod openapi;
pub mod org;
pub mod page;
pub mod password;
pub mod push;
pub mod rate_limit;
pub mod routes;
pub mod scope;
pub mod seed;
pub mod session;
pub mod storage;
pub mod terms;
pub mod validate;

use std::{sync::Arc, time::Duration};

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
    /*
        Sends email. `Arc` because AppState is cloned for every request:
        each clone points at the same mailer instead of copying it
    */
    pub mailer: Arc<dyn mail::Mailer>,
    // Rate limits on the public endpoints. See `rate_limit`.
    pub limits: Arc<rate_limit::Limiter>,
    // Key for the email codes' HMAC. See `codes::CodeSecret`.
    pub code_secret: codes::CodeSecret,
    // MarkCliq's inbox for new company registrations and leads (REVIEW_EMAIL).
    pub review_email: String,
    // Encrypts payout bank account numbers (BANK_KEY). See `bank::BankKey`.
    pub bank_key: bank::BankKey,
    // Cloudflare R2, for uploads. None: `POST /uploads` answers 503.
    pub storage: Option<storage::Storage>,
}

/*
    The product's name, as users see it in emails. A working name:
    change it here
*/
pub const PRODUCT_NAME: &str = "SolaCliq";

/*
    The admin website (org admins' dashboard), for links in emails. The
    production address in every environment: emails only make sense
    pointing at the real site
*/
pub const WEBSITE: &str = "https://solacliq.markcliq.com";

/*
    Where people reach MarkCliq: replies to any email go here (Reply-To),
    and the app's Help sheet shows it. Emails are sent from MAIL_FROM
*/
pub const SUPPORT_EMAIL: &str = "info@markcliq.com";

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
