//! A worker's tasks (phase 8): lists, one task, proof photos checked
//! against R2, checklist, submit, problems, replies, history and stats.

mod common;

use axum::http::StatusCode;
use chrono::{DateTime, Duration, Utc};
use common::{Res, call, call_with, member, org, r2_has, r2_put};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

// Ramesh's roof in Mohali, where the photos should be taken.
const SITE: (f64, f64) = (30.7046, 76.7179);

// A company with an admin and Ravi, a worker; Ravi's token.
struct Setup {
    org: Uuid,
    admin: Uuid,
    ravi: String,
}

async fn setup(db: &PgPool) -> Setup {
    let org = org(db, "Example Solar", "active").await;
    member(db, org, "dev@example.com", "org_admin", None).await;
    let ravi = member(db, org, "ravi@example.com", "worker", None).await;
    Setup {
        org,
        admin: user_id(db, "dev@example.com").await,
        ravi,
    }
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

/*
    What the admin website will do: a customer, and a task for `worker`
    with two photo slots and two checklist items, written straight in SQL
*/
async fn task(db: &PgPool, s: &Setup, worker: &str, status: &str, due_at: DateTime<Utc>) -> Uuid {
    let customer = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO customers (id, org_id, reference, name, phone, address, lat, lng, system_kw)
         VALUES ($1, $2, 'SC-' || $1::text, 'Ramesh Sahoo', '9814022671', 'Sector 70, Mohali',
                 $3, $4, 5)",
    )
    .bind(customer)
    .bind(s.org)
    .bind(SITE.0)
    .bind(SITE.1)
    .execute(db)
    .await
    .unwrap();
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO tasks (id, org_id, customer_id, reference, title, stage_index, assignee_id,
                            assigned_by, due_at, status, admin_note, admin_note_at)
         SELECT $1, $2, $3, 'TSK-' || $1::text, 'Panel installation', 3, u.id, $4, $5,
                $6::task_status, 'Use the new clamps.', now()
         FROM users u WHERE u.email = $7",
    )
    .bind(id)
    .bind(s.org)
    .bind(customer)
    .bind(s.admin)
    .bind(due_at)
    .bind(status)
    .bind(worker)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO task_photo_slots (org_id, task_id, slot_id, position, label, hint)
         VALUES ($1, $2, 'rails', 1, 'Rails', 'Rails on the structure'),
                ($1, $2, 'clamp', 2, 'Clamp close-up', 'Bolt visible')",
    )
    .bind(s.org)
    .bind(id)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO task_checklist_items (org_id, task_id, item_id, position, text)
         VALUES ($1, $2, 'rails', 1, 'Mount rails'), ($1, $2, 'torque', 2, 'Check clamp torque')",
    )
    .bind(s.org)
    .bind(id)
    .execute(db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO task_events (id, org_id, task_id, kind, actor_id, detail)
         VALUES ($1, $2, $3, 'assigned', $4, 'Due today')",
    )
    .bind(Uuid::now_v7())
    .bind(s.org)
    .bind(id)
    .bind(s.admin)
    .execute(db)
    .await
    .unwrap();
    id
}

fn path(s: &Setup, rest: &str) -> String {
    format!("/api/v1/orgs/{}/{rest}", s.org)
}

// Where an upload of the company's lives in the bucket.
fn key(s: &Setup, upload_id: &str) -> String {
    format!("orgs/{}/proof/{upload_id}", s.org)
}

