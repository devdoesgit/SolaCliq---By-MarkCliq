/*
    Phase 3b: 6-digit email codes (verify, resend, forgot, reset)
    --------------------------------------------------------------------
    - emails land in the test outbox; `common::last_code` reads the code
    - the outbox is shared by every test in this file, so each test uses
      its own email addresses
*/

mod common;

use axum::http::StatusCode;
use common::{emails_to, get, last_code, post, verified_user};
use serde_json::json;
use sqlx::PgPool;

const PASSWORD: &str = "sunlight33";

async fn signup(db: &PgPool, email: &str) {
    let res = post(
        db,
        "/api/v1/auth/signup",
        json!({ "name": "Asha Example", "email": email, "password": PASSWORD }),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
}

async fn verify(db: &PgPool, email: &str, code: &str) -> common::Res {
    post(
        db,
        "/api/v1/auth/email/verify",
        json!({ "email": email, "code": code }),
    )
    .await
}

async fn login(db: &PgPool, email: &str, password: &str) -> common::Res {
    post(
        db,
        "/api/v1/auth/login",
        json!({ "email": email, "password": password, "client": "app" }),
    )
    .await
}

fn code_of(res: &common::Res) -> &str {
    res.body["code"].as_str().unwrap_or_default()
}

// A 6-digit code that isn't `code`.
fn other_code(code: &str) -> String {
    let n: u32 = code.parse().unwrap();
    format!("{:06}", (n + 1) % 1_000_000)
}

#[sqlx::test]
async fn signup_code_verifies_and_then_login_works(db: PgPool) {
    let email = "verify.ok@example.com";
    signup(&db, email).await;
    assert_eq!(
        code_of(&login(&db, email, PASSWORD).await),
        "account.email_unverified"
    );

    let res = verify(&db, email, &last_code(email)).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    assert_eq!(login(&db, email, PASSWORD).await.status, StatusCode::OK);
}

#[sqlx::test]
async fn codes_are_stored_as_an_hmac_not_the_code(db: PgPool) {
    let email = "stored.hashed@example.com";
    signup(&db, email).await;
    let code = last_code(email);
    let (hash,): (Vec<u8>,) = sqlx::query_as("SELECT code_hash FROM email_codes")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(hash.len(), 32); // HMAC-SHA256
    assert!(!hash.windows(6).any(|w| w == code.as_bytes()));
}

#[sqlx::test]
async fn a_wrong_code_is_refused_and_the_right_one_still_works(db: PgPool) {
    let email = "verify.wrong@example.com";
    signup(&db, email).await;
    let code = last_code(email);

    let res = verify(&db, email, &other_code(&code)).await;
    assert_eq!(res.status, StatusCode::BAD_REQUEST);
    assert_eq!(code_of(&res), "auth.code_invalid");
    assert_eq!(
        verify(&db, email, &code).await.status,
        StatusCode::NO_CONTENT
    );
}

#[sqlx::test]
async fn a_code_works_once(db: PgPool) {
    let email = "verify.once@example.com";
    signup(&db, email).await;
    let code = last_code(email);
    assert_eq!(
        verify(&db, email, &code).await.status,
        StatusCode::NO_CONTENT
    );

    let again = verify(&db, email, &code).await;
    assert_eq!(again.status, StatusCode::BAD_REQUEST);
    assert_eq!(code_of(&again), "auth.code_expired");
}

#[sqlx::test]
async fn the_sixth_try_is_refused_even_with_the_right_code(db: PgPool) {
    let email = "verify.tries@example.com";
    signup(&db, email).await;
    let code = last_code(email);

    for _ in 0..5 {
        let res = verify(&db, email, &other_code(&code)).await;
        assert_eq!(code_of(&res), "auth.code_invalid");
    }
    let res = verify(&db, email, &code).await;
    assert_eq!(res.status, StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(code_of(&res), "auth.too_many_attempts");
}

#[sqlx::test]
async fn an_expired_code_is_refused(db: PgPool) {
    let email = "verify.expired@example.com";
    signup(&db, email).await;
    sqlx::query("UPDATE email_codes SET expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .unwrap();

    let res = verify(&db, email, &last_code(email)).await;
    assert_eq!(res.status, StatusCode::BAD_REQUEST);
    assert_eq!(code_of(&res), "auth.code_expired");
}

#[sqlx::test]
async fn a_malformed_code_is_refused_without_using_a_try(db: PgPool) {
    let email = "verify.malformed@example.com";
    signup(&db, email).await;

    for bad in ["12ab56", "12345", "1234567", ""] {
        let res = verify(&db, email, bad).await;
        assert_eq!(code_of(&res), "auth.code_invalid", "{bad:?}");
    }
    let (attempts,): (i32,) = sqlx::query_as("SELECT attempts FROM email_codes")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(attempts, 0);
}

#[sqlx::test]
async fn an_unknown_email_looks_like_no_code(db: PgPool) {
    let res = verify(&db, "nobody.verify@example.com", "123456").await;
    assert_eq!(res.status, StatusCode::BAD_REQUEST);
    assert_eq!(code_of(&res), "auth.code_expired");

    for path in ["/api/v1/auth/email/resend", "/api/v1/auth/password/forgot"] {
        let res = post(&db, path, json!({ "email": "nobody.verify@example.com" })).await;
        assert_eq!(res.status, StatusCode::ACCEPTED, "{path}");
    }
    assert!(emails_to("nobody.verify@example.com").is_empty());
}

#[sqlx::test]
async fn resend_waits_a_minute_then_replaces_the_code(db: PgPool) {
    let email = "resend.cooldown@example.com";
    signup(&db, email).await;
    let first = last_code(email);

    // Within the minute: still 202, but no new email.
    let res = post(&db, "/api/v1/auth/email/resend", json!({ "email": email })).await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    assert_eq!(emails_to(email).len(), 1);

    // A minute later: a new code, and the first one stops working.
    sqlx::query("UPDATE email_codes SET created_at = now() - interval '61 seconds'")
        .execute(&db)
        .await
        .unwrap();
    post(&db, "/api/v1/auth/email/resend", json!({ "email": email })).await;
    assert_eq!(emails_to(email).len(), 2);
    let second = last_code(email);
    if first != second {
        assert_eq!(
            code_of(&verify(&db, email, &first).await),
            "auth.code_invalid"
        );
    }
    assert_eq!(
        verify(&db, email, &second).await.status,
        StatusCode::NO_CONTENT
    );
}

#[sqlx::test]
async fn resend_sends_nothing_to_a_verified_account(db: PgPool) {
    let email = "resend.verified@example.com";
    verified_user(&db, email, PASSWORD).await;
    let before = emails_to(email).len();

    let res = post(&db, "/api/v1/auth/email/resend", json!({ "email": email })).await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    assert_eq!(emails_to(email).len(), before);
}

#[sqlx::test]
async fn signing_up_again_with_a_verified_email_sends_a_notice(db: PgPool) {
    let email = "signup.again@example.com";
    verified_user(&db, email, PASSWORD).await;

    signup(&db, email).await;
    let last = emails_to(email).pop().unwrap();
    assert!(last.subject.contains("already have"), "{}", last.subject);
    assert!(
        !last.body.chars().any(|c| c.is_ascii_digit()),
        "no code in it"
    );
}

#[sqlx::test]
async fn reset_sets_the_password_and_ends_every_session(db: PgPool) {
    let email = "reset.ok@example.com";
    verified_user(&db, email, PASSWORD).await;
    let old = login(&db, email, PASSWORD).await;
    let old_token = old.body["tokens"]["access_token"]
        .as_str()
        .unwrap()
        .to_owned();

    let res = post(
        &db,
        "/api/v1/auth/password/forgot",
        json!({ "email": email }),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    let code = last_code(email);

    // A weak password is refused before the code is tried.
    let weak = post(
        &db,
        "/api/v1/auth/password/reset",
        json!({ "email": email, "code": code, "new_password": "short" }),
    )
    .await;
    assert_eq!(weak.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(code_of(&weak), "auth.password_too_weak");

    let res = post(
        &db,
        "/api/v1/auth/password/reset",
        json!({ "email": email, "code": code, "new_password": "moonlight44" }),
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);

    let me = get(&db, "/api/v1/me", Some(&old_token)).await;
    assert_eq!(me.status, StatusCode::UNAUTHORIZED);
    assert_eq!(
        code_of(&login(&db, email, PASSWORD).await),
        "auth.invalid_credentials"
    );
    assert_eq!(
        login(&db, email, "moonlight44").await.status,
        StatusCode::OK
    );

    let (reason,): (Option<String>,) = sqlx::query_as("SELECT revoked_reason FROM sessions")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(reason.as_deref(), Some("password_reset"));
}

#[sqlx::test]
async fn reset_sets_a_first_password_and_verifies_the_email(db: PgPool) {
    // An account an agent or admin created: no password, not verified.
    let email = "reset.first@example.com";
    sqlx::query("INSERT INTO users (id, email, name) VALUES ($1, $2, 'Ravi Example')")
        .bind(uuid::Uuid::now_v7())
        .bind(email)
        .execute(&db)
        .await
        .unwrap();
    assert_eq!(
        code_of(&login(&db, email, PASSWORD).await),
        "account.password_not_set"
    );

    post(
        &db,
        "/api/v1/auth/password/forgot",
        json!({ "email": email }),
    )
    .await;
    let res = post(
        &db,
        "/api/v1/auth/password/reset",
        json!({ "email": email, "code": last_code(email), "new_password": PASSWORD }),
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    assert_eq!(login(&db, email, PASSWORD).await.status, StatusCode::OK);
}

#[sqlx::test]
async fn a_verify_code_cannot_reset_a_password(db: PgPool) {
    let email = "reset.purpose@example.com";
    signup(&db, email).await;
    let res = post(
        &db,
        "/api/v1/auth/password/reset",
        json!({ "email": email, "code": last_code(email), "new_password": "moonlight44" }),
    )
    .await;
    assert_eq!(res.status, StatusCode::BAD_REQUEST);
    assert_eq!(code_of(&res), "auth.code_expired");
}
