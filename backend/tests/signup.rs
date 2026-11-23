//! Code-first sign-up (F1, QA-27 and QA-28): no account, and nothing
//! typed, exists until the inbox is proven. The takeover table in
//! docs/features/F1-accounts-login.md, a test per row.
//! The outbox is shared by the file, so each test uses its own emails.

mod common;

use std::sync::Arc;

use axum::{body::Body, http::Request, http::StatusCode};
use backend::rate_limit::Limiter;
use common::{Res, call, emails_to, last_code, member, org, post, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;
use tower::ServiceExt;

async fn start(db: &PgPool, email: &str) -> Res {
    post(db, "/api/v1/auth/signup", json!({ "email": email })).await
}

async fn verify(db: &PgPool, email: &str, code: &str) -> Res {
    let body = json!({ "email": email, "code": code });
    post(db, "/api/v1/auth/signup/verify", body).await
}

fn details(token: &str) -> Value {
    json!({
        "signup_token": token,
        "name": " Asha Example ",
        "phone": "9876511223",
        "password": "sunlight1",
        "terms_version": 1
    })
}

async fn complete(db: &PgPool, body: Value) -> Res {
    post(db, "/api/v1/auth/signup/complete", body).await
}

async fn proven(db: &PgPool, email: &str) -> String {
    assert_eq!(start(db, email).await.status, StatusCode::ACCEPTED);
    let res = verify(db, email, &last_code(email)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["expires_in"], 900);
    res.body["signup_token"].as_str().unwrap().to_owned()
}

async fn login(db: &PgPool, email: &str, password: &str) -> Res {
    let body = json!({ "email": email, "password": password, "client": "app" });
    post(db, "/api/v1/auth/login", body).await
}

async fn account(db: &PgPool, email: &str) -> Option<(String, Option<String>, bool, bool)> {
    sqlx::query_as(
        "SELECT name, phone, password_hash IS NOT NULL, email_verified_at IS NOT NULL
         FROM users WHERE email = $1",
    )
    .bind(email)
    .fetch_optional(db)
    .await
    .unwrap()
}

// What an attacker sends first: the request the old app sent, password and all.
async fn attack(db: &PgPool, email: &str) {
    post(
        db,
        "/api/v1/auth/signup",
        json!({"email": email, "name": "Mallory", "phone": "9000000000",
               "password": "attacker99", "terms_version": 1}),
    )
    .await;
    // A minute on, so the person gets a code of their own.
    sqlx::query("UPDATE signups SET created_at = now() - interval '61 seconds'")
        .execute(db)
        .await
        .unwrap();
}

// The person finishes; the attacker's password opens nothing.
async fn person_owns(db: &PgPool, email: &str) -> String {
    let token = proven(db, email).await;
    let res = complete(db, details(&token)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(
        account(db, email).await.unwrap(),
        ("Asha Example".into(), Some("9876511223".into()), true, true)
    );
    let attacker = login(db, email, "attacker99").await;
    assert_eq!(attacker.status, StatusCode::UNAUTHORIZED);
    assert_eq!(login(db, email, "sunlight1").await.status, StatusCode::OK);
    res.body["tokens"]["access_token"]
        .as_str()
        .unwrap()
        .to_owned()
}

#[sqlx::test]
async fn an_email_alone_creates_nothing(db: PgPool) {
    let email = "nothing@example.com";
    let res = start(&db, "  Nothing@Example.com ").await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    assert!(account(&db, email).await.is_none());
    let hash: Vec<u8> = sqlx::query_scalar("SELECT code_hash FROM signups WHERE email = $1")
        .bind(email)
        .fetch_one(&db)
        .await
        .unwrap();
    let code = last_code(email);
    assert_eq!(hash.len(), 32);
    assert!(
        !hash.windows(6).any(|w| w == code.as_bytes()),
        "an HMAC, not the code"
    );
}

#[sqlx::test]
async fn the_three_steps_make_an_account_and_log_it_in(db: PgPool) {
    let email = "three.steps@example.com";
    let access = person_owns(&db, email).await;
    let me = common::get(&db, "/api/v1/me", Some(&access)).await;
    assert_eq!(me.body["email"], email);
    assert_eq!(me.body["terms"]["accepted_version"], 1);
}

#[sqlx::test]
async fn attacker_first_then_the_person_signs_up(db: PgPool) {
    let email = "row.plain@example.com";
    attack(&db, email).await;
    assert!(
        account(&db, email).await.is_none(),
        "nothing of the attacker's is kept"
    );
    person_owns(&db, email).await;
}

#[sqlx::test]
async fn attacker_then_an_admin_adds_them_then_they_sign_up(db: PgPool) {
    let email = "row.installer@example.com";
    attack(&db, email).await;
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "admin.row3@example.com", "org_admin", None).await;
    let body = json!({"name": "Ravi As Typed", "email": email, "role": "worker"});
    let path = format!("/api/v1/orgs/{a}/members");
    assert_eq!(
        call(&db, "POST", &path, &admin, Some(body)).await.status,
        StatusCode::CREATED
    );
    let access = person_owns(&db, email).await;
    let me = common::get(&db, "/api/v1/me", Some(&access)).await;
    assert_eq!(me.body["memberships"][0]["role"], "worker");
}

#[sqlx::test]
async fn attacker_then_the_owner_registers_then_signs_up(db: PgPool) {
    let email = "row.owner@example.com";
    attack(&db, email).await;
    let res = post(
        &db,
        "/api/v1/org-registrations",
        json!({"legal_name": "Owner Solar", "business_type": "proprietorship",
               "gstin": "27AAPFU0939F1ZV", "address_line_1": "Plot 1", "city": "Pune",
               "pin_code": "411001", "owner_name": "Owner", "email": email,
               "phone": "9814000100", "terms_version": 1}),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);
    // That registration emailed them too; the code is the newest email after this.
    let access = person_owns(&db, email).await;
    let me = common::get(&db, "/api/v1/me", Some(&access)).await;
    assert_eq!(me.body["memberships"][0]["role"], "org_admin");
}

#[sqlx::test]
async fn attacker_then_the_person_uses_forgot_password(db: PgPool) {
    let email = "row.forgot@example.com";
    sqlx::query("INSERT INTO users (id, email, name) VALUES ($1, $2, 'Added By Admin')")
        .bind(uuid::Uuid::now_v7())
        .bind(email)
        .execute(&db)
        .await
        .unwrap();
    attack(&db, email).await;
    post(
        &db,
        "/api/v1/auth/password/forgot",
        json!({ "email": email }),
    )
    .await;
    let body = json!({"email": email, "code": last_code(email), "new_password": "moonlight44"});
    let res = post(&db, "/api/v1/auth/password/reset", body).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    assert_eq!(
        login(&db, email, "moonlight44").await.status,
        StatusCode::OK
    );
    assert_eq!(
        login(&db, email, "attacker99").await.status,
        StatusCode::UNAUTHORIZED
    );
}

#[sqlx::test]
async fn the_database_refuses_a_password_on_an_unproven_email(db: PgPool) {
    let res = sqlx::query(
        "INSERT INTO users (id, email, name, password_hash) VALUES ($1, 'u@example.com', 'U', 'x')",
    )
    .bind(uuid::Uuid::now_v7())
    .execute(&db)
    .await;
    assert!(
        res.unwrap_err()
            .to_string()
            .contains("users_password_needs_verified")
    );
}

#[sqlx::test]
async fn a_setup_token_works_once(db: PgPool) {
    let token = proven(&db, "token.once@example.com").await;
    assert_eq!(complete(&db, details(&token)).await.status, StatusCode::OK);
    let again = complete(&db, details(&token)).await;
    assert_eq!(again.status, StatusCode::BAD_REQUEST);
    assert_eq!(again.body["code"], "auth.signup_expired");
}

#[sqlx::test]
async fn a_setup_token_lasts_fifteen_minutes(db: PgPool) {
    let email = "token.old@example.com";
    let token = proven(&db, email).await;
    sqlx::query("UPDATE signups SET token_expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .unwrap();
    let res = complete(&db, details(&token)).await;
    assert_eq!(res.body["code"], "auth.signup_expired");
    assert!(account(&db, email).await.is_none());
}

#[sqlx::test]
async fn a_made_up_token_opens_nothing(db: PgPool) {
    let email = "token.fake@example.com";
    proven(&db, email).await;
    let res = complete(&db, details(&"0".repeat(64))).await;
    assert_eq!(res.body["code"], "auth.signup_expired");
    assert!(account(&db, email).await.is_none());
}

#[sqlx::test]
async fn someone_asking_again_doesnt_cancel_the_persons_token(db: PgPool) {
    let email = "token.spam@example.com";
    let token = proven(&db, email).await;
    sqlx::query("UPDATE signups SET created_at = now() - interval '61 seconds'")
        .execute(&db)
        .await
        .unwrap();
    start(&db, email).await;
    assert_eq!(complete(&db, details(&token)).await.status, StatusCode::OK);
}

#[sqlx::test]
async fn a_token_cant_replace_a_password_set_meanwhile(db: PgPool) {
    let email = "token.late@example.com";
    let token = proven(&db, email).await;
    verified_user(&db, email, "moonlight44").await;
    let res = complete(&db, details(&token)).await;
    assert_eq!(res.body["code"], "auth.signup_expired");
    assert_eq!(
        login(&db, email, "moonlight44").await.status,
        StatusCode::OK
    );
}

#[sqlx::test]
async fn bad_details_are_listed_and_dont_use_the_token(db: PgPool) {
    let token = proven(&db, "token.retry@example.com").await;
    let bad = json!({"signup_token": token, "name": " ", "phone": "123", "password": "x",
                     "terms_version": 1});
    let res = complete(&db, bad).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    let fields: Vec<&str> = res.body["errors"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["field"].as_str().unwrap())
        .collect();
    assert_eq!(fields, ["name", "phone", "password"]);

    let mut weak = details(&token);
    weak["password"] = json!("sunlight");
    assert_eq!(
        complete(&db, weak).await.body["code"],
        "auth.password_too_weak"
    );

    let mut no_terms = details(&token);
    no_terms["terms_version"] = json!(null);
    assert_eq!(complete(&db, no_terms).await.body["code"], "terms.required");

    let mut good = details(&token);
    good["phone"] = json!("");
    assert_eq!(complete(&db, good).await.status, StatusCode::OK);
    let saved = account(&db, "token.retry@example.com").await.unwrap();
    assert_eq!(saved.1, None, "a blank phone is no phone");
}

#[sqlx::test]
async fn a_bad_email_is_refused(db: PgPool) {
    for bad in ["nope", "", &format!("{}@example.com", "a".repeat(300))] {
        let res = start(&db, bad).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{bad}");
        assert_eq!(res.body["errors"][0]["field"], "email");
    }
}

/*
    QA-28: log in mustn't show who has an account or who was invited
*/
#[sqlx::test]
async fn login_answers_the_same_for_everyone_it_refuses(db: PgPool) {
    verified_user(&db, "qa28.verified@example.com", "sunlight1").await;
    sqlx::query("INSERT INTO users (id, email, name) VALUES ($1, 'qa28.invited@example.com', 'I')")
        .bind(uuid::Uuid::now_v7())
        .execute(&db)
        .await
        .unwrap();
    start(&db, "qa28.pending@example.com").await;
    let nobody = login(&db, "qa28.nobody@example.com", "whatever12").await;
    assert_eq!(nobody.status, StatusCode::UNAUTHORIZED);
    for who in ["verified", "invited", "pending"] {
        let res = login(&db, &format!("qa28.{who}@example.com"), "whatever12").await;
        assert_eq!(res.status, nobody.status, "{who}");
        assert_eq!(res.body, nobody.body, "{who}");
    }
}

#[sqlx::test]
async fn an_email_with_an_account_gets_a_notice_not_a_code(db: PgPool) {
    let email = "already.here@example.com";
    verified_user(&db, email, "sunlight1").await;
    assert_eq!(start(&db, email).await.status, StatusCode::ACCEPTED);
    let mail = emails_to(email).pop().unwrap();
    assert!(mail.subject.contains("already have"), "{}", mail.subject);
    assert!(
        !mail.body.chars().any(|c| c.is_ascii_digit()),
        "no code in it"
    );
}

/*
    Code guessing is bounded per email, not only per IP: 3 code emails an
    hour, 5 tries each
*/
#[sqlx::test]
async fn code_emails_are_limited_per_email_the_same_for_anyone(db: PgPool) {
    verified_user(&db, "limit.known@example.com", "sunlight1").await;
    let mut state = common::state(&db);
    state.limits = Arc::new(Limiter::new());
    let pool = state.db.clone();
    let router = backend::app(state);
    let mut ip = 0;
    for path in ["/api/v1/auth/signup", "/api/v1/auth/password/forgot"] {
        for email in ["limit.known@example.com", "limit.nobody@example.com"] {
            let mut seen = Vec::new();
            for _ in 0..4 {
                ip += 1;
                let req = Request::post(path)
                    .header("content-type", "application/json")
                    .header("x-real-ip", format!("10.0.1.{ip}"))
                    .body(Body::from(json!({ "email": email }).to_string()))
                    .unwrap();
                seen.push(router.clone().oneshot(req).await.unwrap().status().as_u16());
            }
            assert_eq!(seen, [202, 202, 202, 429], "{path} {email}");
        }
    }
    drop(router);
    pool.close().await;
}

/*
    The migration, on what the old flow left: a squatter's password on an
    unverified account is cleared, a verified account is untouched
*/
#[sqlx::test(migrations = false)]
async fn the_migration_clears_what_squatters_left(db: PgPool) {
    const THIS: &str = "20261122000002_code_first_signup.sql";
    let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("migrations");
    let mut files: Vec<String> = std::fs::read_dir(&dir)
        .unwrap()
        .map(|f| f.unwrap().file_name().into_string().unwrap())
        .filter(|f| f.ends_with(".sql") && f.as_str() <= THIS)
        .collect();
    files.sort();
    let last = files.pop().unwrap();
    assert_eq!(last, THIS);
    let run = async |file: &str| {
        let sql = std::fs::read_to_string(dir.join(file)).unwrap();
        sqlx::raw_sql(sqlx::AssertSqlSafe(sql))
            .execute(&db)
            .await
            .unwrap();
    };
    for file in &files {
        run(file).await;
    }
    sqlx::query(
        "INSERT INTO users (id, email, name, phone, password_hash, email_verified_at) VALUES
           (gen_random_uuid(), 'squatted@example.com', 'Mallory', '9000000000', 'theirs', NULL),
           (gen_random_uuid(), 'real@example.com', 'Real', '9814000001', 'mine', now())",
    )
    .execute(&db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO agreements (id, user_id, document, version, source)
         SELECT gen_random_uuid(), id, 'terms', 1, 'signup' FROM users",
    )
    .execute(&db)
    .await
    .unwrap();
    run(&last).await;

    let squatted = account(&db, "squatted@example.com").await.unwrap();
    assert_eq!(squatted, ("squatted".into(), None, false, false));
    let real = account(&db, "real@example.com").await.unwrap();
    assert_eq!(real, ("Real".into(), Some("9814000001".into()), true, true));
    let agreed: Vec<String> =
        sqlx::query_scalar("SELECT u.email FROM agreements a JOIN users u ON u.id = a.user_id")
            .fetch_all(&db)
            .await
            .unwrap();
    assert_eq!(agreed, ["real@example.com"]);
}