// The app's way: ask for an upload, send the file (to the stand-in), attach.
async fn upload(db: &PgPool, org: Uuid, token: &str) -> String {
    let res = call(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/uploads"),
        token,
        Some(json!({"content_type": "image/jpeg", "size_bytes": 1000, "purpose": "proof"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    res.body["upload_id"].as_str().unwrap().to_owned()
}

async fn add_photo(
    db: &PgPool,
    s: &Setup,
    task: Uuid,
    slot: &str,
    upload_id: &str,
    at: (f64, f64),
) -> Res {
    call(
        db,
        "POST",
        &path(s, &format!("tasks/{task}/photos")),
        &s.ravi,
        Some(json!({
            "slot_id": slot, "upload_id": upload_id, "taken_at": Utc::now(),
            "lat": at.0, "lng": at.1, "accuracy_m": 8, "mocked_location": false
        })),
    )
    .await
}

async fn photo(db: &PgPool, s: &Setup, task: Uuid, slot: &str) -> Res {
    let id = upload(db, s.org, &s.ravi).await;
    r2_put(&key(s, &id), 1000);
    add_photo(db, s, task, slot, &id, SITE).await
}

async fn tick(db: &PgPool, s: &Setup, task: Uuid, item: &str) -> Res {
    call(
        db,
        "PUT",
        &path(s, &format!("tasks/{task}/checklist/{item}")),
        &s.ravi,
        Some(json!({"done": true})),
    )
    .await
}

async fn submit(db: &PgPool, s: &Setup, task: Uuid, key: &str) -> Res {
    call_with(
        db,
        "POST",
        &path(s, &format!("tasks/{task}/submit")),
        &s.ravi,
        Some(json!({"note": "All fixed."})),
        &[("idempotency-key", key)],
    )
    .await
}

async fn list(db: &PgPool, s: &Setup, view: &str) -> Vec<Value> {
    let res = call(
        db,
        "GET",
        &path(s, &format!("tasks?view={view}")),
        &s.ravi,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body["items"].as_array().unwrap().clone()
}

fn ids(items: &[Value]) -> Vec<String> {
    items
        .iter()
        .map(|t| t["id"].as_str().unwrap().to_owned())
        .collect()
}

#[sqlx::test]
async fn each_list_holds_the_right_tasks(db: PgPool) {
    let s = setup(&db).await;
    let now = Utc::now();
    let overdue = task(
        &db,
        &s,
        "ravi@example.com",
        "assigned",
        now - Duration::days(2),
    )
    .await;
    let today = task(&db, &s, "ravi@example.com", "assigned", now).await;
    let returned = task(
        &db,
        &s,
        "ravi@example.com",
        "returned",
        now - Duration::days(5),
    )
    .await;
    let later = task(
        &db,
        &s,
        "ravi@example.com",
        "assigned",
        now + Duration::days(3),
    )
    .await;
    let approved = task(
        &db,
        &s,
        "ravi@example.com",
        "approved",
        now - Duration::days(1),
    )
    .await;
    member(&db, s.org, "neha@example.com", "worker", None).await;
    let nehas = task(&db, &s, "neha@example.com", "assigned", now).await;

    let t = ids(&list(&db, &s, "today").await);
    assert_eq!(
        t,
        [returned, overdue, today].map(|i| i.to_string()),
        "in due order"
    );
    assert_eq!(ids(&list(&db, &s, "upcoming").await), [later.to_string()]);
    assert_eq!(ids(&list(&db, &s, "done").await), [approved.to_string()]);
    for view in ["today", "upcoming", "done"] {
        assert!(!ids(&list(&db, &s, view).await).contains(&nehas.to_string()));
    }

    let row = &list(&db, &s, "today").await[2];
    assert_eq!(row["title"], "Panel installation");
    assert_eq!(row["customer_name"], "Ramesh Sahoo");
    assert_eq!(row["status"], "assigned");
    assert_eq!(row["has_problem"], false);
}

#[sqlx::test]
async fn lists_page_through_in_order(db: PgPool) {
    let s = setup(&db).await;
    let now = Utc::now() + Duration::days(2);
    let mut made = Vec::new();
    for i in 0..3 {
        made.push(
            task(
                &db,
                &s,
                "ravi@example.com",
                "assigned",
                now + Duration::hours(i),
            )
            .await,
        );
    }
    let first = call(
        &db,
        "GET",
        &path(&s, "tasks?view=upcoming&limit=2"),
        &s.ravi,
        None,
    )
    .await;
    let cursor = first.body["page"]["next_cursor"].as_str().unwrap();
    let second = call(
        &db,
        "GET",
        &path(&s, &format!("tasks?view=upcoming&limit=2&cursor={cursor}")),
        &s.ravi,
        None,
    )
    .await;
    let mut seen = ids(first.body["items"].as_array().unwrap());
    seen.extend(ids(second.body["items"].as_array().unwrap()));
    assert_eq!(seen, made.iter().map(Uuid::to_string).collect::<Vec<_>>());
    assert!(second.body["page"]["next_cursor"].is_null());
}

#[sqlx::test]
async fn a_task_shows_its_customer_slots_and_checklist(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    let res = call(&db, "GET", &path(&s, &format!("tasks/{id}")), &s.ravi, None).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let t = &res.body;
    assert_eq!(t["stage"], json!({"index": 3, "count": 7}));
    assert_eq!(t["customer"]["phone"], "9814022671");
    assert_eq!(t["assigned_by"]["role"], "Admin");
    assert_eq!(t["admin_note"]["text"], "Use the new clamps.");
    assert_eq!(t["photos"][1]["id"], "clamp");
    assert!(t["photos"][1].get("photo").is_none());
    assert_eq!(
        t["checklist"][0],
        json!({"id": "rails", "text": "Mount rails", "done": false})
    );
}

#[sqlx::test]
async fn someone_elses_task_is_not_found(db: PgPool) {
    let s = setup(&db).await;
    member(&db, s.org, "neha@example.com", "worker", None).await;
    let nehas = task(&db, &s, "neha@example.com", "assigned", Utc::now()).await;
    for (method, rest) in [
        ("GET", format!("tasks/{nehas}")),
        ("GET", format!("tasks/{nehas}/history")),
    ] {
        let res = call(&db, method, &path(&s, &rest), &s.ravi, None).await;
        assert_eq!(res.status, StatusCode::NOT_FOUND, "{rest}");
    }
    assert_eq!(
        tick(&db, &s, nehas, "rails").await.status,
        StatusCode::NOT_FOUND
    );

    // Another company's task can't be reached through this one either.
    let other = org(&db, "Solar B", "active").await;
    common::join(&db, other, "ravi@example.com", "worker", None).await;
    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{other}/tasks/{nehas}"),
        &s.ravi,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::NOT_FOUND);
}

#[sqlx::test]
async fn only_workers_have_tasks(db: PgPool) {
    let s = setup(&db).await;
    let agent = member(&db, s.org, "meena@example.com", "agent", Some("commission")).await;
    for rest in ["tasks?view=today", "me/stats"] {
        let res = call(&db, "GET", &path(&s, rest), &agent, None).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN, "{rest}");
        assert_eq!(res.body["code"], "org.role_not_allowed");
    }
}

#[sqlx::test]
async fn a_full_day_photos_checklist_submit(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;

    let res = photo(&db, &s, id, "rails").await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let url = res.body["photos"][0]["photo"]["url"].as_str().unwrap();
    assert!(
        url.contains(&format!("/test-bucket/orgs/{}/proof/", s.org)),
        "a signed link under the company: {url}"
    );
    assert!(url.contains("X-Amz-Signature="));
    assert_eq!(photo(&db, &s, id, "clamp").await.status, StatusCode::OK);
    tick(&db, &s, id, "rails").await;
    let res = tick(&db, &s, id, "torque").await;
    assert_eq!(res.body["checklist"][1]["done"], true);

    let res = submit(&db, &s, id, &Uuid::now_v7().to_string()).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "submitted");
    assert_eq!(res.body["worker_note"], "All fixed.");

    // Locked now: no more photos or ticks.
    let res = photo(&db, &s, id, "rails").await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "task.locked");
    assert_eq!(
        tick(&db, &s, id, "rails").await.status,
        StatusCode::CONFLICT
    );

    let res = call(
        &db,
        "GET",
        &path(&s, &format!("tasks/{id}/history")),
        &s.ravi,
        None,
    )
    .await;
    let kinds: Vec<_> = res.body["events"]
        .as_array()
        .unwrap()
        .iter()
        .map(|e| e["kind"].as_str().unwrap())
        .collect();
    assert_eq!(
        kinds,
        ["submitted", "photos_uploaded", "assigned"],
        "one line per round of photos"
    );
    assert_eq!(res.body["events"][0]["actor"]["you"], true);
    assert_eq!(
        res.body["events"][0]["detail"],
        "2 photos · checklist done · note added"
    );
    assert_eq!(res.body["events"][2]["actor"]["role"], "Admin");
}

#[sqlx::test]
async fn a_photo_that_never_reached_r2_is_refused(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;

    // The app asked for an upload, then lost signal: nothing in R2.
    let lost = upload(&db, s.org, &s.ravi).await;
    let res = add_photo(&db, &s, id, "rails", &lost, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "upload_id");

    // Only part of it arrived.
    let partial = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &partial), 400);
    let res = add_photo(&db, &s, id, "rails", &partial, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);

    let used: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads WHERE used_at IS NOT NULL")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(used, 0, "neither was attached");
    let filled: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM task_photo_slots WHERE task_id = $1 AND upload_id IS NOT NULL",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert_eq!(filled, 0);
}

