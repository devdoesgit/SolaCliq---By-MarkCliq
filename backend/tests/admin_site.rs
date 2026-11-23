//! The admin website's side of the API (docs/features/admin-website.md):
//! what the company's admin reads, the stage, the price and the settings.
//! The decisions themselves are `admin.rs`.

mod common;

use axum::{body::Body, http::Request, http::StatusCode};
use chrono::{Duration, FixedOffset, Utc};
use common::{Res, call, call_with, member, org};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

struct Co {
    org: Uuid,
    admin: String,
    ravi: String,
    ravi_id: Uuid,
    meena: String,
    meena_id: Uuid,
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

// A company with an admin, an installer and an agent; `tag` keeps emails apart.
async fn company(db: &PgPool, tag: &str) -> Co {
    let org = org(db, &format!("Solar {tag}"), "active").await;
    let (a, r, m) = (
        format!("dev.{tag}@example.com"),
        format!("ravi.{tag}@example.com"),
        format!("meena.{tag}@example.com"),
    );
    Co {
        org,
        admin: member(db, org, &a, "org_admin", None).await,
        ravi: member(db, org, &r, "worker", None).await,
        ravi_id: user_id(db, &r).await,
        meena: member(db, org, &m, "agent", Some("commission")).await,
        meena_id: user_id(db, &m).await,
    }
}

async fn act(db: &PgPool, co: &Co, method: &str, rest: &str, body: Option<Value>) -> Res {
    call(
        db,
        method,
        &format!("/api/v1/orgs/{}/{rest}", co.org),
        &co.admin,
        body,
    )
    .await
}

async fn read(db: &PgPool, co: &Co, rest: &str) -> Value {
    let res = act(db, co, "GET", rest, None).await;
    assert_eq!(res.status, StatusCode::OK, "{rest}: {}", res.body);
    res.body
}

async fn file(db: &PgPool, co: &Co, owner: Uuid, purpose: &str, kind: &str) -> Uuid {
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO uploads (id, org_id, owner_id, purpose, content_type, size_bytes, r2_key, used_at)
         VALUES ($1, $2, $3, $4::upload_purpose, $5, 1234,
                 'orgs/' || $2::text || '/' || $4 || '/' || $1::text, now())",
    )
    .bind(id)
    .bind(co.org)
    .bind(owner)
    .bind(purpose)
    .bind(kind)
    .execute(db)
    .await
    .unwrap();
    id
}

// A registration by the agent, in review, with a PDF Aadhaar and a commission.
async fn customer(db: &PgPool, co: &Co, name: &str, phone: &str) -> Uuid {
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, email, address, city,
                                consumer_number, system_kw, registered_by, kyc_status, subsidy,
                                commission, commission_status)
         VALUES ($1, $2, 'SC-' || $4, $3, $4, $4 || '@example.com', 'House 12', 'Mohali',
                 'CN' || $4, 5, $5, 'in_review', true, 400000, 'in_review')",
    )
    .bind(id)
    .bind(co.org)
    .bind(name)
    .bind(phone)
    .bind(co.meena_id)
    .execute(db)
    .await
    .unwrap();
    let upload = file(db, co, co.meena_id, "kyc", "application/pdf").await;
    sqlx::query(
        "WITH d AS (INSERT INTO documents (id, org_id, customer_id, kind, uploaded_by)
                    VALUES ($1, $2, $3, 'aadhaar', $5) RETURNING id, org_id)
         INSERT INTO document_files (org_id, document_id, upload_id, position)
         SELECT org_id, id, $4, 1 FROM d",
    )
    .bind(Uuid::now_v7())
    .bind(co.org)
    .bind(id)
    .bind(upload)
    .bind(co.meena_id)
    .execute(db)
    .await
    .unwrap();
    id
}

async fn verified(db: &PgPool, co: &Co, name: &str, phone: &str) -> Uuid {
    let id = customer(db, co, name, phone).await;
    let body = json!({"total": 20_000_000});
    let res = act(
        db,
        co,
        "POST",
        &format!("customers/{id}/verify"),
        Some(body),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    id
}

async fn new_task(db: &PgPool, co: &Co, customer: Uuid, key: Uuid) -> Res {
    call_with(
        db,
        "POST",
        &format!("/api/v1/orgs/{}/tasks", co.org),
        &co.admin,
        Some(
            json!({"customer_id": customer, "title": "Site survey", "stage_index": 1,
                    "assignee_id": co.ravi_id, "due_at": Utc::now() + Duration::days(1),
                    "photos": [{"id": "roof", "label": "Roof"}]}),
        ),
        &[("idempotency-key", &key.to_string())],
    )
    .await
}

async fn task(db: &PgPool, co: &Co, customer: Uuid) -> Uuid {
    let res = new_task(db, co, customer, Uuid::now_v7()).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    res.body["id"].as_str().unwrap().parse().unwrap()
}

async fn expense(db: &PgPool, co: &Co, status: &str, n: i32) -> Uuid {
    let id = Uuid::now_v7();
    let receipt = file(db, co, co.ravi_id, "receipt", "image/jpeg").await;
    sqlx::query(
        "INSERT INTO expenses (id, org_id, reference, owner_id, amount, category, note, spent_on,
                               status, receipt_upload_id)
         VALUES ($1, $2, 'EXP-' || $3, $4, 455, 'fuel', 'Diesel', current_date,
                 $5::expense_status, $6)",
    )
    .bind(id)
    .bind(co.org)
    .bind(n.to_string())
    .bind(co.ravi_id)
    .bind(status)
    .bind(receipt)
    .execute(db)
    .await
    .unwrap();
    id
}

async fn bank(db: &PgPool, user: Uuid, last4: &str) {
    sqlx::query(
        "INSERT INTO user_details (user_id, bank_holder, bank_ifsc, bank_name, bank_last4,
                                   bank_account_enc)
         VALUES ($1, 'Holder Name', 'HDFC0001234', 'HDFC Bank', $2, '\\x0102')",
    )
    .bind(user)
    .bind(last4)
    .execute(db)
    .await
    .unwrap();
}

async fn payments(db: &PgPool, co: &Co, customer: Uuid) -> Vec<Value> {
    read(db, co, &format!("admin/customers/{customer}")).await["payments"]
        .as_array()
        .unwrap()
        .clone()
}

