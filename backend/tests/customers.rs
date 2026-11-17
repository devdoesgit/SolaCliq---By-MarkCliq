//! Customers an agent registers (phase 9, F4): registration with KYC,
//! the agent's list and detail, fixing a returned document, and "my
//! documents".

mod common;

use axum::http::StatusCode;
use common::{Res, call, call_with, emails_to, member, org, r2_put};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

// Solar A with Meena (commission agent); her token.
async fn setup(db: &PgPool) -> (Uuid, String) {
    let a = org(db, "Solar A", "active").await;
    (
        a,
        member(db, a, "meena@example.com", "agent", Some("commission")).await,
    )
}

// A KYC photo the app uploaded (to the R2 stand-in).
async fn kyc_file(db: &PgPool, org: Uuid, token: &str) -> String {
    let res = call(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/uploads"),
        token,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 3000, "purpose": "kyc"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["upload_id"].as_str().unwrap().to_owned();
    r2_put(&format!("orgs/{org}/kyc/{id}"), 3000);
    id
}

// A full registration for `email`, with every required document.
async fn form(db: &PgPool, org: Uuid, token: &str, email: &str, phone: &str) -> Value {
    let mut documents = Vec::new();
    for kind in [
        "aadhaar",
        "pan",
        "electricity_bill",
        "land_document",
        "signature",
    ] {
        documents.push(json!({"kind": kind, "upload_id": kyc_file(db, org, token).await}));
    }
    json!({
        "name": "Rajinder Kaur", "phone": phone, "email": email,
        "address": "House 12, Sector 70", "city": "Mohali", "pin_code": "160062",
        "state": "Punjab", "discom": "PSPCL", "consumer_number": format!("C-{phone}"),
        "sanctioned_load_kw": 5, "connection_type": "residential", "proposed_kw": 5,
        "roof": "rcc", "subsidy": false, "documents": documents, "consent": true,
        "commission": 400_000, "commission_note": "Standard rate"
    })
}

async fn register(db: &PgPool, org: Uuid, token: &str, body: Value) -> Res {
    call_with(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/customer-registrations"),
        token,
        Some(body),
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await
}

async fn count(db: &PgPool, sql: &'static str) -> i64 {
    sqlx::query_scalar(sql).fetch_one(db).await.unwrap()
}

#[sqlx::test]
async fn registers_a_customer_with_their_kyc(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let body = form(&db, a, &meena, "rajinder.new@example.com", "9814000101").await;
    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(res.body["reference"], "SC-0001");
    assert_eq!(res.body["status"], "submitted");

    // Their account: made with no password, a customer here.
    let (has_password, role): (bool, String) = sqlx::query_as(
        "SELECT u.password_hash IS NOT NULL, m.role::text FROM users u
         JOIN memberships m ON m.user_id = u.id AND m.org_id = $1
         WHERE u.email = 'rajinder.new@example.com'",
    )
    .bind(a)
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(!has_password);
    assert_eq!(role, "customer");
    assert_eq!(count(&db, "SELECT count(*) FROM documents").await, 5);
    assert_eq!(
        count(
            &db,
            "SELECT count(*) FROM uploads WHERE used_at IS NOT NULL"
        )
        .await,
        5
    );

    // The email: who, what, and how to set up.
    let email = emails_to("rajinder.new@example.com").pop().unwrap();
    assert!(
        email
            .body
            .contains("registered you for a solar installation")
    );
    assert!(email.body.contains("Forgot password?"));

    // In Meena's list, with the admin, her commission waiting too.
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers"),
        &meena,
        None,
    )
    .await;
    let c = &res.body["items"][0];
    assert_eq!(c["name"], "Rajinder Kaur");
    assert_eq!(c["kyc_status"], "in_review");
    assert_eq!(c["detail"], "Sent today");
    assert_eq!(c["place"], "Mohali");
    assert_eq!(c["system_kw"], 5.0);
    assert_eq!(
        c["commission"],
        json!({"amount": 400_000, "status": "in_review"})
    );
}

#[sqlx::test]
async fn refuses_missing_documents_consent_and_commission(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let base = form(&db, a, &meena, "x@example.com", "9814000102").await;

    let mut no_pan = base.clone();
    no_pan["documents"]
        .as_array_mut()
        .unwrap()
        .retain(|d| d["kind"] != "pan");
    let res = register(&db, a, &meena, no_pan).await;
    assert_eq!(res.body["code"], "registration.document_required");
    assert_eq!(res.body["detail"], "PAN is required.");

    let mut subsidy = base.clone();
    subsidy["subsidy"] = json!(true);
    let res = register(&db, a, &meena, subsidy).await;
    assert_eq!(res.body["code"], "registration.bank_proof_required");

    let mut no_consent = base.clone();
    no_consent["consent"] = json!(false);
    no_consent["pin_code"] = json!("012345");
    let res = register(&db, a, &meena, no_consent).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    let fields: Vec<_> = res.body["errors"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["field"].as_str().unwrap())
        .collect();
    assert_eq!(fields, ["pin_code", "consent"], "every field at once");

    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let res = register(&db, a, &aman, base).await;
    assert_eq!(res.body["code"], "registration.commission_not_allowed");

    assert_eq!(count(&db, "SELECT count(*) FROM customers").await, 0);
    assert_eq!(
        count(
            &db,
            "SELECT count(*) FROM users WHERE email = 'x@example.com'"
        )
        .await,
        0,
        "no account for a refused registration"
    );
}

#[sqlx::test]
async fn a_customer_is_registered_once(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let first = form(&db, a, &meena, "same@example.com", "9814000103").await;
    assert_eq!(
        register(&db, a, &meena, first).await.status,
        StatusCode::CREATED
    );

    // Aman brings the same household: same phone, another email.
    let mut again = form(&db, a, &aman, "other@example.com", "9814000103").await;
    again.as_object_mut().unwrap().remove("commission");
    let res = register(&db, a, &aman, again).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "registration.duplicate");
    let detail = res.body["detail"].as_str().unwrap();
    assert!(
        detail.starts_with("Asha Example registered this customer on"),
        "{detail}"
    );
    assert!(detail.ends_with("(SC-0001)."), "{detail}");

    // Another company may still register them.
    let b = org(&db, "Solar B", "active").await;
    let ravi = member(
        &db,
        b,
        "ravi.agent@example.com",
        "agent",
        Some("commission"),
    )
    .await;
    let other = form(&db, b, &ravi, "same@example.com", "9814000103").await;
    assert_eq!(
        register(&db, b, &ravi, other).await.status,
        StatusCode::CREATED
    );
}

