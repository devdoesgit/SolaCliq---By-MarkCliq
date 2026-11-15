//! Phase 6: the Personal workspace (quotes, details, settings, the
//! personal feed). Needs `make db`.

mod common;

use axum::http::StatusCode;
use common::{call, call_with, emails_to, get, token, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const QUOTES: &str = "/api/v1/quote-requests";

fn quote() -> Value {
    json!({
        "quote_for": "home", "pin_code": "160062", "city": "Mohali",
        "bill_band": "from_3000_to_6000", "roof": "rcc",
        "timeline": "this_month", "phone": "98140 22671", "share_consent": true,
    })
}

async fn asha(db: &PgPool) -> String {
    verified_user(db, "asha@example.com", "sunlight1").await;
    token(db, "asha@example.com").await
}

async fn ask(db: &PgPool, t: &str, body: Value, key: &str) -> common::Res {
    call_with(
        db,
        "POST",
        QUOTES,
        t,
        Some(body),
        &[("idempotency-key", key)],
    )
    .await
}

// Rows in `table`; always a table name written in this file.
async fn count(db: &PgPool, table: &'static str) -> i64 {
    sqlx::query_scalar(sqlx::AssertSqlSafe(format!("SELECT count(*) FROM {table}")))
        .fetch_one(db)
        .await
        .unwrap()
}

// ------------------------------------------------------------- quotes

#[sqlx::test]
async fn a_quote_request_is_saved_estimated_emailed_and_notified(db: PgPool) {
    let t = asha(&db).await;
    let res = ask(&db, &t, quote(), &Uuid::now_v7().to_string()).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(res.body["status"], "open");
    assert_eq!(
        res.body["estimate"],
        json!({"kw_min": 3, "kw_max": 5, "price_min": 16_500_000,
               "price_max": 32_500_000, "subsidy_max": 7_800_000})
    );

    let lead = emails_to("review@example.com")
        .into_iter()
        .find(|e| e.subject.contains("quote request"))
        .unwrap();
    assert!(lead.body.contains("+91 9814022671"), "{}", lead.body);

    let feed = get(&db, "/api/v1/me/notifications", Some(&t)).await;
    assert_eq!(feed.body["unread_count"], 1);
    assert_eq!(feed.body["items"][0]["kind"], "quote_shared");

    let res = call(&db, "POST", "/api/v1/me/notifications/read", &t, None).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    let feed = get(&db, "/api/v1/me/notifications", Some(&t)).await;
    assert_eq!(feed.body["unread_count"], 0);
    assert_eq!(feed.body["items"][0]["read"], true);
}

#[sqlx::test]
async fn a_retry_with_the_same_key_creates_nothing_new(db: PgPool) {
    let t = asha(&db).await;
    let key = Uuid::now_v7().to_string();
    let first = ask(&db, &t, quote(), &key).await;
    let again = ask(&db, &t, quote(), &key).await;
    assert_eq!(again.status, StatusCode::CREATED);
    assert_eq!(again.body["id"], first.body["id"]);
    assert_eq!(count(&db, "quote_requests").await, 1);
    assert_eq!(count(&db, "notifications").await, 1);

    // Racing with one key: still one.
    let key = Uuid::now_v7().to_string();
    let (a, b) = tokio::join!(ask(&db, &t, quote(), &key), ask(&db, &t, quote(), &key));
    assert_eq!(a.body["id"], b.body["id"]);
    assert_eq!(count(&db, "quote_requests").await, 2);
}

#[sqlx::test]
async fn quote_rules(db: PgPool) {
    let t = asha(&db).await;
    let k = || Uuid::now_v7().to_string();

    let res = call(&db, "POST", QUOTES, &t, Some(quote())).await;
    assert_eq!(res.body["code"], "validation.failed", "no Idempotency-Key");

    let mut body = quote();
    body["share_consent"] = json!(false);
    assert_eq!(
        ask(&db, &t, body, &k()).await.body["code"],
        "quote.consent_required"
    );

    let mut body = quote();
    body.as_object_mut().unwrap().remove("phone");
    assert_eq!(
        ask(&db, &t, body, &k()).await.body["code"],
        "quote.phone_required"
    );

    let mut body = quote();
    body["pin_code"] = json!("011001");
    assert_eq!(
        ask(&db, &t, body, &k()).await.body["code"],
        "validation.failed"
    );
    assert_eq!(count(&db, "quote_requests").await, 0);
}

// ------------------------------------------------------------ details

#[sqlx::test]
async fn details_save_partially_and_keep_the_bank_number_secret(db: PgPool) {
    let t = asha(&db).await;
    let empty = get(&db, "/api/v1/me/details", Some(&t)).await;
    assert_eq!(empty.body, json!({}));

    let res = call(
        &db,
        "PUT",
        "/api/v1/me/details",
        &t,
        Some(json!({"phone": "98765 11223", "address": "H.No 12, Mohali",
                    "bank": {"holder": "Asha", "account_number": "001234567890",
                             "ifsc": "hdfc0001234"}})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(
        res.body,
        json!({"phone": "9876511223", "address": "H.No 12, Mohali",
               "bank": {"holder": "Asha", "account_last4": "7890",
                        "ifsc": "HDFC0001234", "bank_name": "HDFC Bank"}})
    );

    // Stored encrypted, never as the number.
    let stored: Vec<u8> = sqlx::query_scalar("SELECT bank_account_enc FROM user_details")
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(!stored.windows(12).any(|w| w == b"001234567890"));

    // Only what is sent changes; a blank clears it.
    let res = call(
        &db,
        "PUT",
        "/api/v1/me/details",
        &t,
        Some(json!({"address": " "})),
    )
    .await;
    assert!(res.body.get("address").is_none());
    assert_eq!(res.body["phone"], "9876511223");
    assert_eq!(res.body["bank"]["account_last4"], "7890");
}

#[sqlx::test]
async fn a_bank_needs_a_valid_number_and_ifsc(db: PgPool) {
    let t = asha(&db).await;
    let res = call(
        &db,
        "PUT",
        "/api/v1/me/details",
        &t,
        Some(json!({"bank": {"account_number": "12ab", "ifsc": "HDFC1001234"}})),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    let fields: Vec<_> = res.body["errors"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["field"].as_str().unwrap())
        .collect();
    assert_eq!(fields, ["bank.account_number", "bank.ifsc"]);
    assert_eq!(count(&db, "user_details").await, 0);
}

// ----------------------------------------------------------- settings

#[sqlx::test]
async fn settings_start_from_defaults_and_save(db: PgPool) {
    let t = asha(&db).await;
    let res = get(&db, "/api/v1/me/settings", Some(&t)).await;
    assert_eq!(
        res.body,
        json!({"push": true, "whatsapp": false, "sound": true, "language": "en"})
    );
    let mine = json!({"push": false, "whatsapp": true, "sound": false, "language": "pa"});
    let res = call(&db, "PUT", "/api/v1/me/settings", &t, Some(mine.clone())).await;
    assert_eq!(res.body, mine);
    assert_eq!(get(&db, "/api/v1/me/settings", Some(&t)).await.body, mine);

    let bad = json!({"push": true, "whatsapp": true, "sound": true, "language": "fr"});
    let res = call(&db, "PUT", "/api/v1/me/settings", &t, Some(bad)).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
}

#[sqlx::test]
async fn the_personal_feed_needs_a_login(db: PgPool) {
    let res = get(&db, "/api/v1/me/notifications", None).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}