fn ids(page: &Value) -> Vec<String> {
    page["items"]
        .as_array()
        .unwrap()
        .iter()
        .map(|i| {
            let id = i.get("id").or_else(|| i.get("customer_id")).unwrap();
            id.as_str().unwrap().to_owned()
        })
        .collect()
}

#[sqlx::test]
async fn every_admin_read_and_write_is_the_admins_alone(db: PgPool) {
    let co = company(&db, "a").await;
    let customer_token = member(&db, co.org, "cust.a@example.com", "customer", None).await;
    let other = company(&db, "b").await;
    let id = Uuid::now_v7();
    let all = [
        ("GET", "admin/customers".to_owned(), None),
        ("GET", format!("admin/customers/{id}"), None),
        (
            "PUT",
            format!("admin/customers/{id}/stage"),
            Some(json!({"stage_index": 2})),
        ),
        (
            "PUT",
            format!("admin/customers/{id}/price"),
            Some(json!({"total": 100_000, "subsidy": 0})),
        ),
        ("GET", "admin/tasks".to_owned(), None),
        ("GET", format!("admin/tasks/{id}"), None),
        ("GET", "admin/expenses".to_owned(), None),
        ("GET", format!("admin/expenses/{id}"), None),
        ("GET", "admin/commissions".to_owned(), None),
        ("GET", "admin/payments".to_owned(), None),
        ("GET", "admin/settings".to_owned(), None),
        (
            "PUT",
            "admin/settings".to_owned(),
            Some(json!({"upi_id": null})),
        ),
    ];
    for (method, rest, body) in all {
        let path = format!("/api/v1/orgs/{}/{rest}", co.org);
        for (token, code) in [
            (&co.ravi, "org.role_not_allowed"),
            (&co.meena, "org.role_not_allowed"),
            (&customer_token, "org.role_not_allowed"),
            (&other.admin, "org.not_member"),
        ] {
            let res = call(&db, method, &path, token, body.clone()).await;
            assert_eq!(res.status, StatusCode::FORBIDDEN, "{method} {rest}");
            assert_eq!(res.body["code"], code, "{method} {rest}");
        }
    }
}

#[sqlx::test]
async fn another_companys_records_are_not_there(db: PgPool) {
    let a = company(&db, "a").await;
    let b = company(&db, "b").await;
    let theirs = verified(&db, &b, "Theirs", "9814000001").await;
    let their_task = task(&db, &b, theirs).await;
    let their_expense = expense(&db, &b, "approved", 1).await;
    for (method, rest, body) in [
        ("GET", format!("admin/customers/{theirs}"), None),
        ("GET", format!("admin/tasks/{their_task}"), None),
        ("GET", format!("admin/expenses/{their_expense}"), None),
        (
            "PUT",
            format!("admin/customers/{theirs}/stage"),
            Some(json!({"stage_index": 3})),
        ),
        (
            "PUT",
            format!("admin/customers/{theirs}/price"),
            Some(json!({"total": 100_000, "subsidy": 0})),
        ),
    ] {
        let res = act(&db, &a, method, &rest, body).await;
        assert_eq!(
            res.status,
            StatusCode::NOT_FOUND,
            "{method} {rest}: {}",
            res.body
        );
    }
    for list in ["customers", "tasks", "expenses", "commissions", "payments"] {
        assert!(
            ids(&read(&db, &a, &format!("admin/{list}")).await).is_empty(),
            "{list}"
        );
        assert!(
            !ids(&read(&db, &b, &format!("admin/{list}")).await).is_empty(),
            "{list}"
        );
    }
    let filtered = format!("admin/tasks?customer_id={theirs}");
    assert!(ids(&read(&db, &a, &filtered).await).is_empty());
}

#[sqlx::test]
async fn customers_are_searched_filtered_and_paged(db: PgPool) {
    let co = company(&db, "a").await;
    let asha = customer(&db, &co, "Asha Verma", "9814000001").await;
    let bal = verified(&db, &co, "Balwinder 100%_Solar", "9814000002").await;
    let chand = customer(&db, &co, "Chand", "9814000003").await;

    for (query, want) in [
        ("q=ASHA", vec![asha]),
        ("q=9814000003", vec![chand]),
        ("q=cn9814000002", vec![bal]),
        ("q=sc-9814000001", vec![asha]),
        ("q=9814000002%40example.com", vec![bal]),
        // The text as typed: % and _ aren't wildcards.
        ("q=100%25_", vec![bal]),
        ("q=%25a%25", vec![]),
        ("kyc_status=approved", vec![bal]),
        ("kyc_status=in_review", vec![chand, asha]),
        ("stage=1", vec![bal]),
        ("stage=2", vec![]),
        ("q=", vec![chand, bal, asha]),
    ] {
        let got = ids(&read(&db, &co, &format!("admin/customers?{query}")).await);
        let want: Vec<String> = want.iter().map(Uuid::to_string).collect();
        assert_eq!(got, want, "{query}");
    }

    let first = read(&db, &co, "admin/customers?limit=2").await;
    assert_eq!(ids(&first), [chand.to_string(), bal.to_string()]);
    let next = first["page"]["next_cursor"].as_str().unwrap();
    let last = read(&db, &co, &format!("admin/customers?limit=2&cursor={next}")).await;
    assert_eq!(ids(&last), [asha.to_string()]);
    assert!(last["page"]["next_cursor"].is_null());
    let res = act(&db, &co, "GET", "admin/customers?kyc_status=nope", None).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
}

