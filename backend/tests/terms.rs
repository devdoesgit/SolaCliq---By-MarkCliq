//! Agreeing to the terms (F16): sign-up, company registration, `/me` and
//! `POST /me/terms` record who agreed to which version, when and from
//! where. Needs `make db` running.

mod common;

use axum::{body::Body, http::Request, http::StatusCode};
use backend::terms::TERMS_VERSION;
use common::{call, get, post, token, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn signup_body(email: &str, terms_version: Option<i32>) -> Value {
    let mut body = json!({ "name": "Asha Example", "email": email, "password": "sunlight1" });
    if let Some(v) = terms_version {
        body["terms_version"] = json!(v);
    }
    body
}

fn registration(email: &str, terms_version: Option<i32>) -> Value {
    let mut body = json!({
        "legal_name": "Example Solar Private Limited",
        "business_type": "private_limited",
        "gstin": "27aapfu0939f1zv",
        "address_line_1": "Plot 4, MIDC",
        "city": "Pune",
        "pin_code": "411001",
        "owner_name": "Dev Owner",
        "email": email,
        "phone": "98140 22671",
    });
    if let Some(v) = terms_version {
        body["terms_version"] = json!(v);
    }
    body
}

// POST as if through Caddy, which sets X-Real-IP to the client's address.
async fn post_from(db: &PgPool, path: &str, ip: &str, body: Value) -> common::Res {
    let req = Request::post(path)
        .header("content-type", "application/json")
        .header("x-real-ip", ip)
        .body(Body::from(body.to_string()))
        .unwrap();
    common::send(db, req).await
}

// (document, org_id, version, source, ip) of each of a person's agreements.
type Row = (String, Option<Uuid>, i32, String, Option<String>);

async fn agreements(db: &PgPool, email: &str) -> Vec<Row> {
    sqlx::query_as(
        "SELECT a.document::text, a.org_id, a.version, a.source::text, host(a.ip)
         FROM agreements a JOIN users u ON u.id = a.user_id
         WHERE u.email = $1
         ORDER BY a.accepted_at, a.document::text",
    )
    .bind(email)
    .fetch_all(db)
    .await
    .unwrap()
}

async fn user_count(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM users")
        .fetch_one(db)
        .await
        .unwrap()
}

#[sqlx::test]
async fn signup_records_the_agreement(db: PgPool) {
    let res = post_from(
        &db,
        "/api/v1/auth/signup",
        "49.36.10.20",
        signup_body("asha@example.com", Some(TERMS_VERSION)),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);

    assert_eq!(
        agreements(&db, "asha@example.com").await,
        vec![(
            "terms".into(),
            None,
            TERMS_VERSION,
            "signup".into(),
            Some("49.36.10.20".into())
        )]
    );
}

#[sqlx::test]
async fn signup_without_agreeing_makes_no_account(db: PgPool) {
    for version in [None, Some(0), Some(TERMS_VERSION + 1)] {
        let res = post(
            &db,
            "/api/v1/auth/signup",
            signup_body("asha@example.com", version),
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{version:?}");
        assert_eq!(res.body["code"], "terms.required");
        assert_eq!(res.body["errors"][0]["field"], "terms_version");
    }
    assert_eq!(user_count(&db).await, 0);
}

#[sqlx::test]
async fn signup_on_an_existing_email_agrees_nothing_for_it(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    sqlx::query("DELETE FROM agreements")
        .execute(&db)
        .await
        .unwrap();

    // Someone else signing up with Asha's email can't agree for her.
    let res = post(
        &db,
        "/api/v1/auth/signup",
        signup_body("asha@example.com", Some(TERMS_VERSION)),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    assert!(agreements(&db, "asha@example.com").await.is_empty());
}

#[sqlx::test]
async fn registration_records_the_company_terms_and_the_owners(db: PgPool) {
    let res = post_from(
        &db,
        "/api/v1/org-registrations",
        "103.21.4.5",
        registration("dev.owner@example.com", Some(TERMS_VERSION)),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);
    let org: Uuid = sqlx::query_scalar("SELECT id FROM orgs")
        .fetch_one(&db)
        .await
        .unwrap();

    let ip = Some("103.21.4.5".to_owned());
    assert_eq!(
        agreements(&db, "dev.owner@example.com").await,
        vec![
            (
                "company_terms".into(),
                Some(org),
                TERMS_VERSION,
                "org_registration".into(),
                ip.clone()
            ),
            (
                "terms".into(),
                None,
                TERMS_VERSION,
                "org_registration".into(),
                ip
            ),
        ]
    );
}

#[sqlx::test]
async fn registration_by_an_existing_account_records_only_the_company_terms(db: PgPool) {
    verified_user(&db, "dev.owner@example.com", "sunlight1").await;
    sqlx::query("DELETE FROM agreements")
        .execute(&db)
        .await
        .unwrap();

    let res = post(
        &db,
        "/api/v1/org-registrations",
        registration("dev.owner@example.com", Some(TERMS_VERSION)),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);
    let docs: Vec<String> = agreements(&db, "dev.owner@example.com")
        .await
        .into_iter()
        .map(|r| r.0)
        .collect();
    assert_eq!(docs, ["company_terms"]);
}

#[sqlx::test]
async fn registration_without_agreeing_saves_nothing(db: PgPool) {
    let res = post(
        &db,
        "/api/v1/org-registrations",
        registration("dev.owner@example.com", None),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "terms.required");
    let orgs: i64 = sqlx::query_scalar("SELECT count(*) FROM orgs")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!((orgs, user_count(&db).await), (0, 0));
}

#[sqlx::test]
async fn an_account_made_for_someone_agrees_in_the_app(db: PgPool) {
    // An account someone else made: it has never agreed.
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    sqlx::query("DELETE FROM agreements")
        .execute(&db)
        .await
        .unwrap();
    let ravi = token(&db, "ravi@example.com").await;

    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    assert_eq!(
        me.body["terms"],
        json!({ "current_version": TERMS_VERSION })
    );

    // Only the version in force.
    let old = call(
        &db,
        "POST",
        "/api/v1/me/terms",
        &ravi,
        Some(json!({ "version": TERMS_VERSION + 1 })),
    )
    .await;
    assert_eq!(old.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(old.body["code"], "terms.required");

    let ok = call(
        &db,
        "POST",
        "/api/v1/me/terms",
        &ravi,
        Some(json!({ "version": TERMS_VERSION })),
    )
    .await;
    assert_eq!(ok.status, StatusCode::NO_CONTENT, "{}", ok.body);

    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    assert_eq!(
        me.body["terms"],
        json!({ "accepted_version": TERMS_VERSION, "current_version": TERMS_VERSION })
    );
    let rows = agreements(&db, "ravi@example.com").await;
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].3, "app");
}

#[sqlx::test]
async fn login_returns_the_terms_too(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    let res = post(
        &db,
        "/api/v1/auth/login",
        json!({ "email": "asha@example.com", "password": "sunlight1", "client": "app" }),
    )
    .await;
    assert_eq!(
        res.body["user"]["terms"],
        json!({ "accepted_version": TERMS_VERSION, "current_version": TERMS_VERSION })
    );
}

#[sqlx::test]
async fn agreeing_needs_a_login(db: PgPool) {
    let res = post(&db, "/api/v1/me/terms", json!({ "version": TERMS_VERSION })).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}

#[sqlx::test]
async fn the_api_can_never_edit_an_agreement(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    // The API's own restricted login (solacliq_api).
    let api = common::app_db(&db);
    let err = sqlx::query("UPDATE agreements SET version = 99")
        .execute(&api)
        .await
        .unwrap_err();
    assert!(err.to_string().contains("permission denied"), "{err}");
    api.close().await;
}
