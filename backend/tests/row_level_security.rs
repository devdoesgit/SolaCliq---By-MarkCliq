//! Row-level security: Postgres itself keeps each transaction to the rows
//! of its scope (a company, a person, or the platform), even for a query
//! with no filter at all. And the API's login sees nothing without one.

mod common;

use backend::scope;
use common::{app_db, member, org};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

async fn notify(db: &PgPool, email: &str, org_id: Option<Uuid>) {
    sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
         SELECT $1, id, $2, 'task_assigned', 'T', 'B' FROM users WHERE email = $3",
    )
    .bind(Uuid::now_v7())
    .bind(org_id)
    .bind(email)
    .execute(db)
    .await
    .unwrap();
}

async fn user_id(db: &PgPool, email: &str) -> Uuid {
    sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_one(db)
        .await
        .unwrap()
}

async fn count(conn: &mut PgConnection, table: &str) -> i64 {
    // The mistake row-level security catches: no org_id, no user_id.
    let sql = match table {
        "orgs" => "SELECT count(*) FROM orgs",
        "memberships" => "SELECT count(*) FROM memberships",
        "notifications" => "SELECT count(*) FROM notifications",
        _ => unreachable!(),
    };
    sqlx::query_scalar(sql).fetch_one(conn).await.unwrap()
}

/*
    Two companies: Ravi works for A, Meena for B. Each has two company
    notifications' worth of rows between them, and Ravi one personal one
*/
async fn two_companies(db: &PgPool) -> (Uuid, Uuid) {
    let a = org(db, "Solar A", "active").await;
    let b = org(db, "Solar B", "active").await;
    member(db, a, "ravi@example.com", "worker", None).await;
    member(db, b, "meena@example.com", "worker", None).await;
    notify(db, "ravi@example.com", Some(a)).await;
    notify(db, "ravi@example.com", Some(a)).await;
    notify(db, "meena@example.com", Some(b)).await;
    notify(db, "ravi@example.com", None).await;
    (a, b)
}

#[sqlx::test]
async fn a_company_sees_only_its_own_rows(db: PgPool) {
    let (a, b) = two_companies(&db).await;
    let app = app_db(&db);

    let mut tx = scope::company(&app, a).await.unwrap();
    assert_eq!(count(&mut tx, "orgs").await, 1, "only Solar A");
    assert_eq!(count(&mut tx, "memberships").await, 1, "only Ravi");
    assert_eq!(
        count(&mut tx, "notifications").await,
        2,
        "only A's, no personal"
    );
    drop(tx);

    let mut tx = scope::company(&app, b).await.unwrap();
    assert_eq!(count(&mut tx, "notifications").await, 1, "only Solar B's");
}

#[sqlx::test]
async fn a_person_sees_only_their_own_rows(db: PgPool) {
    two_companies(&db).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let app = app_db(&db);

    let mut tx = scope::person(&app, ravi).await.unwrap();
    assert_eq!(count(&mut tx, "orgs").await, 1, "the company Ravi is in");
    assert_eq!(count(&mut tx, "memberships").await, 1, "Ravi's own");
    assert_eq!(
        count(&mut tx, "notifications").await,
        1,
        "his personal one only"
    );
}

#[sqlx::test]
async fn a_removed_member_no_longer_sees_the_company(db: PgPool) {
    let (a, _) = two_companies(&db).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    sqlx::query("UPDATE memberships SET removed_at = now() WHERE org_id = $1")
        .bind(a)
        .execute(&db)
        .await
        .unwrap();

    let mut tx = scope::person(&app_db(&db), ravi).await.unwrap();
    assert_eq!(count(&mut tx, "orgs").await, 0);
}

#[sqlx::test]
async fn the_platform_sees_every_company(db: PgPool) {
    two_companies(&db).await;
    let mut tx = scope::platform(&app_db(&db)).await.unwrap();
    assert_eq!(count(&mut tx, "orgs").await, 2);
    assert_eq!(count(&mut tx, "memberships").await, 2);
    assert_eq!(count(&mut tx, "notifications").await, 0, "not the feeds");
}

