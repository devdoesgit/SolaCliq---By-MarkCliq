//! Errors as RFC 9457 problem details (`application/problem+json`), matching
//! `Problem` in ../api/openapi.yaml. The app reads `code`; `detail` is safe
//! to show to the user.

use axum::{
    Json,
    http::{StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::Serialize;
use utoipa::ToSchema;

const PROBLEM_BASE: &str = "https://solacliq.markcliq.com/problems/";

#[derive(Debug, Serialize, ToSchema)]
pub struct FieldError {
    pub field: String,
    pub message: String,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct Problem {
    /// Link to the code's description, `<base>/<code>`.
    pub r#type: String,
    pub title: String,
    pub status: u16,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
    /// Machine-readable, `<area>.<reason>`.
    pub code: String,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub errors: Vec<FieldError>,
}

/// What a handler returns on failure. Build with the constructors, e.g.
/// `ApiError::new(StatusCode::CONFLICT, "expense.limit_exceeded", "Over the limit")`.
#[derive(Debug)]
pub struct ApiError {
    status: StatusCode,
    code: &'static str,
    title: &'static str,
    detail: Option<String>,
    errors: Vec<FieldError>,
}

pub type ApiResult<T> = Result<T, ApiError>;

impl ApiError {
    pub fn new(status: StatusCode, code: &'static str, title: &'static str) -> Self {
        Self {
            status,
            code,
            title,
            detail: None,
            errors: Vec::new(),
        }
    }

    pub fn detail(mut self, detail: impl Into<String>) -> Self {
        self.detail = Some(detail.into());
        self
    }

    /// Adds a per-field message, shown under that field in the app.
    pub fn field(mut self, field: &str, message: impl Into<String>) -> Self {
        self.errors.push(FieldError {
            field: field.to_owned(),
            message: message.into(),
        });
        self
    }

    /// No valid access token or cookie. The app refreshes and retries.
    pub fn unauthenticated() -> Self {
        Self::new(
            StatusCode::UNAUTHORIZED,
            "auth.unauthenticated",
            "Log in to continue",
        )
    }

    pub fn not_found() -> Self {
        Self::new(StatusCode::NOT_FOUND, "common.not_found", "Not found")
    }

    pub fn validation(errors: Vec<FieldError>) -> Self {
        Self {
            errors,
            ..Self::new(
                StatusCode::UNPROCESSABLE_ENTITY,
                "validation.failed",
                "Check the highlighted fields",
            )
        }
    }

    pub fn internal() -> Self {
        Self::new(
            StatusCode::INTERNAL_SERVER_ERROR,
            "common.internal",
            "Something went wrong",
        )
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = Problem {
            r#type: format!("{PROBLEM_BASE}{}", self.code),
            title: self.title.to_owned(),
            status: self.status.as_u16(),
            detail: self.detail,
            code: self.code.to_owned(),
            errors: self.errors,
        };
        (
            self.status,
            [(header::CONTENT_TYPE, "application/problem+json")],
            Json(body),
        )
            .into_response()
    }
}

/// Database errors are logged and never shown: the client gets a plain 500.
impl From<sqlx::Error> for ApiError {
    fn from(e: sqlx::Error) -> Self {
        match e {
            sqlx::Error::RowNotFound => Self::not_found(),
            e => {
                tracing::error!(error = %e, "database error");
                Self::internal()
            }
        }
    }
}
