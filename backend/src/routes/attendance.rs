/*
    Attendance (F17)
    --------------------------------------------------------------------
    - POST /orgs/{org_id}/me/attendance/start   (idem)  start the day
    - POST /orgs/{org_id}/me/attendance/end     (idem)  end it
    - GET  /orgs/{org_id}/attendance/day?date=          the admin's day
    - GET  /orgs/{org_id}/attendance/month?month=       the admin's month
    - GET  /orgs/{org_id}/attendance/month.csv?month=   the same, as CSV
    - who marks: installers and salaried sales (`tracked`); commission
      agents aren't bound to the company's hours, so they get 403
      `attendance.not_tracked`. The org admin only reads
    - a tap's time comes from the server's clock, less how long it
      waited on the phone; one that waited over 5 minutes (sent from
      offline) is marked `sent_late` (`tap`)
    - a day is one India date: it starts and ends on it. Left without an
      end, it shows `no_check_out` from the next date on
    - spec: docs/features/F17-attendance.md
*/

use std::collections::HashMap;

use axum::{
    Json,
    extract::State,
    http::{StatusCode, header},
    response::{IntoResponse, Response},
};
use chrono::{DateTime, Datelike, Duration, Months, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgConnection;
use utoipa::{IntoParams, ToSchema};
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiQuery},
    idempotency::{self, IdempotencyKey},
    india,
    org::{Admins, OrgMember, PayType, Role, WorkersAndAgents},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(start_day))
        .routes(routes!(end_day))
        .routes(routes!(day_view))
        .routes(routes!(month_view))
        .routes(routes!(month_csv))
}

// A tap that waited on the phone longer than this was sent from offline.
const LATE_AFTER: Duration = Duration::minutes(5);
// Older taps are refused: a week offline is a phone problem, not a day's work.
const OLDEST: Duration = Duration::days(7);

/*
    The contract's types
*/

