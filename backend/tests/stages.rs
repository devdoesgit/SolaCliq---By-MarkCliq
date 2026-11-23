//! Each company's install stages (F19): its admin renames them and sets
//! their templates; every member reads them; other companies never do.

mod common;

use axum::http::StatusCode;
use common::{call, member, org};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn stages(db: &PgPool, org: Uuid, token: &str) -> Vec<Value> {
    let res = call(
        db,
        "GET",
        &format!("/api/v1/orgs/{org}/stages"),
        token,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body["stages"].as_array().unwrap().clone()
}

async fn set(db: &PgPool, org: Uuid, token: &str, index: i32, body: Value) -> common::Res {
    call(
        db,
        "PUT",
        &format!("/api/v1/orgs/{org}/admin/stages/{index}"),
        token,
        Some(body),
    )
    .await
}

#[sqlx::test]
async fn a_new_company_has_the_standard_seven(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let worker = member(&db, a, "w@example.com", "worker", None).await;
    let list = stages(&db, a, &worker).await;
    assert_eq!(list.len(), 7);
    assert_eq!(
        list[0],
        json!({"index": 1, "name": "Site survey", "checklist": [], "photos": []})
    );
    assert_eq!(list[6]["name"], "Handover");
}

#[sqlx::test]
async fn the_admin_changes_a_stage_and_everyone_sees_it(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let agent = member(&db, a, "agent@example.com", "agent", Some("commission")).await;

    let res = set(
        &db,
        a,
        &admin,
        2,
        json!({
            "name": "  Mounting ",
            "checklist": ["Rails level", "", "Rails level", "Torque checked"],
            "photos": ["Rails", "Clamps"],
        }),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(
        res.body["stages"][1],
        json!({
            "index": 2, "name": "Mounting",
            "checklist": ["Rails level", "Torque checked"], "photos": ["Rails", "Clamps"],
        })
    );

    // The agent reads the same; the settings carry the names.
    assert_eq!(stages(&db, a, &agent).await[1]["name"], "Mounting");
    let settings = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/admin/settings"),
        &admin,
        None,
    )
    .await;
    assert_eq!(settings.body["stages"][1], "Mounting");
    assert_eq!(settings.body["stages"][2], "Panel installation");

    // Changing it again replaces it.
    let res = set(
        &db,
        a,
        &admin,
        2,
        json!({"name": "Structure", "checklist": [], "photos": []}),
    )
    .await;
    assert_eq!(res.body["stages"][1]["checklist"], json!([]));
}

#[sqlx::test]
async fn one_companys_stages_stay_its_own(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let b = org(&db, "Bright Solar", "active").await;
    let admin_a = member(&db, a, "a@example.com", "org_admin", None).await;
    let admin_b = member(&db, b, "b@example.com", "org_admin", None).await;
    let res = set(
        &db,
        a,
        &admin_a,
        1,
        json!({"name": "Visit", "checklist": [], "photos": []}),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    assert_eq!(stages(&db, b, &admin_b).await[0]["name"], "Site survey");
    // B's admin can't read or change A's.
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/stages"),
        &admin_b,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    let res = set(
        &db,
        a,
        &admin_b,
        1,
        json!({"name": "Mine", "checklist": [], "photos": []}),
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(stages(&db, a, &admin_a).await[0]["name"], "Visit");
}

#[sqlx::test]
async fn only_the_admin_changes_and_only_within_the_rules(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let worker = member(&db, a, "w@example.com", "worker", None).await;
    let ok = json!({"name": "Visit", "checklist": [], "photos": []});

    assert_eq!(
        set(&db, a, &worker, 1, ok.clone()).await.status,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        set(&db, a, &admin, 0, ok.clone()).await.status,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        set(&db, a, &admin, 8, ok.clone()).await.status,
        StatusCode::NOT_FOUND
    );

    for (body, field) in [
        (json!({"name": "  ", "checklist": [], "photos": []}), "name"),
        (
            json!({"name": "x".repeat(41), "checklist": [], "photos": []}),
            "name",
        ),
        (
            json!({"name": "Visit", "checklist": vec!["Same"; 21], "photos": []}),
            "",
        ),
        (
            json!({"name": "Visit", "checklist": ["x".repeat(121)], "photos": []}),
            "checklist",
        ),
        (
            json!({"name": "Visit", "checklist": [], "photos": (0..9).map(|i| format!("Photo {i}")).collect::<Vec<_>>()}),
            "photos",
        ),
    ] {
        let res = set(&db, a, &admin, 1, body.clone()).await;
        if field.is_empty() {
            // 21 items, all the same: kept once, so allowed.
            assert_eq!(res.status, StatusCode::OK, "{body}");
            continue;
        }
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{body}");
        assert_eq!(res.body["errors"][0]["field"], field, "{}", res.body);
    }
    let many: Vec<String> = (0..21).map(|i| format!("Check {i}")).collect();
    let res = set(
        &db,
        a,
        &admin,
        1,
        json!({"name": "Visit", "checklist": many, "photos": []}),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
}