#[sqlx::test]
async fn a_registration_shows_its_files_and_then_its_money(db: PgPool) {
    let co = company(&db, "a").await;
    let id = customer(&db, &co, "Asha", "9814000001").await;
    let before = read(&db, &co, &format!("admin/customers/{id}")).await;
    let doc = &before["documents"][0];
    assert_eq!(doc["title"], "Aadhaar");
    assert_eq!(doc["files"][0]["file"]["content_type"], "application/pdf");
    assert_eq!(doc["files"][0]["file"]["size_bytes"], 1234);
    let url = doc["files"][0]["file"]["url"].as_str().unwrap();
    assert!(url.contains(&format!("/orgs/{}/kyc/", co.org)), "{url}");
    assert!(url.contains("X-Amz-Signature="));
    assert_eq!(before["suggested_subsidy"], 7_800_000);
    assert_eq!(before["subsidy_requested"], true);
    assert_eq!(before["agent_name"], "Asha Example");
    assert!(before.get("price").is_none());
    assert!(before.get("stage").is_none());

    let back = json!({"note": "Blurred"});
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{id}/documents/aadhaar/return"),
        Some(back),
    )
    .await;
    let returned = read(&db, &co, &format!("admin/customers/{id}")).await;
    assert_eq!(returned["documents"][0]["note"], "Blurred");
    assert_eq!(returned["kyc_status"], "needs_fix");

    let done = verified(&db, &co, "Bal", "9814000002").await;
    let after = read(&db, &co, &format!("admin/customers/{done}")).await;
    assert_eq!(
        after["price"],
        json!({"total": 20_000_000, "subsidy": 7_800_000, "editable": true})
    );
    assert_eq!(
        after["stage"],
        json!({"index": 1, "count": 7, "name": "Site survey"})
    );
    let plan: Vec<&str> = after["payments"]
        .as_array()
        .unwrap()
        .iter()
        .map(|p| p["status"].as_str().unwrap())
        .collect();
    assert_eq!(plan, ["due", "later", "later"]);
    assert_eq!(after["commission"]["amount"], 400_000);
    assert_eq!(after["commission"]["advance_paid"], false);
}

#[sqlx::test]
async fn the_admin_moves_a_stage_until_handover(db: PgPool) {
    let co = company(&db, "a").await;
    let id = verified(&db, &co, "Asha", "9814000001").await;
    let path = format!("admin/customers/{id}/stage");
    for index in [4, 2] {
        let res = act(&db, &co, "PUT", &path, Some(json!({"stage_index": index}))).await;
        assert_eq!(res.status, StatusCode::OK, "{}", res.body);
        let now = read(&db, &co, &format!("admin/customers/{id}")).await;
        assert_eq!(now["stage"]["index"], index);
    }
    for bad in [0, 8] {
        let res = act(&db, &co, "PUT", &path, Some(json!({"stage_index": bad}))).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{bad}");
    }

    let waiting = customer(&db, &co, "Bal", "9814000002").await;
    let early = format!("admin/customers/{waiting}/stage");
    let res = act(&db, &co, "PUT", &early, Some(json!({"stage_index": 2}))).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "registration.locked");

    act(&db, &co, "POST", &format!("customers/{id}/handover"), None).await;
    let res = act(&db, &co, "PUT", &path, Some(json!({"stage_index": 2}))).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
}

#[sqlx::test]
async fn a_price_changes_until_a_payment_is_paid(db: PgPool) {
    let co = company(&db, "a").await;
    let id = verified(&db, &co, "Asha", "9814000001").await;
    let account = user_id(&db, "ravi.a@example.com").await;
    sqlx::query("UPDATE customers SET user_id = $2 WHERE id = $1")
        .bind(id)
        .bind(account)
        .execute(&db)
        .await
        .unwrap();
    // The customer says they paid the old advance.
    sqlx::query("UPDATE install_payments SET status = 'claimed', claimed_at = now(), claimed_method = 'upi' WHERE position = 0")
        .execute(&db)
        .await
        .unwrap();

    let path = format!("admin/customers/{id}/price");
    let body = json!({"total": 10_000_099, "subsidy": 300_000});
    let res = act(&db, &co, "PUT", &path, Some(body)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let now = read(&db, &co, &format!("admin/customers/{id}")).await;
    assert_eq!(now["price"]["total"], 10_000_099);
    assert_eq!(now["price"]["subsidy"], 300_000);
    let parts = payments(&db, &co, id).await;
    let amounts: Vec<i64> = parts
        .iter()
        .map(|p| p["amount"].as_i64().unwrap())
        .collect();
    assert_eq!(amounts, [3_000_000, 6_000_000, 1_000_099]);
    assert_eq!(
        parts[0]["status"], "due",
        "the claim was for the old amount"
    );
    assert!(parts[0].get("claimed_at").is_none());
    let told: String = sqlx::query_scalar(
        "SELECT body FROM notifications WHERE user_id = $1 AND title = 'Amount changed'",
    )
    .bind(account)
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(told.starts_with("₹30,000"), "{told}");

    for bad in [
        json!({"total": 999, "subsidy": 0}),
        json!({"total": 10_000_000_001_i64, "subsidy": 0}),
        json!({"total": 100_000, "subsidy": 100_001}),
        json!({"total": 100_000, "subsidy": -1}),
    ] {
        let res = act(&db, &co, "PUT", &path, Some(bad.clone())).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{bad}");
    }

    let advance = parts[0]["id"].as_str().unwrap();
    act(
        &db,
        &co,
        "POST",
        &format!("payments/{advance}/confirm"),
        None,
    )
    .await;
    let body = json!({"total": 5_000_000, "subsidy": 0});
    let res = act(&db, &co, "PUT", &path, Some(body)).await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "price.locked");
    let after = read(&db, &co, &format!("admin/customers/{id}")).await;
    assert_eq!(after["price"]["editable"], false);
    assert_eq!(after["price"]["total"], 10_000_099);
}

