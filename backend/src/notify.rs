/*
    Notifications: what changed for a person
    --------------------------------------------------------------------
    - one table for all of them; `org_id` empty means the person's own
      (Personal workspace), set means one company's
    - `add` writes one, inside the caller's transaction, so it exists
      only if the change it describes does
    - `page` reads a feed, newest first, with the unread count
*/

use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::PgConnection;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::{
    error::ApiResult,
    page::{Cursor, Page, PageInfo},
};

/*
    The contract's notification kinds, all of them: a row of any kind in
    the table must read back, so the list matches the contract even
    before the features that write each kind are built
*/
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "text", rename_all = "snake_case")]
pub enum Kind {
    TaskAssigned,
    TaskApproved,
    TaskReturned,
    TaskCancelled,
    TaskRescheduled,
    ExpenseApproved,
    ExpenseReturned,
    ExpensePaid,
    KycReturned,
    KycSubmitted,
    KycApproved,
    InstallStarted,
    CommissionChanged,
    CommissionPayable,
    CommissionPaid,
    VisitBooked,
    PaymentDue,
    DocumentsVerified,
    QuoteShared,
    Guide,
}

// The contract's `Notification`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Notification {
    pub id: Uuid,
    pub kind: Kind,
    pub title: String,
    pub body: String,
    pub at: DateTime<Utc>,
    pub read: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub task_id: Option<Uuid>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expense_id: Option<Uuid>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub customer_id: Option<Uuid>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct NotificationPage {
    pub items: Vec<Notification>,
    pub unread_count: i64,
    pub page: PageInfo,
}

// A personal notification for `user_id`, in the caller's transaction.
pub async fn add_personal(
    conn: &mut PgConnection,
    user_id: Uuid,
    kind: Kind,
    title: &str,
    body: &str,
) -> ApiResult<()> {
    sqlx::query(
        "INSERT INTO notifications (id, user_id, kind, title, body)
         VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(kind)
    .bind(title)
    .bind(body)
    .execute(conn)
    .await?;
    Ok(())
}

// What a company notification opens in the app, when anything.
#[derive(Debug, Default, Clone, Copy)]
pub struct Links {
    pub task_id: Option<Uuid>,
    pub expense_id: Option<Uuid>,
    pub customer_id: Option<Uuid>,
}

/*
    A notification for `user_id` in one company, in the caller's
    transaction: it exists only if the change it describes does
*/
pub async fn add(
    conn: &mut PgConnection,
    org_id: Uuid,
    user_id: Uuid,
    kind: Kind,
    title: &str,
    body: &str,
    links: Links,
) -> ApiResult<()> {
    sqlx::query(
        "INSERT INTO notifications (id, user_id, org_id, kind, title, body,
                                    task_id, expense_id, customer_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(org_id)
    .bind(kind)
    .bind(title)
    .bind(body)
    .bind(links.task_id)
    .bind(links.expense_id)
    .bind(links.customer_id)
    .execute(conn)
    .await?;
    Ok(())
}

// Marks every unread one in a feed read (`org_id` None: the person's own).
pub async fn read_all(
    conn: &mut PgConnection,
    user_id: Uuid,
    org_id: Option<Uuid>,
) -> ApiResult<()> {
    sqlx::query(
        "UPDATE notifications SET read_at = now()
         WHERE user_id = $1 AND org_id IS NOT DISTINCT FROM $2 AND read_at IS NULL",
    )
    .bind(user_id)
    .bind(org_id)
    .execute(&mut *conn)
    .await?;
    Ok(())
}

// How many in a feed are unread: the bell's dot.
pub async fn unread(
    conn: &mut PgConnection,
    user_id: Uuid,
    org_id: Option<Uuid>,
) -> ApiResult<i64> {
    Ok(sqlx::query_scalar(
        "SELECT count(*) FROM notifications
         WHERE user_id = $1 AND org_id IS NOT DISTINCT FROM $2 AND read_at IS NULL",
    )
    .bind(user_id)
    .bind(org_id)
    .fetch_one(&mut *conn)
    .await?)
}

#[derive(sqlx::FromRow)]
struct Row {
    id: Uuid,
    kind: Kind,
    title: String,
    body: String,
    created_at: DateTime<Utc>,
    read: bool,
    task_id: Option<Uuid>,
    expense_id: Option<Uuid>,
    customer_id: Option<Uuid>,
}

/*
    One page of a person's feed: their own (`org_id` None) or one
    company's. `IS NOT DISTINCT FROM` treats two empty org ids as equal,
    which `=` doesn't
*/
pub async fn page(
    conn: &mut PgConnection,
    user_id: Uuid,
    org_id: Option<Uuid>,
    page: Page,
) -> ApiResult<NotificationPage> {
    let mut rows: Vec<Row> = sqlx::query_as(
        "SELECT id, kind, title, body, created_at, read_at IS NOT NULL AS read,
                task_id, expense_id, customer_id
         FROM notifications
         WHERE user_id = $1 AND org_id IS NOT DISTINCT FROM $2
           AND ($4::timestamptz IS NULL OR (created_at, id) < ($4, $5))
         ORDER BY created_at DESC, id DESC
         LIMIT $3",
    )
    .bind(user_id)
    .bind(org_id)
    .bind(page.fetch())
    .bind(page.after_time())
    .bind(page.after_id())
    .fetch_all(&mut *conn)
    .await?;

    let unread_count = unread(conn, user_id, org_id).await?;

    let info = page.finish(&mut rows, |r| Cursor {
        created_at: r.created_at,
        id: r.id,
    });
    Ok(NotificationPage {
        items: rows
            .into_iter()
            .map(|r| Notification {
                id: r.id,
                kind: r.kind,
                title: r.title,
                body: r.body,
                at: r.created_at,
                read: r.read,
                task_id: r.task_id,
                expense_id: r.expense_id,
                customer_id: r.customer_id,
            })
            .collect(),
        unread_count,
        page: info,
    })
}
