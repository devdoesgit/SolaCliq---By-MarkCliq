//! A person's notifications in one company (phase 7).

mod common;

use axum::http::StatusCode;
use common::{call, member, org};
use sqlx::PgPool;
use uuid::Uuid;

// A notification for `email`, in `org_id` (None: their own feed).
async fn notify(db: &PgPool, email: &str, org_id: Option<Uuid>, kind: &str, title: &str) {
    sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
         SELECT $1, id, $2, $3, $4, 'Body' FROM users WHERE email = $5",
    )
    .bind(Uuid::now_v7())
    .bind(org_id)
    .bind(kind)
    .bind(title)
    .bind(email)
    .execute(db)
    .await
    .unwrap();
}

fn titles(body: &serde_json::Value) -> Vec<String> {
    body["items"]
        .as_array()
        .unwrap()
        .iter()
        .map(|n| n["title"].as_str().unwrap().to_owned())
        .collect()
}

#[sqlx::test]
async fn a_member_sees_only_their_own_in_that_company(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    member(&db, a, "meena@example.com", "agent", Some("commission")).await;

    notify(
        &db,
        "ravi@example.com",
        Some(a),
        "task_assigned",
        "Mine in A",
    )
    .await;
    notify(
        &db,
        "ravi@example.com",
        Some(b),
        "task_assigned",
        "Mine in B",
    )
    .await;
    notify(&db, "ravi@example.com", None, "quote_shared", "My own").await;
    notify(
        &db,
        "meena@example.com",
        Some(a),
        "kyc_returned",
        "Meena's in A",
    )
    .await;

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/notifications"),
        &ravi,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(titles(&res.body), ["Mine in A"]);
    assert_eq!(res.body["unread_count"], 1);
    assert_eq!(res.body["items"][0]["kind"], "task_assigned");
}

#[sqlx::test]
async fn read_all_marks_only_that_company(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    notify(&db, "ravi@example.com", Some(a), "task_assigned", "In A").await;
    notify(&db, "ravi@example.com", Some(b), "task_assigned", "In B").await;
    notify(&db, "ravi@example.com", None, "guide", "Own").await;

    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/notifications/read"),
        &ravi,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);

    let unread = |path: String| {
        let (db, ravi) = (db.clone(), ravi.clone());
        async move { call(&db, "GET", &path, &ravi, None).await.body["unread_count"].clone() }
    };
    assert_eq!(unread(format!("/api/v1/orgs/{a}/notifications")).await, 0);
    assert_eq!(unread(format!("/api/v1/orgs/{b}/notifications")).await, 1);
    assert_eq!(unread("/api/v1/me/notifications".into()).await, 1);
}

#[sqlx::test]
async fn every_contract_kind_reads_back(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let kinds = [
        "task_assigned",
        "task_approved",
        "task_returned",
        "task_cancelled",
        "task_rescheduled",
        "expense_approved",
        "expense_returned",
        "expense_paid",
        "kyc_returned",
        "kyc_submitted",
        "kyc_approved",
        "install_started",
        "commission_changed",
        "commission_payable",
        "commission_paid",
        "visit_booked",
        "payment_due",
        "documents_verified",
    ];
    for kind in kinds {
        notify(&db, "ravi@example.com", Some(a), kind, kind).await;
    }
    let path = format!("/api/v1/orgs/{a}/notifications?limit=100");
    let res = call(&db, "GET", &path, &ravi, None).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["items"].as_array().unwrap().len(), kinds.len());
}

#[sqlx::test]
async fn outsiders_and_inactive_companies_are_refused(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let pending = org(&db, "Solar P", "pending").await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    let outsider = member(&db, pending, "asha@example.com", "worker", None).await;

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/notifications"),
        &outsider,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{pending}/notifications"),
        &outsider,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/notifications/read"),
        &outsider,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
}
