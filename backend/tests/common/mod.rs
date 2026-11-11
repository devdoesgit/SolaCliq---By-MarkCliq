//! Helpers shared by the test files. (A folder with mod.rs, so cargo doesn't
//! treat it as a test file of its own.) Each test file uses some of them.
#![allow(dead_code)]

use axum::{
    body::Body,
    http::{HeaderMap, Request, StatusCode},
};
use backend::{AppState, app};
use http_body_util::BodyExt;
use serde_json::{Value, json};
use sqlx::PgPool;
use tower::ServiceExt;

pub fn state(db: &PgPool) -> AppState {
    AppState {
        db: db.clone(),
        cookie_secure: false,
        lifetimes: Default::default(),
    }
}

/// A finished response: status, headers and the body as JSON (Null if none).
pub struct Res {
    pub status: StatusCode,
    pub headers: HeaderMap,
    pub body: Value,
}

pub async fn send(db: &PgPool, req: Request<Body>) -> Res {
    let res = app(state(db)).oneshot(req).await.unwrap();
    let status = res.status();
    let headers = res.headers().clone();
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    Res {
        status,
        headers,
        body: serde_json::from_slice(&bytes).unwrap_or(Value::Null),
    }
}

pub async fn post(db: &PgPool, path: &str, body: Value) -> Res {
    let req = Request::post(path)
        .header("content-type", "application/json")
        .body(Body::from(body.to_string()))
        .unwrap();
    send(db, req).await
}

/// GET with `Authorization: Bearer <token>` when a token is given.
pub async fn get(db: &PgPool, path: &str, token: Option<&str>) -> Res {
    let mut req = Request::get(path);
    if let Some(t) = token {
        req = req.header("authorization", format!("Bearer {t}"));
    }
    send(db, req.body(Body::empty()).unwrap()).await
}

/// Signs up through the API, then marks the email verified in SQL (the
/// code step is phase 3).
pub async fn verified_user(db: &PgPool, email: &str, password: &str) {
    let res = post(
        db,
        "/api/v1/auth/signup",
        json!({ "name": "Asha Example", "email": email, "password": password }),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    sqlx::query("UPDATE users SET email_verified_at = now() WHERE email = $1")
        .bind(email)
        .execute(db)
        .await
        .unwrap();
}
