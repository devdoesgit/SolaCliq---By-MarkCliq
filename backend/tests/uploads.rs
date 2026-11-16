//! POST /orgs/{org_id}/uploads: a signed URL for one of the company's
//! files, and its row.

mod common;

use axum::http::StatusCode;
use common::{call, member, org};
use serde_json::json;
use sqlx::PgPool;

// Solar A, and Ravi's token there.
async fn ravi(db: &PgPool) -> (uuid::Uuid, String) {
    let a = org(db, "Solar A", "active").await;
    (a, member(db, a, "ravi@example.com", "worker", None).await)
}

#[sqlx::test]
async fn gives_a_signed_url_for_exactly_that_file(db: PgPool) {
    let (a, token) = ravi(&db).await;
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &token,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 245_000, "purpose": "proof"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["upload_id"].as_str().unwrap();
    let url = res.body["url"].as_str().unwrap();
    // The R2 stand-in's address; storage.rs tests the real one's shape.
    // Under the company's own prefix (the stand-in's address; storage.rs
    // tests the real one's shape).
    assert!(url.starts_with(&format!(
        "{}/test-bucket/orgs/{a}/proof/{id}?",
        common::fake_r2()
    )));
    assert!(url.contains("X-Amz-SignedHeaders=content-length%3Bcontent-type%3Bhost"));
    assert_eq!(res.body["method"], "PUT");
    assert_eq!(res.body["headers"], json!({"Content-Type": "image/jpeg"}));

    let (owner, org_id, size, used): (String, uuid::Uuid, i64, bool) = sqlx::query_as(
        "SELECT u.email, up.org_id, up.size_bytes, up.used_at IS NOT NULL
         FROM uploads up JOIN users u ON u.id = up.owner_id WHERE up.id = $1::uuid",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert_eq!(owner, "ravi@example.com");
    assert_eq!(org_id, a);
    assert_eq!(size, 245_000);
    assert!(!used, "attached later, by the record it's for");
}

#[sqlx::test]
async fn refuses_big_or_unknown_files(db: PgPool) {
    let (a, token) = ravi(&db).await;
    for body in [
        json!({"content_type": "image/jpeg", "size_bytes": 10_485_761, "purpose": "proof"}),
        json!({"content_type": "image/jpeg", "size_bytes": 0, "purpose": "proof"}),
        json!({"content_type": "image/gif", "size_bytes": 100, "purpose": "proof"}),
        json!({"content_type": "image/png", "size_bytes": 100, "purpose": "selfie"}),
    ] {
        let res = call(
            &db,
            "POST",
            &format!("/api/v1/orgs/{a}/uploads"),
            &token,
            Some(body.clone()),
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{body}");
    }
    let rows: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(rows, 0);
}

#[sqlx::test]
async fn needs_a_login(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let res = common::post(
        &db,
        &format!("/api/v1/orgs/{a}/uploads"),
        json!({"content_type": "image/jpeg", "size_bytes": 100, "purpose": "proof"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}

#[sqlx::test]
async fn only_members_of_an_active_company_can_upload(db: PgPool) {
    let (_, token) = ravi(&db).await;
    let other = org(&db, "Solar B", "active").await;
    let suspended = org(&db, "Solar S", "suspended").await;
    common::join(&db, suspended, "ravi@example.com", "worker", None).await;
    for (company, code) in [(other, "org.not_member"), (suspended, "org.suspended")] {
        let res = call(
            &db,
            "POST",
            &format!("/api/v1/orgs/{company}/uploads"),
            &token,
            Some(json!({"content_type": "image/jpeg", "size_bytes": 100, "purpose": "proof"})),
        )
        .await;
        assert_eq!(res.status, StatusCode::FORBIDDEN);
        assert_eq!(res.body["code"], code);
    }
}

#[sqlx::test]
async fn a_company_sees_only_its_own_uploads(db: PgPool) {
    let (a, token) = ravi(&db).await;
    let b = org(&db, "Solar B", "active").await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    for company in [a, a, b] {
        call(
            &db,
            "POST",
            &format!("/api/v1/orgs/{company}/uploads"),
            &token,
            Some(json!({"content_type": "image/jpeg", "size_bytes": 100, "purpose": "proof"})),
        )
        .await;
    }
    let app = common::app_db(&db);
    let mut tx = backend::scope::company(&app, b).await.unwrap();
    let seen: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads")
        .fetch_one(&mut *tx)
        .await
        .unwrap();
    assert_eq!(seen, 1, "Solar B's one, not Solar A's two");
    drop(tx);
    app.close().await;
}
