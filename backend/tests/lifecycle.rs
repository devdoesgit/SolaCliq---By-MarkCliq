//! The whole life of one solar install, through the API only, as the app
//! and the website will drive it: a company registers and is approved,
//! builds its team, an agent brings a customer with KYC, the company
//! verifies them, an installer works the stages with proof photos, the
//! customer pays, the agent's commission is paid, the system is handed
//! over. Every person sets their password with the emailed code, and
//! each step checks what the next person sees and is told.

mod common;

use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{Res, call_with, last_code, post, r2_put, token, verified_user};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

// One person in the story: their email and a logged-in token.
struct Person {
    email: &'static str,
    token: String,
}

// Sets a first password with the emailed code, then logs in.
async fn set_up(db: &PgPool, email: &'static str) -> Person {
    let res = post(
        db,
        "/api/v1/auth/login",
        json!({"email": email, "password": "sunlight1", "client": "app"}),
    )
    .await;
    assert_eq!(
        res.body["code"], "account.password_not_set",
        "{email}: {}",
        res.body
    );
    post(db, "/api/v1/auth/password/forgot", json!({"email": email})).await;
    let res = post(
        db,
        "/api/v1/auth/password/reset",
        json!({"email": email, "code": last_code(email), "new_password": "sunlight1"}),
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{email}: {}", res.body);
    Person {
        email,
        token: token(db, email).await,
    }
}

// Any call with a fresh Idempotency-Key (harmless where none is needed).
async fn send(db: &PgPool, method: &str, path: &str, who: &Person, body: Option<Value>) -> Res {
    call_with(
        db,
        method,
        path,
        &who.token,
        body,
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await
}

async fn ok(db: &PgPool, method: &str, path: &str, who: &Person, body: Option<Value>) -> Value {
    let res = send(db, method, path, who, body).await;
    assert!(
        res.status.is_success(),
        "{method} {path} as {}: {} {}",
        who.email,
        res.status,
        res.body
    );
    res.body
}

// A file the app sends straight to R2 (the stand-in), ready to attach.
async fn file(db: &PgPool, org: Uuid, who: &Person, purpose: &str) -> String {
    let res = ok(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/uploads"),
        who,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 4000, "purpose": purpose})),
    )
    .await;
    let id = res["upload_id"].as_str().unwrap().to_owned();
    r2_put(&format!("orgs/{org}/{purpose}/{id}"), 4000);
    id
}

// The newest notification in someone's feed in this company.
async fn latest(db: &PgPool, org: Uuid, who: &Person) -> Value {
    let feed = ok(
        db,
        "GET",
        &format!("/api/v1/orgs/{org}/notifications"),
        who,
        None,
    )
    .await;
    feed["items"][0].clone()
}

