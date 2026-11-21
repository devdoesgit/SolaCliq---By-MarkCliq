//! Attendance (F17): installers and salaried sales start and end their
//! day; the company's admin reads each day and month. The rules are in
//! docs/features/F17-attendance.md; the time rules' arithmetic is unit
//! tested in src/routes/attendance.rs.

mod common;

use axum::http::StatusCode;
use backend::india;
use chrono::{DateTime, Duration, NaiveDate, NaiveTime, Utc};
use common::{Res, call, call_with, member, org};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn today() -> NaiveDate {
    india::date(Utc::now())
}

// `hh:mm` in India on `date`, in UTC.
fn india_at(date: NaiveDate, h: u32, m: u32) -> DateTime<Utc> {
    india::midnight(date) + (NaiveTime::from_hms_opt(h, m, 0).unwrap() - NaiveTime::MIN)
}

fn time(v: &Value) -> DateTime<Utc> {
    v.as_str().unwrap().parse().unwrap()
}

// `a` and `b` within a few seconds (the request's own time in between).
fn close(a: DateTime<Utc>, b: DateTime<Utc>) -> bool {
    (a - b).num_seconds().abs() <= 5
}

/*
    A tap as the app sends it: `phone_at` and `sent_at` by the phone's
    clock, and an Idempotency-Key
*/
async fn send_tap(
    db: &PgPool,
    org: Uuid,
    token: &str,
    kind: &str,
    phone_at: DateTime<Utc>,
    sent_at: DateTime<Utc>,
    key: &str,
) -> Res {
    call_with(
        db,
        "POST",
        &format!("/api/v1/orgs/{org}/me/attendance/{kind}"),
        token,
        Some(json!({ "phone_at": phone_at, "sent_at": sent_at })),
        &[("idempotency-key", key)],
    )
    .await
}

// Tapped and sent now, on a phone with the right time.
async fn tap(db: &PgPool, org: Uuid, token: &str, kind: &str) -> Res {
    let now = Utc::now();
    send_tap(db, org, token, kind, now, now, &Uuid::now_v7().to_string()).await
}

// Tapped `waited` ago and sent now, on a phone whose clock is `clock` off.
async fn tap_waited(
    db: &PgPool,
    org: Uuid,
    token: &str,
    kind: &str,
    waited: Duration,
    clock: Duration,
) -> Res {
    let sent = Utc::now() + clock;
    send_tap(
        db,
        org,
        token,
        kind,
        sent - waited,
        sent,
        &Uuid::now_v7().to_string(),
    )
    .await
}

async fn home(db: &PgPool, org: Uuid, token: &str) -> Value {
    let res = call(db, "GET", &format!("/api/v1/orgs/{org}/home"), token, None).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body
}

