//! A worker's or agent's own expenses (phase 8, F7): log, list, one, and
//! a new receipt for one sent back.

mod common;

use axum::http::StatusCode;
use chrono::{Duration, FixedOffset, Utc};
use common::{Res, call, call_with, member, org, r2_put};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

// Today in India, as the server counts it.
fn today() -> chrono::NaiveDate {
    Utc::now()
        .with_timezone(&FixedOffset::east_opt(5 * 3600 + 30 * 60).unwrap())
        .date_naive()
}

// Solar A with Ravi, a worker; his token.
async fn setup(db: &PgPool) -> (Uuid, String) {
    let a = org(db, "Solar A", "active").await;
    (a, member(db, a, "ravi@example.com", "worker", None).await)
}

// A receipt the app uploaded to R2 (the stand-in), ready to attach.
async fn receipt(db: &PgPool, org: Uuid, token: &str) -> String {
    let res = call(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/uploads"),
        token,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 2000, "purpose": "receipt"})),
    )
    .await;
    let id = res.body["upload_id"].as_str().unwrap().to_owned();
    r2_put(&format!("orgs/{org}/receipt/{id}"), 2000);
    id
}

async fn log(db: &PgPool, org: Uuid, token: &str, body: Value) -> Res {
    call_with(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/expenses"),
        token,
        Some(body),
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await
}

fn diesel() -> Value {
    json!({"amount": 124_000, "category": "fuel", "note": "Diesel for site van",
           "spent_on": today().to_string()})
}

#[sqlx::test]
async fn logs_an_expense_with_its_receipt(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let up = receipt(&db, a, &ravi).await;
    let mut body = diesel();
    body["receipt_upload_id"] = json!(up);
    let res = log(&db, a, &ravi, body).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let e = &res.body;
    assert_eq!(e["reference"], "EXP-0001");
    assert_eq!(e["amount"], 124_000);
    assert_eq!(e["status"], "in_review");
    assert_eq!(e["spent_on"], today().to_string());
    assert_eq!(e["has_receipt"], true);
    let url = e["receipt_url"].as_str().unwrap();
    assert!(url.contains(&format!("/orgs/{a}/receipt/{up}?")), "{url}");

    // The next one takes the next number.
    let res = log(&db, a, &ravi, diesel()).await;
    assert_eq!(res.body["reference"], "EXP-0002");
    assert_eq!(res.body["has_receipt"], false);
    assert!(res.body.get("receipt_url").is_none());
}

#[sqlx::test]
async fn each_company_numbers_its_own(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let b = org(&db, "Solar B", "active").await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    log(&db, a, &ravi, diesel()).await;
    log(&db, a, &ravi, diesel()).await;
    assert_eq!(
        log(&db, b, &ravi, diesel()).await.body["reference"],
        "EXP-0001"
    );
}

#[sqlx::test]
async fn links_only_the_callers_own_task(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    member(&db, a, "neha@example.com", "worker", None).await;
    let customer = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, address)
         VALUES ($1, $2, 'SC-1', 'Ramesh Sahoo', 'Mohali')",
    )
    .bind(customer)
    .bind(a)
    .execute(&db)
    .await
    .unwrap();
    let task = |email: &'static str| {
        let db = db.clone();
        async move {
            let id = Uuid::now_v7();
            sqlx::query(
                "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index,
                                    assignee_id, due_at)
                 SELECT $1, $2, $3, 'TSK-' || $1::text, 'Panel installation', 1, id, now()
                 FROM users WHERE email = $4",
            )
            .bind(id)
            .bind(a)
            .bind(customer)
            .bind(email)
            .execute(&db)
            .await
            .unwrap();
            id
        }
    };
    let mine = task("ravi@example.com").await;
    let nehas = task("neha@example.com").await;

    let mut body = diesel();
    body["task_id"] = json!(mine);
    let res = log(&db, a, &ravi, body.clone()).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(
        res.body["task"],
        json!({"id": mine, "title": "Panel installation", "customer_name": "Ramesh Sahoo"})
    );

    body["task_id"] = json!(nehas);
    let res = log(&db, a, &ravi, body).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "task_id");
}

#[sqlx::test]
async fn refuses_bad_amounts_days_and_notes(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let long = "x".repeat(201);
    for (field, value) in [
        ("amount", json!(0)),
        ("amount", json!(100_000_001)),
        ("spent_on", json!((today() + Duration::days(1)).to_string())),
        (
            "spent_on",
            json!((today() - Duration::days(400)).to_string()),
        ),
        ("note", json!(long)),
    ] {
        let mut body = diesel();
        body[field] = value;
        let res = log(&db, a, &ravi, body).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{field}");
        assert_eq!(res.body["errors"][0]["field"], field);
    }
    // Nothing was logged, and no number was used up.
    assert_eq!(
        log(&db, a, &ravi, diesel()).await.body["reference"],
        "EXP-0001"
    );
}

