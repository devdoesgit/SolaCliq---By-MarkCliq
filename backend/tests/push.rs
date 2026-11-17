//! Push notifications (F12): saving the phone's token (`PUT /me/device`)
//! and the push worker, against a stand-in for Firebase.

mod common;

use std::sync::{Mutex, OnceLock};

use axum::{Json, body::Body, http::Request, http::StatusCode, response::IntoResponse};
use backend::push::{Fcm, Sender, push_once};
use common::*;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

/*
    The stand-in FCM. Shared by every test (each uses its own tokens):
    keeps each message it's sent, and answers UNREGISTERED for a token
    starting with "gone-"
*/
static SENT: Mutex<Vec<Value>> = Mutex::new(Vec::new());
static FCM_BASE: OnceLock<String> = OnceLock::new();

fn fake_fcm() -> &'static str {
    FCM_BASE.get_or_init(|| {
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        listener.set_nonblocking(true).unwrap();
        let addr = listener.local_addr().unwrap();
        std::thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();
            rt.block_on(async move {
                let listener = tokio::net::TcpListener::from_std(listener).unwrap();
                let app = axum::Router::new().fallback(fcm_answer);
                axum::serve(listener, app).await.unwrap();
            });
        });
        format!("http://{addr}")
    })
}

async fn fcm_answer(Json(message): Json<Value>) -> axum::response::Response {
    let token = message["message"]["token"].as_str().unwrap_or_default();
    if token.starts_with("gone-") {
        let body = json!({"error": {"code": 404, "status": "NOT_FOUND",
            "details": [{"errorCode": "UNREGISTERED"}]}});
        return (StatusCode::NOT_FOUND, Json(body)).into_response();
    }
    SENT.lock().unwrap().push(message);
    Json(json!({"name": "projects/test/messages/1"})).into_response()
}

// The messages the stand-in got for this token.
fn sent_to(token: &str) -> Vec<Value> {
    SENT.lock()
        .unwrap()
        .iter()
        .filter(|m| m["message"]["token"] == token)
        .cloned()
        .collect()
}

fn sender() -> Sender {
    Sender::Fcm(Box::new(Fcm::stand_in(fake_fcm())))
}

// A unique token for this test.
fn new_token(prefix: &str) -> String {
    format!("{prefix}-{}", Uuid::now_v7())
}

async fn register(db: &PgPool, access: &str, token: &str) -> Res {
    call(
        db,
        "PUT",
        "/api/v1/me/device",
        access,
        Some(json!({ "token": token, "platform": "android" })),
    )
    .await
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

// A personal notification, written `minutes_ago`.
async fn notification(db: &PgPool, user: Uuid, minutes_ago: i64) -> Uuid {
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO notifications (id, user_id, kind, title, body, task_id, created_at)
         VALUES ($1, $2, 'task_assigned', 'New task', 'Site survey', $3,
                 now() - make_interval(mins => $4::int))",
    )
    .bind(id)
    .bind(user)
    .bind(Uuid::max())
    .bind(minutes_ago as i32)
    .execute(db)
    .await
    .unwrap();
    id
}

// The worker as the server runs it: the restricted login, in its scope.
async fn push(db: &PgPool) -> usize {
    push_once(&app_db(db), &mut sender()).await.unwrap()
}

#[sqlx::test]
async fn a_notification_reaches_the_phone_once(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let access = token(&db, "ravi@example.com").await;
    let device = new_token("ravi");
    assert_eq!(
        register(&db, &access, &device).await.status,
        StatusCode::NO_CONTENT
    );
    let id = notification(&db, user_id(&db, "ravi@example.com").await, 0).await;

    assert_eq!(push(&db).await, 1);
    let sent = sent_to(&device);
    assert_eq!(sent.len(), 1);
    let m = &sent[0]["message"];
    assert_eq!(m["notification"]["title"], "New task");
    assert_eq!(m["notification"]["body"], "Site survey");
    assert_eq!(m["data"]["notification_id"], id.to_string());
    assert_eq!(m["data"]["kind"], "task_assigned");
    assert_eq!(m["data"]["task_id"], Uuid::max().to_string());
    assert!(m["data"].get("org_id").is_none(), "personal: no company");
    assert_eq!(m["android"]["notification"]["channel_id"], "updates");

    // Handled: the next round sends nothing.
    assert_eq!(push(&db).await, 0);
    assert_eq!(sent_to(&device).len(), 1);
    let pushed: Option<chrono::DateTime<chrono::Utc>> =
        sqlx::query_scalar("SELECT pushed_at FROM notifications WHERE id = $1")
            .bind(id)
            .fetch_one(&db)
            .await
            .unwrap();
    assert!(pushed.is_some());
}

