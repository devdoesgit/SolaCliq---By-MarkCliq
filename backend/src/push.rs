/*
    Push notifications (F12)
    --------------------------------------------------------------------
    - a push is only a doorbell for a notification already in the in-app
      list: its title and body, and the ids that say what it opens
    - the worker (`run`, started in main.rs) every 2 seconds:
        1. claims up to 50 notifications not handled yet and marks them
           handled, in one transaction (`FOR UPDATE SKIP LOCKED`: two
           servers never take the same row)
        2. skips people whose push setting is off, and notifications
           older than 10 minutes (a late doorbell is worse than none)
        3. sends one message per live device: its session not revoked
           and its refresh token not expired
        4. deletes a device Firebase answers UNREGISTERED for (the app
           was uninstalled)
    - claimed, then sent: a crash mid-send loses that push rather than
      sending it twice. The in-app list is the record
    - no retries: a failed push is logged, the notification stays in
      the list
    - nothing secret goes in a push: Google carries it
*/

use std::time::Duration;

use chrono::{DateTime, Utc};
use reqwest::StatusCode;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    error::ApiResult,
    google::{AccessToken, ServiceAccount, TokenError},
    scope,
};

const SCOPE: &str = "https://www.googleapis.com/auth/firebase.messaging";
const BATCH: i64 = 50;
const EVERY: Duration = Duration::from_secs(2);
const TOO_LATE: chrono::Duration = chrono::Duration::minutes(10);

// The app's two Android channels (F12): with and without sound.
const CHANNEL: &str = "updates";
const CHANNEL_SILENT: &str = "updates_silent";

/*
    Where pushes go
    --------------------------------------------------------------------
    - Log: development without FCM_SERVICE_ACCOUNT_KEY_FILE; each push
      is only logged (Config refuses this in production)
    - Fcm: Firebase Cloud Messaging's HTTP v1 API
*/
pub enum Sender {
    Log,
    Fcm(Box<Fcm>),
}

// What one send came to.
#[derive(Debug, PartialEq, Eq)]
pub enum Outcome {
    Sent,
    // The token is dead (app uninstalled): delete the device.
    Unregistered,
    Failed(String),
}

impl Sender {
    async fn send(&mut self, message: &Value) -> Outcome {
        match self {
            Sender::Log => {
                let m = &message["message"];
                tracing::info!(
                    title = %m["notification"]["title"],
                    kind = %m["data"]["kind"],
                    "push (not sent: no FCM key set)"
                );
                Outcome::Sent
            }
            Sender::Fcm(fcm) => fcm.send(message).await,
        }
    }
}

// How the FCM client gets its bearer token.
enum Auth {
    Google(Box<AccessToken>),
    // A stand-in FCM in tests, which takes any token.
    Fixed(String),
}

pub struct Fcm {
    http: reqwest::Client,
    auth: Auth,
    send_url: String,
}

impl Fcm {
    pub fn new(account: ServiceAccount) -> Self {
        let send_url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            account.project_id()
        );
        Self {
            http: http(),
            auth: Auth::Google(Box::new(AccessToken::new(account, SCOPE, None))),
            send_url,
        }
    }

    // FCM at `base` instead of Google (tests' stand-in).
    pub fn stand_in(base: &str) -> Self {
        Self {
            http: http(),
            auth: Auth::Fixed("test-token".into()),
            send_url: format!("{base}/v1/projects/test/messages:send"),
        }
    }

    async fn token(&mut self) -> Result<String, String> {
        match &mut self.auth {
            Auth::Fixed(t) => Ok(t.clone()),
            Auth::Google(token) => token.get(&self.http).await.map_err(|e| match e {
                TokenError::Retry(r) | TokenError::GiveUp(r) => r,
            }),
        }
    }

    // A test notification to one token (`send-test-push`).
    pub async fn send_test(&mut self, token: &str) -> Outcome {
        let message = json!({
            "message": {
                "token": token,
                "notification": {
                    "title": "Test notification",
                    "body": "Sent by send-test-push to check the push setup.",
                },
                "data": { "kind": "guide" },
                "android": {
                    "priority": "high",
                    "notification": { "channel_id": CHANNEL },
                },
            }
        });
        self.send(&message).await
    }

    // One message; a refused access token is replaced once.
    async fn send(&mut self, message: &Value) -> Outcome {
        for _ in 0..2 {
            let token = match self.token().await {
                Ok(t) => t,
                Err(reason) => return Outcome::Failed(reason),
            };
            let response = match self
                .http
                .post(&self.send_url)
                .bearer_auth(token)
                .json(message)
                .send()
                .await
            {
                Ok(r) => r,
                Err(e) => return Outcome::Failed(e.to_string()),
            };
            let status = response.status();
            if status.is_success() {
                return Outcome::Sent;
            }
            if status == StatusCode::UNAUTHORIZED
                && let Auth::Google(token) = &mut self.auth
            {
                token.forget();
                continue;
            }
            let body = response.text().await.unwrap_or_default();
            return answer(status, &body);
        }
        Outcome::Failed("access token refused twice".into())
    }
}

