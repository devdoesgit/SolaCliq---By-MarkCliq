//! The company's admin actions (tasks, expenses, customers, commissions,
//! payments): who may act, the states each needs, and what is checked.
//! The happy path end to end is `lifecycle.rs`.

mod common;

use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{Res, call, member, org};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

// Solar A: an admin, a worker (Ravi) and a commission agent (Meena).
struct Co {
    org: Uuid,
    admin: String,
    ravi: String,
    ravi_id: Uuid,
    meena: String,
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

async fn company(db: &PgPool) -> Co {
    let org = org(db, "Solar A", "active").await;
    let admin = member(db, org, "dev@example.com", "org_admin", None).await;
    let ravi = member(db, org, "ravi@example.com", "worker", None).await;
    let meena = member(db, org, "meena@example.com", "agent", Some("commission")).await;
    Co {
        org,
        admin,
        ravi,
        ravi_id: user_id(db, "ravi@example.com").await,
        meena,
    }
}

/*
    A customer straight in SQL, as Meena registered them: `kyc` status,
    a commission in review, five documents, and `subsidy` asked for
*/
async fn customer(db: &PgPool, co: &Co, kyc: &str, subsidy: bool) -> Uuid {
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, address, city, system_kw,
                                registered_by, kyc_status, subsidy, commission, commission_status)
         SELECT $1, $2, 'SC-' || $1::text, 'Rajinder Kaur', '98' || lpad((SELECT count(*) FROM customers)::text, 8, '0'),
                'House 12', 'Mohali', 5, id, $3::kyc_status, $4, 400000, 'in_review'
         FROM users WHERE email = 'meena@example.com'",
    )
    .bind(id)
    .bind(co.org)
    .bind(kyc)
    .bind(subsidy)
    .execute(db)
    .await
    .unwrap();
    for kind in [
        "aadhaar",
        "pan",
        "electricity_bill",
        "land_document",
        "signature",
    ] {
        let upload = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO uploads (id, org_id, owner_id, purpose, content_type, size_bytes, r2_key, used_at)
             SELECT $1, $2, id, 'kyc', 'image/jpeg', 100, 'orgs/' || $2::text || '/kyc/' || $1::text, now()
             FROM users WHERE email = 'meena@example.com'",
        )
        .bind(upload)
        .bind(co.org)
        .execute(db)
        .await
        .unwrap();
        sqlx::query(
            "INSERT INTO documents (id, org_id, customer_id, kind, upload_id, uploaded_by)
             SELECT $1, $2, $3, $4::kyc_kind, $5, id FROM users WHERE email = 'meena@example.com'",
        )
        .bind(Uuid::now_v7())
        .bind(co.org)
        .bind(id)
        .bind(kind)
        .bind(upload)
        .execute(db)
        .await
        .unwrap();
    }
    id
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

async fn new_task(db: &PgPool, co: &Co, customer: Uuid) -> Res {
    act(
        db,
        co,
        "POST",
        "tasks",
        Some(
            json!({"customer_id": customer, "title": "Site survey", "stage_index": 1,
                    "assignee_id": co.ravi_id, "due_at": Utc::now() + Duration::days(1),
                    "photos": [{"id": "roof", "label": "Roof"}]}),
        ),
    )
    .await
}