#[sqlx::test]
async fn links_existing_accounts_safely(db: PgPool) {
    let (a, meena) = setup(&db).await;
    // A verified account: linked, told to log in as usual.
    common::verified_user(&db, "verified@example.com", "sunlight1").await;
    let body = form(&db, a, &meena, "verified@example.com", "9814000104").await;
    assert_eq!(
        register(&db, a, &meena, body).await.status,
        StatusCode::CREATED
    );
    let email = emails_to("verified@example.com").pop().unwrap();
    assert!(email.body.contains("Log in as usual"));
    let still: bool = sqlx::query_scalar(
        "SELECT password_hash IS NOT NULL FROM users WHERE email = 'verified@example.com'",
    )
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(still, "a verified account keeps its password");

    // Signed up with this email but never verified it: anyone could have.
    let res = common::post(
        &db,
        "/api/v1/auth/signup",
        json!({"name": "Someone", "email": "unverified@example.com", "password": "sunlight1"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED);
    let body = form(&db, a, &meena, "unverified@example.com", "9814000105").await;
    assert_eq!(
        register(&db, a, &meena, body).await.status,
        StatusCode::CREATED
    );
    let cleared: bool = sqlx::query_scalar(
        "SELECT password_hash IS NULL FROM users WHERE email = 'unverified@example.com'",
    )
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(cleared, "only the email's owner may set a password now");
    let email = emails_to("unverified@example.com").pop().unwrap();
    assert!(email.body.contains("Forgot password?"));
}

#[sqlx::test]
async fn someone_already_in_the_company_is_refused(db: PgPool) {
    let (a, meena) = setup(&db).await;
    member(&db, a, "neha@example.com", "worker", None).await;
    let body = form(&db, a, &meena, "neha@example.com", "9814000106").await;
    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "registration.duplicate");
    assert!(
        res.body["detail"]
            .as_str()
            .unwrap()
            .contains("an EPC installer")
    );
}

#[sqlx::test]
async fn a_kyc_file_that_never_reached_r2_stops_it(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let mut body = form(&db, a, &meena, "lost@example.com", "9814000107").await;
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &meena,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 3000, "purpose": "kyc"})),
    )
    .await;
    body["documents"][0]["upload_id"] = res.body["upload_id"].clone();
    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "documents");
    assert_eq!(count(&db, "SELECT count(*) FROM customers").await, 0);
    assert_eq!(
        count(
            &db,
            "SELECT count(*) FROM users WHERE email = 'lost@example.com'"
        )
        .await,
        0
    );
}