#[sqlx::test]
async fn an_upload_is_used_once_by_its_owner(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    let up = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &up), 1000);
    assert_eq!(
        add_photo(&db, &s, id, "rails", &up, SITE).await.status,
        StatusCode::OK
    );
    let res = add_photo(&db, &s, id, "clamp", &up, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "already used");

    // Neha's upload can't go on Ravi's task.
    let neha = member(&db, s.org, "neha@example.com", "worker", None).await;
    let hers = upload(&db, s.org, &neha).await;
    r2_put(&key(&s, &hers), 1000);
    let res = add_photo(&db, &s, id, "clamp", &hers, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
}

#[sqlx::test]
async fn another_companys_upload_cant_be_attached(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    // Ravi also works for Solar B, and uploads a photo there.
    let b = org(&db, "Solar B", "active").await;
    common::join(&db, b, "ravi@example.com", "worker", None).await;
    let other = upload(&db, b, &s.ravi).await;
    r2_put(&format!("orgs/{b}/proof/{other}"), 1000);
    let res = add_photo(&db, &s, id, "rails", &other, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "upload_id");
}

#[sqlx::test]
async fn far_or_rough_photos_are_flagged_not_refused(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    let up = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &up), 1000);
    // About 2 km north of the site.
    let res = add_photo(&db, &s, id, "rails", &up, (SITE.0 + 0.018, SITE.1)).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let (far, distance): (bool, f64) = sqlx::query_as(
        "SELECT far, distance_m FROM task_photo_slots WHERE task_id = $1 AND slot_id = 'rails'",
    )
    .bind(id)
    .fetch_one(&db)
    .await
    .unwrap();
    assert!(far);
    assert!((1900.0..2100.0).contains(&distance), "{distance}");

    let res = add_photo(&db, &s, id, "nope", &up, SITE).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["errors"][0]["field"], "slot_id");
}

