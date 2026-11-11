//! Accounts and sessions (F1). Phase 1: sign up. Phase 2: log in. Codes,
//! refresh and log out arrive in phase 3.

use axum::{
    Json,
    extract::State,
    http::{HeaderValue, StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    AppState,
    error::{ApiError, ApiResult, FieldError},
    extract::{ApiJson, SESSION_COOKIE},
    password,
    routes::me::{self, Me},
    session::{self, Client},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(signup))
        .routes(routes!(login))
}

/// The request body. `Deserialize` lets serde build it from JSON; a missing
/// required field fails before our code runs (see `extract.rs`).
/// `Option<String>` means the field may be left out.
#[derive(Debug, Deserialize, ToSchema)]
pub struct SignupRequest {
    pub name: String,
    pub email: String,
    pub phone: Option<String>,
    pub password: String,
}

/// Create a customer account
///
/// Creates an unverified account and emails a 6-digit code. Always 202,
/// whether or not the email already has an account (no enumeration);
/// an existing account gets an "you already have an account" email.
#[utoipa::path(
    post,
    path = "/auth/signup",
    operation_id = "signup",
    tag = "auth",
    security(()),
    request_body = SignupRequest,
    responses(
        (status = 202, description = "Accepted; a code is on its way if the email is new."),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn signup(
    State(state): State<AppState>,
    ApiJson(req): ApiJson<SignupRequest>,
) -> ApiResult<StatusCode> {
    /*
        Validate all the input fields
            - phone, email, name
            if any error return 422
    */
    let input: ValidSignup = validate(req)?;

    let password_hash = password::hash(input.password).await?;

    /*
        Insert. ON CONFLICT DO NOTHING: if the email already exists,
        nothing happens and nothing fails, even with two sign-ups racing.
        $1, $2... are bound parameters: the values never become part of
        the SQL text, so there's no SQL injection.
    */
    let inserted = sqlx::query(
        "INSERT INTO users (id, email, name, phone, password_hash)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (email) DO NOTHING",
    )
    .bind(Uuid::now_v7())
    .bind(&input.email)
    .bind(&input.name)
    .bind(&input.phone)
    .bind(&password_hash)
    .execute(&state.db)
    .await? // a database error becomes a 500 HTTP Code Error
    .rows_affected()
        == 1;

    if inserted {
        tracing::info!(email = %input.email, "signup: new account");
    } else {
        tracing::info!(email = %input.email, "signup: email already has an account");
    }

    Ok(StatusCode::ACCEPTED)
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
    pub client: Client,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct LoginResponse {
    pub user: Me,
    /// Present for `client: app` only.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tokens: Option<TokenPair>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct TokenPair {
    pub access_token: String,
    /// Single use; the next refresh returns a new one.
    pub refresh_token: String,
    /// Seconds until the access token expires.
    pub access_expires_in: i64,
    /// Always "Bearer".
    pub token_type: &'static str,
}

/// Log in
///
/// `client: app` returns a token pair in the body. `client: web` sets
/// the session cookie and returns no tokens. Wrong email and wrong
/// password give the same `auth.invalid_credentials`; an unverified
/// account gets `account.email_unverified` only after the right
/// password. An account created for someone (by an agent or org admin)
/// that has no password yet gets 403 `account.password_not_set`.
#[utoipa::path(
    post,
    path = "/auth/login",
    operation_id = "login",
    tag = "auth",
    security(()),
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Logged in.", body = LoginResponse),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn login(
    State(state): State<AppState>,
    ApiJson(req): ApiJson<LoginRequest>,
) -> ApiResult<Response> {
    let email = req.email.trim().to_lowercase();
    if req.password.is_empty() || req.password.chars().count() > 128 {
        return Err(invalid_credentials());
    }

    /*
        find the account by email id
            - Option<> since it might not exist
    */
    let row: Option<(Uuid, Option<String>, bool)> = sqlx::query_as(
        "SELECT id, password_hash, email_verified_at IS NOT NULL
         FROM users WHERE email = $1",
    )
    .bind(&email)
    .fetch_optional(&state.db)
    .await?;

    /*
        extract parts from the above row, if None then we assign accordingly
    */
    let (user_id, stored_hash, verified) = match row {
        Some((id, hash, verified)) => (Some(id), hash, verified),
        None => (None, None, false),
    };

    if user_id.is_some() && stored_hash.is_none() {
        /*
            this case is when admin creates the user for their org
        */
        return Err(ApiError::new(
            StatusCode::FORBIDDEN,
            "account.password_not_set",
            "Set your password first",
        )
        .detail("Use \"Forgot password\" to set a password for this account."));
    }

    /*
        Verify password now, if error -> Invalid Creds
    */
    let ok = password::verify(req.password, stored_hash).await?;
    let Some(user_id) = user_id.filter(|_| ok) else {
        return Err(invalid_credentials());
    };

    /*
        if the password was right
            - check if the user if verified
                - YES -> continue
                - NO -> Ask them to verify by sending OTP
    */
    if !verified {
        return Err(ApiError::new(
            StatusCode::FORBIDDEN,
            "account.email_unverified",
            "Verify your email first",
        )
        .detail("Enter the 6-digit code we emailed you."));
    }

    /*
        Start a new session
    */
    let new = session::create(&state.db, &state.lifetimes, user_id, req.client).await?;
    let user = me::load(&state.db, user_id).await?;

    match req.client {
        Client::App => {
            let tokens = TokenPair {
                access_token: new.access_token,
                // `expect` is safe: app sessions always have one.
                refresh_token: new.refresh_token.expect("app session has a refresh token"),
                access_expires_in: new.access_ttl.num_seconds(),
                token_type: "Bearer",
            };
            Ok(Json(LoginResponse {
                user,
                tokens: Some(tokens),
            })
            .into_response())
        }
        Client::Web => {
            let mut res = Json(LoginResponse { user, tokens: None }).into_response();
            let cookie = session_cookie(&new.access_token, new.access_ttl, state.cookie_secure);
            res.headers_mut().insert(header::SET_COOKIE, cookie);
            Ok(res)
        }
    }
}

fn invalid_credentials() -> ApiError {
    ApiError::new(
        StatusCode::UNAUTHORIZED,
        "auth.invalid_credentials",
        "Wrong email or password",
    )
}

/// `solacliq_session=<token>; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200`.
/// HttpOnly: page scripts can't read it. SameSite=Lax: other sites can't
/// send it with their forms. Secure (production): HTTPS only.
fn session_cookie(token: &str, ttl: chrono::Duration, secure: bool) -> HeaderValue {
    let secure = if secure { "; Secure" } else { "" };
    let value = format!(
        "{SESSION_COOKIE}={token}; Path=/; HttpOnly; SameSite=Lax; Max-Age={}{secure}",
        ttl.num_seconds()
    );
    // The token is hex, so the header is always valid ASCII.
    HeaderValue::from_str(&value).expect("cookie is ASCII")
}

/// Sign-up input after checking: trimmed, email lowercased.
#[derive(Debug)]
struct ValidSignup {
    name: String,
    email: String,
    phone: Option<String>,
    password: String,
}

/// Collects every problem at once, so the app can mark all bad fields.
/// A weak password on its own gets the contract's own code,
/// `auth.password_too_weak`, which the app shows under the password field.
fn validate(req: SignupRequest) -> Result<ValidSignup, ApiError> {
    let name = req.name.trim().to_owned();
    let email = req.email.trim().to_lowercase();
    // `.filter(...)` turns Some("") into None: a blank phone means no phone.
    let phone = req
        .phone
        .map(|p| p.trim().to_owned())
        .filter(|p| !p.is_empty());

    let mut errors: Vec<FieldError> = Vec::new();
    if name.is_empty() || name.chars().count() > 100 {
        errors.push(field("name", "Enter your name (up to 100 characters)."));
    }
    if !looks_like_email(&email) {
        errors.push(field("email", "Enter a valid email address."));
    }
    if let Some(p) = &phone
        && !is_indian_mobile(p)
    {
        errors.push(field(
            "phone",
            "Enter a 10-digit mobile number, without +91.",
        ));
    }

    const WEAK: &str = "Use at least 8 characters, including a number.";
    let weak = !password::is_strong_enough(&req.password);
    if weak && errors.is_empty() {
        // Only the password is wrong: use its own code.
        return Err(ApiError::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "auth.password_too_weak",
            "Password too weak",
        )
        .detail(WEAK)
        .field("password", WEAK));
    }
    if weak {
        errors.push(field("password", WEAK));
    }
    if !errors.is_empty() {
        return Err(ApiError::validation(errors));
    }

    Ok(ValidSignup {
        name,
        email,
        phone,
        password: req.password,
    })
}