#[sqlx::test]
async fn one_install_from_start_to_handover(db: PgPool) {
    /*
        1. Example Solar registers; MarkCliq approves it; the owner sets
           a password with the emailed code
    */
    let res = post(
        &db,
        "/api/v1/org-registrations",
        json!({
            "legal_name": "Example Solar Private Limited", "trade_name": "Example Solar",
            "business_type": "private_limited", "gstin": "27aapfu0939f1zv",
            "address_line_1": "Plot 4, MIDC", "city": "Pune", "pin_code": "411001",
            "owner_name": "Dev Owner", "email": "dev.owner@example.com", "phone": "98140 22671",
            "terms_version": 1,
        }),
    )
    .await;
    assert_eq!(res.status, StatusCode::ACCEPTED, "{}", res.body);
    verified_user(&db, "parth@example.com", "sunlight1").await;
    backend::seed::make_platform_admin(&db, "parth@example.com")
        .await
        .unwrap();
    let parth = Person {
        email: "parth@example.com",
        token: token(&db, "parth@example.com").await,
    };
    let org: Uuid = sqlx::query_scalar("SELECT id FROM orgs WHERE gstin = '27AAPFU0939F1ZV'")
        .fetch_one(&db)
        .await
        .unwrap();
    ok(
        &db,
        "POST",
        &format!("/api/v1/platform/orgs/{org}/status"),
        &parth,
        Some(json!({"status": "active"})),
    )
    .await;
    let dev = set_up(&db, "dev.owner@example.com").await;
    let o = |rest: &str| format!("/api/v1/orgs/{org}/{rest}");

    // 2. The team: an installer and a commission agent, each sets a password.
    for (name, email, role, pay) in [
        ("Ravi Kumar", "ravi.k@example.com", "worker", Value::Null),
        (
            "Meena Sharma",
            "meena.s@example.com",
            "agent",
            json!("commission"),
        ),
    ] {
        ok(
            &db,
            "POST",
            &o("members"),
            &dev,
            Some(json!({"name": name, "email": email, "role": role, "pay_type": pay})),
        )
        .await;
    }
    let ravi = set_up(&db, "ravi.k@example.com").await;
    let meena = set_up(&db, "meena.s@example.com").await;

    /*
        3. Meena registers Rajinder on site, with KYC and her commission.
           Rajinder is emailed, sets a password, and sees "being set up"
    */
    let mut documents = Vec::new();
    for kind in [
        "aadhaar",
        "pan",
        "electricity_bill",
        "land_document",
        "signature",
    ] {
        documents.push(json!({"kind": kind, "upload_id": file(&db, org, &meena, "kyc").await}));
    }
    let reg = ok(
        &db,
        "POST",
        &o("customer-registrations"),
        &meena,
        Some(json!({
            "name": "Rajinder Kaur", "phone": "9814033001", "email": "rajinder.k@example.com",
            "address": "House 12, Sector 70", "city": "Mohali", "pin_code": "160062",
            "state": "Punjab", "discom": "PSPCL", "consumer_number": "3002145587",
            "sanctioned_load_kw": 5, "connection_type": "residential", "proposed_kw": 5,
            "roof": "rcc", "subsidy": false, "documents": documents, "consent": true,
            "commission": 400_000, "commission_note": "₹800 a kW"
        })),
    )
    .await;
    assert_eq!(reg["reference"], "SC-0001");
    let customer = reg["id"].as_str().unwrap().to_owned();
    let rajinder = set_up(&db, "rajinder.k@example.com").await;
    let res = send(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert_eq!(res.body["code"], "install.not_started");

    // 4. The admin's queue has the registration; the bill goes back to Meena.
    let queue = ok(&db, "GET", &o("review"), &dev, None).await;
    assert_eq!(queue["registrations"][0]["title"], "Rajinder Kaur");
    ok(
        &db,
        "POST",
        &o(&format!(
            "customers/{customer}/documents/electricity_bill/return"
        )),
        &dev,
        Some(json!({"note": "Bill photo is blurry."})),
    )
    .await;
    assert_eq!(latest(&db, org, &meena).await["kind"], "kyc_returned");
    let detail = ok(
        &db,
        "GET",
        &o(&format!("my-customers/{customer}")),
        &meena,
        None,
    )
    .await;
    assert_eq!(detail["kyc_status"], "needs_fix");
    assert_eq!(detail["detail"], "Electricity bill: Bill photo is blurry.");
    // Verifying now is refused: a document is still out.
    let res = send(
        &db,
        "POST",
        &o(&format!("customers/{customer}/verify")),
        &dev,
        Some(json!({"total": 28_500_000})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);

    let fixed = file(&db, org, &meena, "kyc").await;
    ok(
        &db,
        "PUT",
        &o(&format!(
            "my-customers/{customer}/documents/electricity_bill"
        )),
        &meena,
        Some(json!({"upload_id": fixed})),
    )
    .await;

    /*
        5. Verified at ₹2,85,000: the install is set up with the plan,
           the advance due. Meena and Rajinder are told
    */
    ok(
        &db,
        "POST",
        &o(&format!("customers/{customer}/verify")),
        &dev,
        Some(json!({"total": 28_500_000})),
    )
    .await;
    assert_eq!(latest(&db, org, &meena).await["kind"], "kyc_approved");
    assert_eq!(latest(&db, org, &rajinder).await["kind"], "payment_due");
    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert_eq!(install["stage_index"], 1);
    assert_eq!(install["subsidy"], 0, "no subsidy asked for");
    assert_eq!(install["payments"][0]["status"], "due");
    assert_eq!(install["payments"][0]["amount"], 8_550_000);
    let docs = ok(&db, "GET", &o("me/documents"), &rajinder, None).await;
    assert!(
        docs["items"]
            .as_array()
            .unwrap()
            .iter()
            .all(|d| d["status"] == "verified")
    );

    // 6. The commission: approved at ₹3,500, Meena's ₹4,000 kept beside it.
    ok(
        &db,
        "POST",
        &o(&format!("customers/{customer}/commission")),
        &dev,
        Some(json!({"amount": 350_000, "note": "Our rate is ₹700 a kW."})),
    )
    .await;
    assert_eq!(latest(&db, org, &meena).await["kind"], "commission_changed");
    let detail = ok(
        &db,
        "GET",
        &o(&format!("my-customers/{customer}")),
        &meena,
        None,
    )
    .await;
    assert_eq!(detail["commission"]["amount"], 350_000);
    assert_eq!(detail["commission"]["proposed_amount"], 400_000);
    assert_eq!(detail["commission"]["status"], "approved");
    assert_eq!(
        detail["commission"]["admin_note"]["text"],
        "Our rate is ₹700 a kW."
    );

    /*
        7. The site survey for Ravi tomorrow: Ravi and Rajinder are told,
           and Rajinder's next visit is Ravi
    */
    let ravi_id: Uuid =
        sqlx::query_scalar("SELECT id FROM users WHERE email = 'ravi.k@example.com'")
            .fetch_one(&db)
            .await
            .unwrap();
    let survey = ok(
        &db,
        "POST",
        &o("tasks"),
        &dev,
        Some(json!({
            "customer_id": customer, "title": "Site survey", "stage_index": 1,
            "assignee_id": ravi_id, "due_at": Utc::now() + Duration::days(1),
            "admin_note": "Check the roof for shade.",
            "photos": [{"id": "roof", "label": "Roof", "hint": "The whole roof"},
                       {"id": "meter", "label": "Meter", "hint": "Meter number readable"}],
            "checklist": [{"id": "shade", "text": "Note shade across the day"}]
        })),
    )
    .await;
    assert_eq!(survey["reference"], "TSK-0001");
    let task = survey["id"].as_str().unwrap().to_owned();
    assert_eq!(latest(&db, org, &ravi).await["kind"], "task_assigned");
    assert_eq!(latest(&db, org, &rajinder).await["kind"], "visit_booked");
    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert_eq!(install["next_visit"]["title"], "Site survey");
    assert_eq!(install["next_visit"]["person"]["name"], "Ravi Kumar");
    let upcoming = ok(&db, "GET", &o("tasks?view=upcoming"), &ravi, None).await;
    assert_eq!(upcoming["items"][0]["id"], task);

    /*
        8. Ravi does the survey: two photos at the site, the tick, submit.
           He logs his fuel against it
    */
    for slot in ["roof", "meter"] {
        let photo = file(&db, org, &ravi, "proof").await;
        ok(
            &db,
            "POST",
            &o(&format!("tasks/{task}/photos")),
            &ravi,
            Some(
                json!({"slot_id": slot, "upload_id": photo, "taken_at": Utc::now(),
                        "lat": 30.7046, "lng": 76.7179, "accuracy_m": 6}),
            ),
        )
        .await;
    }
    ok(
        &db,
        "PUT",
        &o(&format!("tasks/{task}/checklist/shade")),
        &ravi,
        Some(json!({"done": true})),
    )
    .await;
    let submitted = ok(
        &db,
        "POST",
        &o(&format!("tasks/{task}/submit")),
        &ravi,
        Some(json!({"note": "No shade."})),
    )
    .await;
    assert_eq!(submitted["status"], "submitted");
    let receipt = file(&db, org, &ravi, "receipt").await;
    let expense = ok(
        &db,
        "POST",
        &o("expenses"),
        &ravi,
        Some(
            json!({"amount": 80_000, "category": "fuel", "note": "Bike to Mohali",
                    "spent_on": Utc::now().date_naive().to_string(),
                    "receipt_upload_id": receipt, "task_id": task}),
        ),
    )
    .await;
    let expense_id = expense["id"].as_str().unwrap().to_owned();

    // 9. The meter photo is retaken, then the survey is approved: stage 2.
    let queue = ok(&db, "GET", &o("review"), &dev, None).await;
    assert_eq!(queue["tasks"][0]["id"], task);
    assert_eq!(queue["expenses"][0]["id"], expense_id);
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{task}/return")),
        &dev,
        Some(json!({"note": "Meter number isn't readable.", "retake": ["meter"]})),
    )
    .await;
    assert_eq!(latest(&db, org, &ravi).await["title"], "Photo retake asked");
    let photo = file(&db, org, &ravi, "proof").await;
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{task}/photos")),
        &ravi,
        Some(
            json!({"slot_id": "meter", "upload_id": photo, "taken_at": Utc::now(),
                    "lat": 30.7046, "lng": 76.7179, "accuracy_m": 6}),
        ),
    )
    .await;
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{task}/submit")),
        &ravi,
        Some(json!({})),
    )
    .await;
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{task}/approve")),
        &dev,
        None,
    )
    .await;
    assert_eq!(latest(&db, org, &ravi).await["kind"], "task_approved");
    let history = ok(
        &db,
        "GET",
        &o(&format!("tasks/{task}/history")),
        &ravi,
        None,
    )
    .await;
    let kinds: Vec<_> = history["events"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["kind"].as_str().unwrap())
        .collect();
    assert_eq!(
        kinds,
        [
            "approved",
            "resubmitted",
            "photos_uploaded",
            "returned",
            "submitted",
            "photos_uploaded",
            "assigned"
        ]
    );
    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert_eq!(install["stage_index"], 2);
    assert_eq!(install["stages"][0]["status"], "done");

    // 10. Ravi's fuel: approved, then paid with his salary.
    ok(
        &db,
        "POST",
        &o(&format!("expenses/{expense_id}/approve")),
        &dev,
        None,
    )
    .await;
    ok(
        &db,
        "POST",
        &o(&format!("expenses/{expense_id}/paid")),
        &dev,
        None,
    )
    .await;
    assert_eq!(latest(&db, org, &ravi).await["kind"], "expense_paid");
    let e = ok(
        &db,
        "GET",
        &o(&format!("expenses/{expense_id}")),
        &ravi,
        None,
    )
    .await;
    assert_eq!(e["status"], "paid");

    /*
        11. Rajinder pays the advance by bank transfer; the company
            confirms it; Meena's commission becomes payable, then is paid
    */
    let advance = install["payments"][0]["id"].as_str().unwrap().to_owned();
    let claimed = ok(
        &db,
        "POST",
        &o(&format!("my-install/payments/{advance}/claim")),
        &rajinder,
        Some(json!({"method": "bank_transfer"})),
    )
    .await;
    assert_eq!(claimed["payments"][0]["status"], "claimed");
    let queue = ok(&db, "GET", &o("review"), &dev, None).await;
    assert_eq!(queue["payments"][0]["id"], advance);
    ok(
        &db,
        "POST",
        &o(&format!("payments/{advance}/confirm")),
        &dev,
        None,
    )
    .await;
    assert_eq!(latest(&db, org, &meena).await["kind"], "commission_payable");
    let home = ok(&db, "GET", &o("home"), &meena, None).await;
    assert_eq!(home["tiles"][1]["value"], "₹3,500", "earnings: payable");
    ok(
        &db,
        "POST",
        &o(&format!("customers/{customer}/commission/paid")),
        &dev,
        None,
    )
    .await;
    assert_eq!(latest(&db, org, &meena).await["kind"], "commission_paid");

    /*
        12. The next stages: a structure visit with a reported problem,
            rescheduled; the installation payment asked for and paid
    */
    let structure = ok(
        &db,
        "POST",
        &o("tasks"),
        &dev,
        Some(
            json!({"customer_id": customer, "title": "Structure", "stage_index": 2,
                    "assignee_id": ravi_id, "due_at": Utc::now() + Duration::days(2)}),
        ),
    )
    .await;
    let structure = structure["id"].as_str().unwrap().to_owned();
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{structure}/problems")),
        &ravi,
        Some(json!({"reason": "material_missing", "note": "Rails not delivered."})),
    )
    .await;
    assert_eq!(
        ok(&db, "GET", &o("review"), &dev, None).await["tasks"][0]["status"],
        "problem"
    );
    ok(
        &db,
        "PUT",
        &o(&format!("tasks/{structure}/schedule")),
        &dev,
        Some(json!({"due_at": Utc::now() + Duration::days(4)})),
    )
    .await;
    assert_eq!(latest(&db, org, &ravi).await["kind"], "task_rescheduled");
    let t = ok(&db, "GET", &o(&format!("tasks/{structure}")), &ravi, None).await;
    assert!(t.get("problem").is_none(), "the admin decided");
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{structure}/submit")),
        &ravi,
        Some(json!({})),
    )
    .await;
    ok(
        &db,
        "POST",
        &o(&format!("tasks/{structure}/approve")),
        &dev,
        None,
    )
    .await;

    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    let installation = install["payments"][1]["id"].as_str().unwrap().to_owned();
    ok(
        &db,
        "POST",
        &o(&format!("payments/{installation}/request")),
        &dev,
        Some(json!({"due_on": (Utc::now() + Duration::days(5)).date_naive().to_string()})),
    )
    .await;
    assert_eq!(
        latest(&db, org, &rajinder).await["title"],
        "On installation due"
    );
    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert!(
        install["upi_uri"].is_null(),
        "no UPI id set yet: bank transfer only"
    );
    ok(
        &db,
        "POST",
        &o(&format!("my-install/payments/{installation}/claim")),
        &rajinder,
        Some(json!({"method": "upi"})),
    )
    .await;
    ok(
        &db,
        "POST",
        &o(&format!("payments/{installation}/confirm")),
        &dev,
        None,
    )
    .await;

    // 13. Handed over: every stage done, the home says so.
    ok(
        &db,
        "POST",
        &o(&format!("customers/{customer}/handover")),
        &dev,
        None,
    )
    .await;
    let install = ok(&db, "GET", &o("my-install"), &rajinder, None).await;
    assert!(
        install["stages"]
            .as_array()
            .unwrap()
            .iter()
            .all(|s| s["status"] == "done")
    );
    let home = ok(&db, "GET", &o("home"), &rajinder, None).await;
    assert!(
        home["headline"]["detail"]
            .as_str()
            .unwrap()
            .starts_with("Handed over on")
    );
    let list = ok(&db, "GET", &o("my-customers"), &meena, None).await;
    assert_eq!(list["items"][0]["detail"], "Stage 7 · Handover");
    assert_eq!(list["items"][0]["commission"]["status"], "paid");

    // Nothing left waiting for the admin.
    let queue = ok(&db, "GET", &o("review"), &dev, None).await;
    for list in [
        "tasks",
        "expenses",
        "registrations",
        "commissions",
        "payments",
    ] {
        assert_eq!(queue[list], json!([]), "{list}");
    }
}