#[sqlx::test]
async fn settings_choose_whether_and_how_it_sounds(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let access = token(&db, "ravi@example.com").await;
    let device = new_token("ravi");
    register(&db, &access, &device).await;
    let ravi = user_id(&db, "ravi@example.com").await;

    let settings =
        |push: bool, sound: bool| json!({ "push": push, "whatsapp": false, "sound": sound });
    call(
        &db,
        "PUT",
        "/api/v1/me/settings",
        &access,
        Some(settings(true, false)),
    )
    .await;
    notification(&db, ravi, 0).await;
    assert_eq!(push(&db).await, 1);
    assert_eq!(
        sent_to(&device)[0]["message"]["android"]["notification"]["channel_id"],
        "updates_silent"
    );

    call(
        &db,
        "PUT",
        "/api/v1/me/settings",
        &access,
        Some(settings(false, true)),
    )
    .await;
    notification(&db, ravi, 0).await;
    assert_eq!(push(&db).await, 0, "push off: nothing sent");
    assert_eq!(sent_to(&device).len(), 1);
}

#[sqlx::test]
async fn late_or_logged_out_gets_nothing(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let access = token(&db, "ravi@example.com").await;
    let device = new_token("ravi");
    register(&db, &access, &device).await;
    let ravi = user_id(&db, "ravi@example.com").await;

    // Older than 10 minutes: not worth ringing for.
    notification(&db, ravi, 11).await;
    assert_eq!(push(&db).await, 0);

    let res = post_with(
        &db,
        "/api/v1/auth/logout",
        &[("authorization", &format!("Bearer {access}"))],
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    notification(&db, ravi, 0).await;
    assert_eq!(push(&db).await, 0, "logged out: no pushes");
    assert!(sent_to(&device).is_empty());
}

#[sqlx::test]
async fn the_phone_follows_whoever_logged_in_last(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    verified_user(&db, "meena@example.com", "sunlight1").await;
    let ravi_access = token(&db, "ravi@example.com").await;
    let meena_access = token(&db, "meena@example.com").await;
    let phone = new_token("shared");
    register(&db, &ravi_access, &phone).await;
    // Meena logs in on the same phone: the same token, her session.
    assert_eq!(
        register(&db, &meena_access, &phone).await.status,
        StatusCode::NO_CONTENT
    );

    notification(&db, user_id(&db, "ravi@example.com").await, 0).await;
    assert_eq!(
        push(&db).await,
        0,
        "Ravi no longer gets this phone's pushes"
    );
    notification(&db, user_id(&db, "meena@example.com").await, 0).await;
    assert_eq!(push(&db).await, 1);
    assert_eq!(sent_to(&phone).len(), 1);

    // A new token for Meena's session replaces her earlier one.
    let fresh = new_token("shared");
    register(&db, &meena_access, &fresh).await;
    let tokens: Vec<String> = sqlx::query_scalar("SELECT token FROM devices ORDER BY token")
        .fetch_all(&db)
        .await
        .unwrap();
    assert_eq!(tokens, vec![fresh]);
}

#[sqlx::test]
async fn an_uninstalled_app_loses_its_device(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let access = token(&db, "ravi@example.com").await;
    register(&db, &access, &new_token("gone")).await;
    notification(&db, user_id(&db, "ravi@example.com").await, 0).await;

    assert_eq!(push(&db).await, 0);
    let left: i64 = sqlx::query_scalar("SELECT count(*) FROM devices")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(left, 0);
}

#[sqlx::test]
async fn only_the_app_registers_and_the_body_is_checked(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let access = token(&db, "ravi@example.com").await;

    let res = register(&db, &access, "  ").await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "token");
    let res = call(
        &db,
        "PUT",
        "/api/v1/me/device",
        &access,
        Some(json!({ "token": "abc", "platform": "ios" })),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);

    // The website's session (a cookie): 403.
    let res = post(
        &db,
        "/api/v1/auth/login",
        json!({ "email": "ravi@example.com", "password": "sunlight1", "client": "web" }),
    )
    .await;
    let session = set_cookies(&res)
        .into_iter()
        .find(|c| c.starts_with("solacliq_session="))
        .unwrap();
    let req = Request::put("/api/v1/me/device")
        .header(
            "cookie",
            format!("solacliq_session={}", cookie_value(&session)),
        )
        .header("content-type", "application/json")
        .body(Body::from(
            json!({ "token": "abc", "platform": "android" }).to_string(),
        ))
        .unwrap();
    let res = send(&db, req).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "auth.app_only");

    // No login: 401.
    let res = register(&db, "not-a-token", "abc").await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}