#[derive(Debug, Deserialize, ToSchema)]
pub struct AttendanceTapCreate {
    // The phone's clock when the person tapped.
    pub phone_at: DateTime<Utc>,
    // The phone's clock when the app sent the tap (later, if it waited offline).
    pub sent_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
pub struct AttendanceTap {
    pub at: DateTime<Utc>,
    // Arrived over 5 minutes after the tap; `at` is the phone's time.
    pub sent_late: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum AttendanceStatus {
    Working,
    Ended,
    NoCheckOut,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendanceDay {
    // The India date the day started.
    pub date: NaiveDate,
    pub status: AttendanceStatus,
    pub start: AttendanceTap,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub end: Option<AttendanceTap>,
    // Worked time, once ended.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub minutes: Option<i64>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendancePerson {
    pub user_id: Uuid,
    pub name: String,
    // Their role now: `worker` or `agent`, or another if it changed since.
    pub role: Role,
    // No longer a member; shown for the days they worked.
    pub removed: bool,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendanceDayEntry {
    pub person: AttendancePerson,
    // Absent when they haven't started on this date.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub day: Option<AttendanceDay>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendanceDayView {
    pub date: NaiveDate,
    pub people: Vec<AttendanceDayEntry>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendanceMonthEntry {
    pub person: AttendancePerson,
    // Dates with a start, oldest first.
    pub days: Vec<AttendanceDay>,
    pub days_worked: i64,
    // Total worked time of the ended days.
    pub minutes: i64,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AttendanceMonthView {
    // YYYY-MM.
    pub month: String,
    pub people: Vec<AttendanceMonthEntry>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum HomeAttendanceState {
    NotStarted,
    Working,
    Ended,
}

// The contract's `HomeAttendance`: the home's attendance card.
#[derive(Debug, Serialize, ToSchema)]
pub struct HomeAttendance {
    pub state: HomeAttendanceState,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub day: Option<AttendanceDay>,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct DayQuery {
    // India date, YYYY-MM-DD; today in India when left out.
    pub date: Option<NaiveDate>,
}

#[derive(Debug, Deserialize, IntoParams)]
pub struct MonthQuery {
    // YYYY-MM; this month in India when left out.
    pub month: Option<String>,
}

/*
    The rules, kept apart from the database so they're tested directly
*/

// Installers and salaried sales; an agent without a pay type counts as salaried.
pub fn tracked(role: Role, pay_type: Option<PayType>) -> bool {
    match role {
        Role::Worker => true,
        Role::Agent => pay_type != Some(PayType::Commission),
        Role::OrgAdmin | Role::Customer => false,
    }
}

/*
    When a tap counts as made
    --------------------------------------------------------------------
    - the app sends two times from the phone's clock: the tap
      (`phone_at`) and the send (`sent_at`). Their gap is how long the
      tap waited on the phone, and it's right even on a phone whose clock
      is wrong, because the error is in both
    - so the tap counts as made that long before it reached the server,
      by the server's clock: a slow, fast or changed phone clock moves
      nothing
    - waited over 5 minutes (sent from offline): marked `sent_late`, as
      the gap is the phone's word
    - a negative gap (the clock was set back in between) counts as
      none; one over 7 days is refused
*/
fn tap(
    now: DateTime<Utc>,
    phone_at: DateTime<Utc>,
    sent_at: DateTime<Utc>,
) -> ApiResult<AttendanceTap> {
    let waited = (sent_at - phone_at).max(Duration::zero());
    if waited > OLDEST {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "attendance.too_old",
            "This tap is more than 7 days old",
        )
        .detail("Ask your admin to note this day."));
    }
    Ok(AttendanceTap {
        at: now - waited,
        sent_late: waited > LATE_AFTER,
    })
}

/*
    A day's status on `today` (India). A day without an end is working
    on its own date and no check-out after it
*/
fn status(date: NaiveDate, ended: bool, today: NaiveDate) -> AttendanceStatus {
    if ended {
        AttendanceStatus::Ended
    } else if date < today {
        AttendanceStatus::NoCheckOut
    } else {
        AttendanceStatus::Working
    }
}

// `YYYY-MM` → its first date; anything else is a 422 on `month`.
fn first_of_month(month: &str) -> ApiResult<NaiveDate> {
    let bad = || ApiError::validation(Vec::new()).field("month", "A month as YYYY-MM.");
    if month.len() != 7 || month.as_bytes()[4] != b'-' {
        return Err(bad());
    }
    NaiveDate::parse_from_str(&format!("{month}-01"), "%Y-%m-%d").map_err(|_| bad())
}

// The asked month, or this one in India.
fn month_range(month: Option<&str>, now: DateTime<Utc>) -> ApiResult<(NaiveDate, NaiveDate)> {
    let first = match month {
        Some(m) => first_of_month(m)?,
        None => india::date(now)
            .with_day(1)
            .expect("every month has a first"),
    };
    let next = first
        .checked_add_months(Months::new(1))
        .ok_or_else(|| ApiError::validation(Vec::new()).field("month", "A month as YYYY-MM."))?;
    Ok((first, next))
}

fn not_tracked() -> ApiError {
    ApiError::new(
        StatusCode::FORBIDDEN,
        "attendance.not_tracked",
        "Your role doesn't mark attendance",
    )
}

fn already_started() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "attendance.already_started",
        "Your day has already started",
    )
}

fn not_started() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "attendance.not_started",
        "Your day hasn't started",
    )
    .detail("Start your day first.")
}

fn already_ended() -> ApiError {
    ApiError::new(
        StatusCode::CONFLICT,
        "attendance.already_ended",
        "Your day has already ended",
    )
}

/*
    Reading days
*/

// The columns every day query selects, in `DayRow`'s order.
macro_rules! day_columns {
    () => {
        "d.work_date, d.started_at, d.start_sent_late, d.ended_at, d.end_sent_late"
    };
}

#[derive(sqlx::FromRow)]
struct DayRow {
    work_date: NaiveDate,
    started_at: DateTime<Utc>,
    start_sent_late: bool,
    ended_at: Option<DateTime<Utc>>,
    end_sent_late: Option<bool>,
}

impl DayRow {
    fn into_day(self, today: NaiveDate) -> AttendanceDay {
        let end = self.ended_at.map(|at| AttendanceTap {
            at,
            sent_late: self.end_sent_late.unwrap_or(false),
        });
        AttendanceDay {
            date: self.work_date,
            status: status(self.work_date, end.is_some(), today),
            start: AttendanceTap {
                at: self.started_at,
                sent_late: self.start_sent_late,
            },
            minutes: end.map(|e| (e.at - self.started_at).num_minutes()),
            end,
        }
    }
}

/*
    The home's card: today's day in India, if any. Only for tracked
    people (`home.rs` checks)
*/
pub async fn home_card(
    conn: &mut PgConnection,
    user_id: Uuid,
    now: DateTime<Utc>,
) -> ApiResult<HomeAttendance> {
    let today = india::date(now);
    let row: Option<DayRow> = sqlx::query_as(concat!(
        "SELECT ",
        day_columns!(),
        " FROM attendance_days d WHERE d.user_id = $1 AND d.work_date = $2"
    ))
    .bind(user_id)
    .bind(today)
    .fetch_optional(conn)
    .await?;
    let day = row.map(|r| r.into_day(today));
    let state = match &day {
        None => HomeAttendanceState::NotStarted,
        Some(d) if d.end.is_some() => HomeAttendanceState::Ended,
        Some(_) => HomeAttendanceState::Working,
    };
    Ok(HomeAttendance { state, day })
}

/*
    The two taps
*/

/*
    Start the caller's day on the tap's India date
    --------------------------------------------------------------------
    - one start per date: a second is 409 `attendance.already_started`
      (the unique key decides, so two at once can't both start)
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/me/attendance/start",
    operation_id = "startAttendanceDay",
    tag = "attendance",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = AttendanceTapCreate,
    responses(
        (status = 201, description = "Started.", body = AttendanceDay),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn start_day(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<AttendanceTapCreate>,
) -> ApiResult<Response> {
    if !tracked(member.role, member.pay_type) {
        return Err(not_tracked());
    }
    let request = format!("POST /api/v1/orgs/{}/me/attendance/start", member.org_id);
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let now = Utc::now();
    let start = tap(now, req.phone_at, req.sent_at)?;

    let mut tx = member.begin(&state.db).await?;
    let row: Option<DayRow> = sqlx::query_as(concat!(
        "INSERT INTO attendance_days AS d (id, org_id, user_id, work_date,
                                           started_at, start_phone_at, start_sent_late)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (org_id, user_id, work_date) DO NOTHING
         RETURNING ",
        day_columns!()
    ))
    .bind(Uuid::now_v7())
    .bind(member.org_id)
    .bind(member.user_id)
    .bind(india::date(start.at))
    .bind(start.at)
    .bind(req.phone_at)
    .bind(start.sent_late)
    .fetch_optional(&mut *tx)
    .await?;
    let Some(row) = row else {
        drop(tx);
        return replay_or(&state, &member, key, &request, already_started()).await;
    };
    let day = row.into_day(india::date(now));

    respond(
        tx,
        &state,
        &member,
        key,
        &request,
        StatusCode::CREATED,
        &day,
    )
    .await
}

/*
    End the caller's day of the tap's India date
    --------------------------------------------------------------------
    - no start on that date, or one after the tap: 409
      `attendance.not_started`; ended already: 409
      `attendance.already_ended`
    - the row is locked while it's checked, so two ends at once can't
      both write
    - safe to retry (Idempotency-Key)
*/
#[utoipa::path(
    post,
    path = "/orgs/{org_id}/me/attendance/end",
    operation_id = "endAttendanceDay",
    tag = "attendance",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("Idempotency-Key" = Uuid, Header, description = "The same UUID on every retry."),
    ),
    request_body = AttendanceTapCreate,
    responses(
        (status = 200, description = "Ended.", body = AttendanceDay),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 409, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn end_day(
    State(state): State<AppState>,
    member: OrgMember<WorkersAndAgents>,
    key: IdempotencyKey,
    ApiJson(req): ApiJson<AttendanceTapCreate>,
) -> ApiResult<Response> {
    if !tracked(member.role, member.pay_type) {
        return Err(not_tracked());
    }
    let request = format!("POST /api/v1/orgs/{}/me/attendance/end", member.org_id);
    if let Some(done) = idempotency::replay(&state.db, member.user_id, key, &request).await? {
        return Ok(done);
    }
    let now = Utc::now();
    let end = tap(now, req.phone_at, req.sent_at)?;
    let date = india::date(end.at);

    let mut tx = member.begin(&state.db).await?;
    let open: Option<(DateTime<Utc>, bool)> = sqlx::query_as(
        "SELECT started_at, ended_at IS NOT NULL FROM attendance_days
         WHERE org_id = $1 AND user_id = $2 AND work_date = $3
         FOR UPDATE",
    )
    .bind(member.org_id)
    .bind(member.user_id)
    .bind(date)
    .fetch_optional(&mut *tx)
    .await?;
    match open {
        None => return Err(not_started()),
        Some((_, true)) => {
            drop(tx);
            return replay_or(&state, &member, key, &request, already_ended()).await;
        }
        Some((started_at, false)) if started_at > end.at => return Err(not_started()),
        Some(_) => {}
    }
    let row: DayRow = sqlx::query_as(concat!(
        "UPDATE attendance_days AS d
            SET ended_at = $4, end_phone_at = $5, end_sent_late = $6
          WHERE d.org_id = $1 AND d.user_id = $2 AND d.work_date = $3
          RETURNING ",
        day_columns!()
    ))
    .bind(member.org_id)
    .bind(member.user_id)
    .bind(date)
    .bind(end.at)
    .bind(req.phone_at)
    .bind(end.sent_late)
    .fetch_one(&mut *tx)
    .await?;
    let day = row.into_day(india::date(now));

    respond(tx, &state, &member, key, &request, StatusCode::OK, &day).await
}

/*
    A clash (already started or ended) may be this very request: a retry
    sent while the first was still running waits for it, then meets its
    row. Then the first one's answer, else the clash
*/
async fn replay_or(
    state: &AppState,
    member: &OrgMember<WorkersAndAgents>,
    key: IdempotencyKey,
    request: &str,
    clash: ApiError,
) -> ApiResult<Response> {
    match idempotency::replay(&state.db, member.user_id, key, request).await? {
        Some(done) => Ok(done),
        None => Err(clash),
    }
}

// Stores the answer with the Idempotency-Key, commits, and sends it.
async fn respond(
    mut tx: crate::scope::Tx,
    state: &AppState,
    member: &OrgMember<WorkersAndAgents>,
    key: IdempotencyKey,
    request: &str,
    status: StatusCode,
    day: &AttendanceDay,
) -> ApiResult<Response> {
    let body = serde_json::to_value(day).map_err(|_| ApiError::internal())?;
    if !idempotency::save(&mut tx, member.user_id, key, request, status, &body).await? {
        drop(tx);
        return idempotency::replay(&state.db, member.user_id, key, request)
            .await?
            .ok_or_else(ApiError::internal);
    }
    tx.commit().await?;
    Ok((status, Json(body)).into_response())
}

/*
    The admin's views (read only)
    --------------------------------------------------------------------
    - the people: installers and salaried sales who are members now,
      plus anyone with a day in the range whatever has changed since
      (removed, moved to commission, another role), so a month's record
      stays whole
    - by name, case aside
*/

#[derive(sqlx::FromRow)]
struct PersonRow {
    user_id: Uuid,
    name: String,
    role: Role,
    removed: bool,
}

impl PersonRow {
    fn into_person(self) -> AttendancePerson {
        AttendancePerson {
            user_id: self.user_id,
            name: self.name,
            role: self.role,
            removed: self.removed,
        }
    }
}

// The people for dates `from` up to (not including) `to`.
async fn people(
    conn: &mut PgConnection,
    from: NaiveDate,
    to: NaiveDate,
) -> ApiResult<Vec<PersonRow>> {
    let rows = sqlx::query_as(
        "SELECT u.id AS user_id, u.name, m.role, m.removed_at IS NOT NULL AS removed
         FROM memberships m JOIN users u ON u.id = m.user_id
         WHERE (m.removed_at IS NULL
                AND (m.role = 'worker'
                     OR (m.role = 'agent' AND m.pay_type IS DISTINCT FROM 'commission')))
            OR EXISTS (SELECT 1 FROM attendance_days d
                       WHERE d.org_id = m.org_id AND d.user_id = m.user_id
                         AND d.work_date >= $1 AND d.work_date < $2)
         ORDER BY lower(u.name), u.id",
    )
    .bind(from)
    .bind(to)
    .fetch_all(conn)
    .await?;
    Ok(rows)
}

#[derive(sqlx::FromRow)]
struct UserDayRow {
    user_id: Uuid,
    #[sqlx(flatten)]
    day: DayRow,
}

// Every day from `from` up to (not including) `to`, by person, oldest first.
async fn days(
    conn: &mut PgConnection,
    from: NaiveDate,
    to: NaiveDate,
    today: NaiveDate,
) -> ApiResult<HashMap<Uuid, Vec<AttendanceDay>>> {
    let rows: Vec<UserDayRow> = sqlx::query_as(concat!(
        "SELECT d.user_id, ",
        day_columns!(),
        " FROM attendance_days d
         WHERE d.work_date >= $1 AND d.work_date < $2
         ORDER BY d.user_id, d.work_date"
    ))
    .bind(from)
    .bind(to)
    .fetch_all(conn)
    .await?;
    let mut by_person: HashMap<Uuid, Vec<AttendanceDay>> = HashMap::new();
    for r in rows {
        by_person
            .entry(r.user_id)
            .or_default()
            .push(r.day.into_day(today));
    }
    Ok(by_person)
}

/*
    Everyone's attendance on one date (default today in India)
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/attendance/day",
    operation_id = "getAttendanceDay",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), DayQuery),
    responses(
        (status = 200, description = "The date.", body = AttendanceDayView),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn day_view(
    State(state): State<AppState>,
    member: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<DayQuery>,
) -> ApiResult<Json<AttendanceDayView>> {
    let today = india::date(Utc::now());
    let date = q.date.unwrap_or(today);
    let next = date
        .succ_opt()
        .ok_or_else(|| ApiError::validation(Vec::new()).field("date", "A date as YYYY-MM-DD."))?;

    let mut tx = member.begin(&state.db).await?;
    let people = people(&mut tx, date, next).await?;
    let mut days = days(&mut tx, date, next, today).await?;
    tx.commit().await?;

    let people = people
        .into_iter()
        .map(|p| AttendanceDayEntry {
            // One date: at most one day each.
            day: days.remove(&p.user_id).and_then(|d| d.into_iter().next()),
            person: p.into_person(),
        })
        .collect();
    Ok(Json(AttendanceDayView { date, people }))
}

// The month's entries for the JSON view and the CSV.
async fn month_entries(
    state: &AppState,
    member: &OrgMember<Admins>,
    month: Option<&str>,
) -> ApiResult<(NaiveDate, Vec<AttendanceMonthEntry>)> {
    let now = Utc::now();
    let (first, next) = month_range(month, now)?;
    let today = india::date(now);

    let mut tx = member.begin(&state.db).await?;
    let people = people(&mut tx, first, next).await?;
    let mut days = days(&mut tx, first, next, today).await?;
    tx.commit().await?;

    let entries = people
        .into_iter()
        .map(|p| {
            let days = days.remove(&p.user_id).unwrap_or_default();
            AttendanceMonthEntry {
                days_worked: days.len() as i64,
                minutes: days.iter().filter_map(|d| d.minutes).sum(),
                days,
                person: p.into_person(),
            }
        })
        .collect();
    Ok((first, entries))
}

/*
    Everyone's attendance in one month (default this month in India)
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/attendance/month",
    operation_id = "getAttendanceMonth",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), MonthQuery),
    responses(
        (status = 200, description = "The month.", body = AttendanceMonthView),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn month_view(
    State(state): State<AppState>,
    member: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<MonthQuery>,
) -> ApiResult<Json<AttendanceMonthView>> {
    let (first, people) = month_entries(&state, &member, q.month.as_deref()).await?;
    Ok(Json(AttendanceMonthView {
        month: first.format("%Y-%m").to_string(),
        people,
    }))
}

/*
    One month as CSV, for payroll
    --------------------------------------------------------------------
    - one row per person per day worked, by name then date
    - India times as HH:MM; `minutes` empty without an end; `flags`
      space-separated
*/
#[utoipa::path(
    get,
    path = "/orgs/{org_id}/attendance/month.csv",
    operation_id = "exportAttendanceMonth",
    tag = "admin",
    params(("org_id" = Uuid, Path, description = "The company."), MonthQuery),
    responses(
        (status = 200, description = "The month.", body = String, content_type = "text/csv"),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn month_csv(
    State(state): State<AppState>,
    member: OrgMember<Admins>,
    ApiQuery(q): ApiQuery<MonthQuery>,
) -> ApiResult<Response> {
    let (first, people) = month_entries(&state, &member, q.month.as_deref()).await?;
    let disposition = format!(
        "attachment; filename=\"attendance-{}.csv\"",
        first.format("%Y-%m")
    );
    Ok((
        [
            (header::CONTENT_TYPE, "text/csv; charset=utf-8".to_owned()),
            (header::CONTENT_DISPOSITION, disposition),
        ],
        csv(&people),
    )
        .into_response())
}

fn csv(people: &[AttendanceMonthEntry]) -> String {
    let mut out = String::from("name,role,date,start,end,minutes,flags\n");
    for p in people {
        let role = match p.person.role {
            Role::Worker => "worker",
            Role::Agent => "agent",
            Role::Customer => "customer",
            Role::OrgAdmin => "org_admin",
        };
        for d in &p.days {
            let mut flags = Vec::new();
            if d.start.sent_late {
                flags.push("start_sent_late");
            }
            if d.end.is_some_and(|e| e.sent_late) {
                flags.push("end_sent_late");
            }
            if d.status == AttendanceStatus::NoCheckOut {
                flags.push("no_check_out");
            }
            let row = [
                csv_field(&p.person.name),
                role.to_owned(),
                d.date.to_string(),
                clock(d.start.at),
                d.end.map(|e| clock(e.at)).unwrap_or_default(),
                d.minutes.map(|m| m.to_string()).unwrap_or_default(),
                flags.join(" "),
            ];
            out.push_str(&row.join(","));
            out.push('\n');
        }
    }
    out
}

// "09:12", in India.
fn clock(at: DateTime<Utc>) -> String {
    india::now(at).format("%H:%M").to_string()
}

/*
    A name as one CSV cell
    --------------------------------------------------------------------
    - quoted when it holds a comma, quote or line break, quotes doubled
    - a leading = + - @ (or tab, return) gets a ' first, so a spreadsheet
      shows it as text instead of running it as a formula
*/
fn csv_field(value: &str) -> String {
    let value = if value.starts_with(['=', '+', '-', '@', '\t', '\r']) {
        format!("'{value}")
    } else {
        value.to_owned()
    };
    if value.contains([',', '"', '\n', '\r']) {
        format!("\"{}\"", value.replace('"', "\"\""))
    } else {
        value
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn at(h: u32, m: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 12, 1, h, m, 0).unwrap()
    }

    #[test]
    fn installers_and_salaried_sales_mark_attendance() {
        assert!(tracked(Role::Worker, None));
        assert!(tracked(Role::Agent, Some(PayType::Salary)));
        assert!(tracked(Role::Agent, None));
        assert!(!tracked(Role::Agent, Some(PayType::Commission)));
        assert!(!tracked(Role::OrgAdmin, None));
        assert!(!tracked(Role::Customer, None));
    }

    #[test]
    fn a_tap_sent_at_once_takes_the_servers_clock() {
        let now = at(4, 0);
        // Right, 3 hours fast, 10 minutes slow: the phone's clock doesn't matter.
        for clock in [Duration::zero(), Duration::hours(3), -Duration::minutes(10)] {
            let phone = now + clock;
            assert_eq!(
                tap(now, phone, phone).unwrap(),
                AttendanceTap {
                    at: now,
                    sent_late: false
                }
            );
        }
    }

    #[test]
    fn a_tap_that_waited_counts_from_when_it_was_made() {
        let now = at(12, 0);
        // On a phone 2 hours slow, tapped 40 minutes before it was sent.
        let sent = now - Duration::hours(2);
        let late = tap(now, sent - Duration::minutes(40), sent).unwrap();
        assert_eq!(late.at, now - Duration::minutes(40));
        assert!(late.sent_late);
        // Five minutes is still on time; a clock set back counts as no wait.
        assert!(!tap(now, now - Duration::minutes(5), now).unwrap().sent_late);
        assert_eq!(tap(now, now + Duration::hours(1), now).unwrap().at, now);
        // Seven days still counts; a second more doesn't.
        assert!(tap(now, now - Duration::days(7), now).is_ok());
        assert!(tap(now, now - Duration::days(7) - Duration::seconds(1), now).is_err());
    }

    #[test]
    fn a_day_without_an_end_is_no_check_out_after_its_date() {
        let day = NaiveDate::from_ymd_opt(2026, 12, 1).unwrap();
        let next = day.succ_opt().unwrap();
        assert_eq!(status(day, false, day), AttendanceStatus::Working);
        assert_eq!(status(day, false, next), AttendanceStatus::NoCheckOut);
        assert_eq!(status(day, true, next), AttendanceStatus::Ended);
    }

    #[test]
    fn months_are_yyyy_mm() {
        let (first, next) = month_range(Some("2026-12"), at(0, 0)).unwrap();
        assert_eq!(first.to_string(), "2026-12-01");
        assert_eq!(next.to_string(), "2027-01-01");
        for bad in ["2026-13", "2026-1", "26-12", "2026/12", "2026-12-01", ""] {
            assert!(month_range(Some(bad), at(0, 0)).is_err(), "{bad}");
        }
        // Left out: this month in India (1 Dec 20:00 UTC is 2 Dec there).
        let (first, _) = month_range(None, at(20, 0)).unwrap();
        assert_eq!(first.to_string(), "2026-12-01");
    }

    #[test]
    fn csv_cells_stay_text() {
        assert_eq!(csv_field("Ravi Kumar"), "Ravi Kumar");
        assert_eq!(csv_field("Kumar, Ravi"), "\"Kumar, Ravi\"");
        assert_eq!(csv_field("Ravi \"RK\""), "\"Ravi \"\"RK\"\"\"");
        assert_eq!(csv_field("=HYPERLINK(1)"), "'=HYPERLINK(1)");
        assert_eq!(csv_field("-1,2"), "\"'-1,2\"");
    }

    #[test]
    fn the_csv_has_a_row_per_day_in_indian_time() {
        let started = at(3, 42); // 09:12 in India
        let ended = at(13, 10); // 18:40
        let entry = AttendanceMonthEntry {
            person: AttendancePerson {
                user_id: Uuid::nil(),
                name: "Ravi".to_owned(),
                role: Role::Worker,
                removed: false,
            },
            days: vec![
                DayRow {
                    work_date: india::date(started),
                    started_at: started,
                    start_sent_late: true,
                    ended_at: Some(ended),
                    end_sent_late: Some(false),
                }
                .into_day(india::date(ended)),
                DayRow {
                    work_date: india::date(started) + Duration::days(1),
                    started_at: started + Duration::days(1),
                    start_sent_late: false,
                    ended_at: None,
                    end_sent_late: None,
                }
                .into_day(india::date(started) + Duration::days(5)),
            ],
            days_worked: 2,
            minutes: 568,
        };
        assert_eq!(
            csv(&[entry]),
            "name,role,date,start,end,minutes,flags\n\
             Ravi,worker,2026-12-01,09:12,18:40,568,start_sent_late\n\
             Ravi,worker,2026-12-02,09:12,,,no_check_out\n"
        );
    }
}
