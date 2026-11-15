//! Rate limits on the public endpoints, through the real router.

mod common;

use std::sync::Arc;

use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use backend::{app, rate_limit::Limiter};
use serde_json::json;
use sqlx::PgPool;
use tower::ServiceExt;

// A login from `ip` against an app whose limits are on.
async fn login(router: &axum::Router, ip: &str, email: &str) -> (StatusCode, Option<String>) {
    let req = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .header("x-real-ip", ip)
        .body(Body::from(
            json!({"email": email, "password": "wrong-password", "client": "app"}).to_string(),
        ))
        .unwrap();
    let res = router.clone().oneshot(req).await.unwrap();
    let retry = res
        .headers()
        .get("retry-after")
        .map(|v| v.to_str().unwrap().to_owned());
    (res.status(), retry)
}

#[sqlx::test]
async fn guessing_one_accounts_password_is_stopped(db: PgPool) {
    let mut state = common::state(&db);
    state.limits = Arc::new(Limiter::new());
    let router = app(state);

    // 10 tries per account per 15 minutes, even from different IPs.
    for i in 0..10 {
        let (status, _) = login(&router, &format!("10.0.0.{i}"), "asha@example.com").await;
        assert_eq!(status, StatusCode::UNAUTHORIZED);
    }
    let (status, retry) = login(&router, "10.0.0.99", "asha@example.com").await;
    assert_eq!(status, StatusCode::TOO_MANY_REQUESTS);
    assert!(retry.is_some(), "429 says when to try again");

    // Another account isn't affected.
    let (status, _) = login(&router, "10.0.0.99", "ravi@example.com").await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
}

#[sqlx::test]
async fn one_ip_is_stopped_without_blocking_others(db: PgPool) {
    let mut state = common::state(&db);
    state.limits = Arc::new(Limiter::new());
    let router = app(state);

    // 30 tries per IP per 15 minutes, across accounts.
    for i in 0..30 {
        let (status, _) = login(&router, "10.1.1.1", &format!("p{i}@example.com")).await;
        assert_eq!(status, StatusCode::UNAUTHORIZED);
    }
    let (status, _) = login(&router, "10.1.1.1", "another@example.com").await;
    assert_eq!(status, StatusCode::TOO_MANY_REQUESTS);
    let (status, _) = login(&router, "10.2.2.2", "another@example.com").await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
}
