/*
    Sending email through the Gmail API
    --------------------------------------------------------------------
    - production's mailer. Chosen in main.rs when MAIL_FROM and
      GOOGLE_SERVICE_ACCOUNT_KEY_FILE are set
    - signs in as a Google service account with domain-wide delegation,
      acting as the MAIL_FROM user (a Workspace user), allowed only the
      gmail.send scope
    - `send` puts the email on a queue and returns; one background task
      takes emails off the queue and sends them in order
    - how one email goes out:
        1. an access token for the gmail.send scope, acting as MAIL_FROM
           (`google::AccessToken`)
        2. the email as a MIME message, base64url-encoded, posted to
           users/me/messages/send
        3. a network error, 429 or 5xx is tried again (3 tries in all);
           a 401 drops the token and tries again with a new one; any
           other answer is logged and the email dropped
    - never logs an email's body: it can hold a sign-in code
*/

use std::time::Duration;

use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use lettre::message::{Mailbox, Message, MultiPart, header::ContentType};
use reqwest::StatusCode;
use tokio::{sync::mpsc, task::JoinHandle};

use super::{Email, Mailer};
use crate::google::{AccessToken, ServiceAccount, TokenError, retryable};

const SCOPE: &str = "https://www.googleapis.com/auth/gmail.send";
const SEND_URL: &str = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send";
/*
    Emails waiting to be sent. Far more than a burst of sign-ups makes;
    past this, `send` drops the email and logs it rather than let memory
    grow without bound
*/
const QUEUE_LEN: usize = 1000;
const TRIES: u32 = 3;

/*
    The mailer handlers see. Cheap to share: it only holds the queue's
    sending end
*/
pub struct GmailMailer {
    queue: mpsc::Sender<Email>,
}

impl GmailMailer {
    /*
        Starts the background task that sends queued emails
        --------------------------------------------------------------------
        - the task stops once every GmailMailer is dropped and the queue
          is empty, so awaiting the JoinHandle after the server stops
          lets queued emails go out first
    */
    pub fn start(account: ServiceAccount, from: Mailbox) -> (Self, JoinHandle<()>) {
        let (queue, emails) = mpsc::channel(QUEUE_LEN);
        let http = reqwest::Client::builder()
            .timeout(Duration::from_secs(20))
            .build()
            .expect("HTTP client");
        let token = AccessToken::new(account, SCOPE, Some(from.email.to_string()));
        let sender = Sender { http, token, from };
        (Self { queue }, tokio::spawn(sender.run(emails)))
    }
}

impl Mailer for GmailMailer {
    fn send(&self, email: Email) {
        if let Err(e) = self.queue.try_send(email) {
            let (mpsc::error::TrySendError::Full(email) | mpsc::error::TrySendError::Closed(email)) =
                e;
            tracing::error!(to = %email.to, subject = %email.subject, "email dropped: send queue full or closed");
        }
    }
}

// The background task's state.
struct Sender {
    http: reqwest::Client,
    token: AccessToken,
    from: Mailbox,
}

// Why one try failed, and whether trying again could help.
enum Failure {
    Retry(String),
    // The access token was refused: get a new one, then try again.
    Unauthorized,
    GiveUp(String),
}

impl Sender {
    async fn run(mut self, mut emails: mpsc::Receiver<Email>) {
        while let Some(email) = emails.recv().await {
            self.deliver(email).await;
        }
    }

    async fn deliver(&mut self, email: Email) {
        let raw = match mime(&self.from, &email) {
            Ok(raw) => raw,
            Err(e) => {
                tracing::error!(to = %email.to, error = %e, "email not sent: can't build the message");
                return;
            }
        };
        for attempt in 1..=TRIES {
            let reason = match self.try_send(&raw).await {
                Ok(()) => {
                    tracing::info!(to = %email.to, subject = %email.subject, "email sent");
                    return;
                }
                Err(Failure::GiveUp(reason)) => {
                    tracing::error!(to = %email.to, subject = %email.subject, %reason, "email not sent");
                    return;
                }
                Err(Failure::Unauthorized) => {
                    self.token.forget();
                    "access token refused".to_owned()
                }
                Err(Failure::Retry(reason)) => reason,
            };
            if attempt == TRIES {
                tracing::error!(to = %email.to, subject = %email.subject, %reason, "email not sent after {TRIES} tries");
                return;
            }
            tracing::warn!(to = %email.to, %reason, attempt, "email send failed; trying again");
            // 2s, then 8s.
            tokio::time::sleep(Duration::from_secs(2 * 4u64.pow(attempt - 1))).await;
        }
    }

