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
use sqlx::{PgPool, postgres::PgPoolOptions};
use tower::ServiceExt;

/*
    The router's state. `db` is the test database's owner, for setting up
    rows and checking them; the router gets the restricted login instead
    (`app_db`), as the real server does, so a handler that forgets its
    row-level security scope fails its tests
*/
pub fn state(db: &PgPool) -> AppState {
    AppState {
        db: app_db(db),
        cookie_secure: false,
        lifetimes: Default::default(),
        mailer: Arc::new(Outbox),
        limits: Arc::new(backend::rate_limit::Limiter::disabled()),
        code_secret: CodeSecret::new(b"test-secret-at-least-32-bytes-long".to_vec()),
        review_email: "review@example.com".into(),
        bank_key: backend::bank::BankKey::from_hex(
            "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
        )
        .unwrap(),
        // Signing needs no network, so tests sign with a made-up key.
        storage: Some(backend::storage::Storage::new(
            "test-account".into(),
            "test-bucket".into(),
            "test-key-id".into(),
            "test-secret".into(),
        )),
    }
}

/*
    The same test database as `solacliq_api` (`make db` creates it, with
    this local-only password). Lazy: connects on first use
*/
pub fn app_db(db: &PgPool) -> PgPool {
    let options = (*db.connect_options())
        .clone()
        .username("solacliq_api")
        .password("solacliq_api");
    PgPoolOptions::new()
        .max_connections(2)
        .connect_lazy_with(options)
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
    let state = state(db);
    let app_db = state.db.clone();
    let res = app(state).oneshot(req).await.unwrap();
    // Closed now, or the test database couldn't be dropped after the test.
    app_db.close().await;
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

/*
    Phase 4 helpers: companies and members, made straight in SQL so each
    test sets up exactly the state it needs
*/

// A company with this status ('pending', 'active' or 'suspended').
pub async fn org(db: &PgPool, name: &str, status: &str) -> uuid::Uuid {
    let id = uuid::Uuid::now_v7();
    // Dummy GST details; the id as GSTIN keeps each one unique.
    sqlx::query(
        "INSERT INTO orgs (id, name, status, phone, gstin, pan, legal_name,
                           business_type, address_line_1, city, state, pin_code)
         VALUES ($1, $2, $3::org_status, '9814000000', $1::text, 'AAAAA0000A', $2,
                 'other', 'Plot 1', 'Mohali', 'Punjab', '160062')",
    )
    .bind(id)
    .bind(name)
    .bind(status)
    .execute(db)
    .await
    .unwrap();
    id
}

/*
    A verified account with password "sunlight1" that belongs to `org`
    with `role` ('agent' gets pay type `pay_type`); returns an access token
*/
pub async fn member(
    db: &PgPool,
    org: uuid::Uuid,
    email: &str,
    role: &str,
    pay_type: Option<&str>,
) -> String {
    if !user_exists(db, email).await {
        verified_user(db, email, "sunlight1").await;
    }
    join(db, org, email, role, pay_type).await;
    token(db, email).await
}

// Adds an existing account to `org`.
pub async fn join(db: &PgPool, org: uuid::Uuid, email: &str, role: &str, pay_type: Option<&str>) {
    sqlx::query(
        "INSERT INTO memberships (id, user_id, org_id, role, pay_type)
         SELECT $1, id, $2, $3::member_role, $4::pay_type FROM users WHERE email = $5",
    )
    .bind(uuid::Uuid::now_v7())
    .bind(org)
    .bind(role)
    .bind(pay_type)
    .bind(email)
    .execute(db)
    .await
    .unwrap();
}

async fn user_exists(db: &PgPool, email: &str) -> bool {
    sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM users WHERE email = $1)")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

// Logs in as the app ("sunlight1") and returns the access token.
pub async fn token(db: &PgPool, email: &str) -> String {
    let res = post(
        db,
        "/api/v1/auth/login",
        json!({ "email": email, "password": "sunlight1", "client": "app" }),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body["tokens"]["access_token"]
        .as_str()
        .unwrap()
        .to_owned()
}

// Any method, with a bearer token and an optional JSON body.
pub async fn call(db: &PgPool, method: &str, path: &str, token: &str, body: Option<Value>) -> Res {
    call_with(db, method, path, token, body, &[]).await
}

// `call`, plus extra headers (an Idempotency-Key, say).
pub async fn call_with(
    db: &PgPool,
    method: &str,
    path: &str,
    token: &str,
    body: Option<Value>,
    headers: &[(&str, &str)],
) -> Res {
    let mut req = Request::builder()
        .method(method)
        .uri(path)
        .header("authorization", format!("Bearer {token}"))
        .header("content-type", "application/json");
    for (name, value) in headers {
        req = req.header(*name, *value);
    }
    let body = body.map_or_else(Body::empty, |b| Body::from(b.to_string()));
    send(db, req.body(body).unwrap()).await
}
