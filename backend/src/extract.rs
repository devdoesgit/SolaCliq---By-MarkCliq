//! Our own versions of axum's extractors, so that a bad request gets the
//! same problem-JSON error as everything else instead of axum's plain text.

use axum::{extract::FromRequest, extract::rejection::JsonRejection};

use crate::error::ApiError;

/// Use `ApiJson<T>` instead of `axum::Json<T>` for request bodies.
///
/// `#[derive(FromRequest)]` writes the extractor for us: it runs
/// `axum::Json<T>` (the `via`), and when that fails (body isn't JSON, a
/// required field is missing...) it turns the error into an `ApiError`
/// with the `From` impl below (the `rejection`).
#[derive(FromRequest)]
#[from_request(via(axum::Json), rejection(ApiError))]
pub struct ApiJson<T>(pub T);

impl From<JsonRejection> for ApiError {
    fn from(rejection: JsonRejection) -> Self {
        // body_text() says what was wrong, e.g. "missing field `email`".
        ApiError::validation(Vec::new()).detail(rejection.body_text())
    }
}

/// The logged-in person. Put `user: AuthUser` in a handler's arguments and
/// the handler only runs for a valid session; otherwise axum answers 401
/// `auth.unauthenticated` without calling it.
///
/// The token comes from `Authorization: Bearer <token>` (the app) or the
/// `solacliq_session` cookie (the website).
#[derive(Debug, Clone, Copy)]
pub struct AuthUser {
    pub user_id: uuid::Uuid,
    pub session_id: uuid::Uuid,
}

/// The website's access token cookie, sent on every request.
pub const SESSION_COOKIE: &str = "solacliq_session";
/// The website's refresh token cookie, sent only to `/auth/refresh`.
pub const REFRESH_COOKIE: &str = "solacliq_refresh";

impl axum::extract::FromRequestParts<crate::AppState> for AuthUser {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut axum::http::request::Parts,
        state: &crate::AppState,
    ) -> Result<Self, Self::Rejection> {
        let token = bearer_token(&parts.headers)
            .or_else(|| cookie(&parts.headers, SESSION_COOKIE))
            .ok_or_else(ApiError::unauthenticated)?;
        let (session_id, user_id) = crate::session::find(&state.db, token)
            .await?
            .ok_or_else(ApiError::unauthenticated)?;
        Ok(AuthUser {
            user_id,
            session_id,
        })
    }
}

/// `Authorization: Bearer abc` → `Some("abc")`.
fn bearer_token(headers: &axum::http::HeaderMap) -> Option<&str> {
    headers
        .get(axum::http::header::AUTHORIZATION)?
        .to_str()
        .ok()?
        .strip_prefix("Bearer ")
        .filter(|t| !t.is_empty())
}

/// `cookie(headers, "solacliq_session")` with
/// `Cookie: a=1; solacliq_session=abc` → `Some("abc")`.
pub fn cookie<'a>(headers: &'a axum::http::HeaderMap, name: &str) -> Option<&'a str> {
    headers
        .get_all(axum::http::header::COOKIE)
        .iter()
        .filter_map(|v| v.to_str().ok())
        .flat_map(|v| v.split(';'))
        .find_map(|pair| {
            let (key, value) = pair.trim().split_once('=')?;
            (key == name && !value.is_empty()).then_some(value)
        })
}