    async fn try_send(&mut self, raw: &str) -> Result<(), Failure> {
        let token = self.token.get(&self.http).await.map_err(|e| match e {
            TokenError::Retry(r) => Failure::Retry(r),
            TokenError::GiveUp(r) => Failure::GiveUp(r),
        })?;
        let response = self
            .http
            .post(SEND_URL)
            .bearer_auth(token)
            .json(&serde_json::json!({ "raw": raw }))
            .send()
            .await
            .map_err(|e| Failure::Retry(e.to_string()))?;
        match response.status() {
            s if s.is_success() => Ok(()),
            StatusCode::UNAUTHORIZED => Err(Failure::Unauthorized),
            s => Err(failure(s, response.text().await.unwrap_or_default())),
        }
    }
}

// 429 and 5xx may pass on a later try; any other answer won't.
fn failure(status: StatusCode, body: String) -> Failure {
    let reason = format!("{status}: {body}");
    if retryable(status) {
        Failure::Retry(reason)
    } else {
        Failure::GiveUp(reason)
    }
}

/*
    The email as the Gmail API wants it: a MIME message, base64url
    encoded. lettre writes the headers, so a subject outside ASCII is
    encoded properly and a line break in one can't add a header. With
    HTML it is multipart/alternative: the plain text first, the HTML
    last (the one email apps prefer)
*/
fn mime(from: &Mailbox, email: &Email) -> Result<String, Box<dyn std::error::Error>> {
    let builder = Message::builder()
        .from(from.clone())
        .to(email.to.parse()?)
        // Replies reach MarkCliq's inbox, not the sending mailbox.
        .reply_to(crate::SUPPORT_EMAIL.parse()?)
        .subject(&email.subject);
    let message = match &email.html {
        Some(html) => builder.multipart(MultiPart::alternative_plain_html(
            email.body.clone(),
            html.clone(),
        ))?,
        None => builder
            .header(ContentType::TEXT_PLAIN)
            .body(email.body.clone())?,
    };
    Ok(URL_SAFE_NO_PAD.encode(message.formatted()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn email(subject: &str) -> Email {
        Email {
            html: None,
            to: "asha@example.com".into(),
            subject: subject.into(),
            body: "Your code is 123456.".into(),
        }
    }

    fn decoded(raw: &str) -> String {
        String::from_utf8(URL_SAFE_NO_PAD.decode(raw).unwrap()).unwrap()
    }

    #[test]
    fn mime_has_the_headers_and_body() {
        let from: Mailbox = "SolaCliq <support@solacliq.markcliq.com>".parse().unwrap();
        let text = decoded(&mime(&from, &email("Verify your email")).unwrap());
        assert!(text.contains("From: SolaCliq <support@solacliq.markcliq.com>"));
        assert!(text.contains("To: asha@example.com"));
        assert!(text.contains("Reply-To: info@markcliq.com"));
        assert!(text.contains("Subject: Verify your email"));
        assert!(text.contains("Content-Type: text/plain; charset=utf-8"));
        assert!(text.contains("Your code is 123456."));
    }

    #[test]
    fn with_html_both_parts_go_out() {
        let from: Mailbox = "support@solacliq.markcliq.com".parse().unwrap();
        let mut e = email("Verify your email");
        e.html = Some("<p>Your code is <b>123456</b></p>".into());
        let text = decoded(&mime(&from, &e).unwrap());
        assert!(text.contains("Content-Type: multipart/alternative"));
        let plain = text.find("Content-Type: text/plain").expect("a plain part");
        let html = text.find("Content-Type: text/html").expect("an html part");
        assert!(plain < html, "plain text first, HTML last");
    }

    #[test]
    fn a_line_break_in_the_subject_adds_no_header() {
        let from: Mailbox = "support@solacliq.markcliq.com".parse().unwrap();
        let text = decoded(&mime(&from, &email("Hi\r\nBcc: evil@example.com")).unwrap());
        assert!(!text.contains("\r\nBcc:"));
    }

    #[test]
    fn mime_refuses_a_bad_address() {
        let from: Mailbox = "support@solacliq.markcliq.com".parse().unwrap();
        let mut e = email("Hi");
        e.to = "not an address".into();
        assert!(mime(&from, &e).is_err());
    }
}