// 30% of under ₹4 rounds to ₹0, which the payments table refuses.
#[sqlx::test]
async fn a_price_too_small_to_split_is_refused(db: PgPool) {
    let co = company(&db, "a").await;
    let id = customer(&db, &co, "Asha", "9814000001").await;
    let path = format!("customers/{id}/verify");
    let body = json!({"total": 300, "subsidy": 0});
    let res = act(&db, &co, "POST", &path, Some(body)).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", res.body);
    let body = json!({"total": 1000, "subsidy": 0});
    let res = act(&db, &co, "POST", &path, Some(body)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
}

#[sqlx::test]
async fn tasks_are_listed_by_view_and_shown_whole(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let open = task(&db, &co, cust).await;
    let submitted = task(&db, &co, cust).await;
    let stuck = task(&db, &co, cust).await;
    let done = task(&db, &co, cust).await;
    let problem = file(&db, &co, co.ravi_id, "proof", "image/jpeg").await;
    let photo = file(&db, &co, co.ravi_id, "proof", "image/jpeg").await;
    for (id, sql) in [
        (
            submitted,
            "UPDATE tasks SET status = 'submitted', submitted_at = now(), worker_note = 'Done' WHERE id = $1",
        ),
        (
            stuck,
            "UPDATE tasks SET problem_reason = 'safety', problem_note = 'Live wire', problem_at = now() WHERE id = $1",
        ),
        (done, "UPDATE tasks SET status = 'approved' WHERE id = $1"),
    ] {
        sqlx::query(sql).bind(id).execute(&db).await.unwrap();
    }
    sqlx::query("UPDATE tasks SET problem_upload_id = $2 WHERE id = $1")
        .bind(stuck)
        .bind(problem)
        .execute(&db)
        .await
        .unwrap();
    sqlx::query("UPDATE task_photo_slots SET upload_id = $2, taken_at = now(), lat = 30.7, lng = 76.7, accuracy_m = 8 WHERE task_id = $1")
        .bind(submitted)
        .bind(photo)
        .execute(&db)
        .await
        .unwrap();
    let said = json!({"text": "Gate is locked"});
    let path = format!("/api/v1/orgs/{}/tasks/{open}/messages", co.org);
    let res = call(&db, "POST", &path, &co.ravi, Some(said)).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);

    for (query, want) in [
        ("", vec![done, stuck, submitted, open]),
        ("?view=open", vec![stuck, open]),
        ("?view=submitted", vec![submitted]),
        ("?view=problem", vec![stuck]),
        ("?view=done", vec![done]),
    ] {
        let got = ids(&read(&db, &co, &format!("admin/tasks{query}")).await);
        let want: Vec<String> = want.iter().map(Uuid::to_string).collect();
        assert_eq!(got, want, "{query}");
    }
    let nobody = format!("admin/tasks?assignee_id={}", co.meena_id);
    assert!(ids(&read(&db, &co, &nobody).await).is_empty());

    let t = read(&db, &co, &format!("admin/tasks/{submitted}")).await;
    assert_eq!(t["worker_note"], "Done");
    assert_eq!(t["stage"]["name"], "Site survey");
    assert_eq!(t["photos"][0]["photo"]["lat"], 30.7);
    assert!(
        t["photos"][0]["photo"]["url"]
            .as_str()
            .unwrap()
            .contains("/proof/")
    );
    assert_eq!(t["events"][0]["kind"], "assigned");

    let t = read(&db, &co, &format!("admin/tasks/{stuck}")).await;
    assert_eq!(t["problem"]["note"], "Live wire");
    assert!(
        t["problem"]["photo"]["url"]
            .as_str()
            .unwrap()
            .contains(&problem.to_string())
    );

    let t = read(&db, &co, &format!("admin/tasks/{open}")).await;
    assert_eq!(
        t["events"][0]["kind"], "message",
        "the installer's reply, newest first"
    );
    assert_eq!(t["events"][0]["detail"], "Gate is locked");
}

#[sqlx::test]
async fn open_tasks_are_counted_and_stay_visible_after_removal(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let open = task(&db, &co, cust).await;
    let waiting = task(&db, &co, cust).await;
    let done = task(&db, &co, cust).await;
    for (id, status) in [(waiting, "submitted"), (done, "approved")] {
        sqlx::query("UPDATE tasks SET status = $2::task_status WHERE id = $1")
            .bind(id)
            .bind(status)
            .execute(&db)
            .await
            .unwrap();
    }
    let team = read(&db, &co, "members?role=worker").await;
    assert_eq!(team["items"][0]["open_tasks"], 2);

    act(&db, &co, "DELETE", &format!("members/{}", co.ravi_id), None).await;
    let t = read(&db, &co, &format!("admin/tasks/{open}")).await;
    assert_eq!(t["assignee_active"], false);

    let other = member(&db, co.org, "new.worker@example.com", "worker", None).await;
    let to = user_id(&db, "new.worker@example.com").await;
    let body = json!({"due_at": Utc::now() + Duration::days(2), "assignee_id": to});
    let res = act(
        &db,
        &co,
        "PUT",
        &format!("tasks/{open}/schedule"),
        Some(body),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let path = format!("/api/v1/orgs/{}/tasks/{open}", co.org);
    assert_eq!(
        call(&db, "GET", &path, &other, None).await.status,
        StatusCode::OK
    );
}

#[sqlx::test]
async fn creating_a_task_twice_makes_one(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let key = Uuid::now_v7();
    let first = new_task(&db, &co, cust, key).await;
    let again = new_task(&db, &co, cust, key).await;
    assert_eq!(first.status, StatusCode::CREATED);
    assert_eq!(again.status, StatusCode::CREATED);
    assert_eq!(first.body["id"], again.body["id"]);
    let count: i64 = sqlx::query_scalar("SELECT count(*) FROM tasks")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(count, 1);
}

#[sqlx::test]
async fn an_approved_expense_can_still_be_found_and_paid(db: PgPool) {
    let co = company(&db, "a").await;
    let id = expense(&db, &co, "in_review", 1).await;
    bank(&db, co.ravi_id, "9012").await;
    act(&db, &co, "POST", &format!("expenses/{id}/approve"), None).await;
    let told: String = sqlx::query_scalar("SELECT body FROM notifications WHERE user_id = $1")
        .bind(co.ravi_id)
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(told.contains("₹4.55"), "paise are kept: {told}");

    let list = read(&db, &co, "admin/expenses?status=approved").await;
    assert_eq!(ids(&list), [id.to_string()]);
    let e = read(&db, &co, &format!("admin/expenses/{id}")).await;
    assert_eq!(e["amount"], 455);
    assert!(e["receipt"]["url"].as_str().unwrap().contains("/receipt/"));
    assert_eq!(e["payout_last4"], "9012");
    let text = e.to_string();
    for hidden in ["HDFC", "Holder Name", "bank_account"] {
        assert!(!text.contains(hidden), "{hidden}");
    }
    act(&db, &co, "POST", &format!("expenses/{id}/paid"), None).await;
    assert_eq!(
        ids(&read(&db, &co, "admin/expenses?status=paid").await),
        [id.to_string()]
    );
}

#[sqlx::test]
async fn commissions_show_only_the_last_four_digits(db: PgPool) {
    let co = company(&db, "a").await;
    let id = verified(&db, &co, "Asha", "9814000001").await;
    let gone = customer(&db, &co, "Gone", "9814000002").await;
    let no = json!({"note": "No roof"});
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{gone}/reject"),
        Some(no),
    )
    .await;
    bank(&db, co.meena_id, "4321").await;

    let list = read(&db, &co, "admin/commissions?status=in_review").await;
    assert_eq!(ids(&list), [id.to_string()]);
    assert_eq!(list["items"][0]["payout_last4"], "4321");
    let text = list.to_string();
    for hidden in ["HDFC", "Holder Name", "bank_account"] {
        assert!(!text.contains(hidden), "{hidden}");
    }
}

