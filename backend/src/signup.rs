/*
    An email being proven, before any account exists (F1, code first)
    --------------------------------------------------------------------
    1. issue: a 6-digit code for the email, kept as an HMAC
    2. prove: the right code gives a one-time setup token, kept as a hash
    3. claim: the token gives back the email it proved, inside the
       transaction that makes the account, so both happen or neither
    - keyed by email, never by account: nothing here can be inherited,
      and an email with an account answers like one without
    - asking for another code doesn't cancel a token: else anyone could
      keep someone from finishing by typing their email
*/

use sqlx::{PgConnection, PgPool};

use crate::{
    codes::{self, CodeSecret},
    error::ApiError,
    session,
};

// How long the setup token works.
pub const TOKEN_MINUTES: i32 = 15;

// A new code to email, or None within a minute of the last one.
pub async fn issue(
    db: &PgPool,
    secret: &CodeSecret,
    email: &str,
) -> Result<Option<String>, ApiError> {
    // What was abandoned: anyone can type an email, so rows mustn't pile up.
    sqlx::query(
        "DELETE FROM signups
         WHERE created_at < now() - interval '1 day'
           AND (token_expires_at IS NULL OR token_expires_at < now())",
    )
    .execute(db)
    .await?;

    let code = codes::new_code()?;
    let stored = sqlx::query(
        "INSERT INTO signups (email, code_hash, expires_at)
         VALUES ($1, $2, now() + $3 * interval '1 minute')
         ON CONFLICT (email) DO UPDATE
            SET code_hash = EXCLUDED.code_hash,
                attempts = 0,
                expires_at = EXCLUDED.expires_at,
                created_at = now()
          WHERE signups.created_at <= now() - $4 * interval '1 second'",
    )
    .bind(email)
    .bind(secret.hash(&code))
    .bind(codes::TTL_MINUTES)
    .bind(codes::COOLDOWN_SECONDS)
    .execute(db)
    .await?
    .rows_affected()
        == 1;
    Ok(stored.then_some(code))
}

/*
    The right code → a setup token
    --------------------------------------------------------------------
    - the try is counted first, in its own statement, so a wrong guess
      stays counted (as in codes.rs)
    - every refusal is the same `auth.code_invalid`
    - the code is used up by the statement that stores the token
*/
pub async fn prove(
    db: &PgPool,
    secret: &CodeSecret,
    email: &str,
    code: &str,
) -> Result<String, ApiError> {
    if !codes::is_six_digits(code) {
        return Err(codes::code_invalid());
    }
    let hash: Option<Vec<u8>> = sqlx::query_scalar(
        "UPDATE signups SET attempts = attempts + 1
         WHERE email = $1 AND code_hash IS NOT NULL
           AND expires_at > now() AND attempts < $2
         RETURNING code_hash",
    )
    .bind(email)
    .bind(codes::MAX_ATTEMPTS)
    .fetch_optional(db)
    .await?;
    let hash = hash
        .filter(|hash| secret.matches(code, hash))
        .ok_or_else(codes::code_invalid)?;

    let token = session::new_token()?;
    let used = sqlx::query(
        "UPDATE signups
         SET code_hash = NULL,
             token_hash = $3,
             token_expires_at = now() + $4 * interval '1 minute'
         WHERE email = $1 AND code_hash = $2",
    )
    .bind(email)
    .bind(&hash)
    .bind(session::hash_token(&token))
    .bind(TOKEN_MINUTES)
    .execute(db)
    .await?
    .rows_affected();
    // Another request used it, or replaced it, first.
    if used == 0 {
        return Err(codes::code_invalid());
    }
    Ok(token)
}

// The email a live token proved; the token is gone once the caller commits.
pub async fn claim(conn: &mut PgConnection, token: &str) -> Result<Option<String>, ApiError> {
    Ok(sqlx::query_scalar(
        "DELETE FROM signups
         WHERE token_hash = $1 AND token_expires_at > now()
         RETURNING email",
    )
    .bind(session::hash_token(token))
    .fetch_optional(conn)
    .await?)
}
