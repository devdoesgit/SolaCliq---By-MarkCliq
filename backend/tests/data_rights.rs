/*
    F18: account deletion and KYC retention
    (docs/features/F18-data-rights.md). Throwaway databases and the fake
    R2 only
*/

mod common;

use axum::http::StatusCode;
use common::{call, member, org, post, r2_has, r2_put, token, verified_user};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

const DELETE: &str = "/api/v1/me/delete";

async fn user(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

async fn delete(db: &PgPool, token: &str, password: &str) -> common::Res {
    call(
        db,
        "POST",
        DELETE,
        token,
        Some(json!({"password": password})),
    )
    .await
}

async fn account(db: &PgPool, id: Uuid) -> (String, String, Option<String>) {
    sqlx::query_as("SELECT name, email, password_hash FROM users WHERE id = $1")
        .bind(id)
        .fetch_one(db)
        .await
        .unwrap()
}

#[sqlx::test]
async fn deleting_needs_the_password_then_erases(db: PgPool) {
    let email = "rights.solo@example.com";
    verified_user(&db, email, "sunlight1").await;
    let access = token(&db, email).await;
    let id = user(&db, email).await;
    sqlx::query("INSERT INTO user_settings VALUES ($1, true, true, true) ON CONFLICT DO NOTHING")
        .bind(id)
        .execute(&db)
        .await
        .unwrap();

    let res = delete(&db, &access, "wrong-password").await;
    assert_eq!(res.status, StatusCode::BAD_REQUEST);
    assert_eq!(res.body["code"], "account.password_incorrect");
    assert_eq!(account(&db, id).await.1, email);

    assert_eq!(
        delete(&db, &access, "sunlight1").await.status,
        StatusCode::NO_CONTENT
    );
    let (name, stored, hash) = account(&db, id).await;
    assert_eq!(name, "Deleted account");
    assert!(stored.ends_with("@deleted.invalid") && hash.is_none());
    let left: i64 = sqlx::query_scalar(
        "SELECT (SELECT count(*) FROM sessions WHERE user_id = $1)
              + (SELECT count(*) FROM user_settings WHERE user_id = $1)
              + (SELECT count(*) FROM agreements WHERE user_id = $1)",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert_eq!(left, 0);
    assert_eq!(
        call(&db, "GET", "/api/v1/me", &access, None).await.status,
        StatusCode::UNAUTHORIZED
    );
    let body = json!({"email": email, "password": "sunlight1", "client": "app"});
    assert_eq!(
        post(&db, "/api/v1/auth/login", body).await.status,
        StatusCode::UNAUTHORIZED
    );

    // The address is free again.
    verified_user(&db, email, "sunlight1").await;
    assert_ne!(user(&db, email).await, id);
}

#[sqlx::test]
async fn a_members_name_stays_on_the_companys_records(db: PgPool) {
    let co = org(&db, "Rights Solar", "active").await;
    let access = member(&db, co, "rights.worker@example.com", "worker", None).await;
    let id = user(&db, "rights.worker@example.com").await;
    let before = account(&db, id).await.0;
    sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
         VALUES ($1, $2, $3, 'guide', 'A', 'B')",
    )
    .bind(Uuid::now_v7())
    .bind(id)
    .bind(co)
    .execute(&db)
    .await
    .unwrap();
    assert_eq!(
        delete(&db, &access, "sunlight1").await.status,
        StatusCode::NO_CONTENT
    );
    assert_eq!(account(&db, id).await.0, before);
    let (open, told): (i64, i64) = sqlx::query_as(
        "SELECT (SELECT count(*) FROM memberships WHERE user_id = $1 AND removed_at IS NULL),
                (SELECT count(*) FROM notifications WHERE user_id = $1)",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert_eq!((open, told), (0, 0));
}

#[sqlx::test]
async fn the_last_admin_cant_leave_and_nothing_changes(db: PgPool) {
    let other = org(&db, "Works Here", "active").await;
    let co = org(&db, "Runs This", "active").await;
    let email = "rights.admin@example.com";
    member(&db, other, email, "worker", None).await;
    let access = member(&db, co, email, "org_admin", None).await;
    let res = delete(&db, &access, "sunlight1").await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "account.last_admin");
    let open: i64 = sqlx::query_scalar("SELECT count(*) FROM memberships WHERE removed_at IS NULL")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(open, 2, "refused before anything changed");

    // A company has one admin; only a rejected one lets them go.
    sqlx::query(
        "UPDATE orgs SET status = 'rejected', reviewed_at = now(), review_note = 'Test' WHERE id = $1",
    )
    .bind(co)
    .execute(&db)
    .await
    .unwrap();
    assert_eq!(
        delete(&db, &access, "sunlight1").await.status,
        StatusCode::NO_CONTENT
    );
}

#[sqlx::test]
async fn a_platform_admin_cant_delete_themselves(db: PgPool) {
    let email = "rights.platform@example.com";
    verified_user(&db, email, "sunlight1").await;
    let access = token(&db, email).await;
    sqlx::query("UPDATE users SET is_platform_admin = true WHERE email = $1")
        .bind(email)
        .execute(&db)
        .await
        .unwrap();
    let res = delete(&db, &access, "sunlight1").await;
    assert_eq!(res.body["code"], "account.platform_admin");
}

struct Kept {
    id: Uuid,
    user: Uuid,
    keys: [String; 2],
}

// A customer with a current KYC file and a replaced one.
async fn customer(db: &PgPool, co: Uuid, agent: Uuid, n: i32) -> Kept {
    let (id, user, doc) = (Uuid::now_v7(), Uuid::now_v7(), Uuid::now_v7());
    sqlx::query("INSERT INTO users (id, email, name) VALUES ($1, $2, 'Invited Customer')")
        .bind(user)
        .bind(format!("rights.customer{n}@example.com"))
        .execute(db)
        .await
        .unwrap();
    sqlx::query(
        "INSERT INTO memberships (id, user_id, org_id, role) VALUES ($1, $2, $3, 'customer')",
    )
    .bind(Uuid::now_v7())
    .bind(user)
    .bind(co)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, address, registered_by,
                                user_id, kyc_status)
         VALUES ($1, $2, $3, 'Customer', $4, 'House 1', $5, $6, 'in_review')",
    )
    .bind(id)
    .bind(co)
    .bind(format!("SC-{n}"))
    .bind(format!("98140000{n:02}"))
    .bind(agent)
    .bind(user)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO documents (id, org_id, customer_id, kind, uploaded_by)
         VALUES ($1, $2, $3, 'pan', $4)",
    )
    .bind(doc)
    .bind(co)
    .bind(id)
    .bind(agent)
    .execute(db)
    .await
    .unwrap();
    let mut keys = [String::new(), String::new()];
    for (i, key) in keys.iter_mut().enumerate() {
        let upload = Uuid::now_v7();
        *key = format!("orgs/{co}/kyc/{upload}");
        r2_put(key, 100);
        sqlx::query(
            "INSERT INTO uploads (id, org_id, owner_id, purpose, content_type, size_bytes,
                                  r2_key, used_at)
             VALUES ($1, $2, $3, 'kyc', 'image/jpeg', 100, $4, now())",
        )
        .bind(upload)
        .bind(co)
        .bind(agent)
        .bind(&*key)
        .execute(db)
        .await
        .unwrap();
        sqlx::query(
            "INSERT INTO document_files (org_id, document_id, upload_id, position, replaced_at)
             VALUES ($1, $2, $3, 1, CASE WHEN $4 THEN now() END)",
        )
        .bind(co)
        .bind(doc)
        .bind(upload)
        .bind(i == 1)
        .execute(db)
        .await
        .unwrap();
    }
    Kept { id, user, keys }
}

