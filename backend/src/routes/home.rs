/*
    The home screen, composed per role (phase 7)
    --------------------------------------------------------------------
    - GET /orgs/{org_id}/home: the parts the app draws (headline, week,
      tiles, progress, a list), so a role's home changes without an app
      update. Shapes and actions: docs/backend-handoff.md, "Home"
    - built from what exists: a worker's tasks and expenses (phase 8),
      an agent's customers and commissions (phase 9), a customer's
      install (phase 10). Live energy after handover needs inverter data; until each lands its numbers are honest zeros and the
      list says what's coming, never sample data
    - dates and greetings are in Indian time: an installer's "today" is
      today in India, whatever the server's clock says
    - always `unread_notifications`, for the bell's dot
*/

use axum::{Json, extract::State};
use chrono::{DateTime, Datelike, Duration, FixedOffset, Timelike, Utc, Weekday};
use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use sqlx::PgConnection;
use uuid::Uuid;

use crate::{
    AppState,
    error::ApiResult,
    notify,
    org::{OrgMember, PayType, Role},
    routes::{
        customers::{CommissionStatus, KycKind, KycStatus, STAGES},
        install::{self, Install, PaymentStatus, StageStatus},
        quotes::rupees,
        tasks::TaskStatus,
    },
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new().routes(routes!(home))
}

