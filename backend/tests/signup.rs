//! Sign-up against a real Postgres. `#[sqlx::test]` makes a fresh database
//! for each test (from DATABASE_URL), runs migrations/, passes the pool in,
//! and drops the database afterwards. Needs `make db` running.

mod common;

use axum::http::StatusCode;
use serde_json::{Value, json};
use sqlx::PgPool;

/// POSTs JSON and returns the status and body.
async fn post(db: &PgPool, path: &str, body: Value) -> (StatusCode, Value) {
    let res = common::post(db, path, body).await;
    (res.status, res.body)
}

fn asha() -> Value {
    json!({
        "name": "Asha Example",
        "email": "  Asha@Example.com ",
        "phone": "9876511223",
        "password": "sunlight1"
    })
}

async fn user_count(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM users")
        .fetch_one(db)
        .await
        .unwrap()
}

#[sqlx::test]
async fn creates_an_unverified_account(db: PgPool) {
    let (status, _) = post(&db, "/api/v1/auth/signup", asha()).await;
    assert_eq!(status, StatusCode::ACCEPTED);

    // A tuple of columns; sqlx maps each to the Rust type asked for.
    let (email, hash, verified): (String, String, Option<chrono::DateTime<chrono::Utc>>) =
        sqlx::query_as("SELECT email, password_hash, email_verified_at FROM users")
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(email, "asha@example.com", "trimmed and lowercased");
    assert!(hash.starts_with("$argon2id$"), "hashed, never plain");
    assert!(verified.is_none(), "unverified until the code is entered");
}

#[sqlx::test]
async fn existing_email_still_202_and_no_second_account(db: PgPool) {
    post(&db, "/api/v1/auth/signup", asha()).await;
    let mut again = asha();
    again["email"] = json!("asha@example.com");
    let (status, _) = post(&db, "/api/v1/auth/signup", again).await;

    assert_eq!(status, StatusCode::ACCEPTED, "no hint the email exists");
    assert_eq!(user_count(&db).await, 1);
}

#[sqlx::test]
async fn weak_password_has_its_own_code(db: PgPool) {
    let mut body = asha();
    body["password"] = json!("sunlight"); // no number
    let (status, problem) = post(&db, "/api/v1/auth/signup", body).await;

    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(problem["code"], "auth.password_too_weak");
    assert_eq!(problem["errors"][0]["field"], "password");
    assert_eq!(user_count(&db).await, 0);
}

#[sqlx::test]
async fn every_bad_field_is_listed(db: PgPool) {
    let body = json!({ "name": " ", "email": "nope", "phone": "123", "password": "x" });
    let (status, problem) = post(&db, "/api/v1/auth/signup", body).await;

    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(problem["code"], "validation.failed");
    let fields: Vec<&str> = problem["errors"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["field"].as_str().unwrap())
        .collect();
    assert_eq!(fields, ["name", "email", "phone", "password"]);
}

#[sqlx::test]
async fn missing_field_is_problem_json(db: PgPool) {
    let (status, problem) = post(&db, "/api/v1/auth/signup", json!({ "name": "Asha" })).await;

    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(problem["code"], "validation.failed");
}

#[sqlx::test]
async fn blank_phone_is_no_phone(db: PgPool) {
    let mut body = asha();
    body["phone"] = json!("");
    let (status, _) = post(&db, "/api/v1/auth/signup", body).await;
    assert_eq!(status, StatusCode::ACCEPTED);

    let phone: Option<String> = sqlx::query_scalar("SELECT phone FROM users")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(phone, None);
}