async fn day_view(db: &PgPool, org: Uuid, admin: &str, date: NaiveDate) -> Vec<Value> {
    let res = call(
        db,
        "GET",
        &format!("/api/v1/orgs/{org}/attendance/day?date={date}"),
        admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    res.body["people"].as_array().unwrap().clone()
}

fn names(people: &[Value]) -> Vec<&str> {
    people
        .iter()
        .map(|p| p["person"]["name"].as_str().unwrap())
        .collect()
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

async fn rename(db: &PgPool, email: &str, name: &str) {
    sqlx::query("UPDATE users SET name = $2 WHERE email = $1")
        .bind(email)
        .bind(name)
        .execute(db)
        .await
        .unwrap();
}

async fn sql(db: &PgPool, query: &'static str) {
    sqlx::query(query).execute(db).await.unwrap();
}

async fn day_count(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM attendance_days")
        .fetch_one(db)
        .await
        .unwrap()
}

// A past day written straight in, 09:00 to `end` (h, m) in India.
async fn past_day(db: &PgPool, org: Uuid, email: &str, date: NaiveDate, end: Option<(u32, u32)>) {
    let start = india_at(date, 9, 0);
    let end = end.map(|(h, m)| india_at(date, h, m));
    sqlx::query(
        "INSERT INTO attendance_days (id, org_id, user_id, work_date, started_at, start_phone_at,
                                      start_sent_late, ended_at, end_phone_at, end_sent_late)
         VALUES ($1, $2, $3, $4, $5, $5, false, $6, $6, CASE WHEN $6 IS NULL THEN NULL ELSE false END)",
    )
    .bind(Uuid::now_v7())
    .bind(org)
    .bind(user_id(db, email).await)
    .bind(date)
    .bind(start)
    .bind(end)
    .execute(db)
    .await
    .unwrap();
}

/*
    The everyday flow
*/

#[sqlx::test]
async fn an_installer_starts_and_ends_the_day(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    assert_eq!(
        home(&db, a, &ravi).await["attendance"],
        json!({"state": "not_started"})
    );

    let before = Utc::now();
    let res = tap(&db, a, &ravi, "start").await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(res.body["date"], today().to_string());
    assert_eq!(res.body["status"], "working");
    assert_eq!(res.body["start"]["sent_late"], false);
    assert!(close(time(&res.body["start"]["at"]), before));
    assert!(res.body.get("end").is_none());
    assert!(res.body.get("minutes").is_none());

    let card = home(&db, a, &ravi).await["attendance"].clone();
    assert_eq!(card["state"], "working");
    assert_eq!(card["day"]["start"], res.body["start"]);

    let res = tap(&db, a, &ravi, "end").await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["status"], "ended");
    assert_eq!(res.body["end"]["sent_late"], false);
    assert_eq!(res.body["minutes"], 0);
    let card = home(&db, a, &ravi).await["attendance"].clone();
    assert_eq!(card["state"], "ended");
    assert_eq!(card["day"]["end"], res.body["end"]);
}

#[sqlx::test]
async fn one_start_and_one_end_a_day(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    let res = tap(&db, a, &ravi, "end").await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "attendance.not_started");

    assert_eq!(
        tap(&db, a, &ravi, "start").await.status,
        StatusCode::CREATED
    );
    let res = tap(&db, a, &ravi, "start").await;
    assert_eq!(res.status, StatusCode::CONFLICT);
    assert_eq!(res.body["code"], "attendance.already_started");

    assert_eq!(tap(&db, a, &ravi, "end").await.status, StatusCode::OK);
    for kind in ["end", "start"] {
        let res = tap(&db, a, &ravi, kind).await;
        assert_eq!(res.status, StatusCode::CONFLICT, "{kind}");
    }
    assert_eq!(day_count(&db).await, 1);
}

#[sqlx::test]
async fn a_day_left_open_is_no_check_out_the_next_day(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;
    let yesterday = today() - Duration::days(1);
    past_day(&db, a, "ravi@example.com", yesterday, None).await;

    // Today starts fresh, and ending now doesn't touch yesterday.
    assert_eq!(
        home(&db, a, &ravi).await["attendance"]["state"],
        "not_started"
    );
    let res = tap(&db, a, &ravi, "end").await;
    assert_eq!(res.body["code"], "attendance.not_started");
    assert_eq!(
        day_view(&db, a, &admin, yesterday).await[0]["day"]["status"],
        "no_check_out"
    );

    assert_eq!(
        tap(&db, a, &ravi, "start").await.status,
        StatusCode::CREATED
    );
    assert_eq!(
        day_view(&db, a, &admin, yesterday).await[0]["day"]["status"],
        "no_check_out"
    );
    assert_eq!(
        day_view(&db, a, &admin, today()).await[0]["day"]["status"],
        "working"
    );
}

/*
    Clocks and offline taps
*/

#[sqlx::test]
async fn a_wrong_phone_clock_moves_nothing(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    // Three hours fast, sent at once: now, not late.
    let before = Utc::now();
    let res = tap_waited(&db, a, &ravi, "start", Duration::zero(), Duration::hours(3)).await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    assert_eq!(res.body["start"]["sent_late"], false);
    assert!(close(time(&res.body["start"]["at"]), before));

    // Ten minutes slow, sent at once: the same.
    let before = Utc::now();
    let res = tap_waited(
        &db,
        a,
        &ravi,
        "end",
        Duration::zero(),
        -Duration::minutes(10),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["end"]["sent_late"], false);
    assert!(close(time(&res.body["end"]["at"]), before));
}