#[sqlx::test]
async fn only_the_companys_admin_acts(db: PgPool) {
    let co = company(&db).await;
    for token in [&co.ravi, &co.meena] {
        let res = call(
            &db,
            "GET",
            &format!("/api/v1/orgs/{}/review", co.org),
            token,
            None,
        )
        .await;
        assert_eq!(res.status, StatusCode::FORBIDDEN);
        assert_eq!(res.body["code"], "org.role_not_allowed");
    }
    // Solar B's admin can't touch Solar A's customer.
    let b = org(&db, "Solar B", "active").await;
    let other = member(&db, b, "admin.b@example.com", "org_admin", None).await;
    let c = customer(&db, &co, "in_review", false).await;
    let res = call(
        &db,
        "POST",
        &format!("/api/v1/orgs/{b}/customers/{c}/verify"),
        &other,
        Some(json!({"total": 1000})),
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
}

#[sqlx::test]
async fn a_task_needs_an_approved_customer_and_an_installer(db: PgPool) {
    let co = company(&db).await;
    let pending = customer(&db, &co, "in_review", false).await;
    let res = new_task(&db, &co, pending).await;
    assert_eq!(res.body["errors"][0]["field"], "customer_id");

    let approved = customer(&db, &co, "approved", false).await;
    let meena_id = user_id(&db, "meena@example.com").await;
    for (field, body) in [
        ("assignee_id", json!({"assignee_id": meena_id})),
        ("stage_index", json!({"stage_index": 8})),
        (
            "photos",
            json!({"photos": [{"id": "a", "label": "A"}, {"id": "a", "label": "B"}]}),
        ),
        ("title", json!({"title": " "})),
    ] {
        let mut req = json!({"customer_id": approved, "title": "Site survey", "stage_index": 1,
                             "assignee_id": co.ravi_id, "due_at": Utc::now()});
        for (k, v) in body.as_object().unwrap() {
            req[k] = v.clone();
        }
        let res = act(&db, &co, "POST", "tasks", Some(req)).await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{field}");
        assert_eq!(res.body["errors"][0]["field"], field);
    }
    let res = new_task(&db, &co, approved).await;
    assert_eq!(res.status, StatusCode::CREATED);
    assert_eq!(res.body["reference"], "TSK-0001");
}

#[sqlx::test]
async fn task_decisions_follow_its_state(db: PgPool) {
    let co = company(&db).await;
    let c = customer(&db, &co, "approved", false).await;
    let task = new_task(&db, &co, c).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();

    // Not submitted yet: nothing to approve or return.
    for action in ["approve", "return"] {
        let res = act(
            &db,
            &co,
            "POST",
            &format!("tasks/{task}/{action}"),
            Some(json!({"note": "x"})),
        )
        .await;
        assert_eq!(res.status, StatusCode::CONFLICT, "{action}");
        assert_eq!(res.body["code"], "task.locked");
    }
    sqlx::query("UPDATE tasks SET status = 'submitted' WHERE id = $1::uuid")
        .bind(&task)
        .execute(&db)
        .await
        .unwrap();
    // A retake of a photo the task doesn't have changes nothing.
    let res = act(
        &db,
        &co,
        "POST",
        &format!("tasks/{task}/return"),
        Some(json!({"note": "Again", "retake": ["nope"]})),
    )
    .await;
    assert_eq!(res.body["errors"][0]["field"], "retake");
    let status: String = sqlx::query_scalar("SELECT status::text FROM tasks WHERE id = $1::uuid")
        .bind(&task)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(status, "submitted");
    // Submitted: can't be rescheduled, can be cancelled; then nothing more.
    let res = act(
        &db,
        &co,
        "PUT",
        &format!("tasks/{task}/schedule"),
        Some(json!({"due_at": Utc::now()})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    let res = act(
        &db,
        &co,
        "POST",
        &format!("tasks/{task}/cancel"),
        Some(json!({"note": "Postponed."})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    let res = act(
        &db,
        &co,
        "POST",
        &format!("tasks/{task}/cancel"),
        Some(json!({"note": "Again."})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    let done = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/tasks?view=done", co.org),
        &co.ravi,
        None,
    )
    .await;
    assert_eq!(done.body["items"][0]["status"], "cancelled");
}

#[sqlx::test]
async fn a_reassigned_task_moves_to_the_new_installer(db: PgPool) {
    let co = company(&db).await;
    let neha = member(&db, co.org, "neha@example.com", "worker", None).await;
    let neha_id = user_id(&db, "neha@example.com").await;
    let c = customer(&db, &co, "approved", false).await;
    let task = new_task(&db, &co, c).await.body["id"]
        .as_str()
        .unwrap()
        .to_owned();
    let res = act(
        &db,
        &co,
        "PUT",
        &format!("tasks/{task}/schedule"),
        Some(json!({"due_at": Utc::now() + Duration::days(3), "assignee_id": neha_id})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let path = format!("/api/v1/orgs/{}/tasks/{task}", co.org);
    assert_eq!(
        call(&db, "GET", &path, &co.ravi, None).await.status,
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        call(&db, "GET", &path, &neha, None).await.status,
        StatusCode::OK
    );
    let feed = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/notifications", co.org),
        &co.ravi,
        None,
    )
    .await;
    assert_eq!(feed.body["items"][0]["title"], "Task moved");
    let feed = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/notifications", co.org),
        &neha,
        None,
    )
    .await;
    assert_eq!(feed.body["items"][0]["kind"], "task_assigned");
}

#[sqlx::test]
async fn expense_decisions_follow_its_state(db: PgPool) {
    let co = company(&db).await;
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO expenses (id, org_id, reference, owner_id, amount, category, note, spent_on)
         VALUES ($1, $2, 'EXP-0001', $3, 50000, 'fuel', 'Diesel', current_date)",
    )
    .bind(id)
    .bind(co.org)
    .bind(co.ravi_id)
    .execute(&db)
    .await
    .unwrap();
    let res = act(&db, &co, "POST", &format!("expenses/{id}/paid"), None).await;
    assert_eq!(
        res.body["code"], "expense.locked",
        "paid needs approved first"
    );
    let res = act(
        &db,
        &co,
        "POST",
        &format!("expenses/{id}/return"),
        Some(json!({"note": "Unreadable."})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    let e = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/expenses/{id}", co.org),
        &co.ravi,
        None,
    )
    .await;
    assert_eq!(e.body["status"], "needs_fix");
    assert_eq!(e.body["admin_note"], "Unreadable.");
    let res = act(&db, &co, "POST", &format!("expenses/{id}/approve"), None).await;
    assert_eq!(res.status, StatusCode::CONFLICT, "waits for a new receipt");
}

#[sqlx::test]
async fn customer_decisions_follow_its_state(db: PgPool) {
    let co = company(&db).await;
    // Subsidy asked for: the table's ₹78,000 for 5 kW.
    let c = customer(&db, &co, "in_review", true).await;
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/verify"),
        Some(json!({"total": 0})),
    )
    .await;
    assert_eq!(res.body["errors"][0]["field"], "total");
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/verify"),
        Some(json!({"total": 28_500_000})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let subsidy: i64 = sqlx::query_scalar("SELECT subsidy FROM installs WHERE customer_id = $1")
        .bind(c)
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(subsidy, 7_800_000);
    for (rest, body) in [
        ("verify", json!({"total": 28_500_000})),
        ("reject", json!({"note": "Too late."})),
        ("documents/pan/return", json!({"note": "Blurry."})),
    ] {
        let res = act(
            &db,
            &co,
            "POST",
            &format!("customers/{c}/{rest}"),
            Some(body),
        )
        .await;
        assert_eq!(res.status, StatusCode::CONFLICT, "{rest} after verifying");
        assert_eq!(res.body["code"], "registration.locked");
    }
    let res = act(&db, &co, "POST", &format!("customers/{c}/handover"), None).await;
    assert_eq!(res.status, StatusCode::OK);
    let res = act(&db, &co, "POST", &format!("customers/{c}/handover"), None).await;
    assert_eq!(res.status, StatusCode::CONFLICT, "once");

    // A rejected customer: nothing to verify, and its commission is closed.
    let r = customer(&db, &co, "in_review", false).await;
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{r}/reject"),
        Some(json!({"note": "Roof shaded."})),
    )
    .await;
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{r}/verify"),
        Some(json!({"total": 100})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{r}/commission"),
        Some(json!({})),
    )
    .await;
    assert_eq!(res.body["code"], "commission.locked");
    let list = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{}/my-customers", co.org),
        &co.meena,
        None,
    )
    .await;
    let rejected = list.body["items"]
        .as_array()
        .unwrap()
        .iter()
        .find(|i| i["id"] == r.to_string())
        .unwrap()
        .clone();
    assert_eq!(rejected["kyc_status"], "rejected");
    assert_eq!(rejected["detail"], "Roof shaded.");
}

#[sqlx::test]
async fn commission_and_payments_follow_their_state(db: PgPool) {
    let co = company(&db).await;
    let c = customer(&db, &co, "in_review", false).await;
    act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/verify"),
        Some(json!({"total": 10_000_000})),
    )
    .await;
    let ids: Vec<Uuid> = sqlx::query_scalar(
        "SELECT p.id FROM install_payments p JOIN installs i ON i.id = p.install_id
         WHERE i.customer_id = $1 ORDER BY p.position",
    )
    .bind(c)
    .fetch_all(&db)
    .await
    .unwrap();

    // Not payable yet: nothing to pay out.
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/commission/paid"),
        None,
    )
    .await;
    assert_eq!(res.body["code"], "commission.locked");
    // A later payment can't be confirmed; asking for it needs a date ahead.
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{}/confirm", ids[2]),
        None,
    )
    .await;
    assert_eq!(res.body["code"], "payment.not_due");
    let yesterday = (Utc::now() - Duration::days(2)).date_naive().to_string();
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{}/request", ids[2]),
        Some(json!({"due_on": yesterday})),
    )
    .await;
    assert_eq!(res.body["errors"][0]["field"], "due_on");
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{}/request", ids[0]),
        Some(json!({"due_on": Utc::now().date_naive().to_string()})),
    )
    .await;
    assert_eq!(
        res.status,
        StatusCode::CONFLICT,
        "the advance is already due"
    );

    // The advance paid at the office first: approving the commission makes it payable at once.
    let res = act(
        &db,
        &co,
        "POST",
        &format!("payments/{}/confirm", ids[0]),
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/commission"),
        Some(json!({})),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let status: String =
        sqlx::query_scalar("SELECT commission_status::text FROM customers WHERE id = $1")
            .bind(c)
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(status, "payable");
    let res = act(
        &db,
        &co,
        "POST",
        &format!("customers/{c}/commission"),
        Some(json!({})),
    )
    .await;
    assert_eq!(res.body["code"], "commission.locked", "decided once");
}