#[sqlx::test]
async fn every_payment_can_be_found_asked_for_and_confirmed(db: PgPool) {
    let co = company(&db, "a").await;
    let id = verified(&db, &co, "Asha", "9814000001").await;
    let later = read(&db, &co, "admin/payments?status=later").await;
    assert_eq!(later["items"].as_array().unwrap().len(), 2);
    assert_eq!(later["items"][0]["customer_id"], id.to_string());
    let next = payments(&db, &co, id).await[1]["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let body = json!({"due_on": (Utc::now() + Duration::days(3)).date_naive()});
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{next}/request"),
        Some(body),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let res = act(&db, &co, "POST", &format!("payments/{next}/confirm"), None).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(
        ids(&read(&db, &co, "admin/payments?status=paid").await),
        [next]
    );

    let two = read(&db, &co, "admin/payments?limit=2").await;
    let cursor = two["page"]["next_cursor"].as_str().unwrap();
    let rest = read(&db, &co, &format!("admin/payments?limit=2&cursor={cursor}")).await;
    let mut all = [ids(&two), ids(&rest)].concat();
    all.sort();
    all.dedup();
    assert_eq!(
        all.len(),
        3,
        "same created_at: neither repeated nor skipped"
    );
}

#[sqlx::test]
async fn the_upi_id_is_set_checked_and_cleared(db: PgPool) {
    let co = company(&db, "a").await;
    let empty = read(&db, &co, "admin/settings").await;
    assert!(empty.get("upi_id").is_none());
    assert_eq!(empty["stages"].as_array().unwrap().len(), 7);

    let body = json!({"upi_id": " example.solar-1@okhdfc "});
    let res = act(&db, &co, "PUT", "admin/settings", Some(body)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["upi_id"], "example.solar-1@okhdfc");

    for bad in [
        "nobank",
        "a b@okhdfc",
        "x@ok&am=1",
        "@okhdfc",
        "name@",
        "a@b@c",
    ] {
        let res = act(
            &db,
            &co,
            "PUT",
            "admin/settings",
            Some(json!({"upi_id": bad})),
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{bad}");
        assert_eq!(res.body["errors"][0]["field"], "upi_id");
    }
    let res = act(
        &db,
        &co,
        "PUT",
        "admin/settings",
        Some(json!({"upi_id": ""})),
    )
    .await;
    assert!(res.body.get("upi_id").is_none(), "{}", res.body);
}

/*
    The database's date, pushed a day away from India's, mustn't become
    the commission's date
*/
#[sqlx::test]
async fn commission_dates_are_indias(db: PgPool) {
    let co = company(&db, "a").await;
    let id = verified(&db, &co, "Asha", "9814000001").await;
    let india = FixedOffset::east_opt(19_800).unwrap();
    let today = Utc::now().with_timezone(&india).date_naive();
    let ahead = FixedOffset::east_opt(14 * 3600).unwrap();
    // UTC+14 and UTC-12 are 26 hours apart: one isn't on India's date.
    let zone = if Utc::now().with_timezone(&ahead).date_naive() == today {
        "Etc/GMT+12"
    } else {
        "Pacific/Kiritimati"
    };
    let name: String = sqlx::query_scalar("SELECT current_database()")
        .fetch_one(&db)
        .await
        .unwrap();
    let sql = format!("ALTER DATABASE \"{name}\" SET timezone TO '{zone}'");
    sqlx::query(sqlx::AssertSqlSafe(sql))
        .execute(&db)
        .await
        .unwrap();

    let advance = payments(&db, &co, id).await[0]["id"]
        .as_str()
        .unwrap()
        .to_owned();
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{id}/commission"),
        Some(json!({})),
    )
    .await;
    act(
        &db,
        &co,
        "POST",
        &format!("payments/{advance}/confirm"),
        None,
    )
    .await;
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{id}/commission/paid"),
        None,
    )
    .await;
    let list = read(&db, &co, "admin/commissions").await;
    assert_eq!(list["items"][0]["payable_since"], today.to_string());
    assert_eq!(list["items"][0]["paid_on"], today.to_string());
}