#[sqlx::test]
async fn a_retry_registers_once(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let body = form(&db, a, &meena, "retry@example.com", "9814000108").await;
    let key = Uuid::now_v7().to_string();
    let path = format!("/api/v1/orgs/{a}/customer-registrations");
    let headers = [("idempotency-key", key.as_str())];
    let first = call_with(&db, "POST", &path, &meena, Some(body.clone()), &headers).await;
    let again = call_with(&db, "POST", &path, &meena, Some(body), &headers).await;
    assert_eq!(
        again.status,
        StatusCode::CREATED,
        "not a duplicate: the same request"
    );
    assert_eq!(again.body["id"], first.body["id"]);
    assert_eq!(count(&db, "SELECT count(*) FROM customers").await, 1);
    assert_eq!(emails_to("retry@example.com").len(), 1, "emailed once");
}

#[sqlx::test]
async fn only_agents_see_only_their_own(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let body = form(&db, a, &meena, "own@example.com", "9814000109").await;
    let id = register(&db, a, &meena, body).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();

    let path = format!("/api/v1/orgs/{a}/my-customers/{id}");
    assert_eq!(
        call(&db, "GET", &path, &meena, None).await.status,
        StatusCode::OK
    );
    assert_eq!(
        call(&db, "GET", &path, &aman, None).await.status,
        StatusCode::NOT_FOUND
    );
    let list = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers"),
        &aman,
        None,
    )
    .await;
    assert_eq!(list.body["items"], json!([]));
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers"),
        &worker,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
}

#[sqlx::test]
async fn a_returned_document_takes_a_new_copy(db: PgPool) {
    let (a, meena) = setup(&db).await;
    member(&db, a, "dev@example.com", "org_admin", None).await;
    let body = form(&db, a, &meena, "fix@example.com", "9814000110").await;
    let id = register(&db, a, &meena, body).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();

    // The admin sends the bill back (the website's job; SQL here).
    sqlx::query(
        "UPDATE documents SET status = 'needs_fix', admin_note = 'Photo is blurry.',
                              admin_note_by = (SELECT id FROM users WHERE email = 'dev@example.com'),
                              admin_note_at = now()
         WHERE customer_id = $1::uuid AND kind = 'electricity_bill'",
    )
    .bind(&id)
    .execute(&db)
    .await
    .unwrap();
    sqlx::query("UPDATE customers SET kyc_status = 'needs_fix' WHERE id = $1::uuid")
        .bind(&id)
        .execute(&db)
        .await
        .unwrap();

    let path = format!("/api/v1/orgs/{a}/my-customers/{id}");
    let res = call(&db, "GET", &path, &meena, None).await;
    assert_eq!(res.body["detail"], "Electricity bill: Photo is blurry.");
    assert_eq!(res.body["returned"]["kind"], "electricity_bill");
    assert_eq!(res.body["returned"]["note"]["by"]["role"], "Admin");
    assert_eq!(res.body["documents"]["status"], "needs_fix");

    // Only the bill was sent back.
    let file = kyc_file(&db, a, &meena).await;
    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/pan"),
        &meena,
        Some(json!({"upload_id": file})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "registration.locked");

    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/electricity_bill"),
        &meena,
        Some(json!({"upload_id": file})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["kyc_status"], "in_review");
    assert!(res.body.get("returned").is_none());
    assert_eq!(res.body["documents"]["detail"], "5 with the admin");
}

