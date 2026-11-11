//! Login sessions: making tokens, storing their hashes, and finding the
//! session a token belongs to.

use chrono::{Duration, Utc};
use sha2::{Digest, Sha256};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::ApiError;

/// How long tokens last. Set from the environment by `Config`
/// (`ACCESS_TOKEN_MINUTES`, `REFRESH_TOKEN_DAYS`, `WEB_SESSION_HOURS`);
/// `Default` holds the values used when those aren't set.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Lifetimes {
    /// An app's access token, before it must be refreshed.
    pub access: Duration,
    /// How long an app stays logged in without being opened.
    pub refresh: Duration,
    /// The website's cookie.
    pub web: Duration,
}

impl Default for Lifetimes {
    fn default() -> Self {
        Self {
            access: Duration::minutes(15),
            refresh: Duration::days(30),
            web: Duration::hours(12),
        }
    }
}

/// Who is logging in. Matches the contract's `client: app | web`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Deserialize, utoipa::ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum Client {
    App,
    Web,
}

impl Client {
    fn as_str(self) -> &'static str {
        match self {
            Client::App => "app",
            Client::Web => "web",
        }
    }
}

/// The plain tokens of a new session. They exist only in this value and in
/// the response; the database keeps their hashes.
pub struct NewSession {
    pub access_token: String,
    /// `None` for the website.
    pub refresh_token: Option<String>,
    pub access_ttl: Duration,
}

/// 32 random bytes as 64 hex characters. Unguessable, so a fast hash
/// (SHA-256) is enough to store it; passwords need Argon2 because people
/// pick guessable ones.
fn new_token() -> Result<String, ApiError> {
    let mut bytes = [0u8; 32];
    getrandom::fill(&mut bytes).map_err(|e| {
        tracing::error!(error = %e, "no randomness");
        ApiError::internal()
    })?;
    Ok(bytes.iter().map(|b| format!("{b:02x}")).collect())
}

/// What the database stores and looks tokens up by.
pub fn hash_token(token: &str) -> Vec<u8> {
    Sha256::digest(token.as_bytes()).to_vec()
}

pub async fn create(
    db: &PgPool,
    lifetimes: &Lifetimes,
    user_id: Uuid,
    client: Client,
) -> Result<NewSession, ApiError> {
    let now = Utc::now();
    let access_token = new_token()?;
    let (access_ttl, refresh_token) = match client {
        Client::App => (lifetimes.access, Some(new_token()?)),
        Client::Web => (lifetimes.web, None),
    };

    sqlx::query(
        "INSERT INTO sessions
           (id, user_id, client, access_hash, access_expires_at, refresh_hash, refresh_expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(client.as_str())
    .bind(hash_token(&access_token))
    .bind(now + access_ttl)
    // `.as_deref()` turns Option<String> into Option<&str>; `.map(...)`
    // hashes it only when there is one. None is stored as NULL.
    .bind(refresh_token.as_deref().map(hash_token))
    .bind(refresh_token.as_ref().map(|_| now + lifetimes.refresh))
    .execute(db)
    .await?;

    Ok(NewSession {
        access_token,
        refresh_token,
        access_ttl,
    })
}

/// The live session an access token or cookie belongs to:
/// (session id, user id). `None` when unknown, expired or revoked.
pub async fn find(db: &PgPool, token: &str) -> Result<Option<(Uuid, Uuid)>, ApiError> {
    let row = sqlx::query_as(
        "SELECT id, user_id FROM sessions
         WHERE access_hash = $1
           AND revoked_at IS NULL
           AND access_expires_at > now()",
    )
    .bind(hash_token(token))
    .fetch_optional(db) // Ok(None) when no row matches, instead of an error
    .await?;
    Ok(row)
}
