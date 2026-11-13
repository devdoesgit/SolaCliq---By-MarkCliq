//! Login sessions: making tokens, storing their hashes, and finding the
//! session a token belongs to.

use chrono::{Duration, Utc};
use sha2::{Digest, Sha256};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::ApiError;

/// How long tokens last. Set from the environment by `Config`
/// (`ACCESS_TOKEN_MINUTES`, `REFRESH_TOKEN_DAYS`); `Default` holds the
/// values used when those aren't set. The same for the app and the website.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Lifetimes {
    pub access: Duration,
    pub refresh: Duration,
}

impl Default for Lifetimes {
    fn default() -> Self {
        Self {
            access: Duration::minutes(15),
            refresh: Duration::days(30),
        }
    }
}

// who is logging in. Matches the contract's `client: app | web`.
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

/// The plain tokens of a session, fresh from login or refresh. They exist
/// only in this value and in the response; the database keeps their hashes.
pub struct Tokens {
    pub access_token: String,
    pub refresh_token: String,
    pub access_ttl: Duration,
    pub refresh_ttl: Duration,
}

impl Tokens {
    fn new(lifetimes: &Lifetimes) -> Result<Self, ApiError> {
        Ok(Self {
            access_token: new_token()?,
            refresh_token: new_token()?,
            access_ttl: lifetimes.access,
            refresh_ttl: lifetimes.refresh,
        })
    }
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

/// Starts a session and returns its tokens.
pub async fn create(
    db: &PgPool,
    lifetimes: &Lifetimes,
    user_id: Uuid,
    client: Client,
) -> Result<Tokens, ApiError> {
    let now = Utc::now();
    let tokens = Tokens::new(lifetimes)?;
    sqlx::query(
        "INSERT INTO sessions
           (id, user_id, client, access_hash, access_expires_at, refresh_hash, refresh_expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)",
    )
    .bind(Uuid::now_v7())
    .bind(user_id)
    .bind(client.as_str())
    .bind(hash_token(&tokens.access_token))
    .bind(now + tokens.access_ttl)
    .bind(hash_token(&tokens.refresh_token))
    .bind(now + tokens.refresh_ttl)
    .execute(db)
    .await?;
    Ok(tokens)
}

/// Trades a refresh token for new tokens (OAuth 2.1 rotation): both tokens
/// are replaced, so the old refresh token and the old access token stop
/// working. Returns which client the session belongs to, so the caller
/// answers in JSON (app) or cookies (website).
///
/// Errors with 401 `auth.session_expired` when the token is unknown,
/// expired or revoked. If it is the session's *previous* refresh token,
/// someone kept a copy, so the session is revoked as well.
pub async fn rotate(
    db: &PgPool,
    lifetimes: &Lifetimes,
    refresh_token: &str,
) -> Result<(Tokens, Client), ApiError> {
    let now = Utc::now();
    let old = hash_token(refresh_token);
    // create new pair of token
    let tokens = Tokens::new(lifetimes)?;

    // One UPDATE does the check and the swap, so it is atomic: if two
    // requests bring the same token at once, Postgres locks the row, the
    // first one changes refresh_hash, and the second then matches nothing
    // and is treated as reuse below. The refresh expiry moves forward too,
    // so a person who opens the app at least once a month stays logged in.
    let rotated: Option<(String,)> = sqlx::query_as(
        "UPDATE sessions
         SET previous_refresh_hash = refresh_hash,
             refresh_hash = $2, refresh_expires_at = $3,
             access_hash = $4, access_expires_at = $5
         WHERE refresh_hash = $1
           AND revoked_at IS NULL
           AND refresh_expires_at > now()
         RETURNING client",
    )
    .bind(&old)
    .bind(hash_token(&tokens.refresh_token))
    .bind(now + tokens.refresh_ttl)
    .bind(hash_token(&tokens.access_token))
    .bind(now + tokens.access_ttl)
    .fetch_optional(db)
    .await?;

    if let Some(client) = rotated {
        let client = if client.0 == "web" {
            Client::Web
        } else {
            Client::App
        };
        return Ok((tokens, client));
    }

    /*
        Revoke logic: if old refresh token gets used
    */
    let reused: Option<(Uuid,)> = sqlx::query_as(
        "UPDATE sessions SET revoked_at = now(), revoked_reason = 'refresh_reuse'
         WHERE previous_refresh_hash = $1 AND revoked_at IS NULL
         RETURNING id",
    )
    .bind(&old)
    .fetch_optional(db)
    .await?;

    if let Some((session_id,)) = reused {
        tracing::warn!(%session_id, "old refresh token reused; session revoked");
    }
    Err(session_expired())
}

/*
    End a session
*/
pub async fn revoke(db: &PgPool, session_id: Uuid, reason: &str) -> Result<(), ApiError> {
    sqlx::query(
        "UPDATE sessions SET revoked_at = now(), revoked_reason = $2
         WHERE id = $1 AND revoked_at IS NULL",
    )
    .bind(session_id)
    .bind(reason)
    .execute(db)
    .await?;
    Ok(())
}

/// The refresh token is no good: the app logs out on this code.
pub fn session_expired() -> ApiError {
    ApiError::new(
        axum::http::StatusCode::UNAUTHORIZED,
        "auth.session_expired",
        "Log in again",
    )
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