#[sqlx::test]
async fn approved_and_rejected_customers_read_plainly(db: PgPool) {
    let (a, meena) = setup(&db).await;
    for (email, phone) in [
        ("one@example.com", "9814000111"),
        ("two@example.com", "9814000112"),
    ] {
        let body = form(&db, a, &meena, email, phone).await;
        register(&db, a, &meena, body).await;
    }
    sqlx::query(
        "UPDATE customers SET kyc_status = 'approved', stage_index = 2 WHERE email = 'one@example.com'",
    )
    .execute(&db)
    .await
    .unwrap();
    sqlx::query(
        "UPDATE customers SET kyc_status = 'rejected', rejected_note = 'Roof too shaded.'
         WHERE email = 'two@example.com'",
    )
    .execute(&db)
    .await
    .unwrap();
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers"),
        &meena,
        None,
    )
    .await;
    let items = res.body["items"].as_array().unwrap();
    assert_eq!(items[0]["kyc_status"], "rejected");
    assert_eq!(items[0]["detail"], "Roof too shaded.");
    // Not taken up: no documents "with the admin" any more.
    let rejected = items[0]["id"].as_str().unwrap();
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers/{rejected}"),
        &meena,
        None,
    )
    .await;
    assert!(res.body.get("documents").is_none(), "{}", res.body);
    assert_eq!(items[1]["detail"], "Stage 2 · Structure");
    let id = items[1]["id"].as_str().unwrap();
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers/{id}"),
        &meena,
        None,
    )
    .await;
    assert_eq!(
        res.body["stage"],
        json!({"index": 2, "count": 7, "label": "Structure"})
    );
}

#[sqlx::test]
async fn customers_and_workers_see_their_documents(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let body = form(&db, a, &meena, "rajinder.docs@example.com", "9814000113").await;
    register(&db, a, &meena, body).await;
    // Rajinder sets up the account, then opens Documents.
    sqlx::query(
        "UPDATE users SET email_verified_at = now(),
                          password_hash = (SELECT password_hash FROM users WHERE email = 'meena@example.com')
         WHERE email = 'rajinder.docs@example.com'",
    )
    .execute(&db)
    .await
    .unwrap();
    let rajinder = common::token(&db, "rajinder.docs@example.com").await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/me/documents"),
        &rajinder,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["items"].as_array().unwrap().len(), 5);
    assert_eq!(res.body["items"][0]["kind"], "aadhaar");
    assert_eq!(res.body["items"][0]["status"], "in_review");
    assert_eq!(res.body["uploaded_by"], "Asha Example");

    let worker = member(&db, a, "ravi@example.com", "worker", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/me/documents"),
        &worker,
        None,
    )
    .await;
    assert_eq!(res.body, json!({"items": []}));
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/me/documents"),
        &meena,
        None,
    )
    .await;
    assert_eq!(
        res.status,
        StatusCode::FORBIDDEN,
        "agents have my-customers"
    );
}

