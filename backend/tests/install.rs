//! A customer's own install (phase 10): stages, next visit, payment plan,
//! claiming a payment, and the customer's home.

mod common;

use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{Res, call, call_with, member, org};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

// Solar A; Rajinder (customer) with a 5 kW install at stage `stage`.
struct Setup {
    org: Uuid,
    customer: Uuid,
    install: Uuid,
    token: String,
    // The three payments, in plan order.
    payments: Vec<Uuid>,
}

async fn setup(db: &PgPool, stage: i32, statuses: [&str; 3]) -> Setup {
    let a = org(db, "Solar A", "active").await;
    let token = member(db, a, "rajinder@example.com", "customer", None).await;
    let customer = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, address, city, system_kw,
                                user_id, kyc_status, stage_index)
         SELECT $1, $2, 'SC-1', 'Rajinder Kaur', '9814000201', 'House 12', 'Mohali', 5,
                id, 'approved', $3
         FROM users WHERE email = 'rajinder@example.com'",
    )
    .bind(customer)
    .bind(a)
    .bind(stage)
    .execute(db)
    .await
    .unwrap();
    let install = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO installs (id, org_id, customer_id, total, subsidy) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(install)
    .bind(a)
    .bind(customer)
    .bind(28_500_000_i64)
    .bind(backend::routes::install::pm_surya_ghar(5.0))
    .execute(db)
    .await
    .unwrap();
    let mut payments = Vec::new();
    for (position, ((label, detail, amount), status)) in
        backend::routes::install::default_plan(28_500_000)
            .into_iter()
            .zip(statuses)
            .enumerate()
    {
        let id = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO install_payments (id, org_id, install_id, position, label, detail,
                                           amount, due_on, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7, current_date + 7, $8::payment_status)",
        )
        .bind(id)
        .bind(a)
        .bind(install)
        .bind(position as i32)
        .bind(label)
        .bind(detail)
        .bind(amount)
        .bind(status)
        .execute(db)
        .await
        .unwrap();
        payments.push(id);
    }
    Setup {
        org: a,
        customer,
        install,
        token,
        payments,
    }
}

async fn mine(db: &PgPool, s: &Setup) -> Res {
    call(
        db,
        "GET",
        &format!("/api/v1/orgs/{}/my-install", s.org),
        &s.token,
        None,
    )
    .await
}

async fn claim(db: &PgPool, s: &Setup, payment: Uuid, key: &str) -> Res {
    call_with(
        db,
        "POST",
        &format!("/api/v1/orgs/{}/my-install/payments/{payment}/claim", s.org),
        &s.token,
        Some(json!({"method": "upi"})),
        &[("idempotency-key", key)],
    )
    .await
}

#[sqlx::test]
async fn a_customer_follows_their_install(db: PgPool) {
    let s = setup(&db, 2, ["paid", "due", "later"]).await;
    sqlx::query("UPDATE orgs SET upi_id = 'solara@okhdfc' WHERE id = $1")
        .bind(s.org)
        .execute(&db)
        .await
        .unwrap();
    // The next visit: Ravi, tomorrow.
    member(&db, s.org, "ravi@example.com", "worker", None).await;
    sqlx::query("UPDATE users SET phone = '9814000301' WHERE email = 'ravi@example.com'")
        .execute(&db)
        .await
        .unwrap();
    sqlx::query(
        "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index, assignee_id, due_at)
         SELECT $1, $2, $3, 'TSK-1', 'Structure', 2, id, $4 FROM users WHERE email = 'ravi@example.com'",
    )
    .bind(Uuid::now_v7())
    .bind(s.org)
    .bind(s.customer)
    .bind(Utc::now() + Duration::days(1))
    .execute(&db)
    .await
    .unwrap();

    let res = mine(&db, &s).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let i = &res.body;
    assert_eq!(i["stage_index"], 2);
    assert_eq!(i["total"], 28_500_000);
    assert_eq!(i["subsidy"], 7_800_000);
    assert_eq!(i["place"], "Mohali");
    let statuses: Vec<_> = i["stages"]
        .as_array()
        .unwrap()
        .iter()
        .map(|s| s["status"].as_str().unwrap())
        .collect();
    assert_eq!(
        statuses,
        [
            "done", "next", "upcoming", "upcoming", "upcoming", "upcoming", "upcoming"
        ]
    );
    assert!(
        i["stages"][1]["detail"]
            .as_str()
            .unwrap()
            .ends_with("· Asha"),
        "test accounts are named Asha Example"
    );
    assert_eq!(i["next_visit"]["title"], "Structure");
    assert_eq!(i["next_visit"]["person"]["phone"], "9814000301");
    assert_eq!(i["payments"][0]["status"], "paid");
    assert_eq!(i["payments"][1]["status"], "due");
    assert!(
        i["payments"][1]["detail"]
            .as_str()
            .unwrap()
            .starts_with("Due ")
    );
    assert_eq!(i["payments"][2]["detail"], "After net meter");
    let upi = i["upi_uri"].as_str().unwrap();
    assert!(
        upi.starts_with("upi://pay?pa=solara@okhdfc&pn=Solar%20A&am=171000.00&cu=INR"),
        "{upi}"
    );
}