/*
    A8: a cookie is sent by any page on *.markcliq.com (same site), so
    writes also need to come from the website's own origin
*/
#[sqlx::test]
async fn a_write_from_another_origin_is_refused(db: PgPool) {
    let co = company(&db, "a").await;
    let id = expense(&db, &co, "approved", 1).await;
    let paid = format!("/api/v1/orgs/{}/expenses/{id}/paid", co.org);
    let cookie = format!("solacliq_session={}", co.admin);
    let host = ("host", "solacliq.markcliq.com");
    let refused: [&[(&str, &str)]; 7] = [
        &[("sec-fetch-site", "same-site")],
        &[("sec-fetch-site", "cross-site")],
        &[
            ("sec-fetch-site", "same-site"),
            ("origin", "https://solacliq.markcliq.com"),
        ],
        &[("origin", "https://markcliq.com")],
        &[("origin", "null")],
        &[("origin", "https://solacliq.markcliq.com.evil.example")],
        // An empty bearer falls back to the cookie, so it's no way round.
        &[
            ("authorization", "Bearer "),
            ("origin", "https://markcliq.com"),
        ],
    ];
    for extra in refused {
        let headers = [&[("cookie", cookie.as_str()), host][..], extra].concat();
        let res = common::post_with(&db, &paid, &headers).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN, "{extra:?}");
        assert_eq!(res.body["code"], "auth.cross_origin", "{extra:?}");
    }
    let status: String = sqlx::query_scalar("SELECT status::text FROM expenses WHERE id = $1")
        .bind(id)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(status, "approved");

    let allowed: [&[(&str, &str)]; 3] = [
        &[("sec-fetch-site", "same-origin")],
        &[("origin", "https://solacliq.markcliq.com")],
        // Not a browser.
        &[],
    ];
    for (n, extra) in allowed.into_iter().enumerate() {
        let id = expense(&db, &co, "approved", 10 + n as i32).await;
        let paid = format!("/api/v1/orgs/{}/expenses/{id}/paid", co.org);
        let headers = [&[("cookie", cookie.as_str()), host][..], extra].concat();
        let res = common::post_with(&db, &paid, &headers).await;
        assert_eq!(res.status, StatusCode::OK, "{extra:?}");
    }

    let bearer = format!("Bearer {}", co.admin);
    let headers = [
        ("authorization", bearer.as_str()),
        ("sec-fetch-site", "cross-site"),
    ];
    let res = common::post_with(&db, &paid, &headers).await;
    assert_eq!(
        res.status,
        StatusCode::OK,
        "a bearer can't be forged by another site"
    );

    let login = Request::post("/api/v1/auth/login")
        .header("content-type", "application/json")
        .header("sec-fetch-site", "same-site")
        .body(Body::from(
            json!({"email": "dev.a@example.com", "password": "sunlight1", "client": "web"})
                .to_string(),
        ))
        .unwrap();
    assert_eq!(common::send(&db, login).await.status, StatusCode::FORBIDDEN);

    let get = Request::get("/api/v1/me")
        .header("cookie", &cookie)
        .header("sec-fetch-site", "cross-site")
        .body(Body::empty())
        .unwrap();
    assert_eq!(
        common::send(&db, get).await.status,
        StatusCode::OK,
        "reads are untouched"
    );
}

/*
    W5 and the dead ends (docs/features/admin-website.md)
*/

// What a person was told in this company, oldest first.
async fn told(db: &PgPool, user: Uuid) -> Vec<(String, String, String)> {
    sqlx::query_as(
        "SELECT kind, title, body FROM notifications
         WHERE user_id = $1 AND org_id IS NOT NULL ORDER BY created_at, id",
    )
    .bind(user)
    .fetch_all(db)
    .await
    .unwrap()
}

async fn uploaded(db: &PgPool, co: &Co, token: &str, purpose: &str) -> String {
    let path = format!("/api/v1/orgs/{}/uploads", co.org);
    let body = json!({"content_type": "image/jpeg", "size_bytes": 1234, "purpose": purpose});
    let res = call(db, "POST", &path, token, Some(body)).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let id = res.body["upload_id"].as_str().unwrap().to_owned();
    common::r2_put(&format!("orgs/{}/{purpose}/{id}", co.org), 1234);
    id
}

async fn as_app(db: &PgPool, co: &Co, token: &str, rest: &str, body: Value) -> Res {
    let method = if rest.ends_with("/receipt") || rest.contains("/documents/") {
        "PUT"
    } else {
        "POST"
    };
    call_with(
        db,
        method,
        &format!("/api/v1/orgs/{}/{rest}", co.org),
        token,
        Some(body),
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await
}

// A verified customer who has the app; their token.
async fn customer_with_app(db: &PgPool, co: &Co, id: Uuid, email: &str) -> String {
    let token = member(db, co.org, email, "customer", None).await;
    sqlx::query(
        "UPDATE customers SET user_id = (SELECT id FROM users WHERE email = $2) WHERE id = $1",
    )
    .bind(id)
    .bind(email)
    .execute(db)
    .await
    .unwrap();
    token
}

#[sqlx::test]
async fn the_admin_hears_of_everything_waiting_for_them(db: PgPool) {
    let co = company(&db, "a").await;
    let _other = company(&db, "b").await;
    let admin = user_id(&db, "dev.a@example.com").await;

    let mut docs = Vec::new();
    for kind in [
        "aadhaar",
        "pan",
        "electricity_bill",
        "land_document",
        "signature",
    ] {
        docs.push(json!({"kind": kind, "files": [{"upload_id": uploaded(&db, &co, &co.meena, "kyc").await}]}));
    }
    let form = json!({"name": "New Customer", "phone": "9814000077", "email": "new.kyc@example.com",
        "address": "House 7", "city": "Mohali", "pin_code": "160055", "state": "Punjab",
        "discom": "PSPCL", "consumer_number": "300777", "sanctioned_load_kw": 5,
        "connection_type": "residential", "proposed_kw": 3, "roof": "rcc", "subsidy": false,
        "documents": docs, "consent": true});
    let res = as_app(&db, &co, &co.meena, "customer-registrations", form).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let new: Uuid = res.body["id"].as_str().unwrap().parse().unwrap();
    let back = json!({"note": "Blurred"});
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{new}/documents/pan/return"),
        Some(back),
    )
    .await;
    let body = json!({"files": [{"upload_id": uploaded(&db, &co, &co.meena, "kyc").await}]});
    let res = as_app(
        &db,
        &co,
        &co.meena,
        &format!("my-customers/{new}/documents/pan"),
        body,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);

    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let asha = customer_with_app(&db, &co, cust, "asha.tell@example.com").await;
    let t = task(&db, &co, cust).await;
    let body = json!({"reason": "safety", "note": "Live wire"});
    as_app(&db, &co, &co.ravi, &format!("tasks/{t}/problems"), body).await;
    let body = json!({"text": "Going back at 4"});
    as_app(&db, &co, &co.ravi, &format!("tasks/{t}/messages"), body).await;
    sqlx::query("UPDATE task_photo_slots SET upload_id = NULL WHERE task_id = $1")
        .bind(t)
        .execute(&db)
        .await
        .unwrap();
    sqlx::query("DELETE FROM task_photo_slots WHERE task_id = $1")
        .bind(t)
        .execute(&db)
        .await
        .unwrap();
    let res = as_app(&db, &co, &co.ravi, &format!("tasks/{t}/submit"), json!({})).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);

    let day = Utc::now()
        .with_timezone(&FixedOffset::east_opt(19_800).unwrap())
        .date_naive();
    let body = json!({"amount": 455, "category": "fuel", "note": "Diesel", "spent_on": day});
    let res = as_app(&db, &co, &co.ravi, "expenses", body).await;
    let exp = res.body["id"].as_str().unwrap().to_owned();
    act(
        &db,
        &co,
        "POST",
        &format!("expenses/{exp}/return"),
        Some(json!({"note": "Receipt?"})),
    )
    .await;
    let body = json!({"upload_id": uploaded(&db, &co, &co.ravi, "receipt").await});
    as_app(&db, &co, &co.ravi, &format!("expenses/{exp}/receipt"), body).await;

    let advance = payments(&db, &co, cust).await[0]["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let path = format!("my-install/payments/{advance}/claim");
    as_app(&db, &co, &asha, &path, json!({"method": "upi"})).await;

    let heard = told(&db, admin).await;
    let kinds: Vec<&str> = heard.iter().map(|n| n.0.as_str()).collect();
    assert_eq!(
        kinds,
        [
            "kyc_submitted",
            "kyc_submitted",
            "task_problem",
            "task_message",
            "task_submitted",
            "expense_submitted",
            "expense_submitted",
            "payment_claimed",
        ]
    );
    assert!(heard[3].2.contains("Going back at 4"));
    assert!(heard[5].2.contains("₹4.55"));
    assert!(
        told(&db, user_id(&db, "dev.b@example.com").await)
            .await
            .is_empty()
    );

    let feed = read(&db, &co, "notifications").await;
    assert_eq!(feed["unread_count"], 8);
}

