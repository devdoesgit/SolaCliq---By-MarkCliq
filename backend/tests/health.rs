use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use backend::{AppState, app};
use http_body_util::BodyExt;
use sqlx::postgres::PgPoolOptions;
use tower::ServiceExt;

/// A pool pointing at nothing, so the database reads as down.
fn unreachable_db() -> AppState {
    let db = PgPoolOptions::new()
        .acquire_timeout(std::time::Duration::from_millis(200))
        .connect_lazy("postgres://nobody@127.0.0.1:1/none")
        .expect("lazy pool");
    AppState {
        db,
        cookie_secure: false,
        lifetimes: Default::default(),
        mailer: std::sync::Arc::new(backend::mail::LogMailer),
        code_secret: backend::codes::CodeSecret::new(
            b"test-secret-at-least-32-bytes-long".to_vec(),
        ),
    }
}

async fn get(path: &str) -> (StatusCode, Option<String>, serde_json::Value) {
    let res = app(unreachable_db())
        .oneshot(Request::get(path).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = res.status();
    let content_type = res
        .headers()
        .get("content-type")
        .map(|v| v.to_str().unwrap().to_owned());
    let body = res.into_body().collect().await.unwrap().to_bytes();
    (
        status,
        content_type,
        serde_json::from_slice(&body).unwrap_or_default(),
    )
}

#[tokio::test]
async fn health_is_503_when_the_database_is_down() {
    let (status, _, body) = get("/api/v1/health").await;
    assert_eq!(status, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(body["status"], "degraded");
    assert_eq!(body["database"], "unavailable");
    assert_eq!(body["version"], env!("CARGO_PKG_VERSION"));
}

#[tokio::test]
async fn unknown_paths_are_problem_json() {
    let (status, content_type, body) = get("/api/v1/nope").await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(content_type.as_deref(), Some("application/problem+json"));
    assert_eq!(body["code"], "common.not_found");
}

#[tokio::test]
async fn generated_spec_has_health() {
    let spec = backend::openapi::spec();
    assert!(spec.paths.paths.contains_key("/health"));
}