#[sqlx::test]
async fn the_agents_home_counts_their_customers(db: PgPool) {
    let (a, meena) = setup(&db).await;
    for (email, phone) in [
        ("h1@example.com", "9814000114"),
        ("h2@example.com", "9814000115"),
    ] {
        let body = form(&db, a, &meena, email, phone).await;
        register(&db, a, &meena, body).await;
    }
    sqlx::query(
        "UPDATE customers SET kyc_status = 'approved', commission_status = 'payable'
         WHERE email = 'h1@example.com'",
    )
    .execute(&db)
    .await
    .unwrap();
    let res = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &meena, None).await;
    let h = &res.body;
    assert_eq!(h["headline"]["value"], "2");
    assert_eq!(h["tiles"][1]["value"], "₹4,000", "the payable commission");
    assert_eq!(h["progress"]["trailing"], "2 total");
    assert_eq!(h["list"]["rows"][0]["action"], "customer");
    assert_eq!(h["list"]["rows"][0]["initials"], "RK");
}

#[sqlx::test]
async fn a_new_customer_sets_up_and_follows_their_install(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let email = "balwinder@example.com";
    let body = form(&db, a, &meena, email, "9814000116").await;
    assert_eq!(
        register(&db, a, &meena, body).await.status,
        StatusCode::CREATED
    );

    // No password yet: the app sends them to "Set up your account".
    let login = |password: &'static str| {
        common::post(
            &db,
            "/api/v1/auth/login",
            json!({"email": email, "password": password, "client": "app"}),
        )
    };
    assert_eq!(
        login("moonlight44").await.body["code"],
        "account.password_not_set"
    );

    // The emailed code sets a password (and verifies the email).
    common::post(&db, "/api/v1/auth/password/forgot", json!({"email": email})).await;
    let res = common::post(
        &db,
        "/api/v1/auth/password/reset",
        json!({"email": email, "code": common::last_code(email), "new_password": "moonlight44"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{}", res.body);
    let res = login("moonlight44").await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let token = res.body["tokens"]["access_token"]
        .as_str()
        .unwrap()
        .to_owned();

    // The company is in their workspaces, as a customer.
    let membership = &res.body["user"]["memberships"][0];
    assert_eq!(membership["org"]["id"], a.to_string());
    assert_eq!(membership["role"], "customer");

    // Their documents, collected by Meena, and their home.
    let docs = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/me/documents"),
        &token,
        None,
    )
    .await;
    assert_eq!(docs.body["items"].as_array().unwrap().len(), 5);
    let home = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &token, None).await;
    assert_eq!(home.status, StatusCode::OK);
    assert_eq!(home.body["eyebrow"], "Your solar");
}

#[sqlx::test]
async fn whoever_signed_up_with_the_email_loses_the_account(db: PgPool) {
    let (a, meena) = setup(&db).await;
    // Someone signed up with this email (never verified it), password known to them.
    common::post(
        &db,
        "/api/v1/auth/signup",
        json!({"name": "Not Them", "email": "taken@example.com", "password": "squatter99"}),
    )
    .await;
    let body = form(&db, a, &meena, "taken@example.com", "9814000117").await;
    assert_eq!(
        register(&db, a, &meena, body).await.status,
        StatusCode::CREATED
    );
    sqlx::query("UPDATE users SET email_verified_at = now() WHERE email = 'taken@example.com'")
        .execute(&db)
        .await
        .unwrap();
    // Even with the email verified later, the old password opens nothing.
    let res = common::post(
        &db,
        "/api/v1/auth/login",
        json!({"email": "taken@example.com", "password": "squatter99", "client": "app"}),
    )
    .await;
    assert_ne!(res.status, StatusCode::OK);
}

