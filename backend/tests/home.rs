//! Each role's home (phase 7).

mod common;

use axum::http::StatusCode;
use common::{call, member, org};
use serde_json::Value;
use sqlx::PgPool;

async fn home(db: &PgPool, org: uuid::Uuid, token: &str) -> Value {
    let res = call(db, "GET", &format!("/api/v1/orgs/{org}/home"), token, None).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body
}

fn actions(home: &Value) -> Vec<String> {
    home["tiles"]
        .as_array()
        .unwrap()
        .iter()
        .map(|t| t["action"].as_str().unwrap().to_owned())
        .collect()
}

#[sqlx::test]
async fn each_role_gets_its_home(db: PgPool) {
    let a = org(&db, "Example Solar", "active").await;
    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let commission = member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let salary = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let customer = member(&db, a, "rajinder@example.com", "customer", None).await;

    let w = home(&db, a, &worker).await;
    assert!(w["title"].as_str().unwrap().ends_with("'s day"));
    assert_eq!(w["week"].as_array().unwrap().len(), 7);
    assert_eq!(actions(&w), ["to_submit", "expenses"]);
    assert_eq!(w["list"]["title"], "Up next");

    assert_eq!(
        actions(&home(&db, a, &commission).await),
        ["fix", "earnings"]
    );
    assert_eq!(actions(&home(&db, a, &salary).await), ["fix", "review"]);

    let c = home(&db, a, &customer).await;
    assert_eq!(c["eyebrow"], "Your solar");
    assert_eq!(c["progress"]["segments"].as_array().unwrap().len(), 7);
    assert_eq!(actions(&c), ["track", "payments"]);
    assert!(c.get("week").is_none(), "only a worker's home has a week");
    assert_eq!(
        c["progress"]["stages"],
        serde_json::json!(["Site survey", "Handover"])
    );
}

#[sqlx::test]
async fn a_customers_bar_uses_the_companys_own_stage_names(db: PgPool) {
    let a = org(&db, "Example Solar", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let customer = member(&db, a, "rajinder@example.com", "customer", None).await;
    for (index, name) in [(1, "Roof check"), (7, "Switch-on")] {
        let res = call(
            &db,
            "PUT",
            &format!("/api/v1/orgs/{a}/admin/stages/{index}"),
            &admin,
            Some(serde_json::json!({"name": name, "checklist": [], "photos": []})),
        )
        .await;
        assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    }
    let c = home(&db, a, &customer).await;
    assert_eq!(
        c["progress"]["stages"],
        serde_json::json!(["Roof check", "Switch-on"])
    );
}

#[sqlx::test]
async fn the_bell_counts_this_company_only(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    for org_id in [Some(a), Some(a), Some(b), None] {
        sqlx::query(
            "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
             SELECT $1, id, $2, 'task_assigned', 'T', 'B' FROM users WHERE email = 'ravi@example.com'",
        )
        .bind(uuid::Uuid::now_v7())
        .bind(org_id)
        .execute(&db)
        .await
        .unwrap();
    }
    assert_eq!(home(&db, a, &ravi).await["unread_notifications"], 2);
    assert_eq!(home(&db, b, &ravi).await["unread_notifications"], 1);
}

#[sqlx::test]
async fn outsiders_and_inactive_companies_get_no_home(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let pending = org(&db, "Solar P", "pending").await;
    let outsider = member(&db, pending, "asha@example.com", "worker", None).await;
    for path in [
        format!("/api/v1/orgs/{a}/home"),
        format!("/api/v1/orgs/{pending}/home"),
    ] {
        let res = call(&db, "GET", &path, &outsider, None).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN, "{path}");
    }
}