#[sqlx::test]
async fn before_the_install_is_set_up_it_says_so(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let token = member(&db, a, "walkin@example.com", "customer", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-install"),
        &token,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
    assert_eq!(res.body["code"], "install.not_started");
    let home = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &token, None).await;
    assert_eq!(
        home.body["headline"]["detail"],
        "Your install is being set up"
    );
}

#[sqlx::test]
async fn a_due_payment_is_claimed_once(db: PgPool) {
    let s = setup(&db, 2, ["paid", "due", "later"]).await;
    let key = Uuid::now_v7().to_string();
    let res = claim(&db, &s, s.payments[1], &key).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["payments"][1]["status"], "claimed");
    assert!(
        res.body["payments"][1]["detail"]
            .as_str()
            .unwrap()
            .ends_with("the company confirms")
    );
    assert!(res.body.get("upi_uri").is_none(), "nothing due now");
    let method: String =
        sqlx::query_scalar("SELECT claimed_method::text FROM install_payments WHERE id = $1")
            .bind(s.payments[1])
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(method, "upi");

    // A lost response, retried: the same answer, not a 409.
    let again = claim(&db, &s, s.payments[1], &key).await;
    assert_eq!(again.status, StatusCode::OK);

    // A new claim of it, or of a paid or later payment: not due.
    for payment in [s.payments[1], s.payments[0], s.payments[2]] {
        let res = claim(&db, &s, payment, &Uuid::now_v7().to_string()).await;
        assert_eq!(res.status, StatusCode::CONFLICT);
        assert_eq!(res.body["code"], "payment.not_due");
    }
}

#[sqlx::test]
async fn only_the_customer_sees_and_claims_their_own(db: PgPool) {
    let s = setup(&db, 2, ["due", "later", "later"]).await;
    // Another customer of the same company.
    let other = member(&db, s.org, "other@example.com", "customer", None).await;
    let res = call_with(
        &db,
        "POST",
        &format!(
            "/api/v1/orgs/{}/my-install/payments/{}/claim",
            s.org, s.payments[0]
        ),
        &other,
        Some(json!({"method": "bank_transfer"})),
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/my-install", s.org),
        &other,
        None,
    )
    .await;
    assert_eq!(res.body["code"], "install.not_started", "not Rajinder's");

    // Workers and agents have no install here.
    let ravi = member(&db, s.org, "ravi@example.com", "worker", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/my-install", s.org),
        &ravi,
        None,
    )
    .await;
    assert_eq!(res.body["code"], "org.role_not_allowed");

    // In another company, Rajinder has no install.
    let b = org(&db, "Solar B", "active").await;
    common::join(&db, b, "rajinder@example.com", "customer", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{b}/my-install"),
        &s.token,
        None,
    )
    .await;
    assert_eq!(res.body["code"], "install.not_started");
}

#[sqlx::test]
async fn without_a_upi_id_there_is_no_upi_link(db: PgPool) {
    let s = setup(&db, 1, ["due", "later", "later"]).await;
    let res = mine(&db, &s).await;
    assert!(res.body.get("upi_uri").is_none());
    assert_eq!(res.body["payments"][0]["status"], "due");
}

#[sqlx::test]
async fn a_handed_over_install_is_all_done(db: PgPool) {
    let s = setup(&db, 7, ["paid", "paid", "paid"]).await;
    sqlx::query("UPDATE installs SET handed_over_on = '2026-11-10' WHERE id = $1")
        .bind(s.install)
        .execute(&db)
        .await
        .unwrap();
    let res = mine(&db, &s).await;
    assert_eq!(res.body["handed_over_on"], "2026-11-10");
    assert!(
        res.body["stages"]
            .as_array()
            .unwrap()
            .iter()
            .all(|s| s["status"] == "done")
    );
    assert_eq!(res.body["stages"][6]["detail"], "10 Nov");
    let home = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/home", s.org),
        &s.token,
        None,
    )
    .await;
    assert_eq!(home.body["headline"]["value"], "7");
    assert_eq!(home.body["headline"]["detail"], "Handed over on 10 Nov");
    assert_eq!(home.body["tiles"][1]["footer"], "nothing due");
}

#[sqlx::test]
async fn the_customers_home_shows_the_install(db: PgPool) {
    let s = setup(&db, 2, ["paid", "due", "later"]).await;
    let home = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/home", s.org),
        &s.token,
        None,
    )
    .await;
    let h = &home.body;
    assert_eq!(h["title"], "5 kW · Mohali");
    assert_eq!(h["headline"]["value"], "2");
    assert_eq!(h["headline"]["detail"], "Structure is next");
    assert_eq!(h["tiles"][1]["label"], "On installation");
    assert_eq!(h["tiles"][1]["value"], "₹1,71,000");
    let tones: Vec<_> = h["progress"]["segments"]
        .as_array()
        .unwrap()
        .iter()
        .map(|s| s["tone"].as_str().unwrap())
        .collect();
    assert_eq!(tones[..3], ["success", "live", "empty"]);
}