#[sqlx::test]
async fn subsidy_and_optional_documents(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let mut body = form(&db, a, &meena, "subsidy@example.com", "9814000118").await;
    body["subsidy"] = json!(true);
    for kind in ["bank_proof", "roof_photo", "name_change"] {
        let file = kyc_file(&db, a, &meena).await;
        body["documents"]
            .as_array_mut()
            .unwrap()
            .push(json!({"kind": kind, "upload_id": file}));
    }

    // The same kind twice is refused.
    let mut twice = body.clone();
    let extra = json!({"kind": "pan", "upload_id": kyc_file(&db, a, &meena).await});
    twice["documents"].as_array_mut().unwrap().push(extra);
    let res = register(&db, a, &meena, twice).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["message"], "PAN is there twice.");

    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(count(&db, "SELECT count(*) FROM documents").await, 8);
}

#[sqlx::test]
async fn a_salaried_agents_home_shows_what_is_with_the_admin(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let mut body = form(&db, a, &aman, "s1@example.com", "9814000119").await;
    body.as_object_mut().unwrap().remove("commission");
    body.as_object_mut().unwrap().remove("commission_note");
    assert_eq!(
        register(&db, a, &aman, body).await.status,
        StatusCode::CREATED
    );
    let home = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &aman, None).await;
    assert_eq!(home.body["tiles"][1]["label"], "In review");
    assert_eq!(home.body["tiles"][1]["value"], "1");
    let list = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/my-customers"),
        &aman,
        None,
    )
    .await;
    assert!(list.body["items"][0].get("commission").is_none());
}

/*
    Scenarios: races, tidy-ups, files that aren't the agent's to use,
    who may register, customers in two companies, fixing two documents
*/

#[sqlx::test]
async fn two_registrations_at_once_make_one_customer(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let first = form(&db, a, &meena, "race@example.com", "9814000120").await;
    let mut second = form(&db, a, &aman, "race2@example.com", "9814000120").await;
    second.as_object_mut().unwrap().remove("commission");
    let (x, y) = tokio::join!(
        register(&db, a, &meena, first),
        register(&db, a, &aman, second)
    );
    let mut statuses = [x.status, y.status];
    statuses.sort();
    assert_eq!(statuses, [StatusCode::CREATED, StatusCode::CONFLICT]);
    assert_eq!(count(&db, "SELECT count(*) FROM customers").await, 1);
    // The loser's files weren't used: they can go into a corrected registration.
    assert_eq!(
        count(&db, "SELECT count(*) FROM uploads WHERE used_at IS NULL").await,
        5
    );
}

#[sqlx::test]
async fn an_email_written_differently_is_still_the_same_customer(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let body = form(&db, a, &meena, "same.person@example.com", "9814000121").await;
    register(&db, a, &meena, body).await;
    let again = form(&db, a, &meena, "  Same.Person@Example.COM ", "9814000122").await;
    let res = register(&db, a, &meena, again).await;
    assert_eq!(res.body["code"], "registration.duplicate");
}

#[sqlx::test]
async fn files_that_arent_the_agents_kyc_are_refused(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let b = org(&db, "Solar B", "active").await;
    common::join(&db, b, "meena@example.com", "agent", Some("commission")).await;

    // A receipt, not a KYC upload.
    let receipt = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &meena,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 3000, "purpose": "receipt"})),
    )
    .await;
    let receipt = receipt.body["upload_id"].as_str().unwrap().to_owned();
    r2_put(&format!("orgs/{a}/receipt/{receipt}"), 3000);
    let others = kyc_file(&db, a, &aman).await; // Aman's
    let elsewhere = kyc_file(&db, b, &meena).await; // Solar B's
    let base = form(&db, a, &meena, "files@example.com", "9814000123").await;
    let same = base["documents"][1]["upload_id"].clone();

    for (i, upload) in [json!(receipt), json!(others), json!(elsewhere), same]
        .into_iter()
        .enumerate()
    {
        let mut body = base.clone();
        body["documents"][0]["upload_id"] = upload;
        let res = register(&db, a, &meena, body).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "case {i}");
        assert_eq!(res.body["errors"][0]["field"], "documents", "case {i}");
    }
    assert_eq!(count(&db, "SELECT count(*) FROM customers").await, 0);
    assert!(
        emails_to("files@example.com").is_empty(),
        "no email for a refusal"
    );
}

