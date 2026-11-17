//! PUT and DELETE /orgs/{org_id}/logo, and the logo link in /me (F15).

mod common;

use axum::http::StatusCode;
use common::{call, get, member, org, r2_has, r2_put};
use serde_json::json;
use sqlx::PgPool;

// Asks for a logo upload as `token` and "sends" the file; returns its id and key.
async fn uploaded(db: &PgPool, a: uuid::Uuid, token: &str, size: i64) -> (String, String) {
    let res = call(
        db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        token,
        Some(json!({"content_type": "image/png", "size_bytes": size, "purpose": "logo"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["upload_id"].as_str().unwrap().to_owned();
    let key = format!("orgs/{a}/logo/{id}");
    r2_put(&key, size);
    (id, key)
}

async fn set(db: &PgPool, a: uuid::Uuid, token: &str, id: &str) -> common::Res {
    call(
        db,
        "PUT",
        &format!("/api/v1/orgs/{a}/logo"),
        token,
        Some(json!({"upload_id": id})),
    )
    .await
}

#[sqlx::test]
async fn members_see_the_logo_the_admin_sets(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    // No logo yet: no link, so the app shows initials.
    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    assert!(me.body["memberships"][0]["org"].get("logo_url").is_none());

    let (id, key) = uploaded(&db, a, &admin, 40_000).await;
    let res = set(&db, a, &admin, &id).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{}", res.body);

    let me = get(&db, "/api/v1/me", Some(&ravi)).await;
    let url = me.body["memberships"][0]["org"]["logo_url"]
        .as_str()
        .unwrap();
    assert!(url.starts_with(&format!("{}/test-bucket/{key}?", common::fake_r2())));
    assert!(url.contains("X-Amz-Signature="));
}

#[sqlx::test]
async fn a_new_logo_replaces_the_old_one_and_its_file(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let (first, first_key) = uploaded(&db, a, &admin, 40_000).await;
    assert_eq!(
        set(&db, a, &admin, &first).await.status,
        StatusCode::NO_CONTENT
    );
    let (second, second_key) = uploaded(&db, a, &admin, 50_000).await;
    assert_eq!(
        set(&db, a, &admin, &second).await.status,
        StatusCode::NO_CONTENT
    );

    assert!(!r2_has(&first_key), "the old file is deleted");
    assert!(r2_has(&second_key));
    let rows: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads WHERE org_id = $1")
        .bind(a)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(rows, 1, "only the current logo's upload is left");

    // Removing it: back to initials, file gone.
    let res = call(
        &db,
        "DELETE",
        &format!("/api/v1/orgs/{a}/logo"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    assert!(!r2_has(&second_key));
    let key: Option<String> = sqlx::query_scalar("SELECT logo_key FROM orgs WHERE id = $1")
        .bind(a)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(key, None);
}

#[sqlx::test]
async fn only_the_admin_sets_it_from_a_logo_upload(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    // A worker can neither ask for a logo upload nor set one.
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &ravi,
        Some(json!({"content_type": "image/png", "size_bytes": 100, "purpose": "logo"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    let (id, _) = uploaded(&db, a, &admin, 100).await;
    assert_eq!(set(&db, a, &ravi, &id).await.status, StatusCode::FORBIDDEN);

    // A receipt can't become the logo.
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &admin,
        Some(json!({"content_type": "image/png", "size_bytes": 100, "purpose": "receipt"})),
    )
    .await;
    let receipt = res.body["upload_id"].as_str().unwrap();
    r2_put(&format!("orgs/{a}/receipt/{receipt}"), 100);
    let res = set(&db, a, &admin, receipt).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", res.body);

    // A file that never arrived in R2 isn't taken.
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &admin,
        Some(json!({"content_type": "image/png", "size_bytes": 100, "purpose": "logo"})),
    )
    .await;
    let missing = res.body["upload_id"].as_str().unwrap();
    assert_eq!(
        set(&db, a, &admin, missing).await.status,
        StatusCode::UNPROCESSABLE_ENTITY
    );
}

#[sqlx::test]
async fn a_logo_is_a_small_image(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "dev@example.com", "org_admin", None).await;
    for (body, field) in [
        (
            json!({"content_type": "application/pdf", "size_bytes": 100, "purpose": "logo"}),
            "content_type",
        ),
        (
            json!({"content_type": "image/png", "size_bytes": 1_048_577, "purpose": "logo"}),
            "size_bytes",
        ),
    ] {
        let res = call(
            &db,
            "POST",
            &format!("/api/v1/orgs/{a}/uploads"),
            &admin,
            Some(body),
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", res.body);
        assert!(res.body.to_string().contains(field), "{}", res.body);
    }
}

#[sqlx::test]
async fn another_companys_upload_cant_be_its_logo(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    let admin_a = member(&db, a, "dev@example.com", "org_admin", None).await;
    let admin_b = member(&db, b, "asha@example.com", "org_admin", None).await;
    let (id, _) = uploaded(&db, b, &admin_b, 100).await;
    assert_eq!(
        set(&db, a, &admin_a, &id).await.status,
        StatusCode::UNPROCESSABLE_ENTITY
    );
}
