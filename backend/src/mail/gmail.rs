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
        1. an access token: a JWT signed with the service account's key,
           swapped at Google's token endpoint for a token that lasts an
           hour. Kept and reused until a minute before it expires
        2. the email as a MIME message, base64url-encoded, posted to
           users/me/messages/send
        3. a network error, 429 or 5xx is tried again (3 tries in all);
           a 401 drops the token and tries again with a new one; any
           other answer is logged and the email dropped
    - never logs an email's body: it can hold a sign-in code
*/

use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use base64::{
    Engine,
    engine::general_purpose::{STANDARD, URL_SAFE_NO_PAD},
};
use lettre::message::{Mailbox, Message, MultiPart, header::ContentType};
use reqwest::StatusCode;
use ring::{
    rand::SystemRandom,
    signature::{RSA_PKCS1_SHA256, RsaKeyPair},
};
use serde::Deserialize;
use tokio::{sync::mpsc, task::JoinHandle};

use super::{Email, Mailer};

const SCOPE: &str = "https://www.googleapis.com/auth/gmail.send";
const SEND_URL: &str = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send";
/*
    Emails waiting to be sent. Far more than a burst of sign-ups makes;
    past this, `send` drops the email and logs it rather than let memory
    grow without bound
*/
const QUEUE_LEN: usize = 1000;
const TRIES: u32 = 3;

#[derive(Debug, thiserror::Error)]
pub enum KeyError {
    #[error("can't read the service account key file: {0}")]
    Read(#[from] std::io::Error),
    #[error("the file is not a service account key: {0}")]
    Json(#[from] serde_json::Error),
    #[error("the service account key's private_key is not a PKCS#8 RSA key")]
    PrivateKey,
}

/*
    The service account, from its JSON key file
    --------------------------------------------------------------------
    - no Debug: the private key must never reach a log
*/
pub struct ServiceAccount {
    client_email: String,
    token_uri: String,
    key: RsaKeyPair,
}

// The fields of Google's key file that signing in needs.
#[derive(Deserialize)]
struct KeyFile {
    client_email: String,
    token_uri: String,
    private_key: String,
}

impl ServiceAccount {
    pub fn from_file(path: &std::path::Path) -> Result<Self, KeyError> {
        Self::from_json(&std::fs::read_to_string(path)?)
    }

    fn from_json(json: &str) -> Result<Self, KeyError> {
        let file: KeyFile = serde_json::from_str(json)?;
        let der = pem_body(&file.private_key).ok_or(KeyError::PrivateKey)?;
        let key = RsaKeyPair::from_pkcs8(&der).map_err(|_| KeyError::PrivateKey)?;
        Ok(Self {
            client_email: file.client_email,
            token_uri: file.token_uri,
            key,
        })
    }

    /*
        The signed JWT that asks Google for an access token, acting as
        `sender` (domain-wide delegation's `sub`)
    */
    fn assertion(&self, sender: &str, now: u64) -> String {
        let header = URL_SAFE_NO_PAD.encode(br#"{"alg":"RS256","typ":"JWT"}"#);
        let claims = URL_SAFE_NO_PAD.encode(
            serde_json::json!({
                "iss": self.client_email,
                "sub": sender,
                "scope": SCOPE,
                "aud": self.token_uri,
                "iat": now,
                "exp": now + 3600,
            })
            .to_string(),
        );
        let signed = format!("{header}.{claims}");
        let mut signature = vec![0; self.key.public().modulus_len()];
        self.key
            .sign(
                &RSA_PKCS1_SHA256,
                &SystemRandom::new(),
                signed.as_bytes(),
                &mut signature,
            )
            // Only fails if `signature` is the wrong length, set above.
            .expect("RSA signing");
        format!("{signed}.{}", URL_SAFE_NO_PAD.encode(signature))
    }
}

// The bytes between a PEM's BEGIN and END lines.
fn pem_body(pem: &str) -> Option<Vec<u8>> {
    let body: String = pem
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with("-----"))
        .collect();
    STANDARD.decode(body).ok()
}

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
        let sender = Sender {
            http,
            account,
            from,
            token: None,
        };
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
    account: ServiceAccount,
    from: Mailbox,
    // The access token and when to stop using it.
    token: Option<(String, Instant)>,
}

// Why one try failed, and whether trying again could help.
enum Failure {
    Retry(String),
    // The access token was refused: get a new one, then try again.
    Unauthorized,
    GiveUp(String),
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
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
                    self.token = None;
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
        let token = self.access_token().await?;
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

    // The kept access token, or a new one if it's missing or nearly expired.
    async fn access_token(&mut self) -> Result<String, Failure> {
        if let Some((token, until)) = &self.token
            && Instant::now() < *until
        {
            return Ok(token.clone());
        }
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let assertion = self.account.assertion(self.from.email.as_ref(), now);
        let response = self
            .http
            .post(&self.account.token_uri)
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", assertion.as_str()),
            ])
            .send()
            .await
            .map_err(|e| Failure::Retry(e.to_string()))?;
        let status = response.status();
        if !status.is_success() {
            /*
                Usually setup: `unauthorized_client` means domain-wide
                delegation for gmail.send isn't granted to this service
                account; `invalid_grant` that MAIL_FROM isn't a user
            */
            let body = response.text().await.unwrap_or_default();
            return Err(failure(status, format!("token endpoint: {body}")));
        }
        let t: TokenResponse = response
            .json()
            .await
            .map_err(|e| Failure::Retry(format!("token endpoint: {e}")))?;
        let until = Instant::now() + Duration::from_secs(t.expires_in.saturating_sub(60));
        self.token = Some((t.access_token.clone(), until));
        Ok(t.access_token)
    }
}

// 429 and 5xx may pass on a later try; any other answer won't.
fn failure(status: StatusCode, body: String) -> Failure {
    let reason = format!("{status}: {body}");
    if status == StatusCode::TOO_MANY_REQUESTS || status.is_server_error() {
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

    #[test]
    fn pem_body_skips_the_armour() {
        let pem = "-----BEGIN PRIVATE KEY-----\nAAEC\nAwQ=\n-----END PRIVATE KEY-----\n";
        assert_eq!(pem_body(pem).unwrap(), vec![0, 1, 2, 3, 4]);
    }

    #[test]
    fn a_key_file_without_an_rsa_key_is_refused() {
        let json = r#"{"client_email":"a@b.iam.gserviceaccount.com",
            "token_uri":"https://oauth2.googleapis.com/token",
            "private_key":"-----BEGIN PRIVATE KEY-----\nAAEC\n-----END PRIVATE KEY-----\n"}"#;
        assert!(matches!(
            ServiceAccount::from_json(json),
            Err(KeyError::PrivateKey)
        ));
    }
}