#[sqlx::test]
async fn only_an_active_companys_own_agents_register(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let body = form(&db, a, &meena, "who@example.com", "9814000124").await;
    let b = org(&db, "Solar B", "active").await;
    let outsider = member(&db, b, "outsider@example.com", "agent", Some("salary")).await;
    let res = register(&db, a, &outsider, body.clone()).await;
    assert_eq!(res.body["code"], "org.not_member");

    // Meena registers herself: she's already in the company.
    let mut herself = body.clone();
    herself["email"] = json!("meena@example.com");
    let res = register(&db, a, &meena, herself).await;
    assert_eq!(res.body["code"], "registration.duplicate");

    sqlx::query("UPDATE orgs SET status = 'suspended' WHERE id = $1")
        .bind(a)
        .execute(&db)
        .await
        .unwrap();
    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.body["code"], "org.suspended");
}

#[sqlx::test]
async fn a_customer_in_two_companies_sees_each_ones_documents(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let b = org(&db, "Solar B", "active").await;
    let ravi = member(&db, b, "ravi.agent@example.com", "agent", Some("salary")).await;
    let body = form(&db, a, &meena, "twice@example.com", "9814000125").await;
    register(&db, a, &meena, body).await;
    let mut body = form(&db, b, &ravi, "twice@example.com", "9814000125").await;
    body.as_object_mut().unwrap().remove("commission");
    body["documents"].as_array_mut().unwrap().truncate(5);
    let res = register(&db, b, &ravi, body).await;
    assert_eq!(
        res.status,
        StatusCode::CREATED,
        "another company may: {}",
        res.body
    );
    assert_eq!(
        count(
            &db,
            "SELECT count(*) FROM users WHERE email = 'twice@example.com'"
        )
        .await,
        1,
        "one person, two memberships"
    );
    sqlx::query(
        "UPDATE users SET email_verified_at = now(),
                          password_hash = (SELECT password_hash FROM users WHERE email = 'meena@example.com')
         WHERE email = 'twice@example.com'",
    )
    .execute(&db)
    .await
    .unwrap();
    let token = common::token(&db, "twice@example.com").await;
    for (company, agent) in [(a, "Asha Example"), (b, "Asha Example")] {
        let res = call(
            &db,
            "GET",
            &format!("/api/v1/orgs/{company}/me/documents"),
            &token,
            None,
        )
        .await;
        assert_eq!(res.body["items"].as_array().unwrap().len(), 5);
        assert_eq!(res.body["uploaded_by"], agent);
    }
    let self_signed = common::post(
        &db,
        "/api/v1/auth/signup",
        json!({"name": "Walk In", "email": "walkin@example.com", "password": "sunlight1"}),
    )
    .await;
    assert_eq!(self_signed.status, StatusCode::ACCEPTED);
    sqlx::query("UPDATE users SET email_verified_at = now() WHERE email = 'walkin@example.com'")
        .execute(&db)
        .await
        .unwrap();
    common::join(&db, a, "walkin@example.com", "customer", None).await;
    let walkin = common::token(&db, "walkin@example.com").await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/me/documents"),
        &walkin,
        None,
    )
    .await;
    assert_eq!(
        res.body,
        json!({"items": []}),
        "no registration, no documents"
    );
}

#[sqlx::test]
async fn a_removed_customer_comes_back_when_registered_again(db: PgPool) {
    let (a, meena) = setup(&db).await;
    member(&db, a, "back@example.com", "customer", None).await;
    sqlx::query(
        "UPDATE memberships SET removed_at = now()
         WHERE user_id = (SELECT id FROM users WHERE email = 'back@example.com')",
    )
    .execute(&db)
    .await
    .unwrap();
    let body = form(&db, a, &meena, "back@example.com", "9814000126").await;
    let res = register(&db, a, &meena, body).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(
        count(
            &db,
            "SELECT count(*) FROM memberships WHERE removed_at IS NULL
               AND user_id = (SELECT id FROM users WHERE email = 'back@example.com')"
        )
        .await,
        1
    );
}