#[sqlx::test]
async fn an_offline_tap_counts_from_when_it_was_made(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    // Tapped 30 minutes ago with no signal, on a phone 2 hours slow.
    let res = tap_waited(
        &db,
        a,
        &ravi,
        "start",
        Duration::minutes(30),
        -Duration::hours(2),
    )
    .await;
    assert_eq!(res.status, StatusCode::CREATED, "{}", res.body);
    let at = time(&res.body["start"]["at"]);
    assert!(close(at, Utc::now() - Duration::minutes(30)), "{at}");
    assert_eq!(res.body["start"]["sent_late"], true);
    assert_eq!(res.body["date"], india::date(at).to_string());

    // Waited 4 minutes (a slow network): on time, from when it was made.
    let res = tap_waited(&db, a, &ravi, "end", Duration::minutes(4), Duration::zero()).await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["end"]["sent_late"], false);
    assert!(close(
        time(&res.body["end"]["at"]),
        Utc::now() - Duration::minutes(4)
    ));
    assert_eq!(res.body["minutes"], 26);
}

#[sqlx::test]
async fn yesterdays_end_sent_today_ends_yesterday(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let yesterday = today() - Duration::days(1);
    past_day(&db, a, "ravi@example.com", yesterday, None).await;

    let ended = india_at(yesterday, 18, 40);
    let now = Utc::now();
    let res = send_tap(
        &db,
        a,
        &ravi,
        "end",
        ended,
        now,
        &Uuid::now_v7().to_string(),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["date"], yesterday.to_string());
    assert_eq!(res.body["status"], "ended");
    assert_eq!(res.body["end"]["sent_late"], true);
    assert!(close(time(&res.body["end"]["at"]), ended));
    assert_eq!(res.body["minutes"], 9 * 60 + 40);
    // Today is still free to start.
    assert_eq!(
        home(&db, a, &ravi).await["attendance"]["state"],
        "not_started"
    );
}

#[sqlx::test]
async fn an_end_before_the_start_or_a_week_old_is_refused(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    assert_eq!(
        tap(&db, a, &ravi, "start").await.status,
        StatusCode::CREATED
    );

    // An end tapped two hours ago, before the day started.
    let res = tap_waited(&db, a, &ravi, "end", Duration::hours(2), Duration::zero()).await;
    assert_eq!(res.status, StatusCode::CONFLICT, "{}", res.body);
    assert_eq!(res.body["code"], "attendance.not_started");

    let res = tap_waited(&db, a, &ravi, "end", Duration::days(8), Duration::zero()).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "attendance.too_old");

    // A clock set back between the tap and the send: no wait, now.
    let now = Utc::now();
    let res = send_tap(
        &db,
        a,
        &ravi,
        "end",
        now + Duration::hours(1),
        now,
        &Uuid::now_v7().to_string(),
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["end"]["sent_late"], false);
    assert!(close(time(&res.body["end"]["at"]), now));
}

/*
    Retries and taps at the same moment
*/

#[sqlx::test]
async fn a_retry_gets_the_first_answer(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let key = Uuid::now_v7().to_string();
    let tapped = Utc::now();

    let first = send_tap(&db, a, &ravi, "start", tapped, tapped, &key).await;
    // The retry is sent a minute later, as the app would.
    let again = send_tap(
        &db,
        a,
        &ravi,
        "start",
        tapped,
        tapped + Duration::minutes(1),
        &key,
    )
    .await;
    assert_eq!(first.status, StatusCode::CREATED);
    assert_eq!(again.status, StatusCode::CREATED);
    assert_eq!(first.body, again.body);
    assert_eq!(day_count(&db).await, 1);

    // The key belongs to the start: an end with it is refused.
    let res = send_tap(&db, a, &ravi, "end", tapped, tapped, &key).await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(res.body["code"], "idempotency.key_reused");
}

#[sqlx::test]
async fn a_retry_racing_the_first_request_gets_its_answer(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let now = Utc::now();

    for (kind, status) in [("start", StatusCode::CREATED), ("end", StatusCode::OK)] {
        let key = Uuid::now_v7().to_string();
        let (one, two) = tokio::join!(
            send_tap(&db, a, &ravi, kind, now, now, &key),
            send_tap(&db, a, &ravi, kind, now, now, &key),
        );
        assert_eq!(one.status, status, "{kind}: {}", one.body);
        assert_eq!(two.status, status, "{kind}: {}", two.body);
        assert_eq!(one.body, two.body, "{kind}");
    }
    assert_eq!(day_count(&db).await, 1);
}

