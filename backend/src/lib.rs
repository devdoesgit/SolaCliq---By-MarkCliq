/*
    SolaCliq API. `app` builds the router; `main.rs` wires config, the
    database and the server around it, so tests can build the same router.
*/

pub mod account;
pub mod bank;
pub mod codes;
pub mod config;
pub mod counter;
pub mod error;
pub mod extract;
pub mod google;
pub mod gstin;
pub mod idempotency;
pub mod india;
pub mod mail;
pub mod notify;
pub mod openapi;
pub mod org;
pub mod origin;
pub mod page;
pub mod password;
pub mod push;
pub mod rate_limit;
pub mod retention;
pub mod routes;
pub mod scope;
pub mod seed;
pub mod session;
pub mod signup;
pub mod stages;
pub mod storage;
pub mod terms;
pub mod validate;

use std::{sync::Arc, time::Duration};

use axum::{
    Router,
    body::Body,
    http::{Request, Response, StatusCode},
    response::IntoResponse,
};
use sqlx::PgPool;
use tower_http::{
    catch_panic::CatchPanicLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    timeout::TimeoutLayer,
    trace::{DefaultOnFailure, TraceLayer},
};
use tracing::{Level, Span};

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
        .layer(axum::middleware::from_fn(origin::same_origin))
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            Duration::from_secs(30),
        ))
        // Inside the trace layer, so a panic is logged as the 500 it becomes.
        .layer(CatchPanicLayer::custom(panic_response))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(request_span)
                .on_request(())
                .on_response(log_response)
                .on_failure(DefaultOnFailure::new().level(Level::ERROR)),
        )
        .layer(PropagateRequestIdLayer::x_request_id())
        .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
        .with_state(state)
}

/*
    One span per request: its id (also sent back as X-Request-Id, so a
    person's report can be matched to the log), method and path
    ----------------------------------------------------------------------
    - the path only, never the query: a search's query can hold a name or
      a phone number
    - the health check (every 10 s, from Docker) gets a debug span, so it
      stays out of the log unless RUST_LOG asks for debug
*/
fn request_span(req: &Request<Body>) -> Span {
    let id = req
        .headers()
        .get("x-request-id")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("-");
    let path = req.uri().path();
    if path == "/api/v1/health" {
        tracing::debug_span!("request", id, method = %req.method(), path)
    } else {
        tracing::info_span!("request", id, method = %req.method(), path)
    }
}

/// A line per answered request, with its status and time taken.
fn log_response<B>(res: &Response<B>, latency: Duration, span: &Span) {
    if !span.is_disabled() {
        tracing::info!(
            status = res.status().as_u16(),
            ms = latency.as_millis() as u64,
            "response"
        );
    }
}

/// A panic in a handler: logged, and answered with the usual plain 500.
fn panic_response(err: Box<dyn std::any::Any + Send + 'static>) -> Response<Body> {
    let detail = err
        .downcast_ref::<String>()
        .map(String::as_str)
        .or_else(|| err.downcast_ref::<&str>().copied())
        .unwrap_or("unknown");
    tracing::error!(panic = detail, "handler panicked");
    error::ApiError::internal().into_response()
}
