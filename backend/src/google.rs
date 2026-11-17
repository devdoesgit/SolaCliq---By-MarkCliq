/*
    Signing in to Google APIs as a service account
    --------------------------------------------------------------------
    - shared by the Gmail mailer (`mail/gmail.rs`) and push notifications
      (`push.rs`); each has its own key file, allowed one thing
    - how a token is made: a JWT signed with the service account's key,
      swapped at Google's token endpoint for an access token that lasts
      an hour. `AccessToken` keeps it and reuses it until a minute before
      it expires
*/

use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use base64::{
    Engine,
    engine::general_purpose::{STANDARD, URL_SAFE_NO_PAD},
};
use reqwest::StatusCode;
use ring::{
    rand::SystemRandom,
    signature::{RSA_PKCS1_SHA256, RsaKeyPair},
};
use serde::Deserialize;

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
    // The Google Cloud project the key belongs to (FCM's URL needs it).
    project_id: String,
    key: RsaKeyPair,
}

// The fields of Google's key file that signing in needs.
#[derive(Deserialize)]
struct KeyFile {
    client_email: String,
    token_uri: String,
    #[serde(default)]
    project_id: String,
    private_key: String,
}

impl ServiceAccount {
    pub fn from_file(path: &std::path::Path) -> Result<Self, KeyError> {
        Self::from_json(&std::fs::read_to_string(path)?)
    }

    pub fn from_json(json: &str) -> Result<Self, KeyError> {
        let file: KeyFile = serde_json::from_str(json)?;
        let der = pem_body(&file.private_key).ok_or(KeyError::PrivateKey)?;
        let key = RsaKeyPair::from_pkcs8(&der).map_err(|_| KeyError::PrivateKey)?;
        Ok(Self {
            client_email: file.client_email,
            token_uri: file.token_uri,
            project_id: file.project_id,
            key,
        })
    }

    pub fn project_id(&self) -> &str {
        &self.project_id
    }

    /*
        The signed JWT that asks Google for an access token for `scope`,
        acting as `subject` when set (domain-wide delegation's `sub`)
    */
    fn assertion(&self, scope: &str, subject: Option<&str>, now: u64) -> String {
        let header = URL_SAFE_NO_PAD.encode(br#"{"alg":"RS256","typ":"JWT"}"#);
        let mut claims = serde_json::json!({
            "iss": self.client_email,
            "scope": scope,
            "aud": self.token_uri,
            "iat": now,
            "exp": now + 3600,
        });
        if let Some(subject) = subject {
            claims["sub"] = subject.into();
        }
        let claims = URL_SAFE_NO_PAD.encode(claims.to_string());
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

// Why getting a token failed, and whether trying again could help.
#[derive(Debug)]
pub enum TokenError {
    Retry(String),
    GiveUp(String),
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

/*
    An access token for one scope, kept between calls
    --------------------------------------------------------------------
    - `get` returns the kept one, or asks Google for a new one when it's
      missing or nearly expired
    - `forget` after an API answers 401, so the next `get` makes a new one
*/
pub struct AccessToken {
    account: ServiceAccount,
    scope: &'static str,
    subject: Option<String>,
    token: Option<(String, Instant)>,
}

impl AccessToken {
    pub fn new(account: ServiceAccount, scope: &'static str, subject: Option<String>) -> Self {
        Self {
            account,
            scope,
            subject,
            token: None,
        }
    }

    pub fn account(&self) -> &ServiceAccount {
        &self.account
    }

    pub fn forget(&mut self) {
        self.token = None;
    }

    pub async fn get(&mut self, http: &reqwest::Client) -> Result<String, TokenError> {
        if let Some((token, until)) = &self.token
            && Instant::now() < *until
        {
            return Ok(token.clone());
        }
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let assertion = self
            .account
            .assertion(self.scope, self.subject.as_deref(), now);
        let response = http
            .post(&self.account.token_uri)
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", assertion.as_str()),
            ])
            .send()
            .await
            .map_err(|e| TokenError::Retry(e.to_string()))?;
        let status = response.status();
        if !status.is_success() {
            /*
                Usually setup: for Gmail, `unauthorized_client` means
                domain-wide delegation for gmail.send isn't granted to
                this service account; `invalid_grant` that MAIL_FROM
                isn't a user
            */
            let body = response.text().await.unwrap_or_default();
            let reason = format!("token endpoint: {status}: {body}");
            return Err(if retryable(status) {
                TokenError::Retry(reason)
            } else {
                TokenError::GiveUp(reason)
            });
        }
        let t: TokenResponse = response
            .json()
            .await
            .map_err(|e| TokenError::Retry(format!("token endpoint: {e}")))?;
        let until = Instant::now() + Duration::from_secs(t.expires_in.saturating_sub(60));
        self.token = Some((t.access_token.clone(), until));
        Ok(t.access_token)
    }
}

// 429 and 5xx may pass on a later try; any other answer won't.
pub fn retryable(status: StatusCode) -> bool {
    status == StatusCode::TOO_MANY_REQUESTS || status.is_server_error()
}

#[cfg(test)]
mod tests {
    use super::*;

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
