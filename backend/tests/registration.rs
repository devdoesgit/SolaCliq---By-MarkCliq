//! Company registration and MarkCliq's review (F2). Needs `make db`.

mod common;

use axum::http::StatusCode;
use common::{call, emails_to, get, post, token, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const REGISTER: &str = "/api/v1/org-registrations";
// A GSTIN published as an example by GST portals (Maharashtra).
const GSTIN: &str = "27AAPFU0939F1ZV";

fn registration(email: &str) -> Value {
    json!({
        "legal_name": "Example Solar Private Limited",
        "trade_name": "Example Solar",
        "business_type": "private_limited",
        "gstin": "27aapfu0939f1zv",
        "address_line_1": "Plot 4, MIDC",
        "city": "Pune",
        "pin_code": "411001",
        "owner_name": "Asha Owner",
        "email": email,
        "phone": "98140 22671",
        "terms_version": 1,
    })
}

// A logged-in platform admin's token.
async fn platform_admin(db: &PgPool) -> String {
    verified_user(db, "parth@example.com", "sunlight1").await;
    assert!(
        backend::seed::make_platform_admin(db, "parth@example.com")
            .await
            .unwrap()
    );
    token(db, "parth@example.com").await
}

async fn org_id(db: &PgPool) -> Uuid {
    sqlx::query_scalar("SELECT id FROM orgs WHERE gstin = $1 AND status <> 'rejected'")
        .bind(GSTIN)
        .fetch_one(db)
        .await
        .unwrap()
}

fn status_path(org: Uuid) -> String {
    format!("/api/v1/platform/orgs/{org}/status")
}

#[sqlx::test]
async fn a_registration_is_saved_as_pending_with_its_owner(db: PgPool) {
    let res = post(&db, REGISTER, registration("asha@example.com")).await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);

    let admin = platform_admin(&db).await;
    let org = org_id(&db).await;
    let res = get(&db, &format!("/api/v1/platform/orgs/{org}"), Some(&admin)).await;
    assert_eq!(res.status, StatusCode::OK);
    let b = &res.body;
    assert_eq!(b["name"], "Example Solar");
    assert_eq!(b["status"], "pending");
    assert_eq!(b["gstin"], GSTIN);
    assert_eq!(b["pan"], "AAPFU0939F");
    assert_eq!(b["state"], "Maharashtra");
    assert_eq!(b["phone"], "9814022671");
    assert_eq!(b["owner"]["email"], "asha@example.com");
    assert_eq!(b["owner"]["name"], "Asha Owner");

    // MarkCliq is told, and so is the owner.
    let review = emails_to("review@example.com");
    assert!(review.iter().any(|e| e.body.contains(&org.to_string())));
    assert!(!emails_to("asha@example.com").is_empty());
}

#[sqlx::test]
async fn the_owner_sees_a_pending_company_but_none_of_its_data(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    post(&db, REGISTER, registration("asha@example.com")).await;
    let owner = token(&db, "asha@example.com").await;

    // An existing account is used as it is, now with a pending company.
    let me = get(&db, "/api/v1/me", Some(&owner)).await;
    assert_eq!(me.body["name"], "Asha Example");
    assert_eq!(me.body["memberships"][0]["org"]["status"], "pending");
    assert_eq!(me.body["memberships"][0]["role"], "org_admin");

    let org = org_id(&db).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{org}/members"),
        &owner,
        None,
    )
    .await;
    assert_eq!(res.body["code"], "org.pending");
}

#[sqlx::test]
async fn bad_details_are_refused_and_nothing_is_saved(db: PgPool) {
    // A typo in the GSTIN alone gets its own code.
    let mut body = registration("asha@example.com");
    body["gstin"] = json!("27AAPFU0939F1ZW");
    let res = post(&db, REGISTER, body).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "org.gstin_invalid");

    // Several bad fields: all of them at once.
    let mut body = registration("not-an-email");
    body["pin_code"] = json!("011001");
    body["phone"] = json!("12345");
    body["gstin"] = json!("nope");
    let res = post(&db, REGISTER, body).await;
    assert_eq!(res.body["code"], "validation.failed");
    let fields: Vec<_> = res.body["errors"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["field"].as_str().unwrap())
        .collect();
    assert_eq!(fields, ["pin_code", "email", "phone", "gstin"]);

    let orgs: i64 = sqlx::query_scalar("SELECT count(*) FROM orgs")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(orgs, 0);
}

