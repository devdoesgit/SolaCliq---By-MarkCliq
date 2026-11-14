//! Phase 4: companies, `/me` memberships, the OrgMember check, the team
//! endpoints and the seed (needs `make db` running).

mod common;

use axum::http::StatusCode;
use backend::{config::Environment, seed};
use common::{call, emails_to, get, join, member, org, token};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

fn members_path(org: Uuid) -> String {
    format!("/api/v1/orgs/{org}/members")
}

// ---------------------------------------------------------------- /me

#[sqlx::test]
async fn me_lists_memberships_including_suspended_but_not_removed(db: PgPool) {
    let active = org(&db, "Example Solar", "active").await;
    let suspended = org(&db, "Demo Power", "suspended").await;
    let left = org(&db, "Old Co", "active").await;
    let t = member(
        &db,
        active,
        "kiran@example.com",
        "agent",
        Some("commission"),
    )
    .await;
    join(&db, suspended, "kiran@example.com", "worker", None).await;
    join(&db, left, "kiran@example.com", "worker", None).await;
    sqlx::query("UPDATE memberships SET removed_at = now() WHERE org_id = $1")
        .bind(left)
        .execute(&db)
        .await
        .unwrap();

    let me = get(&db, "/api/v1/me", Some(&t)).await;
    assert_eq!(me.status, StatusCode::OK);
    assert_eq!(
        me.body["memberships"],
        json!([
            {"org": {"id": active, "name": "Example Solar", "status": "active", "phone": "9814000000"},
             "role": "agent", "pay_type": "commission"},
            {"org": {"id": suspended, "name": "Demo Power", "status": "suspended", "phone": "9814000000"},
             "role": "worker"},
        ])
    );
}

// ---------------------------------------------------------- OrgMember

#[sqlx::test]
async fn a_member_of_one_company_cant_open_another(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let b = org(&db, "B", "active").await;
    let admin_a = member(&db, a, "admin-a@example.com", "org_admin", None).await;
    member(&db, b, "admin-b@example.com", "org_admin", None).await;

    let res = call(&db, "GET", &members_path(b), &admin_a, None).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "org.not_member");

    // A company that doesn't exist, or a path that isn't an id: the same.
    for path in [
        members_path(Uuid::now_v7()),
        "/api/v1/orgs/abc/members".into(),
    ] {
        let res = call(&db, "GET", &path, &admin_a, None).await;
        assert_eq!(res.body["code"], "org.not_member");
    }
}

#[sqlx::test]
async fn the_wrong_role_is_refused(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let res = call(&db, "GET", &members_path(a), &worker, None).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "org.role_not_allowed");
}

#[sqlx::test]
async fn a_pending_or_suspended_company_gives_no_data(db: PgPool) {
    for (status, code) in [("pending", "org.pending"), ("suspended", "org.suspended")] {
        let o = org(&db, "Co", status).await;
        let admin = member(&db, o, &format!("{status}@example.com"), "org_admin", None).await;
        let res = call(&db, "GET", &members_path(o), &admin, None).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN);
        assert_eq!(res.body["code"], code);
    }
}

#[sqlx::test]
async fn no_login_is_401(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let res = get(&db, &members_path(a), None).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}

// ------------------------------------------------------------- the team