// The contract's `HomeSummary`.
#[derive(Debug, Serialize, ToSchema)]
pub struct HomeSummary {
    pub unread_notifications: i64,
    pub eyebrow: String,
    pub title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[schema(inline)]
    pub headline: Option<HomeHeadline>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub week: Vec<HomeDay>,
    // A customer's live output after handover, instead of the headline.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub energy: Option<HomeEnergy>,
    pub tiles: Vec<HomeTile>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub progress: Option<HomeProgress>,
    #[schema(inline)]
    pub list: HomeList,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeHeadline {
    pub value: String,
    pub label: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeList {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    pub rows: Vec<HomeRow>,
}

/*
    Live output after handover: now, today, the sun's day and an hourly
    curve. Comes with installs and their meters (phase 10); never sent
    before then
*/
#[derive(Debug, Serialize, ToSchema)]
pub struct HomeEnergy {
    pub now_kw: f64,
    pub today_kwh: f64,
    pub sunrise: String,
    pub sunset: String,
    pub day_progress: f64,
    pub hours: Vec<f64>,
    pub now_index: u32,
}

// One day of a worker's week; `dots` are its tasks' states.
#[derive(Debug, Serialize, ToSchema)]
pub struct HomeDay {
    pub day: String,
    pub date: u32,
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    pub today: bool,
    pub dots: Vec<String>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeTile {
    pub label: String,
    pub value: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<TileIcon>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub footer: Option<String>,
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    pub dark: bool,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub avatars: Vec<HomeVisual>,
    // What tapping it opens; one the app knows, or none.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub action: Option<&'static str>,
}

#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum TileIcon {
    Camera,
    Receipt,
    Alarm,
    Hourglass,
    Shield,
    Wallet,
    Sun,
    Users,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeProgress {
    pub label: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub trailing: Option<String>,
    pub segments: Vec<HomeSegment>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub stages: Vec<String>,
    #[serde(skip_serializing_if = "std::ops::Not::not")]
    pub legend: bool,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeSegment {
    pub weight: u32,
    pub tone: HomeTone,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum HomeTone {
    Success,
    Warning,
    Danger,
    Neutral,
    Live,
    Empty,
}

// A picture: an image URL, initials or a drawn glyph.
#[derive(Debug, Default, Serialize, ToSchema)]
pub struct HomeVisual {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub image: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub initials: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub glyph: Option<Glyph>,
}

#[derive(Debug, Clone, Copy, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum Glyph {
    Card,
    Bill,
    Passbook,
    Rupee,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeRow {
    #[serde(flatten)]
    pub visual: HomeVisual,
    pub id: String,
    pub title: String,
    pub detail: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<HomeStatus>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub action: Option<&'static str>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct HomeStatus {
    pub label: String,
    pub tone: HomeTone,
}

/*
    The home for the caller's role here
    --------------------------------------------------------------------
    Any member of an active company. An org admin gets a plain one: the
    app sends admins to the website and never draws it
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/home",
    operation_id = "getOrgHome",
    tag = "home",
    params(("org_id" = uuid::Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The home's parts.", body = HomeSummary),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn home(State(state): State<AppState>, member: OrgMember) -> ApiResult<Json<HomeSummary>> {
    let mut tx = member.begin(&state.db).await?;
    let (name, org_name): (String, String) =
        sqlx::query_as("SELECT u.name, o.name FROM users u, orgs o WHERE u.id = $1 AND o.id = $2")
            .bind(member.user_id)
            .bind(member.org_id)
            .fetch_one(&mut *tx)
            .await?;
    let unread = notify::unread(&mut tx, member.user_id, Some(member.org_id)).await?;
    let now = india_now(Utc::now());
    let tasks = match member.role {
        Role::Worker => week_tasks(&mut tx, member.user_id, &now).await?,
        _ => Vec::new(),
    };
    // The worker's expenses still with the admin.
    let in_review: i64 = match member.role {
        Role::Worker => {
            sqlx::query_scalar(
                "SELECT count(*) FROM expenses WHERE owner_id = $1 AND status = 'in_review'",
            )
            .bind(member.user_id)
            .fetch_one(&mut *tx)
            .await?
        }
        _ => 0,
    };
    let customers = match member.role {
        Role::Agent => agent_customers(&mut tx, member.user_id).await?,
        _ => Vec::new(),
    };
    let (my_install, my_documents) = match member.role {
        Role::Customer => (
            install::load(&mut tx, member.user_id).await?,
            document_counts(&mut tx, member.user_id).await?,
        ),
        _ => (None, (0, 0)),
    };
    tx.commit().await?;

    let who = Who {
        first_name: name.split_whitespace().next().unwrap_or(&name).to_owned(),
        org_name,
        now,
    };
    let mut summary = match (member.role, member.pay_type) {
        (Role::Worker, _) => worker(&who, &tasks, in_review),
        (Role::Agent, Some(PayType::Commission)) => agent(&who, true, &customers),
        (Role::Agent, _) => agent(&who, false, &customers),
        (Role::Customer, _) => customer(&who, my_install.as_ref(), my_documents),
        (Role::OrgAdmin, _) => admin(&who),
    };
    summary.unread_notifications = unread;
    Ok(Json(summary))
}

// What every home is built from.
struct Who {
    first_name: String,
    org_name: String,
    // Now, in Indian time.
    now: DateTime<FixedOffset>,
}

// India is UTC+5:30 all year (no daylight saving).
fn india_now(utc: DateTime<Utc>) -> DateTime<FixedOffset> {
    let ist = FixedOffset::east_opt(5 * 3600 + 30 * 60).expect("a valid offset");
    utc.with_timezone(&ist)
}

fn greeting(now: &DateTime<FixedOffset>) -> &'static str {
    match now.hour() {
        0..12 => "Good morning",
        12..17 => "Good afternoon",
        _ => "Good evening",
    }
}

fn short_day(day: Weekday) -> &'static str {
    match day {
        Weekday::Mon => "Mon",
        Weekday::Tue => "Tue",
        Weekday::Wed => "Wed",
        Weekday::Thu => "Thu",
        Weekday::Fri => "Fri",
        Weekday::Sat => "Sat",
        Weekday::Sun => "Sun",
    }
}

// One of the worker's tasks this week, or still open from before.
#[derive(Debug, sqlx::FromRow)]
struct WeekTask {
    id: Uuid,
    title: String,
    customer_name: String,
    status: TaskStatus,
    due_at: DateTime<Utc>,
    on_hold: bool,
}

impl WeekTask {
    // Still the worker's to do (not with the admin, not final).
    fn open(&self) -> bool {
        matches!(self.status, TaskStatus::Assigned | TaskStatus::Returned)
    }
}

fn monday(now: &DateTime<FixedOffset>) -> chrono::NaiveDate {
    let today = now.date_naive();
    today - Duration::days(i64::from(today.weekday().num_days_from_monday()))
}

/*
    The worker's tasks from Monday to Sunday (Indian time), plus open ones
    from before: they're still to do. Cancelled ones are left out
*/
async fn week_tasks(
    conn: &mut PgConnection,
    user_id: Uuid,
    now: &DateTime<FixedOffset>,
) -> ApiResult<Vec<WeekTask>> {
    let start = monday(now)
        .and_time(chrono::NaiveTime::MIN)
        .and_local_timezone(*now.offset())
        .single()
        .expect("India has no clock changes");
    let end = start + Duration::days(7);
    Ok(sqlx::query_as(
        "SELECT t.id, t.title, c.name AS customer_name, t.status, t.due_at,
                t.problem_at IS NOT NULL AS on_hold
         FROM tasks t JOIN customers c ON c.id = t.customer_id
         WHERE t.assignee_id = $1 AND t.status <> 'cancelled' AND t.due_at < $3
           AND (t.due_at >= $2 OR t.status IN ('assigned', 'returned'))
         ORDER BY t.due_at, t.id",
    )
    .bind(user_id)
    .bind(start.with_timezone(&Utc))
    .bind(end.with_timezone(&Utc))
    .fetch_all(conn)
    .await?)
}

/*
    This week, Monday to Sunday, one dot per task: `done` once submitted
    or approved, `live` for today's (and overdue) open work, `planned`
    for later in the week
*/
fn week(now: &DateTime<FixedOffset>, tasks: &[WeekTask]) -> Vec<HomeDay> {
    let today = now.date_naive();
    let monday = monday(now);
    (0..7)
        .map(|i| {
            let date = monday + Duration::days(i);
            let dots = tasks
                .iter()
                .filter(|t| t.due_at.with_timezone(now.offset()).date_naive() == date)
                .map(|t| {
                    if !t.open() {
                        "done"
                    } else if date <= today {
                        "live"
                    } else {
                        "planned"
                    }
                    .to_owned()
                })
                .collect();
            HomeDay {
                day: short_day(date.weekday()).to_owned(),
                date: date.day(),
                today: date == today,
                dots,
            }
        })
        .collect()
}

fn tile(
    label: &str,
    value: &str,
    icon: TileIcon,
    footer: &str,
    dark: bool,
    action: &'static str,
) -> HomeTile {
    HomeTile {
        label: label.to_owned(),
        value: value.to_owned(),
        icon: Some(icon),
        footer: Some(footer.to_owned()),
        dark,
        avatars: Vec::new(),
        action: Some(action),
    }
}

// A row that only explains: no picture to tap, no action.
fn note(id: &str, title: &str, detail: &str) -> HomeRow {
    HomeRow {
        visual: HomeVisual::default(),
        id: id.to_owned(),
        title: title.to_owned(),
        detail: detail.to_owned(),
        status: None,
        action: None,
    }
}

fn headline(value: &str, label: &str, detail: &str) -> Option<HomeHeadline> {
    Some(HomeHeadline {
        value: value.to_owned(),
        label: label.to_owned(),
        detail: Some(detail.to_owned()),
    })
}

/*
    An EPC installer's day: the date, the week with each day's tasks,
    today's count, what's left to submit and expenses with the admin,
    then today's tasks in due order
*/
fn worker(who: &Who, tasks: &[WeekTask], expenses_in_review: i64) -> HomeSummary {
    let today = who.now.date_naive();
    let by_tonight: Vec<&WeekTask> = tasks
        .iter()
        .filter(|t| t.due_at.with_timezone(who.now.offset()).date_naive() <= today)
        .collect();
    let due_today = by_tonight
        .iter()
        .filter(|t| t.due_at.with_timezone(who.now.offset()).date_naive() == today)
        .count();
    let to_submit = by_tonight.iter().filter(|t| t.open()).count();

    let rows: Vec<HomeRow> = by_tonight
        .iter()
        .filter(|t| t.open() || t.status == TaskStatus::Submitted)
        .take(5)
        .map(|t| task_row(who, t))
        .collect();
    let rows = if rows.is_empty() {
        vec![note(
            "no_tasks",
            "Nothing to do today",
            &format!("{} assigns your tasks; they show up here", who.org_name),
        )]
    } else {
        rows
    };

    HomeSummary {
        unread_notifications: 0,
        eyebrow: who.now.format("%A, %-d %b").to_string(),
        title: format!("{}'s day", who.first_name),
        headline: headline(&due_today.to_string(), "tasks", "on site today"),
        week: week(&who.now, tasks),
        energy: None,
        tiles: vec![
            tile(
                "To submit",
                &to_submit.to_string(),
                TileIcon::Camera,
                "today",
                true,
                "to_submit",
            ),
            tile(
                "Expenses",
                &expenses_in_review.to_string(),
                TileIcon::Receipt,
                "with admin",
                false,
                "expenses",
            ),
        ],
        progress: None,
        list: HomeList {
            title: Some("Up next".into()),
            rows,
        },
    }
}

// A task in "Up next": the customer, the work and its time, and its state.
fn task_row(who: &Who, t: &WeekTask) -> HomeRow {
    let due = t.due_at.with_timezone(who.now.offset());
    let (label, tone, when) = match t.status {
        TaskStatus::Returned => ("Retake", HomeTone::Danger, due.format("%H:%M").to_string()),
        TaskStatus::Submitted => ("In review", HomeTone::Neutral, "awaiting admin".into()),
        _ if t.on_hold => ("On hold", HomeTone::Warning, "problem reported".into()),
        _ if due.date_naive() < who.now.date_naive() => (
            "Overdue",
            HomeTone::Danger,
            due.format("%a %-d %b").to_string(),
        ),
        _ => ("Assigned", HomeTone::Live, due.format("%H:%M").to_string()),
    };
    HomeRow {
        visual: HomeVisual::default(),
        id: t.id.to_string(),
        title: t.customer_name.clone(),
        detail: format!("{} · {when}", t.title),
        status: Some(HomeStatus {
            label: label.into(),
            tone,
        }),
        action: Some("task"),
    }
}

// One customer an agent registered, as their home shows it.
#[derive(Debug, sqlx::FromRow)]
struct AgentCustomer {
    id: Uuid,
    name: String,
    kyc_status: KycStatus,
    created_at: DateTime<Utc>,
    stage_index: Option<i32>,
    commission: Option<i64>,
    commission_status: Option<CommissionStatus>,
    // The document sent back, while one is.
    fix_kind: Option<KycKind>,
}

// The agent's customers, newest first.
async fn agent_customers(conn: &mut PgConnection, user_id: Uuid) -> ApiResult<Vec<AgentCustomer>> {
    Ok(sqlx::query_as(
        "SELECT c.id, c.name, c.kyc_status, c.created_at, c.stage_index,
                c.commission, c.commission_status,
                (SELECT d.kind FROM documents d
                 WHERE d.customer_id = c.id AND d.status = 'needs_fix' LIMIT 1) AS fix_kind
         FROM customers c WHERE c.registered_by = $1
         ORDER BY c.created_at DESC, c.id DESC",
    )
    .bind(user_id)
    .fetch_all(conn)
    .await?)
}

// "Ramesh Sahoo" → "RS".
fn initials(name: &str) -> String {
    name.split_whitespace()
        .filter_map(|w| w.chars().next())
        .take(2)
        .collect::<String>()
        .to_uppercase()
}

// A recent customer: who, where it stands, and a pill.
fn customer_row(who: &Who, c: &AgentCustomer) -> HomeRow {
    let (detail, label, tone) = match c.kyc_status {
        KycStatus::InReview => {
            let sent = c.created_at.with_timezone(who.now.offset()).date_naive();
            let when = if sent == who.now.date_naive() {
                "Sent today".to_owned()
            } else {
                format!("Sent {}", sent.format("%-d %b"))
            };
            (when, "In review", HomeTone::Neutral)
        }
        KycStatus::NeedsFix => (
            c.fix_kind.map_or_else(
                || "A document to fix".into(),
                |k| format!("{} to fix", k.label()),
            ),
            "Fix KYC",
            HomeTone::Danger,
        ),
        KycStatus::Approved => (
            c.stage_index
                .and_then(|i| {
                    Some(format!(
                        "Stage {i} · {}",
                        STAGES.get(usize::try_from(i).ok()?.checked_sub(1)?)?
                    ))
                })
                .unwrap_or_else(|| "Approved".into()),
            "Approved",
            HomeTone::Success,
        ),
        KycStatus::Rejected => (
            "The company won't go ahead".into(),
            "Not taken up",
            HomeTone::Neutral,
        ),
    };
    HomeRow {
        visual: HomeVisual {
            initials: Some(initials(&c.name)),
            ..HomeVisual::default()
        },
        id: c.id.to_string(),
        title: c.name.clone(),
        detail,
        status: Some(HomeStatus {
            label: label.into(),
            tone,
        }),
        action: Some("customer"),
    }
}

/*
    A sales agent's customers: added this month, KYC to fix, then
    earnings (commission: payable) or what's with the admin (salary),
    KYC this month as a bar, and the latest customers
*/
fn agent(who: &Who, commission: bool, customers: &[AgentCustomer]) -> HomeSummary {
    let month = |c: &&AgentCustomer| {
        let d = c.created_at.with_timezone(who.now.offset()).date_naive();
        (d.year(), d.month()) == (who.now.year(), who.now.month())
    };
    let this_month: Vec<&AgentCustomer> = customers.iter().filter(month).collect();
    let count =
        |list: &[&AgentCustomer], s: KycStatus| list.iter().filter(|c| c.kyc_status == s).count();
    let all: Vec<&AgentCustomer> = customers.iter().collect();
    let to_fix = count(&all, KycStatus::NeedsFix);

    let second = if commission {
        let payable: i64 = customers
            .iter()
            .filter(|c| c.commission_status == Some(CommissionStatus::Payable))
            .filter_map(|c| c.commission)
            .sum();
        tile(
            "Earnings",
            &rupees(payable),
            TileIcon::Wallet,
            "payable",
            false,
            "earnings",
        )
    } else {
        tile(
            "In review",
            &count(&all, KycStatus::InReview).to_string(),
            TileIcon::Hourglass,
            "with admin",
            false,
            "review",
        )
    };

    // KYC this month: approved, in review, to fix (empty parts left out).
    let segments: Vec<HomeSegment> = [
        (KycStatus::Approved, HomeTone::Success, "approved"),
        (KycStatus::InReview, HomeTone::Neutral, "review"),
        (KycStatus::NeedsFix, HomeTone::Danger, "fix"),
    ]
    .into_iter()
    .filter_map(|(s, tone, word)| {
        let n = count(&this_month, s);
        (n > 0).then(|| HomeSegment {
            weight: n as u32,
            tone,
            label: Some(format!("{n} {word}")),
        })
    })
    .collect();
    // Customers not taken up have no KYC to follow: not in the bar or its total.
    let in_bar: u32 = segments.iter().map(|s| s.weight).sum();
    let progress = (!segments.is_empty()).then(|| HomeProgress {
        label: "KYC this month".into(),
        trailing: Some(format!("{in_bar} total")),
        segments,
        stages: Vec::new(),
        legend: true,
    });

    let rows = if customers.is_empty() {
        vec![note(
            "no_customers",
            "No customers yet",
            "Customers you register show up here",
        )]
    } else {
        customers
            .iter()
            .take(3)
            .map(|c| customer_row(who, c))
            .collect()
    };

    HomeSummary {
        unread_notifications: 0,
        eyebrow: greeting(&who.now).into(),
        title: format!("{}'s customers", who.first_name),
        headline: headline(
            &this_month.len().to_string(),
            "customers",
            "added this month",
        ),
        week: Vec::new(),
        energy: None,
        tiles: vec![
            tile(
                "Needs fix",
                &to_fix.to_string(),
                TileIcon::Alarm,
                "KYC",
                true,
                "fix",
            ),
            second,
        ],
        progress,
        list: HomeList {
            title: Some("Recent customers".into()),
            rows,
        },
    }
}

// A customer's KYC documents in this company: (all, verified).
async fn document_counts(conn: &mut PgConnection, user_id: Uuid) -> ApiResult<(i64, i64)> {
    Ok(sqlx::query_as(
        "SELECT count(*), count(*) FILTER (WHERE d.status = 'verified')
         FROM documents d JOIN customers c ON c.id = d.customer_id
         WHERE c.user_id = $1",
    )
    .bind(user_id)
    .fetch_one(conn)
    .await?)
}

/*
    A customer's install: where it is (stage x of 7), the next visit and
    the payment due, the install bar, then their documents and the next
    visit. Until the company sets the install up, the home says so
*/
fn customer(who: &Who, install: Option<&Install>, documents: (i64, i64)) -> HomeSummary {
    let Some(i) = install else {
        return customer_waiting(who);
    };
    let current = &i.stages[(i.stage_index - 1).max(0) as usize];
    let handed_over = i.handed_over_on.is_some();
    let headline_detail = match i.handed_over_on {
        Some(d) => format!("Handed over on {}", d.format("%-d %b")),
        None => format!("{} is next", current.name),
    };

    let visit_tile = match &i.next_visit {
        Some(v) => {
            let at = v.starts_at.with_timezone(who.now.offset());
            tile(
                "Next visit",
                short_day(at.weekday()),
                TileIcon::Alarm,
                &v.title.to_lowercase(),
                true,
                "track",
            )
        }
        None => tile(
            "Next visit",
            "—",
            TileIcon::Alarm,
            if handed_over {
                "all done"
            } else {
                "not booked yet"
            },
            true,
            "track",
        ),
    };
    let payment_tile = match i
        .payments
        .iter()
        .find(|p| matches!(p.status, PaymentStatus::Due | PaymentStatus::Claimed))
    {
        Some(p) => {
            // "Advance, 30%" → "Advance".
            let name = p.label.split(',').next().unwrap_or(&p.label);
            let footer = match (p.status, p.due_on) {
                (PaymentStatus::Claimed, _) => "sent, company confirms".to_owned(),
                (_, Some(d)) => format!("due {}", d.format("%-d %b")),
                _ => "due now".to_owned(),
            };
            tile(
                name,
                &rupees(p.amount),
                TileIcon::Wallet,
                &footer,
                false,
                "payments",
            )
        }
        None => tile(
            "Payments",
            "—",
            TileIcon::Wallet,
            "nothing due",
            false,
            "payments",
        ),
    };

    let segments = i
        .stages
        .iter()
        .map(|s| HomeSegment {
            weight: 1,
            tone: match s.status {
                StageStatus::Done => HomeTone::Success,
                StageStatus::Next => HomeTone::Live,
                StageStatus::Upcoming => HomeTone::Empty,
            },
            label: None,
        })
        .collect();

    let (all, verified) = documents;
    let mut rows = Vec::new();
    if all > 0 {
        let (label, tone) = if verified == all {
            ("Verified", HomeTone::Success)
        } else {
            ("In review", HomeTone::Neutral)
        };
        rows.push(HomeRow {
            visual: HomeVisual {
                glyph: Some(Glyph::Card),
                ..HomeVisual::default()
            },
            id: "documents".into(),
            title: "Documents".into(),
            detail: format!("{all} documents with {}", who.org_name),
            status: Some(HomeStatus {
                label: label.into(),
                tone,
            }),
            action: Some("documents"),
        });
    }
    if let Some(v) = &i.next_visit {
        let at = v.starts_at.with_timezone(who.now.offset());
        let first = v
            .person
            .name
            .split_whitespace()
            .next()
            .unwrap_or(&v.person.name);
        rows.push(HomeRow {
            visual: HomeVisual::default(),
            id: "next_visit".into(),
            title: v.title.clone(),
            detail: format!("{} · {first}", at.format("%a %-d %b, %H:%M")),
            status: Some(HomeStatus {
                label: "Next".into(),
                tone: HomeTone::Warning,
            }),
            action: Some("track"),
        });
    }

    HomeSummary {
        unread_notifications: 0,
        eyebrow: "Your solar".into(),
        title: format!("{} kW · {}", trim_kw(i.system_kw), i.place),
        headline: headline(&i.stage_index.to_string(), "of 7 stages", &headline_detail),
        week: Vec::new(),
        energy: None,
        tiles: vec![visit_tile, payment_tile],
        progress: Some(HomeProgress {
            label: "Install progress".into(),
            trailing: Some(who.org_name.clone()),
            segments,
            stages: vec!["Survey".into(), "Install".into(), "Handover".into()],
            legend: false,
        }),
        list: HomeList { title: None, rows },
    }
}

// 5 → "5", 3.5 → "3.5".
fn trim_kw(kw: f64) -> String {
    let s = format!("{kw:.2}");
    s.trim_end_matches('0').trim_end_matches('.').to_owned()
}

// Before the company has set the install up.
fn customer_waiting(who: &Who) -> HomeSummary {
    let empty = |_| HomeSegment {
        weight: 1,
        tone: HomeTone::Empty,
        label: None,
    };
    HomeSummary {
        unread_notifications: 0,
        eyebrow: "Your solar".into(),
        title: who.org_name.clone(),
        headline: headline("0", "of 7 stages", "Your install is being set up"),
        week: Vec::new(),
        energy: None,
        tiles: vec![
            tile(
                "Next visit",
                "—",
                TileIcon::Alarm,
                "not booked yet",
                true,
                "track",
            ),
            tile(
                "Payments",
                "—",
                TileIcon::Wallet,
                "nothing due yet",
                false,
                "payments",
            ),
        ],
        progress: Some(HomeProgress {
            label: "Install progress".into(),
            trailing: Some(who.org_name.clone()),
            segments: (0..7).map(empty).collect(),
            stages: vec!["Survey".into(), "Install".into(), "Handover".into()],
            legend: false,
        }),
        list: HomeList {
            title: None,
            rows: vec![note(
                "no_install",
                "Your install is being set up",
                &format!("{} adds your stages and visits here", who.org_name),
            )],
        },
    }
}

// Admins use the website; the app shows them "use the website" instead.
fn admin(who: &Who) -> HomeSummary {
    HomeSummary {
        unread_notifications: 0,
        eyebrow: greeting(&who.now).into(),
        title: who.org_name.clone(),
        headline: None,
        week: Vec::new(),
        energy: None,
        tiles: Vec::new(),
        progress: None,
        list: HomeList {
            title: None,
            rows: vec![note(
                "use_website",
                "Your tools are on the website",
                "solacliq.markcliq.com",
            )],
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn who(utc: DateTime<Utc>) -> Who {
        Who {
            first_name: "Ravi".into(),
            org_name: "Example Solar".into(),
            now: india_now(utc),
        }
    }

    #[test]
    fn today_is_today_in_india() {
        // 20:00 UTC on Sun 15 Nov is 01:30 on Mon 16 Nov in India.
        let w = who(Utc.with_ymd_and_hms(2026, 11, 15, 20, 0, 0).unwrap());
        let home = worker(&w, &[], 0);
        assert_eq!(home.eyebrow, "Monday, 16 Nov");
        let today: Vec<_> = home.week.iter().filter(|d| d.today).collect();
        assert_eq!(today.len(), 1);
        assert_eq!((today[0].day.as_str(), today[0].date), ("Mon", 16));
        assert_eq!(home.week[0].day, "Mon");
        assert_eq!(home.week[6].day, "Sun");
    }

    #[test]
    fn greetings_follow_indian_time() {
        let at = |h| {
            greeting(&india_now(
                Utc.with_ymd_and_hms(2026, 11, 16, h, 0, 0).unwrap(),
            ))
        };
        assert_eq!(at(2), "Good morning"); // 07:30
        assert_eq!(at(8), "Good afternoon"); // 13:30
        assert_eq!(at(13), "Good evening"); // 18:30
    }

    #[test]
    fn every_role_gets_tiles_the_app_can_open() {
        let w = who(Utc::now());
        let known = [
            "to_submit",
            "expenses",
            "fix",
            "review",
            "earnings",
            "track",
            "payments",
        ];
        for home in [
            worker(&w, &[], 0),
            agent(&w, true, &[]),
            agent(&w, false, &[]),
            customer(&w, None, (0, 0)),
        ] {
            assert!(home.tiles.len() <= 2);
            for t in &home.tiles {
                assert!(known.contains(&t.action.unwrap()), "{:?}", t.action);
            }
        }
        assert_eq!(agent(&w, true, &[]).tiles[1].action, Some("earnings"));
        assert_eq!(agent(&w, false, &[]).tiles[1].action, Some("review"));
    }

    #[test]
    fn a_workers_week_shows_each_task() {
        // Wed 18 Nov, 10:00 in India.
        let w = who(Utc.with_ymd_and_hms(2026, 11, 18, 4, 30, 0).unwrap());
        let at = |d, h| Utc.with_ymd_and_hms(2026, 11, d, h, 0, 0).unwrap();
        let task = |status, due_at| WeekTask {
            id: Uuid::now_v7(),
            title: "Wiring".into(),
            customer_name: "A".into(),
            status,
            due_at,
            on_hold: false,
        };
        let tasks = [
            task(TaskStatus::Approved, at(16, 5)),  // Mon
            task(TaskStatus::Assigned, at(17, 5)),  // Tue, overdue
            task(TaskStatus::Assigned, at(18, 5)),  // today
            task(TaskStatus::Submitted, at(18, 6)), // today, with the admin
            task(TaskStatus::Assigned, at(20, 5)),  // Fri
        ];
        let home = worker(&w, &tasks, 0);
        let dots: Vec<Vec<String>> = home.week.iter().map(|d| d.dots.clone()).collect();
        assert_eq!(dots[0], ["done"]);
        assert_eq!(dots[1], ["live"]);
        assert_eq!(dots[2], ["live", "done"]);
        assert_eq!(dots[4], ["planned"]);
        assert_eq!(home.headline.unwrap().value, "2", "due today");
        assert_eq!(home.tiles[0].value, "2", "overdue and today's open one");
        let labels: Vec<_> = home
            .list
            .rows
            .iter()
            .map(|r| r.status.as_ref().unwrap().label.as_str())
            .collect();
        assert_eq!(labels, ["Overdue", "Assigned", "In review"]);
        assert!(home.list.rows.iter().all(|r| r.action == Some("task")));
    }

    #[test]
    fn empty_lists_explain_instead_of_showing_nothing() {
        let w = who(Utc::now());
        for home in [
            worker(&w, &[], 0),
            agent(&w, true, &[]),
            customer(&w, None, (0, 0)),
        ] {
            assert_eq!(home.list.rows.len(), 1);
            assert!(home.list.rows[0].action.is_none(), "not tappable");
        }
    }
}