fn http() -> reqwest::Client {
    reqwest::Client::builder()
        .timeout(Duration::from_secs(10))
        .build()
        .expect("HTTP client")
}

/*
    FCM's answer to a failed send. UNREGISTERED (404, or 400 in older
    answers) means the app is gone from that phone
*/
fn answer(status: StatusCode, body: &str) -> Outcome {
    if body.contains("\"UNREGISTERED\"") {
        Outcome::Unregistered
    } else {
        Outcome::Failed(format!("{status}: {body}"))
    }
}

// A claimed notification: what the push carries.
#[derive(sqlx::FromRow)]
struct Claimed {
    id: Uuid,
    user_id: Uuid,
    org_id: Option<Uuid>,
    kind: String,
    title: String,
    body: String,
    task_id: Option<Uuid>,
    expense_id: Option<Uuid>,
    customer_id: Option<Uuid>,
    lead_id: Option<Uuid>,
    created_at: DateTime<Utc>,
}

// A live device of someone who wants pushes.
#[derive(sqlx::FromRow)]
struct Device {
    token: String,
    user_id: Uuid,
    sound: bool,
}

/*
    The FCM v1 message for one notification on one device
    --------------------------------------------------------------------
    - `data` values must be strings; only the ids the row has are sent
      (`org_id` is missing for the Personal workspace)
    - high priority, so it shows at once; the channel decides the sound
*/
fn message(n: &Claimed, token: &str, sound: bool) -> Value {
    let mut data = json!({
        "notification_id": n.id.to_string(),
        "kind": n.kind,
    });
    for (key, id) in [
        ("org_id", n.org_id),
        ("task_id", n.task_id),
        ("expense_id", n.expense_id),
        ("customer_id", n.customer_id),
        ("lead_id", n.lead_id),
    ] {
        if let Some(id) = id {
            data[key] = id.to_string().into();
        }
    }
    json!({
        "message": {
            "token": token,
            "notification": { "title": n.title, "body": n.body },
            "data": data,
            "android": {
                "priority": "high",
                "notification": {
                    "channel_id": if sound { CHANNEL } else { CHANNEL_SILENT },
                },
            },
        }
    })
}