#[sqlx::test]
async fn adding_a_new_email_makes_an_invited_account(db: PgPool) {
    let a = org(&db, "Example Solar", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;

    let res = call(
        &db,
        "POST",
        &members_path(a),
        &admin,
        Some(json!({"name": "Neha", "email": " Neha@Example.com", "role": "worker"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(res.body["email"], "neha@example.com");
    assert_eq!(res.body["role"], "worker");
    assert_eq!(res.body["status"], "invited");
    assert!(res.body.get("pay_type").is_none());

    let mail = emails_to("neha@example.com").pop().unwrap();
    assert!(mail.body.contains("Forgot password?"), "{}", mail.body);

    // No password yet, so logging in asks them to set one.
    let login = common::post(
        &db,
        "/api/v1/auth/login",
        json!({"email": "neha@example.com", "password": "anything1", "client": "app"}),
    )
    .await;
    assert_eq!(login.body["code"], "account.password_not_set");
}

#[sqlx::test]
async fn adding_an_existing_account_only_adds_the_membership(db: PgPool) {
    let a = org(&db, "Example Solar", "active").await;
    let other = org(&db, "Other", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let meena = member(&db, other, "meena@example.com", "worker", None).await;

    let res = call(
        &db,
        "POST",
        &members_path(a),
        &admin,
        Some(json!({"name": "Ignored", "email": "meena@example.com",
                    "role": "agent", "pay_type": "salary"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    // Their own name stays; they have a password, so they're active.
    assert_eq!(res.body["name"], "Asha Example");
    assert_eq!(res.body["status"], "active");
    assert_eq!(res.body["pay_type"], "salary");

    let mail = emails_to("meena@example.com").pop().unwrap();
    assert!(mail.subject.contains("added to Example Solar"));

    let me = get(&db, "/api/v1/me", Some(&meena)).await;
    assert_eq!(me.body["memberships"].as_array().unwrap().len(), 2);
}

#[sqlx::test]
async fn add_rules(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    member(&db, a, "ravi@example.com", "worker", None).await;

    let cases = [
        (
            json!({"name": "R", "email": "ravi@example.com", "role": "worker"}),
            StatusCode::CONFLICT,
            "member.already_in_org",
        ),
        (
            json!({"name": "C", "email": "c@example.com", "role": "customer"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.role_not_allowed",
        ),
        (
            json!({"name": "A", "email": "a@example.com", "role": "org_admin"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.role_not_allowed",
        ),
        (
            json!({"name": "S", "email": "s@example.com", "role": "agent"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.pay_type_required",
        ),
        (
            json!({"name": "W", "email": "w@example.com", "role": "worker", "pay_type": "salary"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "member.pay_type_not_allowed",
        ),
        (
            json!({"name": " ", "email": "not-an-email", "role": "worker"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "validation.failed",
        ),
        (
            json!({"name": "X", "email": "x@example.com", "role": "boss"}),
            StatusCode::UNPROCESSABLE_ENTITY,
            "validation.failed",
        ),
    ];
    for (body, status, code) in cases {
        let res = call(&db, "POST", &members_path(a), &admin, Some(body.clone())).await;
        assert_eq!(
            (res.status, res.body["code"].as_str()),
            (status, Some(code)),
            "{body}"
        );
    }
}

#[sqlx::test]
async fn removing_a_member_ends_their_access_at_once(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let ravi_id: Uuid = sqlx::query_scalar("SELECT id FROM users WHERE email = 'ravi@example.com'")
        .fetch_one(&db)
        .await
        .unwrap();
    let ravi_path = format!("{}/{ravi_id}", members_path(a));

    let res = call(&db, "DELETE", &ravi_path, &admin, None).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);

    // Gone from /me, refused by the company, and a second remove is 404.
    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    assert_eq!(me.body["memberships"], json!([]));
    let res = call(&db, "DELETE", &ravi_path, &admin, None).await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);

    // Added back: the same row returns, now as an agent.
    let res = call(
        &db,
        "POST",
        &members_path(a),
        &admin,
        Some(json!({"name": "Ravi", "email": "ravi@example.com",
                    "role": "agent", "pay_type": "commission"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let rows: i64 = sqlx::query_scalar("SELECT count(*) FROM memberships WHERE user_id = $1")
        .bind(ravi_id)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(rows, 1);
}

#[sqlx::test]
async fn the_admin_cant_be_removed(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let admin_id: Uuid = sqlx::query_scalar("SELECT id FROM users WHERE email = 'dev@example.com'")
        .fetch_one(&db)
        .await
        .unwrap();
    let res = call(
        &db,
        "DELETE",
        &format!("{}/{admin_id}", members_path(a)),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "member.cannot_remove_admin");
}

#[sqlx::test]
async fn the_list_pages_newest_first_without_customers(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    for email in ["w1@example.com", "w2@example.com", "w3@example.com"] {
        member(&db, a, email, "worker", None).await;
    }
    member(&db, a, "meena@example.com", "agent", Some("salary")).await;
    member(&db, a, "rajinder@example.com", "customer", None).await;

    // Two at a time: 5 members (customers left out), so 3 pages.
    let mut seen = Vec::new();
    let mut cursor: Option<String> = None;
    loop {
        let path = match &cursor {
            Some(c) => format!("{}?limit=2&cursor={c}", members_path(a)),
            None => format!("{}?limit=2", members_path(a)),
        };
        let res = call(&db, "GET", &path, &admin, None).await;
        assert_eq!(res.status, StatusCode::OK, "{}", res.body);
        for m in res.body["items"].as_array().unwrap() {
            seen.push(m["email"].as_str().unwrap().to_owned());
        }
        match res.body["page"]["next_cursor"].as_str() {
            Some(c) => cursor = Some(c.to_owned()),
            None => break,
        }
    }
    assert_eq!(
        seen,
        [
            "meena@example.com",
            "w3@example.com",
            "w2@example.com",
            "w1@example.com",
            "dev@example.com"
        ]
    );

    let res = call(
        &db,
        "GET",
        &format!("{}?role=agent", members_path(a)),
        &admin,
        None,
    )
    .await;
    let items = res.body["items"].as_array().unwrap();
    assert_eq!(items.len(), 1);
    assert_eq!(items[0]["pay_type"], "salary");

    for bad in [
        "?limit=0",
        "?limit=101",
        "?limit=abc",
        "?cursor=nonsense",
        "?role=boss",
    ] {
        let res = call(
            &db,
            "GET",
            &format!("{}{bad}", members_path(a)),
            &admin,
            None,
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{bad}");
    }
}

#[sqlx::test]
async fn the_database_keeps_one_admin_and_agent_pay_types(db: PgPool) {
    let a = org(&db, "A", "active").await;
    member(&db, a, "dev@example.com", "org_admin", None).await;
    common::verified_user(&db, "x@example.com", "sunlight1").await;

    let insert = |role: &'static str, pay: Option<&'static str>| {
        let db = db.clone();
        async move {
            sqlx::query(
                "INSERT INTO memberships (id, user_id, org_id, role, pay_type)
                 SELECT $1, id, $2, $3::member_role, $4::pay_type FROM users
                 WHERE email = 'x@example.com'",
            )
            .bind(Uuid::now_v7())
            .bind(a)
            .bind(role)
            .bind(pay)
            .execute(&db)
            .await
        }
    };
    assert!(insert("org_admin", None).await.is_err(), "a second admin");
    assert!(
        insert("agent", None).await.is_err(),
        "an agent without a pay type"
    );
    assert!(
        insert("worker", Some("salary")).await.is_err(),
        "a worker with one"
    );
    assert!(insert("worker", None).await.is_ok());
}

// --------------------------------------------------------------- seed

#[sqlx::test]
async fn the_seed_runs_twice_and_its_people_log_in(db: PgPool) {
    seed::run(&db, Environment::Development).await.unwrap();
    seed::run(&db, Environment::Development).await.unwrap();

    let orgs: i64 = sqlx::query_scalar("SELECT count(*) FROM orgs")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(orgs, 2);

    let ravi = token(&db, "ravi@example.com").await;
    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    let statuses: Vec<_> = me.body["memberships"]
        .as_array()
        .unwrap()
        .iter()
        .map(|m| m["org"]["status"].as_str().unwrap().to_owned())
        .collect();
    assert_eq!(statuses, ["active", "suspended"]);
}

#[sqlx::test]
async fn the_seed_refuses_production(db: PgPool) {
    let err = seed::run(&db, Environment::Production).await.unwrap_err();
    assert!(matches!(err, seed::SeedError::NotDevelopment));
    let users: i64 = sqlx::query_scalar("SELECT count(*) FROM users")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(users, 0);
}

#[sqlx::test]
async fn make_platform_admin(db: PgPool) {
    common::verified_user(&db, "parth@example.com", "sunlight1").await;
    assert!(
        seed::make_platform_admin(&db, " Parth@Example.com ")
            .await
            .unwrap()
    );
    assert!(
        !seed::make_platform_admin(&db, "nobody@example.com")
            .await
            .unwrap()
    );
    let t = token(&db, "parth@example.com").await;
    let me = get(&db, "/api/v1/me", Some(&t)).await;
    assert_eq!(me.body["is_platform_admin"], true);
}

#[sqlx::test]
async fn removing_a_malformed_id_is_a_problem_404(db: PgPool) {
    let a = org(&db, "A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let res = call(
        &db,
        "DELETE",
        &format!("{}/not-an-id", members_path(a)),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
    assert_eq!(res.body["code"], "common.not_found");
}