#[sqlx::test]
async fn a_gstin_registers_once_until_rejected(db: PgPool) {
    post(&db, REGISTER, registration("asha@example.com")).await;
    let res = post(&db, REGISTER, registration("someone@example.com")).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "org.gstin_taken");

    // Rejected: the GSTIN is free again.
    let admin = platform_admin(&db).await;
    let org = org_id(&db).await;
    let res = call(
        &db,
        "POST",
        &status_path(org),
        &admin,
        Some(json!({"status": "rejected", "note": "GSTIN is cancelled"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let res = post(&db, REGISTER, registration("asha@example.com")).await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
}

#[sqlx::test]
async fn approving_opens_the_company_and_emails_the_owner(db: PgPool) {
    verified_user(&db, "asha@example.com", "sunlight1").await;
    post(&db, REGISTER, registration("asha@example.com")).await;
    let admin = platform_admin(&db).await;
    let org = org_id(&db).await;

    let res = call(
        &db,
        "GET",
        "/api/v1/platform/orgs?status=pending",
        &admin,
        None,
    )
    .await;
    assert_eq!(res.body["items"].as_array().unwrap().len(), 1);

    let res = call(
        &db,
        "POST",
        &status_path(org),
        &admin,
        Some(json!({"status": "active"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "active");
    assert!(res.body["reviewed_at"].is_string());
    let mail = emails_to("asha@example.com").pop().unwrap();
    assert!(mail.subject.contains("approved"), "{}", mail.subject);

    // The owner can now use their company.
    let owner = token(&db, "asha@example.com").await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{org}/members"),
        &owner,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
}

#[sqlx::test]
async fn status_moves_follow_the_rules(db: PgPool) {
    post(&db, REGISTER, registration("asha@example.com")).await;
    let admin = platform_admin(&db).await;
    let org = org_id(&db).await;
    let set = |status: &'static str, note: Option<&'static str>| {
        let (db, admin) = (db.clone(), admin.clone());
        async move {
            call(
                &db,
                "POST",
                &status_path(org),
                &admin,
                Some(json!({"status": status, "note": note})),
            )
            .await
        }
    };

    // Pending can't be suspended, and a rejection needs a reason.
    assert_eq!(
        set("suspended", None).await.body["code"],
        "org.status_change_not_allowed"
    );
    assert_eq!(
        set("rejected", None).await.body["code"],
        "validation.failed"
    );
    // Approve → suspend → reactivate; an approved company can't be rejected.
    assert_eq!(set("active", None).await.status, StatusCode::OK);
    assert_eq!(
        set("rejected", Some("x")).await.status,
        StatusCode::CONFLICT
    );
    assert_eq!(
        set("suspended", Some("Unpaid")).await.body["review_note"],
        "Unpaid"
    );
    assert_eq!(set("active", None).await.body["status"], "active");

    let res = call(
        &db,
        "POST",
        &status_path(Uuid::now_v7()),
        &admin,
        Some(json!({"status": "active"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
}

#[sqlx::test]
async fn only_platform_admins_reach_the_platform(db: PgPool) {
    verified_user(&db, "ravi@example.com", "sunlight1").await;
    let ravi = token(&db, "ravi@example.com").await;
    let res = call(&db, "GET", "/api/v1/platform/orgs", &ravi, None).await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "platform.not_admin");
    let res = get(&db, "/api/v1/platform/orgs", None).await;
    assert_eq!(res.status, StatusCode::UNAUTHORIZED);
}

#[sqlx::test]
async fn a_malformed_id_is_a_problem_404(db: PgPool) {
    let admin = platform_admin(&db).await;
    let res = call(&db, "GET", "/api/v1/platform/orgs/not-an-id", &admin, None).await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
    assert_eq!(res.body["code"], "common.not_found");
}