fn field(name: &str, message: &str) -> FieldError {
    FieldError {
        field: name.to_owned(),
        message: message.to_owned(),
    }
}

fn looks_like_email(email: &str) -> bool {
    let Some((local, domain)) = email.split_once('@') else {
        return false;
    };
    email.len() <= 254
        && !local.is_empty()
        && domain.contains('.')
        && !domain.starts_with('.')
        && !domain.ends_with('.')
        && !email.contains(char::is_whitespace)
        && !domain.contains('@')
}

/// `^[6-9][0-9]{9}$`.
fn is_indian_mobile(phone: &str) -> bool {
    phone.len() == 10
        && phone.starts_with(['6', '7', '8', '9'])
        && phone.chars().all(|c| c.is_ascii_digit())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn emails() {
        assert!(looks_like_email("asha@example.com"));
        assert!(!looks_like_email("asha@example"));
        assert!(!looks_like_email("@example.com"));
        assert!(!looks_like_email("asha @example.com"));
        assert!(!looks_like_email("a@b@example.com"));
    }

    #[test]
    fn phones() {
        assert!(is_indian_mobile("9876511223"));
        assert!(!is_indian_mobile("5876511223")); // starts with 5
        assert!(!is_indian_mobile("987651122")); // 9 digits
        assert!(!is_indian_mobile("+919876511"));
    }
}
