//! Landing-page leads (F20): sent with a company's lead key, worked by its
//! admin, handed to its Sales Agents. Rules in docs/features/F20-leads.md.

mod common;

use axum::http::StatusCode;
use common::{Res, call, member, org};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn make_key(db: &PgPool, org: Uuid, admin: &str) -> String {
    let res = call(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/admin/lead-key"),
        admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    res.body["key"].as_str().unwrap().to_owned()
}

async fn send(db: &PgPool, key: &str, body: Value) -> Res {
    call(db, "POST", "/api/v1/leads", key, Some(body)).await
}

fn lead(name: &str) -> Value {
    json!({
        "name": name, "phone": "+91 98140-22671", "city": "Mohali", "source": "Meta ad",
        "monthly_bill": "₹3,000 to ₹5,000", "extra": {"Roof owner?": "Yes", "": "dropped"},
        "consent": true,
    })
}

async fn list(db: &PgPool, org: Uuid, token: &str, query: &str) -> Vec<Value> {
    let res = call(
        db,
        "GET",
        &format!("/api/v1/orgs/{org}/leads{query}"),
        token,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body["items"].as_array().unwrap().clone()
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

#[sqlx::test]
async fn a_lead_sent_with_the_key_reaches_the_company(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let key = make_key(&db, a, &admin).await;
    assert!(key.starts_with("lead_"));

    let res = send(&db, &key, lead("Asha Deshmukh")).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["id"].as_str().unwrap().to_owned();

    let items = list(&db, a, &admin, "").await;
    assert_eq!(items.len(), 1);
    assert_eq!(items[0]["name"], "Asha Deshmukh");
    assert_eq!(items[0]["phone"], "9814022671");
    assert_eq!(items[0]["status"], "new");
    assert_eq!(items[0]["source"], "Meta ad");

    let one = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/leads/{id}"),
        &admin,
        None,
    )
    .await;
    assert_eq!(one.body["monthly_bill"], "₹3,000 to ₹5,000");
    assert_eq!(one.body["extra"], json!({"Roof owner?": "Yes"}));

    // The admin is told, on the website only.
    let feed = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/notifications"),
        &admin,
        None,
    )
    .await;
    assert_eq!(feed.body["items"][0]["kind"], "lead_new");
    assert_eq!(feed.body["items"][0]["lead_id"], id.as_str());
    let pushed: bool = sqlx::query_scalar(
        "SELECT pushed_at IS NOT NULL FROM notifications WHERE lead_id = $1::uuid",
    )
    .bind(&id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(pushed, "admins' lead notices are never pushed");

    // The key shows as set and used, never itself.
    let info = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/admin/lead-key"),
        &admin,
        None,
    )
    .await;
    assert_eq!(info.body["set"], true);
    assert!(info.body["last_used_at"].is_string());
    assert!(info.body.get("key").is_none());
}

#[sqlx::test]
async fn a_resend_with_the_same_external_id_makes_no_second_lead(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let key = make_key(&db, a, &admin).await;
    let mut body = lead("Asha Deshmukh");
    body["external_id"] = json!("form-42");
    let first = send(&db, &key, body.clone()).await;
    assert_eq!(first.status, StatusCode::CREATED);
    body["name"] = json!("Changed");
    let again = send(&db, &key, body).await;
    assert_eq!(again.status, StatusCode::OK);
    assert_eq!(again.body["id"], first.body["id"]);
    let items = list(&db, a, &admin, "").await;
    assert_eq!(items.len(), 1);
    assert_eq!(items[0]["name"], "Asha Deshmukh");
}

#[sqlx::test]
async fn a_wrong_old_or_missing_key_is_refused(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let b = org(&db, "Bright Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let admin_b = member(&db, b, "b@example.com", "org_admin", None).await;

    // No key made yet.
    let made_up = format!("lead_{}_{}", a.simple(), "a".repeat(64));
    let res = send(&db, &made_up, lead("X")).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
    assert_eq!(res.body["code"], "lead.bad_key");

    let old = make_key(&db, a, &admin).await;
    let new = make_key(&db, a, &admin).await;
    assert_ne!(old, new);
    assert_eq!(
        send(&db, &old, lead("X")).await.status,
        StatusCode::UNAUTHORIZED
    );
    assert_eq!(send(&db, &new, lead("X")).await.status, StatusCode::CREATED);

    // B's key can't be bent into A's: the secret is checked against A's.
    let key_b = make_key(&db, b, &admin_b).await;
    let secret_b = key_b.rsplit('_').next().unwrap();
    let forged = format!("lead_{}_{secret_b}", a.simple());
    assert_eq!(
        send(&db, &forged, lead("X")).await.status,
        StatusCode::UNAUTHORIZED
    );

    // A session token isn't a lead key, and no token is nothing.
    assert_eq!(
        send(&db, &admin, lead("X")).await.status,
        StatusCode::UNAUTHORIZED
    );
    let res = common::post(&db, "/api/v1/leads", lead("X")).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);

    // B never sees A's lead.
    assert!(list(&db, b, &admin_b, "").await.is_empty());
}

#[sqlx::test]
async fn the_form_must_be_sound(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let key = make_key(&db, a, &admin).await;

    let mut no_consent = lead("X");
    no_consent["consent"] = json!(false);
    let res = send(&db, &key, no_consent).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "lead.consent_required");

    for (field, value) in [
        ("phone", json!("12345")),
        ("name", json!("  ")),
        ("email", json!("not-an-email")),
        ("pin_code", json!("12")),
        ("message", json!("x".repeat(1001))),
    ] {
        let mut body = lead("X");
        body[field] = value;
        let res = send(&db, &key, body).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{field}");
        assert_eq!(res.body["errors"][0]["field"], field, "{}", res.body);
    }
    let mut body = lead("X");
    body["extra"] = (0..21).map(|i| (format!("Q{i}"), json!("A"))).collect();
    assert_eq!(
        send(&db, &key, body).await.status,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert!(list(&db, a, &admin, "").await.is_empty());
}

#[sqlx::test]
async fn the_admin_hands_a_lead_to_an_agent_who_works_it(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let agent = member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let other = member(&db, a, "dev@example.com", "agent", Some("salary")).await;
    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let key = make_key(&db, a, &admin).await;
    let id = send(&db, &key, lead("Asha")).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let path = format!("/api/v1/orgs/{a}/leads/{id}");
    let meena = user_id(&db, "meena@example.com").await;
    let ravi = user_id(&db, "ravi@example.com").await;

    // Only to a Sales Agent of this company.
    let res = call(&db, "PATCH", &path, &admin, Some(json!({"agent_id": ravi}))).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "lead.not_an_agent");

    let res = call(
        &db,
        "PATCH",
        &path,
        &admin,
        Some(json!({"agent_id": meena})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["agent_name"], "Asha Example");
    let feed = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/notifications"),
        &agent,
        None,
    )
    .await;
    assert_eq!(feed.body["items"][0]["kind"], "lead_assigned");

    // The agent sees it, and works it; the other agent and a worker don't.
    let mine = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/leads/mine"),
        &agent,
        None,
    )
    .await;
    assert_eq!(mine.body["items"].as_array().unwrap().len(), 1);
    let theirs = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/leads/mine"),
        &other,
        None,
    )
    .await;
    assert!(theirs.body["items"].as_array().unwrap().is_empty());
    assert_eq!(
        call(&db, "GET", &path, &other, None).await.status,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        call(&db, "GET", &path, &worker, None).await.status,
        StatusCode::FORBIDDEN
    );
    assert_eq!(
        call(&db, "GET", &format!("/api/v1/orgs/{a}/leads"), &agent, None)
            .await
            .status,
        StatusCode::FORBIDDEN
    );

    let res = call(
        &db,
        "PATCH",
        &path,
        &agent,
        Some(json!({"status": "contacted", "note": "Calls back Monday"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "contacted");
    assert_eq!(res.body["note"], "Calls back Monday");
    // But can't hand it on.
    let res = call(&db, "PATCH", &path, &agent, Some(json!({"agent_id": null}))).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "lead.admin_only");

    // Filters, and an empty note removes it.
    assert_eq!(list(&db, a, &admin, "?status=contacted").await.len(), 1);
    assert_eq!(list(&db, a, &admin, "?status=new").await.len(), 0);
    assert_eq!(
        list(&db, a, &admin, &format!("?agent_id={meena}"))
            .await
            .len(),
        1
    );
    assert_eq!(list(&db, a, &admin, "?q=ash").await.len(), 1);
    assert_eq!(list(&db, a, &admin, "?q=22671").await.len(), 1);
    assert_eq!(list(&db, a, &admin, "?q=nobody").await.len(), 0);
    let res = call(&db, "PATCH", &path, &admin, Some(json!({"note": ""}))).await;
    assert!(res.body.get("note").is_none());
    assert_eq!(res.body["status"], "contacted");

    // The admin takes it back with null.
    let res = call(&db, "PATCH", &path, &admin, Some(json!({"agent_id": null}))).await;
    assert!(res.body.get("agent_id").is_none());
}

#[sqlx::test]
async fn an_agent_who_leaves_gives_their_leads_back(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let key = make_key(&db, a, &admin).await;
    let id = send(&db, &key, lead("Asha")).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let meena = user_id(&db, "meena@example.com").await;
    call(
        &db,
        "PATCH",
        &format!("/api/v1/orgs/{a}/leads/{id}"),
        &admin,
        Some(json!({"agent_id": meena})),
    )
    .await;

    let res = call(
        &db,
        "DELETE",
        &format!("/api/v1/orgs/{a}/members/{meena}"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{}", res.body);
    let items = list(&db, a, &admin, "").await;
    assert!(items[0].get("agent_id").is_none(), "{}", items[0]);
}

#[sqlx::test]
async fn the_admin_deletes_a_lead_for_good(db: PgPool) {
    let a = org(&db, "Arka Solar", "active").await;
    let admin = member(&db, a, "admin@example.com", "org_admin", None).await;
    let key = make_key(&db, a, &admin).await;
    let id = send(&db, &key, lead("Asha")).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let path = format!("/api/v1/orgs/{a}/leads/{id}");
    assert_eq!(
        call(&db, "DELETE", &path, &admin, None).await.status,
        StatusCode::NO_CONTENT
    );
    assert_eq!(
        call(&db, "GET", &path, &admin, None).await.status,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        call(&db, "DELETE", &path, &admin, None).await.status,
        StatusCode::NOT_FOUND
    );
    let left: i64 =
        sqlx::query_scalar("SELECT count(*) FROM notifications WHERE lead_id = $1::uuid")
            .bind(&id)
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(left, 0, "its notifications go with it");
}