#[sqlx::test]
async fn the_queue_has_replies_amounts_and_whats_to_pay(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let with_agent = customer(&db, &co, "With The Agent", "9814000002").await;
    let back = json!({"note": "Blurred"});
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{with_agent}/documents/aadhaar/return"),
        Some(back),
    )
    .await;

    let t = task(&db, &co, cust).await;
    let body = json!({"text": "Gate is locked"});
    as_app(&db, &co, &co.ravi, &format!("tasks/{t}/messages"), body).await;
    let to_pay = expense(&db, &co, "approved", 1).await;
    sqlx::query("UPDATE install_payments SET status = 'claimed', claimed_at = now(), claimed_method = 'upi' WHERE position = 0")
        .execute(&db)
        .await
        .unwrap();

    let q = read(&db, &co, "review").await;
    assert_eq!(q["tasks"][0]["id"], t.to_string());
    assert_eq!(q["tasks"][0]["status"], "reply");
    assert_eq!(q["expenses"][0]["id"], to_pay.to_string());
    assert_eq!(q["expenses"][0]["status"], "approved");
    assert_eq!(q["expenses"][0]["amount"], 455);
    assert_eq!(q["payments"][0]["amount"], 6_000_000);
    assert_eq!(q["commissions"][0]["amount"], 400_000);
    assert_eq!(
        q["registrations"],
        json!([]),
        "with the agent, not waiting for the admin"
    );

    // Acting on the task answers the reply.
    let body = json!({"due_at": Utc::now() + Duration::days(2)});
    act(&db, &co, "PUT", &format!("tasks/{t}/schedule"), Some(body)).await;
    assert_eq!(read(&db, &co, "review").await["tasks"], json!([]));
}

#[sqlx::test]
async fn a_payment_that_didnt_arrive_is_due_again(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let asha = customer_with_app(&db, &co, cust, "asha.false@example.com").await;
    let advance = payments(&db, &co, cust).await[0]["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let path = format!("payments/{advance}/not-received");
    let why = || Some(json!({"note": "Nothing in the account"}));

    let res = act(&db, &co, "POST", &path, why()).await;
    assert_eq!(res.status, StatusCode::CONFLICT, "nothing is claimed yet");

    let claim = format!("my-install/payments/{advance}/claim");
    as_app(&db, &co, &asha, &claim, json!({"method": "upi"})).await;
    let res = act(&db, &co, "POST", &path, Some(json!({"note": " "}))).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{}/{path}", co.org),
        &asha,
        why(),
    )
    .await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);

    let res = act(&db, &co, "POST", &path, why()).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let now = payments(&db, &co, cust).await;
    assert_eq!(now[0]["status"], "due");
    assert!(now[0].get("claimed_at").is_none());
    let heard = told(&db, user_id(&db, "asha.false@example.com").await).await;
    let last = heard.last().unwrap();
    assert_eq!(
        (last.0.as_str(), last.1.as_str()),
        ("payment_due", "Payment not received")
    );
    assert!(last.2.contains("Nothing in the account"));

    let again = as_app(&db, &co, &asha, &claim, json!({"method": "bank_transfer"})).await;
    assert_eq!(again.status, StatusCode::OK, "not a dead end");
}

#[sqlx::test]
async fn an_expense_can_be_rejected_for_good(db: PgPool) {
    let co = company(&db, "a").await;
    let why = || Some(json!({"note": "Not a company cost"}));
    for (n, from) in ["in_review", "needs_fix"].into_iter().enumerate() {
        let id = expense(&db, &co, from, n as i32).await;
        let res = act(&db, &co, "POST", &format!("expenses/{id}/reject"), why()).await;
        assert_eq!(res.status, StatusCode::OK, "{from}: {}", res.body);

        let path = format!("/api/v1/orgs/{}/expenses/{id}", co.org);
        let mine = call(&db, "GET", &path, &co.ravi, None).await;
        assert_eq!(mine.body["status"], "rejected");
        assert_eq!(mine.body["admin_note"], "Not a company cost");
        for (action, body) in [("approve", None), ("paid", None), ("reject", why())] {
            let res = act(&db, &co, "POST", &format!("expenses/{id}/{action}"), body).await;
            assert_eq!(res.status, StatusCode::CONFLICT, "{action} after rejecting");
        }
    }
    assert_eq!(
        told(&db, co.ravi_id).await.last().unwrap().1,
        "Expense not accepted"
    );
    let paid = expense(&db, &co, "approved", 9).await;
    let res = act(&db, &co, "POST", &format!("expenses/{paid}/reject"), why()).await;
    assert_eq!(
        res.status,
        StatusCode::CONFLICT,
        "approved is a promise to pay"
    );
    assert_eq!(
        read(&db, &co, "admin/expenses?status=rejected").await["items"]
            .as_array()
            .unwrap()
            .len(),
        2
    );
}

