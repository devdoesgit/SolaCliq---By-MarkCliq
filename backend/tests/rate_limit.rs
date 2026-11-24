//! Rate limits on the public endpoints, through the real router.

mod common;

use std::sync::Arc;

use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use backend::{app, rate_limit::Limiter};
use serde_json::{Value, json};
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

// A quote request with `key`, on an app whose limits are on.
async fn quote(router: &axum::Router, token: &str, key: &str) -> (StatusCode, Value) {
    let req = Request::builder()
        .method("POST")
        .uri("/api/v1/quote-requests")
        .header("content-type", "application/json")
        .header("authorization", format!("Bearer {token}"))
        .header("idempotency-key", key)
        .body(Body::from(
            json!({
                "quote_for": "home", "pin_code": "160062", "city": "Mohali",
                "bill_band": "from_1500_to_3000", "roof": "rcc",
                "timeline": "this_month", "phone": "98140 22671", "share_consent": true,
            })
            .to_string(),
        ))
        .unwrap();
    let res = router.clone().oneshot(req).await.unwrap();
    let status = res.status();
    let bytes = http_body_util::BodyExt::collect(res.into_body())
        .await
        .unwrap()
        .to_bytes();
    (
        status,
        serde_json::from_slice(&bytes).unwrap_or(Value::Null),
    )
}

#[sqlx::test]
async fn quotes_are_limited_per_account_but_retries_still_work(db: PgPool) {
    common::verified_user(&db, "asha@example.com", "sunlight1").await;
    let token = common::token(&db, "asha@example.com").await;
    let mut state = common::state(&db);
    state.limits = Arc::new(Limiter::new());
    let router = app(state);

    // 5 a day; each emails MarkCliq.
    let keys: Vec<String> = (0..6).map(|_| uuid::Uuid::now_v7().to_string()).collect();
    let mut first = Value::Null;
    for (i, key) in keys[..5].iter().enumerate() {
        let (status, body) = quote(&router, &token, key).await;
        assert_eq!(status, StatusCode::CREATED);
        if i == 0 {
            first = body;
        }
    }
    let (status, body) = quote(&router, &token, &keys[5]).await;
    assert_eq!(status, StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(body["code"], "auth.too_many_attempts");

    // A retry of one that went through still gets its answer.
    let (status, body) = quote(&router, &token, &keys[0]).await;
    assert_eq!(status, StatusCode::CREATED);
    assert_eq!(body["id"], first["id"]);
}

// A lead sent from `ip` with `key`, against an app whose limits are on.
async fn send_lead(router: &axum::Router, ip: &str, key: &str) -> StatusCode {
    let req = Request::builder()
        .method("POST")
        .uri("/api/v1/leads")
        .header("content-type", "application/json")
        .header("authorization", format!("Bearer {key}"))
        .header("x-real-ip", ip)
        .body(Body::from(
            json!({"name": "Asha (illustrative)", "phone": "9814022671", "consent": true})
                .to_string(),
        ))
        .unwrap();
    router.clone().oneshot(req).await.unwrap().status()
}

#[sqlx::test]
async fn wrong_lead_keys_cant_use_up_a_companys_leads(db: PgPool) {
    let a = common::org(&db, "Arka Solar", "active").await;
    let admin = common::member(&db, a, "admin@example.com", "org_admin", None).await;
    let made = common::call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/admin/lead-key"),
        &admin,
        None,
    )
    .await;
    let key = made.body["key"].as_str().unwrap().to_owned();

    let mut state = common::state(&db);
    state.limits = Arc::new(Limiter::new());
    let router = app(state);

    // Made-up keys with the company's id, from one address: 20, then refused.
    let fake = format!("lead_{}_{}", a.simple(), "b".repeat(64));
    for _ in 0..20 {
        assert_eq!(
            send_lead(&router, "10.0.0.1", &fake).await,
            StatusCode::UNAUTHORIZED
        );
    }
    assert_eq!(
        send_lead(&router, "10.0.0.1", &fake).await,
        StatusCode::TOO_MANY_REQUESTS
    );

    // The company's own landing page still gets its leads in.
    assert_eq!(
        send_lead(&router, "10.0.0.2", &key).await,
        StatusCode::CREATED
    );
}