/*
    One round: claims a batch and sends it. Returns how many pushes were
    sent, for the tests
*/
pub async fn push_once(db: &PgPool, sender: &mut Sender) -> ApiResult<usize> {
    let mut tx = scope::push(db).await?;
    let claimed: Vec<Claimed> = sqlx::query_as(
        "UPDATE notifications SET pushed_at = now()
         WHERE id IN (SELECT id FROM notifications
                      WHERE pushed_at IS NULL
                      ORDER BY created_at
                      LIMIT $1
                      FOR UPDATE SKIP LOCKED)
         RETURNING id, user_id, org_id, kind, title, body,
                   task_id, expense_id, customer_id, lead_id, created_at",
    )
    .bind(BATCH)
    .fetch_all(&mut *tx)
    .await?;
    let fresh: Vec<Claimed> = claimed
        .into_iter()
        .filter(|n| Utc::now() - n.created_at < TOO_LATE)
        .collect();
    let people: Vec<Uuid> = fresh.iter().map(|n| n.user_id).collect();
    // Push on and sound on unless the person turned them off.
    let devices: Vec<Device> = if people.is_empty() {
        Vec::new()
    } else {
        sqlx::query_as(
            "SELECT d.token, d.user_id, coalesce(us.sound, true) AS sound
             FROM devices d
             JOIN sessions s ON s.id = d.session_id
             LEFT JOIN user_settings us ON us.user_id = d.user_id
             WHERE d.user_id = ANY($1)
               AND s.revoked_at IS NULL
               AND s.refresh_expires_at > now()
               AND coalesce(us.push, true)",
        )
        .bind(&people)
        .fetch_all(&mut *tx)
        .await?
    };
    tx.commit().await?;

    /*
        Sending
        ----------------------------------------------------------------
        - each message stands alone: a device that can't be cleaned up is
          logged and the round goes on, as the batch is already marked
          sent and a stopped round would lose the rest for good
        - freshness is checked again before each send, not only when the
          batch was claimed: when Firebase is slow a round can take
          minutes, and a doorbell that late is worse than none
    */
    let mut sent = 0;
    for n in &fresh {
        if Utc::now() - n.created_at >= TOO_LATE {
            tracing::warn!(notification_id = %n.id, "push too late; skipped");
            continue;
        }
        for d in devices.iter().filter(|d| d.user_id == n.user_id) {
            match sender.send(&message(n, &d.token, d.sound)).await {
                Outcome::Sent => sent += 1,
                Outcome::Unregistered => {
                    let removed = sqlx::query("DELETE FROM devices WHERE token = $1")
                        .bind(&d.token)
                        .execute(db)
                        .await;
                    match removed {
                        Ok(_) => {
                            tracing::info!(user_id = %d.user_id, "push token unregistered; device removed")
                        }
                        Err(e) => {
                            tracing::error!(error = %e, user_id = %d.user_id, "unregistered device not removed")
                        }
                    }
                }
                Outcome::Failed(reason) => {
                    tracing::warn!(notification_id = %n.id, %reason, "push not sent");
                }
            }
        }
    }
    Ok(sent)
}

// The worker: a round every 2 seconds, until the server stops.
pub async fn run(db: PgPool, mut sender: Sender) {
    let mut every = tokio::time::interval(EVERY);
    every.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
    loop {
        every.tick().await;
        if let Err(e) = push_once(&db, &mut sender).await {
            tracing::error!(error = ?e, "push round failed");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn claimed() -> Claimed {
        Claimed {
            id: Uuid::nil(),
            user_id: Uuid::nil(),
            org_id: None,
            kind: "task_assigned".into(),
            title: "New task".into(),
            body: "Site survey".into(),
            task_id: Some(Uuid::max()),
            expense_id: None,
            customer_id: None,
            lead_id: None,
            created_at: Utc::now(),
        }
    }

    #[test]
    fn the_message_carries_only_the_ids_it_has() {
        let m = message(&claimed(), "tok", true);
        let data = m["message"]["data"].as_object().unwrap();
        assert_eq!(data["kind"], "task_assigned");
        assert_eq!(data["task_id"], Uuid::max().to_string());
        assert!(!data.contains_key("org_id"));
        assert!(!data.contains_key("expense_id"));
        assert!(
            data.values().all(Value::is_string),
            "FCM data is strings only"
        );
        assert_eq!(m["message"]["token"], "tok");
        assert_eq!(
            m["message"]["android"]["notification"]["channel_id"],
            CHANNEL
        );
    }

    #[test]
    fn sound_off_uses_the_silent_channel() {
        let m = message(&claimed(), "tok", false);
        assert_eq!(
            m["message"]["android"]["notification"]["channel_id"],
            CHANNEL_SILENT
        );
    }

    #[test]
    fn unregistered_is_told_apart() {
        let gone = r#"{"error":{"code":404,"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}"#;
        assert_eq!(answer(StatusCode::NOT_FOUND, gone), Outcome::Unregistered);
        let busy = r#"{"error":{"code":503,"status":"UNAVAILABLE"}}"#;
        assert!(matches!(
            answer(StatusCode::SERVICE_UNAVAILABLE, busy),
            Outcome::Failed(_)
        ));
    }
}