#[sqlx::test]
async fn the_customer_hears_when_a_visit_moves_or_they_arent_taken_up(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    customer_with_app(&db, &co, cust, "asha.visit@example.com").await;
    let asha = user_id(&db, "asha.visit@example.com").await;
    let t = task(&db, &co, cust).await;
    let body = json!({"due_at": Utc::now() + Duration::days(3)});
    act(&db, &co, "PUT", &format!("tasks/{t}/schedule"), Some(body)).await;
    act(
        &db,
        &co,
        "POST",
        &format!("tasks/{t}/cancel"),
        Some(json!({"note": "No material"})),
    )
    .await;
    let titles: Vec<String> = told(&db, asha).await.into_iter().map(|n| n.1).collect();
    assert_eq!(titles, ["Visit booked", "Visit moved", "Visit cancelled"]);

    let gone = customer(&db, &co, "Bal", "9814000002").await;
    customer_with_app(&db, &co, gone, "bal.closed@example.com").await;
    let bal = user_id(&db, "bal.closed@example.com").await;
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{gone}/reject"),
        Some(json!({"note": "Roof shaded"})),
    )
    .await;
    let heard = told(&db, bal).await;
    assert_eq!(heard[0].0, "registration_closed");
    assert!(heard[0].2.contains("Roof shaded"));
}

// F12: admins check the site, so what waits for them never rings a phone.
#[sqlx::test]
async fn what_waits_for_the_admin_is_never_pushed(db: PgPool) {
    let co = company(&db, "a").await;
    let admin = user_id(&db, "dev.a@example.com").await;
    let path = "/api/v1/me/device";
    let body = json!({"token": format!("admin-device-{}", co.org), "platform": "android"});
    let res = call(&db, "PUT", path, &co.admin, Some(body)).await;
    assert_eq!(res.status, StatusCode::NO_CONTENT, "{}", res.body);
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let t = task(&db, &co, cust).await;
    let body = json!({"reason": "safety", "note": "Live wire"});
    as_app(&db, &co, &co.ravi, &format!("tasks/{t}/problems"), body).await;
    assert_eq!(told(&db, admin).await.len(), 1, "there is one to hold back");
    let app = common::app_db(&db);
    // The log sender counts every message it is handed as sent.
    let mut sender = backend::push::Sender::Log;
    let claimed = backend::push::push_once(&app, &mut sender).await.unwrap();
    assert_eq!(claimed, 0);
    app.close().await;
}

// A NUL is valid JSON and valid in a URL, but Postgres text refuses it.
#[sqlx::test]
async fn a_nul_character_is_bad_input_not_a_server_error(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = customer(&db, &co, "Asha", "9814000001").await;
    let res = act(&db, &co, "GET", "admin/customers?q=a%00b", None).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", res.body);
    let body = json!({"note": "bad\u{0}note"});
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{cust}/reject"),
        Some(body),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", res.body);
}

/*
    The admin design's Overview, board and list fields
*/

#[sqlx::test]
async fn the_overview_counts_only_this_companys(db: PgPool) {
    let co = company(&db, "a").await;
    let other = company(&db, "b").await;
    verified(&db, &other, "Other", "9814000009").await;
    let running = verified(&db, &co, "Asha", "9814000001").await;
    let done = verified(&db, &co, "Bal", "9814000002").await;
    let today = Utc::now()
        .with_timezone(&FixedOffset::east_opt(19_800).unwrap())
        .date_naive();
    sqlx::query("UPDATE installs SET handed_over_on = $2 WHERE customer_id = $1")
        .bind(done)
        .bind(today - Duration::days(7))
        .execute(&db)
        .await
        .unwrap();
    let advance = payments(&db, &co, running).await[0]["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{advance}/confirm"),
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);

    let o = read(&db, &co, "admin/overview").await;
    assert_eq!(o["installs_running"], 1);
    assert_eq!(o["by_stage"], json!([1, 0, 0, 0, 0, 0, 0]));
    assert_eq!(o["collected_this_month"], 6_000_000);
    assert_eq!(o["to_collect"], 6_000_000, "the other customer's advance");
    let weeks: Vec<i64> = o["finished_by_week"]
        .as_array()
        .unwrap()
        .iter()
        .map(|w| w["count"].as_i64().unwrap())
        .collect();
    assert_eq!(weeks, [0, 0, 1, 0]);
    assert_eq!(o["commissions"]["in_review"], 800_000);

    let path = format!("/api/v1/orgs/{}/admin/overview", co.org);
    for token in [&co.ravi, &co.meena, &other.admin] {
        let res = call(&db, "GET", &path, token, None).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN);
    }
}

#[sqlx::test]
async fn lists_carry_what_the_board_and_tables_show(db: PgPool) {
    let co = company(&db, "a").await;
    let cust = verified(&db, &co, "Asha", "9814000001").await;
    let new = customer(&db, &co, "Not Yet", "9814000002").await;
    let t = task(&db, &co, cust).await;

    let listed = read(&db, &co, "admin/customers").await;
    let of = |id: Uuid| {
        listed["items"]
            .as_array()
            .unwrap()
            .iter()
            .find(|c| c["id"] == id.to_string())
            .unwrap()
            .clone()
    };
    assert_eq!(of(cust)["advance_status"], "due");
    assert_eq!(of(cust)["commission_amount"], 400_000);
    assert!(of(new).get("advance_status").is_none(), "no price yet");

    let assigned = read(&db, &co, "admin/tasks?view=assigned").await;
    assert_eq!(assigned["items"][0]["id"], t.to_string());
    assert!(assigned["items"][0]["place"].is_string());
    assert_eq!(
        read(&db, &co, "admin/tasks?view=returned").await["items"],
        json!([])
    );

    let team = read(&db, &co, "members?role=agent").await;
    assert_eq!(team["items"][0]["customers"], 2);
}
