//! POST /uploads: a signed URL for one file, and its row.

mod common;

use axum::http::StatusCode;
use common::{call, member, org};
use serde_json::json;
use sqlx::PgPool;

async fn ravi(db: &PgPool) -> String {
    let a = org(db, "Solar A", "active").await;
    member(db, a, "ravi@example.com", "worker", None).await
}

#[sqlx::test]
async fn gives_a_signed_url_for_exactly_that_file(db: PgPool) {
    let token = ravi(&db).await;
    let res = call(
        &db,
        "POST",
        "/api/v1/uploads",
        &token,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 245_000, "purpose": "proof"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["upload_id"].as_str().unwrap();
    let url = res.body["url"].as_str().unwrap();
    assert!(url.starts_with(&format!(
        "https://test-account.r2.cloudflarestorage.com/test-bucket/proof/{id}?"
    )));
    assert!(url.contains("X-Amz-SignedHeaders=content-length%3Bcontent-type%3Bhost"));
    assert_eq!(res.body["method"], "PUT");
    assert_eq!(res.body["headers"], json!({"Content-Type": "image/jpeg"}));

    let (owner, size, used): (String, i64, bool) = sqlx::query_as(
        "SELECT u.email, up.size_bytes, up.used_at IS NOT NULL
         FROM uploads up JOIN users u ON u.id = up.owner_id WHERE up.id = $1::uuid",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert_eq!(owner, "ravi@example.com");
    assert_eq!(size, 245_000);
    assert!(!used, "attached later, by the record it's for");
}

#[sqlx::test]
async fn refuses_big_or_unknown_files(db: PgPool) {
    let token = ravi(&db).await;
    for body in [
        json!({"content_type": "image/jpeg", "size_bytes": 10_485_761, "purpose": "proof"}),
        json!({"content_type": "image/jpeg", "size_bytes": 0, "purpose": "proof"}),
        json!({"content_type": "image/gif", "size_bytes": 100, "purpose": "proof"}),
        json!({"content_type": "image/png", "size_bytes": 100, "purpose": "selfie"}),
    ] {
        let res = call(&db, "POST", "/api/v1/uploads", &token, Some(body.clone())).await;
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
    let res = common::post(
        &db,
        "/api/v1/uploads",
        json!({"content_type": "image/jpeg", "size_bytes": 100, "purpose": "proof"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}