#[sqlx::test]
async fn submit_needs_every_photo_and_tick(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    photo(&db, &s, id, "rails").await;
    tick(&db, &s, id, "rails").await;
    let res = submit(&db, &s, id, &Uuid::now_v7().to_string()).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "task.incomplete");
    assert_eq!(
        res.body["detail"],
        "1 photo(s) and 1 checklist item(s) to go."
    );
}

#[sqlx::test]
async fn a_retried_submit_answers_the_same(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    photo(&db, &s, id, "rails").await;
    photo(&db, &s, id, "clamp").await;
    tick(&db, &s, id, "rails").await;
    tick(&db, &s, id, "torque").await;
    let key = Uuid::now_v7().to_string();
    let first = submit(&db, &s, id, &key).await;
    let again = submit(&db, &s, id, &key).await;
    assert_eq!(
        again.status,
        StatusCode::OK,
        "not 409: it's the same request"
    );
    assert_eq!(again.body["submitted_at"], first.body["submitted_at"]);
    let submitted: i64 =
        sqlx::query_scalar("SELECT count(*) FROM task_events WHERE kind = 'submitted'")
            .fetch_one(&db)
            .await
            .unwrap();
    assert_eq!(submitted, 1);
}

#[sqlx::test]
async fn a_returned_task_needs_its_retake(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    photo(&db, &s, id, "rails").await;
    photo(&db, &s, id, "clamp").await;
    tick(&db, &s, id, "rails").await;
    tick(&db, &s, id, "torque").await;
    submit(&db, &s, id, &Uuid::now_v7().to_string()).await;

    // The admin sends it back: the clamp photo is blurry.
    sqlx::query(
        "UPDATE tasks SET status = 'returned', status_at = now(), returned_note = 'Blurry clamp.',
                          returned_by = $2, returned_at = now()
         WHERE id = $1",
    )
    .bind(id)
    .bind(s.admin)
    .execute(&db)
    .await
    .unwrap();
    sqlx::query(
        "UPDATE task_photo_slots SET retake = true WHERE task_id = $1 AND slot_id = 'clamp'",
    )
    .bind(id)
    .execute(&db)
    .await
    .unwrap();

    let t = call(&db, "GET", &path(&s, &format!("tasks/{id}")), &s.ravi, None).await;
    assert_eq!(t.body["returned"]["text"], "Blurry clamp.");
    assert_eq!(t.body["photos"][1]["retake"], true);
    let res = submit(&db, &s, id, &Uuid::now_v7().to_string()).await;
    assert_eq!(
        res.body["code"], "task.incomplete",
        "the retake is still to do"
    );

    let res = photo(&db, &s, id, "clamp").await;
    assert_eq!(res.body["photos"][1]["retake"], false);
    let res = submit(&db, &s, id, &Uuid::now_v7().to_string()).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    let h = call(
        &db,
        "GET",
        &path(&s, &format!("tasks/{id}/history")),
        &s.ravi,
        None,
    )
    .await;
    assert_eq!(h.body["events"][0]["kind"], "resubmitted");
    assert_eq!(h.body["events"][0]["detail"], "Clamp close-up retaken");
}

