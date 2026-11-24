/*
    Accounts and sessions (F1)
    --------------------------------------------------------------------
    - phase 1: sign up
    - phase 2: log in
    - phase 3a: refresh and log out
    - phase 3b: email codes (forgot and reset password)
    - code-first sign-up (2026-11-22, QA-27): email → code → details
*/

use axum::{
    Json,
    body::Bytes,
    extract::State,
    http::{HeaderMap, HeaderValue, StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};
use uuid::Uuid;

use crate::{
    API_PREFIX, AppState, PRODUCT_NAME,
    codes::{self, Purpose},
    error::{ApiError, ApiResult, FieldError},
    extract::{ApiJson, AuthUser, REFRESH_COOKIE, SESSION_COOKIE, cookie},
    mail::{
        Email,
        template::{self as t, Badge, EmailPage, Tone},
    },
    password,
    routes::me::{self, Me},
    session::{self, Client, Tokens},
    signup,
    terms::{self, Agreement, Document, Source},
};
use crate::{
    rate_limit::{ClientIp, Rule},
    validate::{is_indian_mobile, looks_like_email, normalize_email},
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(start_signup))
        .routes(routes!(verify_signup))
        .routes(routes!(complete_signup))
        .routes(routes!(login))
        .routes(routes!(refresh))
        .routes(routes!(logout))
        .routes(routes!(forgot_password))
        .routes(routes!(reset_password))
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct EmailRequest {
    pub email: String,
}

/*
    Sign up, step 1: the email alone
    --------------------------------------------------------------------
    - nothing else is taken, so there's nothing a stranger could plant
      on someone's email (QA-27). Another code is this same request
    - always 202. An email whose account has a password gets a notice
      instead of a code; its step 2 then fails like a wrong code
    - an account made for someone (no password yet) gets a code: proving
      the inbox is all that "set up" needs too
*/
#[utoipa::path(
    post,
    path = "/auth/signup",
    operation_id = "signup",
    tag = "auth",
    security(()),
    request_body = EmailRequest,
    responses(
        (status = 202, description = "Accepted; a code is on its way if the email can sign up."),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn start_signup(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<EmailRequest>,
) -> ApiResult<StatusCode> {
    state.limits.check(Rule::SignupByIp, &ip.0)?;
    let email = normalize_email(&req.email);
    // Checked first: it becomes a key, a row and an address to send to.
    if !looks_like_email(&email) {
        return Err(ApiError::validation(vec![field(
            "email",
            "Enter a valid email address.",
        )]));
    }
    // Before the lookup, so the 429 is the same with or without an account.
    state
        .limits
        .check(Rule::CodeEmailByEmail, &format!("signup:{email}"))?;

    let has_password: Option<bool> =
        sqlx::query_scalar("SELECT password_hash IS NOT NULL FROM users WHERE email = $1")
            .bind(&email)
            .fetch_optional(&state.db)
            .await?;
    if has_password == Some(true) {
        // At most one an hour per address: sign-up can't flood an inbox.
        if state.limits.allow(Rule::AlreadyRegisteredByEmail, &email) {
            state.mailer.send(already_registered_email(&email));
        }
    } else if let Some(code) = signup::issue(&state.db, &state.code_secret, &email).await? {
        state
            .mailer
            .send(codes::email(&email, Purpose::SignUp, &code));
    }
    Ok(StatusCode::ACCEPTED)
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct VerifySignupRequest {
    pub email: String,
    // 6 digits, from the email.
    pub code: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct SignupSetup {
    // Single use, for step 3.
    pub signup_token: String,
    // Seconds it works for.
    pub expires_in: i64,
}

/*
    Sign up, step 2: the code
    --------------------------------------------------------------------
    - right code -> a one-time setup token, 15 minutes
    - codes last 5 minutes and allow 5 tries; past either, or with no
      code at all, the answer is the same as a wrong code
*/
#[utoipa::path(
    post,
    path = "/auth/signup/verify",
    operation_id = "verifySignup",
    tag = "auth",
    security(()),
    request_body = VerifySignupRequest,
    responses(
        (status = 200, description = "The inbox is proven.", body = SignupSetup),
        (status = 400, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn verify_signup(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<VerifySignupRequest>,
) -> ApiResult<Json<SignupSetup>> {
    state.limits.check(Rule::CodeCheckByIp, &ip.0)?;
    let email = normalize_email(&req.email);
    let signup_token = signup::prove(&state.db, &state.code_secret, &email, &req.code).await?;
    Ok(Json(SignupSetup {
        signup_token,
        expires_in: i64::from(signup::TOKEN_MINUTES) * 60,
    }))
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct CompleteSignupRequest {
    pub signup_token: String,
    pub name: String,
    pub phone: Option<String>,
    pub password: String,
    /// The version of the terms the person ticked (F16, `terms.rs`).
    /// Optional here so a missing one gets its own error code.
    #[schema(required = true, minimum = 1)]
    pub terms_version: Option<i32>,
}

/*
    Sign up, step 3: the details, with the token
    --------------------------------------------------------------------
    - the fields are checked first, so a typo doesn't use up the token
    - in one transaction: the token is used, the account is made (or the
      one someone made for them completed) with what was sent here, and
      the agreement to the terms is recorded (F16)
    - never over a password: if one was set meanwhile, 400
    - answers as an app login
*/
#[utoipa::path(
    post,
    path = "/auth/signup/complete",
    operation_id = "completeSignup",
    tag = "auth",
    security(()),
    request_body = CompleteSignupRequest,
    responses(
        (status = 200, description = "Created and logged in.", body = LoginResponse),
        (status = 400, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn complete_signup(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<CompleteSignupRequest>,
) -> ApiResult<Json<LoginResponse>> {
    state.limits.check(Rule::CodeCheckByIp, &ip.0)?;
    let input = validate(&req)?;
    let terms_version = terms::check_sent(req.terms_version)?;
    // Before the transaction: Argon2 is slow on purpose.
    let password_hash = password::hash(req.password).await?;

    let mut tx = state.db.begin().await?;
    let email = signup::claim(&mut tx, &req.signup_token)
        .await?
        .ok_or_else(signup_expired)?;
    let user_id: Uuid = sqlx::query_scalar(
        "INSERT INTO users (id, email, name, phone, password_hash, email_verified_at)
         VALUES ($1, $2, $3, $4, $5, now())
         ON CONFLICT (email) DO UPDATE
            SET name = EXCLUDED.name,
                phone = EXCLUDED.phone,
                password_hash = EXCLUDED.password_hash,
                email_verified_at = now(),
                updated_at = now()
          WHERE users.password_hash IS NULL
         RETURNING id",
    )
    .bind(Uuid::now_v7())
    .bind(&email)
    .bind(&input.name)
    .bind(&input.phone)
    .bind(&password_hash)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(signup_expired)?;
    terms::record(
        &mut tx,
        Agreement {
            user_id,
            document: Document::Terms,
            org_id: None,
            version: terms_version,
            source: Source::Signup,
            ip: &ip,
        },
    )
    .await?;
    tx.commit().await?;
    tracing::info!(%user_id, "sign-up completed");

    let tokens = session::create(&state.db, &state.lifetimes, user_id, Client::App).await?;
    let user = me::load(&state.db, state.storage.as_ref(), user_id).await?;
    Ok(Json(LoginResponse {
        user,
        tokens: Some(tokens.into()),
    }))
}

fn signup_expired() -> ApiError {
    ApiError::new(
        StatusCode::BAD_REQUEST,
        "auth.signup_expired",
        "Start signing up again",
    )
    .detail("This took too long, or the account is already set up.")
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
    // Single use; the next refresh returns a new one.
    pub refresh_token: String,
    // Seconds until the access token expires.
    pub access_expires_in: i64,
    // "Bearer".
    pub token_type: &'static str,
}

/*
    Log in
    --------------------------------------------------------------------
    `client: app` returns a token pair in the body.
    `client: web` sets the access and refresh cookies and returns no tokens
    every refusal is the same `auth.invalid_credentials`, after the same
    Argon2 work: no account, a wrong password, or an account made for
    someone that has no password yet. So log in can't show who has an
    account or who was invited (QA-28)
*/
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
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn login(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<LoginRequest>,
) -> ApiResult<Response> {
    state.limits.check(Rule::LoginByIp, &ip.0)?;
    let email = normalize_email(&req.email);
    // Before it becomes a rate-limit key: no email is longer.
    if email.len() > 254 {
        return Err(invalid_credentials());
    }
    state.limits.check(Rule::LoginByEmail, &email)?;
    if req.password.is_empty() || req.password.chars().count() > 128 {
        return Err(invalid_credentials());
    }

    /*
        find the account by email id
            - Option<> since it might not exist
            - a password only exists on a verified email (the database's
              CHECK), so there is no unverified case
    */
    let row: Option<(Uuid, Option<String>)> =
        sqlx::query_as("SELECT id, password_hash FROM users WHERE email = $1")
            .bind(&email)
            .fetch_optional(&state.db)
            .await?;
    let (user_id, stored_hash) = row.map_or((None, None), |(id, hash)| (Some(id), hash));

    // With no hash it still does the work, against a dummy (password.rs).
    let ok = password::verify(req.password, stored_hash).await?;
    let Some(user_id) = user_id.filter(|_| ok) else {
        return Err(invalid_credentials());
    };

    /*
        Start a new session
    */
    let tokens = session::create(&state.db, &state.lifetimes, user_id, req.client).await?;
    let user = me::load(&state.db, state.storage.as_ref(), user_id).await?;

    match req.client {
        Client::App => Ok(Json(LoginResponse {
            user,
            tokens: Some(tokens.into()),
        })
        .into_response()),
        Client::Web => {
            let mut res = Json(LoginResponse { user, tokens: None }).into_response();
            set_cookies(&mut res, &tokens, state.cookie_secure);
            Ok(res)
        }
    }
}

/// The app's refresh request. The website sends no body: its refresh token
/// is the `solacliq_refresh` cookie.
#[derive(Debug, Deserialize, ToSchema)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

/*
    Get new token

    OAuth 2.1 rotation: returns a new access token *and* a new refresh
    token, and the old refresh token stops working. Reusing an old refresh
    token revokes the login. Either way a dead refresh token gets 401
    `auth.session_expired`, and the client logs out.

    The app sends `{ "refresh_token": ... }` and gets a `TokenPair`. The
    website sends its `solacliq_refresh` cookie, no body, and gets 204 with
    new cookies.
*/
#[utoipa::path(
    post,
    path = "/auth/refresh",
    operation_id = "refreshSession",
    tag = "auth",
    security(()),
    request_body(content = Option<RefreshRequest>, description = "App only."),
    responses(
        (status = 200, description = "New tokens (app).", body = TokenPair),
        (status = 204, description = "New cookies set (website)."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn refresh(
    State(state): State<AppState>,
    headers: HeaderMap,
    /*
        the raw body, because the website sends none: `ApiJson` would
        reject that before this function ran
    */
    body: Bytes,
) -> ApiResult<Response> {
    /*
        where the refresh token comes from
            - app: the JSON body
            - website: the refresh cookie
        neither -> nothing to refresh, log in again
    */
    let from_body = serde_json::from_slice::<RefreshRequest>(&body)
        .ok()
        .map(|r| r.refresh_token);
    let token = from_body
        .or_else(|| cookie(&headers, REFRESH_COOKIE).map(str::to_owned))
        .ok_or_else(session::session_expired)?;

    /*
        swap both tokens; answer the way the session logged in
    */
    let (tokens, client) = session::rotate(&state.db, &state.lifetimes, &token).await?;
    match client {
        Client::App => Ok(Json(TokenPair::from(tokens)).into_response()),
        Client::Web => {
            let mut res = StatusCode::NO_CONTENT.into_response();
            set_cookies(&mut res, &tokens, state.cookie_secure);
            Ok(res)
        }
    }
}

/// Log out of this session
///
/// Revokes the session, so its access and refresh tokens stop working at
/// once. The website's cookies are cleared too.
#[utoipa::path(
    post,
    path = "/auth/logout",
    operation_id = "logout",
    tag = "auth",
    responses(
        (status = 204, description = "Logged out."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn logout(State(state): State<AppState>, user: AuthUser) -> ApiResult<Response> {
    session::revoke(&state.db, user.session_id, "logout").await?;
    let mut res: axum::http::Response<axum::body::Body> = StatusCode::NO_CONTENT.into_response();
    // Harmless for the app, which has no cookies.
    let headers = res.headers_mut();
    headers.append(header::SET_COOKIE, clear_cookie(SESSION_COOKIE, "/"));
    headers.append(
        header::SET_COOKIE,
        clear_cookie(REFRESH_COOKIE, &refresh_path()),
    );
    Ok(res)
}

/*
    Email a password reset or set-up code
    --------------------------------------------------------------------
    - any account, verified or not, with or without a password (an account
      an agent or admin created sets its first password this way)
    - always 202, so it can't be used to find out who has an account
*/
#[utoipa::path(
    post,
    path = "/auth/password/forgot",
    operation_id = "forgotPassword",
    tag = "auth",
    security(()),
    request_body = EmailRequest,
    responses(
        (status = 202, description = "Accepted."),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn forgot_password(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<EmailRequest>,
) -> ApiResult<StatusCode> {
    state.limits.check(Rule::CodeEmailByIp, &ip.0)?;
    let email = normalize_email(&req.email);
    if !looks_like_email(&email) {
        return Ok(StatusCode::ACCEPTED);
    }
    // Before the lookup, so the 429 is the same with or without an account.
    state
        .limits
        .check(Rule::CodeEmailByEmail, &format!("reset:{email}"))?;
    if let Some(user_id) = find_user(&state.db, &email).await?
        && let Some(code) = codes::issue(&state.db, &state.code_secret, user_id).await?
    {
        state
            .mailer
            .send(codes::email(&email, Purpose::ResetPassword, &code));
    }
    Ok(StatusCode::ACCEPTED)
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct ResetPasswordRequest {
    pub email: String,
    // 6 digits, from the email.
    pub code: String,
    pub new_password: String,
}

/*
    Set a new password with the reset code
    --------------------------------------------------------------------
    - weak password -> 422, checked first so it doesn't use up a try
    - right code -> new password, and every session of the account ends
      (whoever had the old password is logged out everywhere)
    - the code came to the inbox, so this also verifies the email
*/
#[utoipa::path(
    post,
    path = "/auth/password/reset",
    operation_id = "resetPassword",
    tag = "auth",
    security(()),
    request_body = ResetPasswordRequest,
    responses(
        (status = 204, description = "Password changed; log in again."),
        (status = 400, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 429, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn reset_password(
    State(state): State<AppState>,
    ip: ClientIp,
    ApiJson(req): ApiJson<ResetPasswordRequest>,
) -> ApiResult<StatusCode> {
    state.limits.check(Rule::CodeCheckByIp, &ip.0)?;
    if !password::is_strong_enough(&req.new_password) {
        return Err(password_too_weak("new_password"));
    }
    let email = normalize_email(&req.email);
    let user_id = find_user(&state.db, &email).await?;
    let checked = codes::check(&state.db, &state.code_secret, user_id, &req.code).await?;

    /*
        hash before the transaction: Argon2 is slow on purpose, and the
        transaction should hold its locks as briefly as possible
    */
    let password_hash = password::hash(req.new_password).await?;

    let user_id = checked.user_id();
    let mut tx = state.db.begin().await?;
    codes::consume(&mut tx, checked).await?;
    sqlx::query(
        "UPDATE users SET password_hash = $2,
                          email_verified_at = COALESCE(email_verified_at, now()),
                          updated_at = now()
         WHERE id = $1",
    )
    .bind(user_id)
    .bind(&password_hash)
    .execute(&mut *tx)
    .await?;
    session::revoke_all(&mut tx, user_id, "password_reset").await?;
    tx.commit().await?;

    tracing::info!(%user_id, "password reset; all sessions ended");
    Ok(StatusCode::NO_CONTENT)
}

// The account with this (already normalized) email, if any.
async fn find_user(db: &sqlx::PgPool, email: &str) -> ApiResult<Option<Uuid>> {
    Ok(sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
        .bind(email)
        .fetch_optional(db)
        .await?)
}

fn already_registered_email(to: &str) -> Email {
    let intro = format!(
        "Someone just tried to sign up to {PRODUCT_NAME} with {to}, which \
         already has an account."
    );
    let was_me = "Log in with this email. Forgot your password? Tap \
                  \"Forgot password?\" on the log in screen and we'll email you a code.";
    let not_me = "Ignore this email. Nothing has changed, and no one can get \
                  in without your password.";
    let note = "You're receiving this email because someone tried to sign up \
                with this address.";
    Email {
        to: to.to_owned(),
        subject: format!("You already have a {PRODUCT_NAME} account"),
        body: format!(
            "{intro}\n\nIt was me: {was_me}\n\nIt wasn't me: {not_me}\n\n{}\n\n{note}\n",
            t::sign_off_text()
        ),
        html: Some(t::page(EmailPage {
            preheader: Some("Someone tried to sign up with your email. Your account is safe."),
            sun_dot: false,
            badge: Some(Badge {
                glyph: "@",
                tone: Tone::Sun,
            }),
            heading: "You already have an account",
            card: [
                t::para(&intro),
                t::callout(Tone::Success, "It was me", was_me),
                t::callout(Tone::Ink, "It wasn't me", not_me),
                t::sign_off(),
            ]
            .concat(),
            note: Some(note),
        })),
    }
}

// 422 `auth.password_too_weak`, shown under `field`.
fn password_too_weak(field: &str) -> ApiError {
    ApiError::new(
        StatusCode::UNPROCESSABLE_ENTITY,
        "auth.password_too_weak",
        "Password too weak",
    )
    .detail(WEAK_PASSWORD)
    .field(field, WEAK_PASSWORD)
}

const WEAK_PASSWORD: &str = "Use at least 8 characters, including a number.";

impl From<Tokens> for TokenPair {
    fn from(t: Tokens) -> Self {
        TokenPair {
            access_token: t.access_token,
            refresh_token: t.refresh_token,
            access_expires_in: t.access_ttl.num_seconds(),
            token_type: "Bearer",
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

/// The website's two cookies, both HttpOnly (page scripts can't read
/// them), SameSite=Lax (other sites can't send them with their forms) and,
/// in production, Secure (HTTPS only).
///
/// - `solacliq_session`: the access token, sent on every request.
/// - `solacliq_refresh`: the refresh token, sent only to `/auth/refresh`,
///   so normal requests never carry the long-lived token.
fn set_cookies(res: &mut Response, tokens: &Tokens, secure: bool) {
    let headers = res.headers_mut();
    headers.append(
        header::SET_COOKIE,
        cookie_header(
            SESSION_COOKIE,
            &tokens.access_token,
            "/",
            tokens.access_ttl.num_seconds(),
            secure,
        ),
    );
    headers.append(
        header::SET_COOKIE,
        cookie_header(
            REFRESH_COOKIE,
            &tokens.refresh_token,
            &refresh_path(),
            tokens.refresh_ttl.num_seconds(),
            secure,
        ),
    );
}

/// Tells the browser to delete a cookie (same name and path, Max-Age=0).
pub(crate) fn clear_cookie(name: &str, path: &str) -> HeaderValue {
    cookie_header(name, "", path, 0, false)
}

pub(crate) fn refresh_path() -> String {
    format!("{API_PREFIX}/auth/refresh")
}

fn cookie_header(name: &str, value: &str, path: &str, max_age: i64, secure: bool) -> HeaderValue {
    let secure = if secure { "; Secure" } else { "" };
    let value =
        format!("{name}={value}; Path={path}; HttpOnly; SameSite=Lax; Max-Age={max_age}{secure}");
    // Tokens are hex, so the header is always valid ASCII.
    HeaderValue::from_str(&value).expect("cookie is ASCII")
}

/// Step 3's input after checking: trimmed.
#[derive(Debug)]
struct ValidSignup {
    name: String,
    phone: Option<String>,
}

/// Collects every problem at once, so the app can mark all bad fields.
/// A weak password on its own gets the contract's own code,
/// `auth.password_too_weak`, which the app shows under the password field.
fn validate(req: &CompleteSignupRequest) -> Result<ValidSignup, ApiError> {
    let name = req.name.trim().to_owned();
    // `.filter(...)` turns Some("") into None: a blank phone means no phone.
    let phone = req
        .phone
        .as_deref()
        .map(str::trim)
        .filter(|p| !p.is_empty())
        .map(str::to_owned);

    let mut errors: Vec<FieldError> = Vec::new();
    if name.is_empty() || name.chars().count() > 100 {
        errors.push(field("name", "Enter your name (up to 100 characters)."));
    }
    if let Some(p) = &phone
        && !is_indian_mobile(p)
    {
        errors.push(field(
            "phone",
            "Enter a 10-digit mobile number, without +91.",
        ));
    }

    let weak = !password::is_strong_enough(&req.password);
    if weak && errors.is_empty() {
        // Only the password is wrong: use its own code.
        return Err(password_too_weak("password"));
    }
    if weak {
        errors.push(field("password", WEAK_PASSWORD));
    }
    if !errors.is_empty() {
        return Err(ApiError::validation(errors));
    }

    Ok(ValidSignup { name, phone })
}

fn field(name: &str, message: &str) -> FieldError {
    FieldError {
        field: name.to_owned(),
        message: message.to_owned(),
    }
}
