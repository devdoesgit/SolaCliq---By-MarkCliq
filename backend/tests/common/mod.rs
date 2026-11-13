//! Helpers shared by the test files. (A folder with mod.rs, so cargo doesn't
//! treat it as a test file of its own.) Each test file uses some of them.
#![allow(dead_code)]

use axum::{
    body::Body,
    http::{HeaderMap, Request, StatusCode},
};
use std::sync::{Arc, Mutex};

use backend::{
    AppState, app,
    codes::CodeSecret,
    mail::{Email, Mailer},
};
use http_body_util::BodyExt;
use serde_json::{Value, json};
use sqlx::PgPool;
use tower::ServiceExt;

pub fn state(db: &PgPool) -> AppState {
    AppState {
        db: db.clone(),
        cookie_secure: false,
        lifetimes: Default::default(),
        mailer: Arc::new(Outbox),
        code_secret: CodeSecret::new(b"test-secret-at-least-32-bytes-long".to_vec()),
    }
}

/*
    Every email the app sent during this test run, oldest first
    --------------------------------------------------------------------
    - one list for the whole test binary
    - tests run at the same time, so each test uses its own email
      addresses and reads only those
*/
static OUTBOX: Mutex<Vec<Email>> = Mutex::new(Vec::new());

// The test mailer: keeps emails in OUTBOX instead of sending them.
struct Outbox;

impl Mailer for Outbox {
    fn send(&self, email: Email) {
        OUTBOX.lock().unwrap().push(email);
    }
}

// Every email sent to `to`, oldest first.
pub fn emails_to(to: &str) -> Vec<Email> {
    OUTBOX
        .lock()
        .unwrap()
        .iter()
        .filter(|e| e.to == to)
        .cloned()
        .collect()
}

// The 6-digit code in the latest email to `to`.
pub fn last_code(to: &str) -> String {
    let email = emails_to(to).pop().expect("no email sent to this address");
    email
        .body
        .split(|c: char| !c.is_ascii_digit())
        .find(|word| word.len() == 6)
        .expect("no 6-digit code in the email")
        .to_owned()
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

/// Every `Set-Cookie` header of a response, in order.
pub fn set_cookies(res: &Res) -> Vec<String> {
    res.headers
        .get_all("set-cookie")
        .iter()
        .map(|v| v.to_str().unwrap().to_owned())
        .collect()
}

/// `solacliq_session=abc; Path=/; ...` → `abc`.
pub fn cookie_value(set_cookie: &str) -> &str {
    set_cookie
        .split(';')
        .next()
        .and_then(|pair| pair.split_once('='))
        .map(|(_, value)| value)
        .unwrap()
}

/// POST with no body and the given headers.
pub async fn post_with(db: &PgPool, path: &str, headers: &[(&str, &str)]) -> Res {
    let mut req = Request::post(path);
    for (name, value) in headers {
        req = req.header(*name, *value);
    }
    send(db, req.body(Body::empty()).unwrap()).await
}