#[sqlx::test]
async fn without_a_scope_the_api_login_sees_nothing(db: PgPool) {
    two_companies(&db).await;
    let mut conn = app_db(&db).acquire().await.unwrap();
    for table in ["orgs", "memberships", "notifications"] {
        assert_eq!(count(&mut conn, table).await, 0, "{table}");
    }
    // The owner, for comparison, sees all of it.
    let mut owner = db.acquire().await.unwrap();
    assert_eq!(count(&mut owner, "notifications").await, 4);
}

#[sqlx::test]
async fn the_scope_ends_with_the_transaction(db: PgPool) {
    let (a, _) = two_companies(&db).await;
    // One connection, so the next query reuses the one the scope was on.
    let app = sqlx::postgres::PgPoolOptions::new()
        .max_connections(1)
        .connect_with((*app_db(&db).connect_options()).clone())
        .await
        .unwrap();
    let tx = scope::company(&app, a).await.unwrap();
    tx.commit().await.unwrap();
    let mut conn = app.acquire().await.unwrap();
    assert_eq!(count(&mut conn, "notifications").await, 0);
}

#[sqlx::test]
async fn writing_into_another_company_is_refused(db: PgPool) {
    let (a, b) = two_companies(&db).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let mut tx = scope::company(&app_db(&db), a).await.unwrap();
    let res = sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
         VALUES ($1, $2, $3, 'task_assigned', 'T', 'B')",
    )
    .bind(Uuid::now_v7())
    .bind(ravi)
    .bind(b)
    .execute(&mut *tx)
    .await;
    assert!(
        res.is_err(),
        "a row for Solar B can't be written from Solar A"
    );
}

#[sqlx::test]
async fn a_person_cant_write_someone_elses_feed(db: PgPool) {
    two_companies(&db).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let meena = user_id(&db, "meena@example.com").await;
    let mut tx = scope::person(&app_db(&db), ravi).await.unwrap();
    let res = sqlx::query(
        "INSERT INTO notifications (id, user_id, kind, title, body)
         VALUES ($1, $2, 'quote_shared', 'T', 'B')",
    )
    .bind(Uuid::now_v7())
    .bind(meena)
    .execute(&mut *tx)
    .await;
    assert!(res.is_err());
}

#[sqlx::test]
async fn a_person_cant_change_memberships(db: PgPool) {
    let (a, _) = two_companies(&db).await;
    let ravi = user_id(&db, "ravi@example.com").await;
    let mut tx = scope::person(&app_db(&db), ravi).await.unwrap();
    // Promoting himself: his own row is readable, not writable.
    let changed = sqlx::query("UPDATE memberships SET role = 'org_admin' WHERE org_id = $1")
        .bind(a)
        .execute(&mut *tx)
        .await
        .unwrap()
        .rows_affected();
    assert_eq!(changed, 0);
}

#[sqlx::test]
async fn the_server_refuses_a_login_that_bypasses_the_policies(db: PgPool) {
    let app = app_db(&db);
    assert_eq!(scope::check_restricted(&app).await.unwrap(), "solacliq_api");
    // The owner (a superuser locally) would see every company's rows.
    assert!(scope::check_restricted(&db).await.is_err());
}

#[sqlx::test]
async fn a_gstin_is_checked_across_every_company(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let gstin: String = sqlx::query_scalar("SELECT gstin FROM orgs WHERE id = $1")
        .bind(a)
        .fetch_one(&db)
        .await
        .unwrap();
    // A brand new company's scope can't see Solar A, but the check can.
    let mut tx = scope::company(&app_db(&db), Uuid::now_v7()).await.unwrap();
    assert_eq!(count(&mut tx, "orgs").await, 0);
    let taken: bool = sqlx::query_scalar("SELECT gstin_registered($1)")
        .bind(gstin)
        .fetch_one(&mut *tx)
        .await
        .unwrap();
    assert!(taken);
}