#[sqlx::test]
async fn a_problem_puts_the_task_on_hold(db: PgPool) {
    let s = setup(&db).await;
    let id = task(
        &db,
        &s,
        "ravi@example.com",
        "assigned",
        Utc::now() + Duration::days(2),
    )
    .await;
    let report = |key: String| {
        let db = db.clone();
        let p = path(&s, &format!("tasks/{id}/problems"));
        let token = s.ravi.clone();
        async move {
            call_with(
                &db,
                "POST",
                &p,
                &token,
                Some(json!({"reason": "material_missing", "note": "MC4 connectors short by 6."})),
                &[("idempotency-key", &key)],
            )
            .await
        }
    };
    let res = report(Uuid::now_v7().to_string()).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "assigned");
    assert_eq!(res.body["problem"]["reason"], "material_missing");

    // On hold: in today's list, whatever its date, and not upcoming.
    assert!(ids(&list(&db, &s, "today").await).contains(&id.to_string()));
    assert!(list(&db, &s, "upcoming").await.is_empty());
    assert_eq!(list(&db, &s, "today").await[0]["has_problem"], true);

    let res = call_with(
        &db,
        "POST",
        &path(&s, &format!("tasks/{id}/problems")),
        &s.ravi,
        Some(json!({"reason": "other", "note": "  "})),
        &[("idempotency-key", &Uuid::now_v7().to_string())],
    )
    .await;
    assert_eq!(
        res.status,
        StatusCode::UNPROCESSABLE_ENTITY,
        "a note is required"
    );
}

