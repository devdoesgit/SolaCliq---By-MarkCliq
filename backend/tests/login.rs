//! Log in and `/me` against a real Postgres (needs `make db` running).

mod common;

use axum::http::StatusCode;
use common::{cookie_value, get, post, set_cookies, verified_user};
use serde_json::json;
use sqlx::PgPool;

const LOGIN: &str = "/api/v1/auth/login";

fn app_login(email: &str, password: &str) -> serde_json::Value {
    json!({ "email": email, "password": password, "client": "app" })
}

#[sqlx::test]
async fn app_login_returns_tokens_that_open_me(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;

    // Any capitalisation and spacing of the email works.
    let res = post(&db, LOGIN, app_login(" Asha@Example.com", "sunlight1")).await;
    assert_eq!(res.status, StatusCode::OK);
    assert_eq!(res.body["user"]["email"], "asha@example.com");
    assert_eq!(res.body["user"]["memberships"], json!([]));
    let tokens = &res.body["tokens"];
    assert_eq!(tokens["token_type"], "Bearer");
    assert_eq!(tokens["access_expires_in"], 900);
    assert_ne!(tokens["access_token"], tokens["refresh_token"]);

    let access = tokens["access_token"].as_str().unwrap();
    let me = get(&db, "/api/v1/me", Some(access)).await;
    assert_eq!(me.status, StatusCode::OK);
    assert_eq!(me.body["name"], "Asha Example");
    assert_eq!(me.body["email_verified"], true);
    assert_eq!(me.body["is_platform_admin"], false);
}

#[sqlx::test]
async fn tokens_are_stored_hashed(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let res = post(&db, LOGIN, app_login("asha@example.com", "sunlight1")).await;
    let access = res.body["tokens"]["access_token"].as_str().unwrap();

    let stored: Vec<u8> = sqlx::query_scalar("SELECT access_hash FROM sessions")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_ne!(stored, access.as_bytes(), "never the token itself");
    assert_eq!(stored, backend::session::hash_token(access));
}

#[sqlx::test]
async fn wrong_password_and_unknown_email_look_the_same(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;

    let wrong = post(&db, LOGIN, app_login("asha@example.com", "sunlight2")).await;
    let unknown = post(&db, LOGIN, app_login("nobody@example.com", "sunlight1")).await;

    assert_eq!(wrong.status, StatusCode::UNAUTHORIZED);
    assert_eq!(wrong.body["code"], "auth.invalid_credentials");
    assert_eq!(
        wrong.body, unknown.body,
        "same error, nothing to tell them apart"
    );
}

#[sqlx::test]
async fn unverified_is_refused_only_after_the_right_password(db: PgPool) {
    common::post(
        &db,
        "/api/v1/auth/signup",
        json!({ "name": "Asha", "email": "asha@example.com", "password": "sunlight1" }),
    )
    .await;

    let wrong = post(&db, LOGIN, app_login("asha@example.com", "nope12345")).await;
    assert_eq!(wrong.body["code"], "auth.invalid_credentials");

    let right = post(&db, LOGIN, app_login("asha@example.com", "sunlight1")).await;
    assert_eq!(right.status, StatusCode::FORBIDDEN);
    assert_eq!(right.body["code"], "account.email_unverified");
}

#[sqlx::test]
async fn account_without_password_is_told_to_set_one(db: PgPool) {
    // What an admin-created account looks like: no password_hash.
    sqlx::query("INSERT INTO users (id, email, name) VALUES ($1, 'ravi@example.com', 'Ravi')")
        .bind(uuid::Uuid::now_v7())
        .execute(&db)
        .await
        .unwrap();

    let res = post(&db, LOGIN, app_login("ravi@example.com", "anything1")).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "account.password_not_set");
}

#[sqlx::test]
async fn web_login_sets_cookies_and_no_tokens(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let res = post(
        &db,
        LOGIN,
        json!({ "email": "asha@example.com", "password": "sunlight1", "client": "web" }),
    )
    .await;

    assert_eq!(res.status, StatusCode::OK);
    assert!(res.body.get("tokens").is_none());
    let cookies = set_cookies(&res);
    assert_eq!(cookies.len(), 2);
    let access = &cookies[0];
    assert!(access.starts_with("solacliq_session="));
    assert!(access.contains("Path=/;"));
    assert!(access.contains("HttpOnly"));
    assert!(access.contains("SameSite=Lax"));
    assert!(access.contains("Max-Age=900"));
    let refresh = &cookies[1];
    assert!(refresh.starts_with("solacliq_refresh="));
    assert!(refresh.contains("Path=/api/v1/auth/refresh;"));
    assert!(refresh.contains("HttpOnly"));
    assert!(refresh.contains("Max-Age=2592000"));

    // The access cookie alone opens /me.
    let token = cookie_value(access);
    let req = axum::http::Request::get("/api/v1/me")
        .header("cookie", format!("theme=dark; solacliq_session={token}"))
        .body(axum::body::Body::empty())
        .unwrap();
    assert_eq!(common::send(&db, req).await.status, StatusCode::OK);
}

#[sqlx::test]
async fn me_needs_a_live_token(db: PgPool) {
    let none = get(&db, "/api/v1/me", None).await;
    assert_eq!(none.status, StatusCode::UNAUTHORIZED);
    assert_eq!(none.body["code"], "auth.unauthenticated");

    let made_up = get(&db, "/api/v1/me", Some("not-a-real-token")).await;
    assert_eq!(made_up.status, StatusCode::UNAUTHORIZED);

    // An expired session no longer works.
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let res = post(&db, LOGIN, app_login("asha@example.com", "sunlight1")).await;
    let access = res.body["tokens"]["access_token"].as_str().unwrap();
    sqlx::query("UPDATE sessions SET access_expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .unwrap();
    assert_eq!(
        get(&db, "/api/v1/me", Some(access)).await.status,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test]
async fn revoked_session_no_longer_works(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let res = post(&db, LOGIN, app_login("asha@example.com", "sunlight1")).await;
    let access = res.body["tokens"]["access_token"].as_str().unwrap();

    sqlx::query("UPDATE sessions SET revoked_at = now()")
        .execute(&db)
        .await
        .unwrap();
    assert_eq!(
        get(&db, "/api/v1/me", Some(access)).await.status,
        StatusCode::UNAUTHORIZED
    );
}
