/*
    The home screen, composed per role (phase 7)
    --------------------------------------------------------------------
    - GET /orgs/{org_id}/home: the parts the app draws (headline, week,
      tiles, progress, a list), so a role's home changes without an app
      update. Shapes and actions: docs/backend-handoff.md, "Home"
    - built from what exists. Tasks and expenses arrive in phase 8,
      customers and commissions in phase 9, installs in phase 10; until
      each lands its numbers are honest zeros and the list says what's
      coming, never sample data
    - dates and greetings are in Indian time: an installer's "today" is
      today in India, whatever the server's clock says
    - always `unread_notifications`, for the bell's dot
*/

use axum::{Json, extract::State};
use chrono::{DateTime, Datelike, Duration, FixedOffset, Timelike, Utc, Weekday};
use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use crate::{
    AppState,
    error::ApiResult,
    notify,
    org::{OrgMember, PayType, Role},
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
    let (name, org_name): (String, String) =
        sqlx::query_as("SELECT u.name, o.name FROM users u, orgs o WHERE u.id = $1 AND o.id = $2")
            .bind(member.user_id)
            .bind(member.org_id)
            .fetch_one(&state.db)
            .await?;
    let who = Who {
        first_name: name.split_whitespace().next().unwrap_or(&name).to_owned(),
        org_name,
        now: india_now(Utc::now()),
    };
    let mut summary = match (member.role, member.pay_type) {
        (Role::Worker, _) => worker(&who),
        (Role::Agent, Some(PayType::Commission)) => agent(&who, true),
        (Role::Agent, _) => agent(&who, false),
        (Role::Customer, _) => customer(&who),
        (Role::OrgAdmin, _) => admin(&who),
    };
    let mut tx = member.begin(&state.db).await?;
    summary.unread_notifications =
        notify::unread(&mut tx, member.user_id, Some(member.org_id)).await?;
    tx.commit().await?;
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

// This week, Monday to Sunday. Each day's dots come with tasks (phase 8).
fn week(now: &DateTime<FixedOffset>) -> Vec<HomeDay> {
    let today = now.date_naive();
    let monday = today - Duration::days(i64::from(today.weekday().num_days_from_monday()));
    (0..7)
        .map(|i| {
            let date = monday + Duration::days(i);
            HomeDay {
                day: short_day(date.weekday()).to_owned(),
                date: date.day(),
                today: date == today,
                dots: Vec::new(),
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
    then the next tasks. Tasks and expenses: phase 8
*/
fn worker(who: &Who) -> HomeSummary {
    HomeSummary {
        unread_notifications: 0,
        eyebrow: who.now.format("%A, %-d %b").to_string(),
        title: format!("{}'s day", who.first_name),
        headline: headline("0", "tasks", "on site today"),
        week: week(&who.now),
        energy: None,
        tiles: vec![
            tile(
                "To submit",
                "0",
                TileIcon::Camera,
                "today",
                true,
                "to_submit",
            ),
            tile(
                "Expenses",
                "0",
                TileIcon::Receipt,
                "with admin",
                false,
                "expenses",
            ),
        ],
        progress: None,
        list: HomeList {
            title: Some("Up next".into()),
            rows: vec![note(
                "no_tasks",
                "Nothing scheduled yet",
                &format!("{} assigns your tasks; they show up here", who.org_name),
            )],
        },
    }
}

/*
    A sales agent's customers: added this month, KYC to fix, then
    earnings (commission) or what's with the admin (salary), and recent
    customers. Customers and commissions: phase 9
*/
fn agent(who: &Who, commission: bool) -> HomeSummary {
    let second = if commission {
        tile(
            "Earnings",
            "₹0",
            TileIcon::Wallet,
            "payable",
            false,
            "earnings",
        )
    } else {
        tile(
            "In review",
            "0",
            TileIcon::Hourglass,
            "with admin",
            false,
            "review",
        )
    };
    HomeSummary {
        unread_notifications: 0,
        eyebrow: greeting(&who.now).into(),
        title: format!("{}'s customers", who.first_name),
        headline: headline("0", "customers", "added this month"),
        week: Vec::new(),
        energy: None,
        tiles: vec![
            tile("Needs fix", "0", TileIcon::Alarm, "KYC", true, "fix"),
            second,
        ],
        progress: None,
        list: HomeList {
            title: Some("Recent customers".into()),
            rows: vec![note(
                "no_customers",
                "No customers yet",
                "Customers you register show up here",
            )],
        },
    }
}

/*
    A customer's install: where it is (stage x of 7), the next visit and
    the next payment. Their install arrives in phase 10; until the
    company sets it up, the home says so
*/
fn customer(who: &Who) -> HomeSummary {
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
        let home = worker(&w);
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
        for home in [worker(&w), agent(&w, true), agent(&w, false), customer(&w)] {
            assert!(home.tiles.len() <= 2);
            for t in &home.tiles {
                assert!(known.contains(&t.action.unwrap()), "{:?}", t.action);
            }
        }
        assert_eq!(agent(&w, true).tiles[1].action, Some("earnings"));
        assert_eq!(agent(&w, false).tiles[1].action, Some("review"));
    }

    #[test]
    fn empty_lists_explain_instead_of_showing_nothing() {
        let w = who(Utc::now());
        for home in [worker(&w), agent(&w, true), customer(&w)] {
            assert_eq!(home.list.rows.len(), 1);
            assert!(home.list.rows[0].action.is_none(), "not tappable");
        }
    }
}