#[sqlx::test]
async fn two_taps_at_once_make_one_day(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;

    for (kind, ok, clash) in [
        ("start", StatusCode::CREATED, "attendance.already_started"),
        ("end", StatusCode::OK, "attendance.already_ended"),
    ] {
        let (one, two) = tokio::join!(tap(&db, a, &ravi, kind), tap(&db, a, &ravi, kind));
        let mut statuses = [one.status, two.status];
        statuses.sort();
        assert_eq!(statuses, [ok, StatusCode::CONFLICT], "{kind}");
        let lost = if one.status == StatusCode::CONFLICT {
            one
        } else {
            two
        };
        assert_eq!(lost.body["code"], clash);
    }
    assert_eq!(day_count(&db).await, 1);
}

/*
    Who can mark, and who can't
*/

#[sqlx::test]
async fn only_installers_and_salaried_sales_mark_attendance(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let salaried = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    let commission = member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    let customer = member(&db, a, "sunita@example.com", "customer", None).await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;

    assert_eq!(
        tap(&db, a, &salaried, "start").await.status,
        StatusCode::CREATED
    );
    assert_eq!(
        home(&db, a, &salaried).await["attendance"]["state"],
        "working"
    );

    for kind in ["start", "end"] {
        let res = tap(&db, a, &commission, kind).await;
        assert_eq!(res.status, StatusCode::FORBIDDEN);
        assert_eq!(res.body["code"], "attendance.not_tracked");
        for token in [&customer, &admin] {
            let res = tap(&db, a, token, kind).await;
            assert_eq!(res.status, StatusCode::FORBIDDEN);
            assert_eq!(res.body["code"], "org.role_not_allowed");
        }
    }
    for token in [&commission, &customer, &admin] {
        assert!(home(&db, a, token).await.get("attendance").is_none());
    }

    // The views are the admin's.
    for path in ["day", "month", "month.csv"] {
        for token in [&salaried, &customer] {
            let res = call(
                &db,
                "GET",
                &format!("/api/v1/orgs/{a}/attendance/{path}"),
                token,
                None,
            )
            .await;
            assert_eq!(res.status, StatusCode::FORBIDDEN, "{path}");
            assert_eq!(res.body["code"], "org.role_not_allowed");
        }
    }
    assert_eq!(day_count(&db).await, 1);
}

#[sqlx::test]
async fn a_removed_member_or_suspended_company_cant_tap(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let b = org(&db, "Solar B", "active").await;
    let vikram = member(&db, b, "vikram@example.com", "worker", None).await;
    sql(&db, "UPDATE memberships SET removed_at = now() WHERE user_id = (SELECT id FROM users WHERE email = 'ravi@example.com')").await;
    sqlx::query("UPDATE orgs SET status = 'suspended' WHERE id = $1")
        .bind(b)
        .execute(&db)
        .await
        .unwrap();

    let res = tap(&db, a, &ravi, "start").await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "org.not_member");
    let res = tap(&db, b, &vikram, "start").await;
    assert_eq!(res.status, StatusCode::FORBIDDEN);
    assert_eq!(res.body["code"], "org.suspended");
    assert_eq!(day_count(&db).await, 0);
}

#[sqlx::test]
async fn moving_to_commission_stops_marking_but_keeps_the_days(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;
    let aman = member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    assert_eq!(
        tap(&db, a, &aman, "start").await.status,
        StatusCode::CREATED
    );
    sql(
        &db,
        "UPDATE memberships SET pay_type = 'commission' WHERE role = 'agent'",
    )
    .await;

    let res = tap(&db, a, &aman, "end").await;
    assert_eq!(res.body["code"], "attendance.not_tracked");
    assert!(home(&db, a, &aman).await.get("attendance").is_none());
    // Today's day still shows; tomorrow they're not listed.
    let people = day_view(&db, a, &admin, today()).await;
    assert_eq!(people.len(), 1);
    assert_eq!(people[0]["day"]["status"], "working");
    assert!(
        day_view(&db, a, &admin, today() + Duration::days(1))
            .await
            .is_empty()
    );
}