async fn rejected(db: &PgPool, c: &Kept, days: i32) {
    sqlx::query(
        "UPDATE customers SET kyc_status = 'rejected', rejected_note = 'Roof shaded',
                decided_by = registered_by, decided_at = now() - make_interval(days => $2)
         WHERE id = $1",
    )
    .bind(c.id)
    .bind(days)
    .execute(db)
    .await
    .unwrap();
}

async fn handed_over(db: &PgPool, co: Uuid, c: &Kept, days: i32) {
    sqlx::query(
        "UPDATE customers SET kyc_status = 'approved', stage_index = 7,
                decided_by = registered_by, decided_at = now() WHERE id = $1",
    )
    .bind(c.id)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO installs (id, org_id, customer_id, total, subsidy, handed_over_on)
         VALUES ($1, $2, $3, 20000000, 0, current_date - $4)",
    )
    .bind(Uuid::now_v7())
    .bind(co)
    .bind(c.id)
    .bind(days)
    .execute(db)
    .await
    .unwrap();
}

async fn rows(db: &PgPool, c: &Kept) -> (i64, i64) {
    sqlx::query_as(
        "SELECT (SELECT count(*) FROM customers WHERE id = $1),
                (SELECT count(*) FROM documents WHERE customer_id = $1)",
    )
    .bind(c.id)
    .fetch_one(db)
    .await
    .unwrap()
}

#[sqlx::test]
async fn kyc_goes_when_its_time_is_up_and_no_sooner(db: PgPool) {
    let co = org(&db, "Keeps KYC", "active").await;
    member(&db, co, "rights.agent@example.com", "agent", Some("salary")).await;
    let agent = user(&db, "rights.agent@example.com").await;

    let old_rejected = customer(&db, co, agent, 1).await;
    rejected(&db, &old_rejected, 31).await;
    let new_rejected = customer(&db, co, agent, 2).await;
    rejected(&db, &new_rejected, 29).await;
    let old_handover = customer(&db, co, agent, 3).await;
    handed_over(&db, co, &old_handover, 368).await;
    let new_handover = customer(&db, co, agent, 4).await;
    handed_over(&db, co, &new_handover, 360).await;
    let waiting = customer(&db, co, agent, 5).await;

    let storage = common::state(&db).storage.expect("the fake R2");
    let app = common::app_db(&db);

    // Off: it only counts.
    let seen = backend::retention::run(&app, &storage, false)
        .await
        .unwrap();
    assert_eq!((seen.due, seen.deleted), (2, 0));
    assert!(r2_has(&old_rejected.keys[0]));
    assert_eq!(rows(&db, &old_rejected).await, (1, 1));

    let done = backend::retention::run(&app, &storage, true).await.unwrap();
    assert_eq!((done.due, done.deleted), (2, 2));
    assert_eq!(rows(&db, &old_rejected).await, (0, 0));
    assert_eq!(
        rows(&db, &old_handover).await,
        (1, 0),
        "the install's record stays"
    );
    for gone in old_rejected.keys.iter().chain(&old_handover.keys) {
        assert!(!r2_has(gone), "replaced files go too");
    }
    for keep in [&new_rejected, &new_handover, &waiting] {
        assert_eq!(rows(&db, keep).await, (1, 1));
        assert!(keep.keys.iter().all(|k| r2_has(k)));
    }
    assert_eq!(account(&db, old_rejected.user).await.0, "Deleted account");
    assert_eq!(account(&db, old_handover.user).await.0, "Invited Customer");

    let again = backend::retention::run(&app, &storage, true).await.unwrap();
    assert_eq!((again.due, again.deleted), (0, 0));
    app.close().await;
}
