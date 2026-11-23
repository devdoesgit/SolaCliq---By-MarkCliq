//! Editing a team member (F21): the admin changes role and pay type, and
//! sends an invite again. The person's own details aren't changed here.
//! Rules in docs/features/F21-team-edit.md.

mod common;

use axum::http::StatusCode;
use common::{Res, call, emails_to, member, org};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

async fn change(db: &PgPool, org: Uuid, admin: &str, who: Uuid, body: serde_json::Value) -> Res {
    call(
        db,
        "PATCH",
        &format!("/api/v1/orgs/{org}/members/{who}"),
        admin,
        Some(body),
    )
    .await
}

// A customer of `org`, and one task for `worker` in `status`.
async fn task_for(db: &PgPool, org: Uuid, worker: Uuid, status: &str) {
    let customer = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, address)
         VALUES ($1, $2, 'SC-' || $1::text, 'Asha', 'Plot 1')",
    )
    .bind(customer)
    .bind(org)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index, assignee_id,
                            due_at, status)
         VALUES ($1, $2, $3, 'TSK-' || $1::text, 'Site survey', 1, $4, now(),
                 $5::task_status)",
    )
    .bind(Uuid::now_v7())
    .bind(org)
    .bind(customer)
    .bind(worker)
    .bind(status)
    .execute(db)
    .await
    .unwrap();
}

#[sqlx::test]
async fn an_agents_pay_changes_from_now_on(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let meena = user_id(&db, "meena@example.com").await;

    let res = change(&db, a, &admin, meena, json!({"pay_type": "salary"})).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["role"], "agent");
    assert_eq!(res.body["pay_type"], "salary");

    // A worker has no pay type.
    member(&db, a, "ravi@example.com", "worker", None).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let res = change(&db, a, &admin, ravi, json!({"pay_type": "salary"})).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "pay_type");
}

#[sqlx::test]
async fn a_role_changes_only_with_nothing_open(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    task_for(&db, a, ravi, "submitted").await;
    task_for(&db, a, ravi, "assigned").await;

    let res = change(
        &db,
        a,
        &admin,
        ravi,
        json!({"role": "agent", "pay_type": "salary"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "member.has_open_work");
    assert!(
        res.body["detail"]
            .as_str()
            .unwrap()
            .contains("2 open tasks"),
        "{}",
        res.body
    );

    // Done and cancelled work doesn't hold it.
    sqlx::query("UPDATE tasks SET status = 'approved' WHERE assignee_id = $1")
        .bind(ravi)
        .execute(&db)
        .await
        .unwrap();
    task_for(&db, a, ravi, "cancelled").await;
    // Becoming an agent needs a pay type.
    let res = change(&db, a, &admin, ravi, json!({"role": "agent"})).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "pay_type");
    let res = change(
        &db,
        a,
        &admin,
        ravi,
        json!({"role": "agent", "pay_type": "commission"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["role"], "agent");
    assert_eq!(res.body["pay_type"], "commission");

    // And back: an agent's open lead holds it.
    sqlx::query(
        "INSERT INTO leads (id, org_id, name, phone, source, agent_id)
         VALUES ($1, $2, 'Lead', '9814022671', 'Meta ad', $3)",
    )
    .bind(Uuid::now_v7())
    .bind(a)
    .bind(ravi)
    .execute(&db)
    .await
    .unwrap();
    let res = change(&db, a, &admin, ravi, json!({"role": "worker"})).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert!(res.body["detail"].as_str().unwrap().contains("1 open lead"));
    sqlx::query("UPDATE leads SET status = 'lost' WHERE agent_id = $1")
        .bind(ravi)
        .execute(&db)
        .await
        .unwrap();
    let res = change(&db, a, &admin, ravi, json!({"role": "worker"})).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert!(res.body.get("pay_type").is_none());
}

#[sqlx::test]
async fn only_this_companys_admin_and_never_the_admin_role(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let b = org(&db, "Bright Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let admin_b = member(&db, b, "b@example.com", "org_admin", None).await;
    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let me = user_id(&db, "admin@example.com").await;

    let body = json!({"role": "agent", "pay_type": "salary"});
    assert_eq!(
        change(&db, a, &worker, ravi, body.clone()).await.status,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        change(&db, a, &admin_b, ravi, body.clone()).await.status,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        change(&db, b, &admin_b, ravi, body.clone()).await.status,
        StatusCode::NOT_FOUND
    );
    let res = change(&db, a, &admin, me, json!({"role": "worker"})).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "member.cannot_change_admin");
    let res = change(&db, a, &admin, ravi, json!({"role": "org_admin"})).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "role");
}

#[sqlx::test]
async fn an_invite_goes_again_until_they_set_up(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let added = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/members"),
        &admin,
        Some(json!({"name": "New Person", "email": "invite.again@example.com", "role": "worker"})),
    )
    .await;
    assert_eq!(added.status, StatusCode::CREATED, "{}", added.body);
    let who = added.body["user_id"].as_str().unwrap();
    let before = emails_to("invite.again@example.com").len();

    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/members/{who}/invite"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{}", res.body);
    assert_eq!(emails_to("invite.again@example.com").len(), before + 1);

    // Someone who can log in already doesn't get one.
    member(&db, a, "ravi@example.com", "worker", None).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/members/{ravi}/invite"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "member.already_set_up");
}