#[sqlx::test]
async fn each_company_has_its_own_days(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    let admin_a = member(&db, a, "owner@a.example.com", "org_admin", None).await;
    let admin_b = member(&db, b, "owner@b.example.com", "org_admin", None).await;
    // Ravi installs for both; Lata left A and works for B.
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    member(&db, b, "ravi@example.com", "worker", None).await;
    member(&db, a, "lata@example.com", "worker", None).await;
    let lata = member(&db, b, "lata@example.com", "worker", None).await;
    sqlx::query(
        "UPDATE memberships SET removed_at = now()
         WHERE org_id = $1 AND user_id = (SELECT id FROM users WHERE email = 'lata@example.com')",
    )
    .bind(a)
    .execute(&db)
    .await
    .unwrap();
    rename(&db, "ravi@example.com", "Ravi").await;
    rename(&db, "lata@example.com", "Lata").await;

    // A start for A doesn't start B.
    assert_eq!(
        tap(&db, a, &ravi, "start").await.status,
        StatusCode::CREATED
    );
    assert_eq!(
        home(&db, b, &ravi).await["attendance"]["state"],
        "not_started"
    );
    assert_eq!(
        tap(&db, b, &ravi, "start").await.status,
        StatusCode::CREATED
    );
    assert_eq!(tap(&db, a, &ravi, "end").await.status, StatusCode::OK);
    assert_eq!(home(&db, b, &ravi).await["attendance"]["state"], "working");
    assert_eq!(
        tap(&db, b, &lata, "start").await.status,
        StatusCode::CREATED
    );

    let people = day_view(&db, a, &admin_a, today()).await;
    assert_eq!(names(&people), ["Ravi"]);
    assert_eq!(people[0]["day"]["status"], "ended");
    let people = day_view(&db, b, &admin_b, today()).await;
    assert_eq!(names(&people), ["Lata", "Ravi"]);
    assert_eq!(people[1]["day"]["status"], "working");
}

/*
    The admin's views
*/

#[sqlx::test]
async fn the_day_lists_everyone_who_should_mark_by_name(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    member(&db, a, "meena@example.com", "agent", Some("commission")).await;
    member(&db, a, "sunita@example.com", "customer", None).await;
    // Removed: Lata worked today, Gopal didn't. Kiran worked, then became a customer.
    for email in ["lata@example.com", "gopal@example.com", "kiran@example.com"] {
        member(&db, a, email, "worker", None).await;
    }
    past_day(&db, a, "lata@example.com", today(), Some((12, 0))).await;
    past_day(&db, a, "kiran@example.com", today(), Some((11, 0))).await;
    sql(&db, "UPDATE memberships SET removed_at = now() WHERE user_id IN (SELECT id FROM users WHERE email IN ('lata@example.com', 'gopal@example.com'))").await;
    sql(&db, "UPDATE memberships SET role = 'customer' WHERE user_id = (SELECT id FROM users WHERE email = 'kiran@example.com')").await;
    for (email, name) in [
        ("ravi@example.com", "Ravi"),
        ("aman@example.com", "aman"),
        ("lata@example.com", "Lata"),
        ("kiran@example.com", "Kiran"),
    ] {
        rename(&db, email, name).await;
    }
    tap(&db, a, &ravi, "start").await;

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/attendance/day"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["date"], today().to_string());
    let people = res.body["people"].as_array().unwrap();
    assert_eq!(names(people), ["aman", "Kiran", "Lata", "Ravi"]);
    assert!(people[0].get("day").is_none());
    assert_eq!(people[0]["person"]["role"], "agent");
    assert_eq!(people[1]["person"]["role"], "customer");
    assert_eq!(people[1]["day"]["minutes"], 120);
    assert_eq!(people[2]["person"]["removed"], true);
    assert_eq!(people[2]["day"]["status"], "ended");
    assert_eq!(people[3]["day"]["status"], "working");
    assert_eq!(people[3]["person"]["removed"], false);

    // Another date: only today's members who should mark.
    let people = day_view(&db, a, &admin, today() - Duration::days(1)).await;
    assert_eq!(names(&people), ["aman", "Ravi"]);
}

