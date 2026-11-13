//! Refresh (OAuth 2.1 rotation) and log out, against a real Postgres.

mod common;

use axum::http::StatusCode;
use common::{Res, cookie_value, get, post, post_with, set_cookies, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;

const LOGIN: &str = "/api/v1/auth/login";
const REFRESH: &str = "/api/v1/auth/refresh";
const LOGOUT: &str = "/api/v1/auth/logout";

/// Logs Asha in on the app and returns (access, refresh).
async fn app_tokens(db: &PgPool) -> (String, String) {
    verified_user(db, "asha@example.com", "sunlight1").await;
    let res = post(
        db,
        LOGIN,
        json!({ "email": "asha@example.com", "password": "sunlight1", "client": "app" }),
    )
    .await;
    pair(&res.body)
}

fn pair(body: &Value) -> (String, String) {
    let t = |k: &str| body[k].as_str().unwrap().to_owned();
    match body.get("tokens") {
        Some(tokens) => pair(tokens),
        None => (t("access_token"), t("refresh_token")),
    }
}

async fn refresh(db: &PgPool, refresh_token: &str) -> Res {
    post(db, REFRESH, json!({ "refresh_token": refresh_token })).await
}

#[sqlx::test]
async fn refresh_replaces_both_tokens(db: PgPool) {
    let (access, refresh_1) = app_tokens(&db).await;

    let res = refresh(&db, &refresh_1).await;
    assert_eq!(res.status, StatusCode::OK);
    assert_eq!(res.body["token_type"], "Bearer");
    assert_eq!(res.body["access_expires_in"], 900);
    let (new_access, refresh_2) = pair(&res.body);
    assert_ne!(new_access, access);
    assert_ne!(refresh_2, refresh_1);

    // The new access token works; the old one is gone.
    assert_eq!(
        get(&db, "/api/v1/me", Some(&new_access)).await.status,
        StatusCode::OK
    );
    assert_eq!(
        get(&db, "/api/v1/me", Some(&access)).await.status,
        StatusCode::UNAUTHORIZED
    );

    // And the new refresh token rotates again.
    assert_eq!(refresh(&db, &refresh_2).await.status, StatusCode::OK);
}

#[sqlx::test]
async fn reusing_an_old_refresh_token_revokes_the_session(db: PgPool) {
    let (_, refresh_1) = app_tokens(&db).await;
    let (access_2, refresh_2) = pair(&refresh(&db, &refresh_1).await.body);

    // Someone replays the old token.
    let res = refresh(&db, &refresh_1).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
    assert_eq!(res.body["code"], "auth.session_expired");

    // The whole session is dead, including the tokens handed out last.
    assert_eq!(
        refresh(&db, &refresh_2).await.status,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        get(&db, "/api/v1/me", Some(&access_2)).await.status,
        StatusCode::UNAUTHORIZED
    );
    let reason: String = sqlx::query_scalar("SELECT revoked_reason FROM sessions")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(reason, "refresh_reuse");
}

#[sqlx::test]
async fn unknown_missing_or_expired_refresh_tokens_are_refused(db: PgPool) {
    let (_, refresh_1) = app_tokens(&db).await;

    let unknown = refresh(&db, "not-a-real-token").await;
    assert_eq!(unknown.status, StatusCode::UNAUTHORIZED);
    assert_eq!(unknown.body["code"], "auth.session_expired");

    // No body and no cookie: nothing to refresh.
    assert_eq!(
        post_with(&db, REFRESH, &[]).await.status,
        StatusCode::UNAUTHORIZED
    );

    sqlx::query("UPDATE sessions SET refresh_expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .unwrap();
    assert_eq!(
        refresh(&db, &refresh_1).await.status,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test]
async fn the_website_refreshes_with_its_cookie(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let login = post(
        &db,
        LOGIN,
        json!({ "email": "asha@example.com", "password": "sunlight1", "client": "web" }),
    )
    .await;
    let old = set_cookies(&login);
    let old_refresh = cookie_value(&old[1]).to_owned();

    let cookie = format!("solacliq_refresh={old_refresh}");
    let res = post_with(&db, REFRESH, &[("cookie", &cookie)]).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    let new = set_cookies(&res);
    assert!(new[0].starts_with("solacliq_session="));
    assert!(new[1].starts_with("solacliq_refresh="));
    assert_ne!(cookie_value(&new[1]), old_refresh);

    // The new access cookie opens /me.
    let access = format!("solacliq_session={}", cookie_value(&new[0]));
    let req = axum::http::Request::get("/api/v1/me")
        .header("cookie", access)
        .body(axum::body::Body::empty())
        .unwrap();
    assert_eq!(common::send(&db, req).await.status, StatusCode::OK);

    // The old refresh cookie is now a reuse.
    assert_eq!(
        post_with(&db, REFRESH, &[("cookie", &cookie)]).await.status,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test]
async fn logout_ends_the_session(db: PgPool) {
    let (access, refresh_1) = app_tokens(&db).await;

    let bearer = format!("Bearer {access}");
    let res = post_with(&db, LOGOUT, &[("authorization", &bearer)]).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);

    // Both tokens are dead.
    assert_eq!(
        get(&db, "/api/v1/me", Some(&access)).await.status,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(
        refresh(&db, &refresh_1).await.status,
        StatusCode::UNAUTHORIZED
    );

    // The website's cookies are cleared.
    let cleared = set_cookies(&res);
    assert!(cleared[0].starts_with("solacliq_session=;"));
    assert!(cleared[1].starts_with("solacliq_refresh=;"));
    assert!(cleared.iter().all(|c| c.contains("Max-Age=0")));

    let reason: String = sqlx::query_scalar("SELECT revoked_reason FROM sessions")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(reason, "logout");
}

#[sqlx::test]
async fn logout_needs_a_login(db: PgPool) {
    let res = post_with(&db, LOGOUT, &[]).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
    assert_eq!(res.body["code"], "auth.unauthenticated");
}

#[sqlx::test]
async fn two_refreshes_at_once_count_as_reuse(db: PgPool) {
    let (_, refresh_1) = app_tokens(&db).await;

    // The same token twice, at the same moment. The row lock lets exactly
    // one rotate; the other finds the token already used.
    let (a, b) = tokio::join!(refresh(&db, &refresh_1), refresh(&db, &refresh_1));
    let mut statuses = [a.status, b.status];
    statuses.sort();
    assert_eq!(statuses, [StatusCode::OK, StatusCode::UNAUTHORIZED]);

    // No grace window (OAuth 2.1 as decided): that is reuse, so the
    // session is revoked. Clients must run one refresh at a time.
    let revoked: bool = sqlx::query_scalar("SELECT revoked_at IS NOT NULL FROM sessions")
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(revoked);
}
