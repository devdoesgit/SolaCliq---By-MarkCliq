/*
    Safe retries for app writes (`Idempotency-Key` header)
    --------------------------------------------------------------------
    - the app sends a fresh UUID with each write and the same one when it
      retries after a lost response
    - the first request does the work and stores its response with the
      key, in the same transaction; a repeat gets that stored response and
      nothing happens twice
    - two requests racing with one key: both do the work in their own
      transaction; the second's insert of the key waits for the first to
      commit, then inserts nothing, so the second rolls back (no
      duplicate row, no email) and answers with the first one's response
    - a key belongs to one request ("POST /api/v1/quote-requests"); reusing
      it for another is 422 `idempotency.key_reused`

    How a handler uses it:
        if let Some(done) = idempotency::replay(&db, user, key, REQUEST).await? {
            return Ok(done);
        }
        let mut tx = db.begin().await?;
        ... the work ...
        if !idempotency::save(&mut tx, user, key, REQUEST, status, &body).await? {
            return idempotency::replay(&db, user, key, REQUEST).await?.ok_or_else(ApiError::internal);
        }
        tx.commit().await?;
*/

use axum::{
    Json,
    extract::FromRequestParts,
    http::{StatusCode, request::Parts},
    response::{IntoResponse, Response},
};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

use crate::error::{ApiError, ApiResult};

const HEADER: &str = "idempotency-key";

// The request's `Idempotency-Key`. Missing or not a UUID: 422.
#[derive(Debug, Clone, Copy)]
pub struct IdempotencyKey(pub Uuid);

impl<S: Send + Sync> FromRequestParts<S> for IdempotencyKey {
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, _: &S) -> Result<Self, ApiError> {
        parts
            .headers
            .get(HEADER)
            .and_then(|v| v.to_str().ok())
            .and_then(|v| Uuid::parse_str(v.trim()).ok())
            .map(IdempotencyKey)
            .ok_or_else(|| {
                ApiError::validation(Vec::new()).field(
                    "Idempotency-Key",
                    "Send a UUID, the same one on every retry.",
                )
            })
    }
}

/*
    The stored response for this key, if the request already ran. 422
    when the key was used for a different request
*/
pub async fn replay(
    db: &PgPool,
    user_id: Uuid,
    key: IdempotencyKey,
    request: &str,
) -> ApiResult<Option<Response>> {
    let row: Option<(String, i32, serde_json::Value)> = sqlx::query_as(
        "SELECT request, status, body FROM idempotency_keys WHERE user_id = $1 AND key = $2",
    )
    .bind(user_id)
    .bind(key.0)
    .fetch_optional(db)
    .await?;
    let Some((stored_request, status, body)) = row else {
        return Ok(None);
    };
    if stored_request != request {
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "idempotency.key_reused",
            "This Idempotency-Key belongs to another request",
        ));
    }
    let status = StatusCode::from_u16(status as u16).map_err(|_| ApiError::internal())?;
    Ok(Some((status, Json(body)).into_response()))
}

/*
    Stores the response with the key, inside the caller's transaction.
    false when another request with this key got there first: the caller
    drops its transaction and answers with `replay`
*/
pub async fn save(
    conn: &mut PgConnection,
    user_id: Uuid,
    key: IdempotencyKey,
    request: &str,
    status: StatusCode,
    body: &serde_json::Value,
) -> ApiResult<bool> {
    let saved = sqlx::query(
        "INSERT INTO idempotency_keys (user_id, key, request, status, body)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (user_id, key) DO NOTHING",
    )
    .bind(user_id)
    .bind(key.0)
    .bind(request)
    .bind(i32::from(status.as_u16()))
    .bind(body)
    .execute(conn)
    .await?
    .rows_affected()
        == 1;
    Ok(saved)
}