#[sqlx::test]
async fn the_month_and_its_csv(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    member(&db, a, "aman@example.com", "agent", Some("salary")).await;
    rename(&db, "ravi@example.com", "Ravi, K").await;
    rename(&db, "aman@example.com", "Aman").await;
    let date = |d| NaiveDate::from_ymd_opt(2026, 10, d).unwrap();
    past_day(&db, a, "ravi@example.com", date(1), Some((18, 30))).await;
    past_day(&db, a, "ravi@example.com", date(2), None).await;
    past_day(&db, a, "ravi@example.com", date(31), Some((17, 0))).await;
    // Either side of October: left out.
    past_day(
        &db,
        a,
        "ravi@example.com",
        NaiveDate::from_ymd_opt(2026, 9, 30).unwrap(),
        Some((17, 0)),
    )
    .await;
    past_day(
        &db,
        a,
        "ravi@example.com",
        NaiveDate::from_ymd_opt(2026, 11, 1).unwrap(),
        Some((17, 0)),
    )
    .await;

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/attendance/month?month=2026-10"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK, "{}", res.body);
    assert_eq!(res.body["month"], "2026-10");
    let people = res.body["people"].as_array().unwrap();
    assert_eq!(names(people), ["Aman", "Ravi, K"]);
    assert_eq!(people[0]["days"], json!([]));
    assert_eq!(people[0]["days_worked"], 0);
    assert_eq!(people[0]["minutes"], 0);
    let ravi = &people[1];
    assert_eq!(ravi["days_worked"], 3);
    // 9:30 and 8:00; the open day adds nothing.
    assert_eq!(ravi["minutes"], 9 * 60 + 30 + 8 * 60);
    let dates: Vec<_> = ravi["days"]
        .as_array()
        .unwrap()
        .iter()
        .map(|d| d["date"].as_str().unwrap())
        .collect();
    assert_eq!(dates, ["2026-10-01", "2026-10-02", "2026-10-31"]);
    assert_eq!(ravi["days"][1]["status"], "no_check_out");

    let res = call(
        &db,
        "GET",
        &format!("/api/v1/orgs/{a}/attendance/month.csv?month=2026-10"),
        &admin,
        None,
    )
    .await;
    assert_eq!(res.status, StatusCode::OK);
    assert_eq!(res.headers["content-type"], "text/csv; charset=utf-8");
    assert_eq!(
        res.headers["content-disposition"],
        "attachment; filename=\"attendance-2026-10.csv\""
    );
    assert_eq!(
        res.text,
        "name,role,date,start,end,minutes,flags\n\
         \"Ravi, K\",worker,2026-10-01,09:00,18:30,570,\n\
         \"Ravi, K\",worker,2026-10-02,09:00,,,no_check_out\n\
         \"Ravi, K\",worker,2026-10-31,09:00,17:00,480,\n"
    );
}

#[sqlx::test]
async fn bad_requests_are_refused_and_change_nothing(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let ravi = member(&db, a, "ravi@example.com", "worker", None).await;
    let admin = member(&db, a, "owner@example.com", "org_admin", None).await;
    let now = Utc::now();
    let path = format!("/api/v1/orgs/{a}/me/attendance/start");

    // No Idempotency-Key.
    let res = call(
        &db,
        "POST",
        &path,
        &ravi,
        Some(json!({"phone_at": now, "sent_at": now})),
    )
    .await;
    assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY);
    // No `sent_at`, a time that isn't one, no body.
    for body in [
        json!({"phone_at": now}),
        json!({"phone_at": "9 am", "sent_at": now}),
        json!(null),
    ] {
        let key = Uuid::now_v7().to_string();
        let res = call_with(
            &db,
            "POST",
            &path,
            &ravi,
            Some(body.clone()),
            &[("idempotency-key", &key)],
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{body}");
    }
    assert_eq!(day_count(&db).await, 0);

    for query in [
        "day?date=2026-02-30",
        "day?date=today",
        "month?month=2026-13",
        "month.csv?month=2026-1",
    ] {
        let res = call(
            &db,
            "GET",
            &format!("/api/v1/orgs/{a}/attendance/{query}"),
            &admin,
            None,
        )
        .await;
        assert_eq!(res.status, StatusCode::UNPROCESSABLE_ENTITY, "{query}");
    }
}