#[sqlx::test]
async fn two_returned_documents_are_fixed_one_at_a_time(db: PgPool) {
    let (a, meena) = setup(&db).await;
    member(&db, a, "dev@example.com", "org_admin", None).await;
    let body = form(&db, a, &meena, "two.fixes@example.com", "9814000127").await;
    let id = register(&db, a, &meena, body).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    sqlx::query(
        "UPDATE documents SET status = 'needs_fix', admin_note = 'Unreadable.',
                              admin_note_by = (SELECT id FROM users WHERE email = 'dev@example.com'),
                              admin_note_at = now()
         WHERE customer_id = $1::uuid AND kind IN ('pan', 'signature')",
    )
    .bind(&id)
    .execute(&db)
    .await
    .unwrap();
    sqlx::query("UPDATE customers SET kyc_status = 'needs_fix' WHERE id = $1::uuid")
        .bind(&id)
        .execute(&db)
        .await
        .unwrap();
    let path = format!("/api/v1/orgs/{a}/my-customers/{id}");

    // A file that never arrived changes nothing.
    let lost = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{a}/uploads"),
        &meena,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 3000, "purpose": "kyc"})),
    )
    .await;
    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/pan"),
        &meena,
        Some(json!({"upload_id": lost.body["upload_id"]})),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);

    let file = kyc_file(&db, a, &meena).await;
    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/pan"),
        &meena,
        Some(json!({"upload_id": file})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    assert_eq!(
        res.body["kyc_status"], "needs_fix",
        "the signature is still to fix"
    );
    assert_eq!(res.body["returned"]["kind"], "signature");

    let file = kyc_file(&db, a, &meena).await;
    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/signature"),
        &meena,
        Some(json!({"upload_id": file})),
    )
    .await;
    assert_eq!(res.body["kyc_status"], "in_review");

    // Once approved, nothing is replaced.
    sqlx::query("UPDATE customers SET kyc_status = 'approved' WHERE id = $1::uuid")
        .bind(&id)
        .execute(&db)
        .await
        .unwrap();
    let file = kyc_file(&db, a, &meena).await;
    let res = call(
        &db,
        "PUT",
        &format!("{path}/documents/pan"),
        &meena,
        Some(json!({"upload_id": file})),
    )
    .await;
    assert_eq!(res.body["code"], "registration.locked");
}

#[sqlx::test]
async fn bounds_on_size_and_text(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let base = form(&db, a, &meena, "bounds@example.com", "9814000128").await;
    for (field, value) in [
        ("proposed_kw", json!(0)),
        ("proposed_kw", json!(1000.5)),
        ("sanctioned_load_kw", json!(-1)),
        ("name", json!("x".repeat(101))),
        ("consumer_number", json!("  ")),
        ("phone", json!("5814000128")),
        ("email", json!("not-an-email")),
        ("commission", json!(-5)),
    ] {
        let mut body = base.clone();
        body[field] = value;
        let res = register(&db, a, &meena, body).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{field}");
        assert_eq!(res.body["errors"][0]["field"], field);
    }
    assert_eq!(
        register(&db, a, &meena, base).await.status,
        StatusCode::CREATED
    );
}

#[sqlx::test]
async fn an_agent_with_no_customers_gets_a_plain_home(db: PgPool) {
    let (a, meena) = setup(&db).await;
    let res = call(&db, "GET", &format!("/api/v1/orgs/{a}/home"), &meena, None).await;
    assert_eq!(res.body["headline"]["value"], "0");
    assert!(res.body.get("progress").is_none());
    assert_eq!(res.body["list"]["rows"][0]["id"], "no_customers");
}