#[sqlx::test]
async fn replies_go_into_the_history(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "returned", Utc::now()).await;
    let res = call(
        &db,
        "POST",
        &path(&s, &format!("tasks/{id}/messages")),
        &s.ravi,
        Some(json!({"text": "Retaking it in the morning, it's dark now."})),
    )
    .await;
    assert_eq!(res.status, StatusCode::NO_CONTENT);
    let h = call(
        &db,
        "GET",
        &path(&s, &format!("tasks/{id}/history")),
        &s.ravi,
        None,
    )
    .await;
    assert_eq!(h.body["events"][0]["kind"], "message");
    assert_eq!(
        h.body["events"][0]["detail"],
        "Retaking it in the morning, it's dark now."
    );

    let done = task(&db, &s, "ravi@example.com", "approved", Utc::now()).await;
    let res = call(
        &db,
        "POST",
        &path(&s, &format!("tasks/{done}/messages")),
        &s.ravi,
        Some(json!({"text": "Hello"})),
    )
    .await;
    assert_eq!(res.status, StatusCode::CONFLICT);
}

#[sqlx::test]
async fn stats_count_this_months_work(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    photo(&db, &s, id, "rails").await;
    photo(&db, &s, id, "clamp").await;
    tick(&db, &s, id, "rails").await;
    tick(&db, &s, id, "torque").await;
    submit(&db, &s, id, &Uuid::now_v7().to_string()).await;
    // Pretend the first photo was taken 90 minutes before submitting.
    sqlx::query(
        "UPDATE task_photo_slots SET taken_at = (SELECT submitted_at FROM tasks WHERE id = $1)
                                                - interval '90 minutes'
         WHERE task_id = $1 AND slot_id = 'rails'",
    )
    .bind(id)
    .execute(&db)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO task_events (id, org_id, task_id, kind, actor_id) VALUES ($1, $2, $3, 'returned', $4)",
    )
    .bind(Uuid::now_v7())
    .bind(s.org)
    .bind(id)
    .bind(s.admin)
    .execute(&db)
    .await
    .unwrap();

    let res = call(&db, "GET", &path(&s, "me/stats"), &s.ravi, None).await;
    assert_eq!(
        res.body,
        json!({"tasks_this_month": 1, "returned_this_month": 1, "avg_minutes_on_site": 90})
    );
}

#[sqlx::test]
async fn the_home_counts_todays_tasks(db: PgPool) {
    let s = setup(&db).await;
    task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    let res = call(&db, "GET", &path(&s, "home"), &s.ravi, None).await;
    assert_eq!(res.body["tiles"][0]["value"], "1", "{}", res.body);
    let row = &res.body["list"]["rows"][0];
    assert_eq!(row["action"], "task");
    assert_eq!(row["title"], "Ramesh Sahoo");
}

#[sqlx::test]
async fn abandoned_uploads_are_swept(db: PgPool) {
    let s = setup(&db).await;
    let id = task(&db, &s, "ravi@example.com", "assigned", Utc::now()).await;
    let abandoned = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &abandoned), 1000);
    let fresh = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &fresh), 1000);
    let attached = upload(&db, s.org, &s.ravi).await;
    r2_put(&key(&s, &attached), 1000);
    add_photo(&db, &s, id, "rails", &attached, SITE).await;
    sqlx::query("UPDATE uploads SET created_at = now() - interval '25 hours' WHERE id <> $1::uuid")
        .bind(&fresh)
        .execute(&db)
        .await
        .unwrap();

    let state = common::state(&db);
    let swept = backend::routes::uploads::sweep(&state.db, state.storage.as_ref().unwrap())
        .await
        .unwrap();
    state.db.close().await;
    assert_eq!(swept, 1);
    assert!(!r2_has(&key(&s, &abandoned)));
    assert!(r2_has(&key(&s, &fresh)), "under a day old");
    assert!(r2_has(&key(&s, &attached)), "in use");
    let left: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads")
        .fetch_one(&db)
        .await
        .unwrap();
    assert_eq!(left, 2);
}