#[sqlx::test]
async fn a_receipt_that_never_reached_r2_is_refused(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &ravi,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 2000, "purpose": "receipt"})),
    )
    .await;
    let mut body = diesel();
    body["receipt_upload_id"] = res.body["upload_id"].clone();
    let res = log(&db, a, &ravi, body).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "receipt_upload_id");
    let logged: i64 = sqlx::query_scalar("SELECT count(*) FROM expenses")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(logged, 0);
}

#[sqlx::test]
async fn a_retry_logs_it_once(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let key = Uuid::now_v7().to_string();
    let path = format!("/api/v1/orgs/{a}/expenses");
    let headers = [("idempotency-key", key.as_str())];
    let first = call_with(&db, "POST", &path, &ravi, Some(diesel()), &headers).await;
    let again = call_with(&db, "POST", &path, &ravi, Some(diesel()), &headers).await;
    assert_eq!(again.status, StatusCode::CREATED);
    assert_eq!(again.body["id"], first.body["id"]);
    let logged: i64 = sqlx::query_scalar("SELECT count(*) FROM expenses")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(logged, 1);
}

#[sqlx::test]
async fn each_person_sees_only_their_own(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    let meena = member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let first = log(&db, a, &ravi, diesel()).await.body["id"].clone();
    let second = log(&db, a, &ravi, diesel()).await.body["id"].clone();
    let hers = log(&db, a, &meena, diesel()).await;
    assert_eq!(hers.status, StatusCode::CREATED, "agents log expenses too");

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/expenses"),
        &ravi,
        None,
    )
    .await;
    let ids: Vec<_> = res.body["items"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["id"].clone())
        .collect();
    assert_eq!(ids, [second, first], "newest first, only his");

    let res = call(
        &db,
        "GET",
        &format!(
            "/api/v1/orgs/{a}/expenses/{}",
            hers.body["id"].as_str().unwrap()
        ),
        &ravi,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
}

#[sqlx::test]
async fn customers_have_no_expenses(db: PgPool) {
    let (a, _) = setup(&db).await;
    let customer = member(&db, a, "rajinder@example.com", "customer", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/expenses"),
        &customer,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "org.role_not_allowed");
}

#[sqlx::test]
async fn a_returned_expense_takes_a_new_receipt(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    member(&db, a, "dev@example.com", "org_admin", None).await;
    let first = receipt(&db, a, &ravi).await;
    let mut body = diesel();
    body["receipt_upload_id"] = json!(first);
    let id = log(&db, a, &ravi, body).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let path = format!("/api/v1/orgs/{a}/expenses/{id}/receipt");

    // Still with the admin: nothing to fix yet.
    let second = receipt(&db, a, &ravi).await;
    let res = call(&db, "PUT", &path, &ravi, Some(json!({"upload_id": second}))).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "expense.locked");

    // The admin sends it back (the website's job; SQL here).
    sqlx::query(
        "UPDATE expenses SET status = 'needs_fix', admin_note = 'Receipt is unreadable.',
                             decided_by = (SELECT id FROM users WHERE email = 'dev@example.com')
         WHERE id = $1::uuid",
    )
    .bind(&id)
    .execute(&db)
    .await
    .unwrap();
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/expenses/{id}"),
        &ravi,
        None,
    )
    .await;
    assert_eq!(res.body["status"], "needs_fix");
    assert_eq!(res.body["admin_note"], "Receipt is unreadable.");
    assert_eq!(res.body["admin_name"], "Asha Example");

    let res = call(
        &db,
        "PUT",
        &path,
        &ravi,
        Some(json!({"upload_id": second, "note": "Clearer photo."})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "in_review");
    assert!(res.body.get("admin_note").is_none(), "fixed now");
    assert!(res.body["receipt_url"].as_str().unwrap().contains(&second));
    let fix_note: Option<String> =
        sqlx::query_scalar("SELECT fix_note FROM expenses WHERE id = $1::uuid")
            .bind(&id)
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(fix_note.as_deref(), Some("Clearer photo."));
}

#[sqlx::test]
async fn the_home_counts_expenses_with_the_admin(db: PgPool) {
    let (a, ravi) = setup(&db).await;
    log(&db, a, &ravi, diesel()).await;
    log(&db, a, &ravi, diesel()).await;
    sqlx::query("UPDATE expenses SET status = 'approved' WHERE reference = 'EXP-0001'")
        .execute(&db)
        .await
        .unwrap();
    let res = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &ravi, None).await;
    assert_eq!(res.body["tiles"][1]["label"], "Expenses");
    assert_eq!(res.body["tiles"][1]["value"], "1");
}
