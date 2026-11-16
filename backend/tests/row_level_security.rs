//! Row-level security: inside a company's transaction, Postgres itself
//! keeps other companies' rows out, even from a query with no filter.

mod common;

use backend::org::begin_for;
use common::{member, org};
use sqlx::PgPool;
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

async fn count(conn: &mut sqlx::PgConnection, sql: &'static str) -> i64 {
    sqlx::query_scalar(sql).fetch_one(conn).await.unwrap()
}

#[sqlx::test]
async fn a_query_without_the_company_filter_sees_only_this_company(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    member(&db, b, "meena@example.com", "worker", None).await;
    notify(&db, "ravi@example.com", Some(a)).await;
    notify(&db, "ravi@example.com", Some(a)).await;
    notify(&db, "meena@example.com", Some(b)).await;
    notify(&db, "ravi@example.com", None).await;

    // The mistake row-level security catches: no org_id, no user_id.
    let all = "SELECT count(*) FROM notifications";
    let mut tx = begin_for(&db, a).await.unwrap();
    assert_eq!(count(&mut tx, all).await, 2, "only Solar A's");
    drop(tx);
    let mut tx = begin_for(&db, b).await.unwrap();
    assert_eq!(count(&mut tx, all).await, 1, "only Solar B's");
    drop(tx);

    // Outside any company the owner sees everything, as before.
    assert_eq!(count(&mut db.acquire().await.unwrap(), all).await, 4);
}

#[sqlx::test]
async fn writing_into_another_company_is_refused(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    let b = org(&db, "Solar B", "active").await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    let mut tx = begin_for(&db, a).await.unwrap();
    let res = sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body)
         SELECT $1, id, $2, 'task_assigned', 'T', 'B' FROM users WHERE email = 'ravi@example.com'",
    )
    .bind(Uuid::now_v7())
    .bind(b)
    .execute(&mut *tx)
    .await;
    assert!(
        res.is_err(),
        "a row for Solar B can't be written from Solar A"
    );
}

#[sqlx::test]
async fn the_setting_ends_with_the_transaction(db: PgPool) {
    let a = org(&db, "Solar A", "active").await;
    member(&db, a, "ravi@example.com", "worker", None).await;
    notify(&db, "ravi@example.com", Some(a)).await;
    let tx = begin_for(&db, a).await.unwrap();
    tx.commit().await.unwrap();
    let mut conn = db.acquire().await.unwrap();
    // Back to the owner, with no company: nothing is narrowed or leaked.
    let role: String = sqlx::query_scalar("SELECT current_user::text")
        .fetch_one(&mut *conn)
        .await
        .unwrap();
    assert_ne!(role, "solacliq_app");
}
