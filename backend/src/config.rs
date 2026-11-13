//! Settings from environment variables. `.env.example` lists them all.

use std::net::SocketAddr;

use chrono::Duration;

use crate::{codes::CodeSecret, session::Lifetimes};

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub bind_addr: SocketAddr,
    pub db_max_connections: u32,
    /// JSON log lines (production) instead of human-readable ones.
    pub log_json: bool,
    /// Mark the website's cookie `Secure` (HTTPS only). Off for local HTTP.
    pub cookie_secure: bool,
    /// How long access and refresh tokens last.
    pub session_lifetimes: Lifetimes,
    // Key for the email codes' HMAC. Required, at least 32 characters.
    pub code_secret: CodeSecret,
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("{0} is not set")]
    Missing(&'static str),
    #[error("{0} is not valid: {1}")]
    Invalid(&'static str, String),
}

impl Config {
    pub fn from_env() -> Result<Self, ConfigError> {
        Ok(Self {
            database_url: required("DATABASE_URL")?,
            bind_addr: parsed("BIND_ADDR", "127.0.0.1:8080")?,
            db_max_connections: parsed("DB_MAX_CONNECTIONS", "10")?,
            log_json: parsed("LOG_JSON", "false")?,
            cookie_secure: parsed("COOKIE_SECURE", "true")?,
            session_lifetimes: lifetimes_from_env()?,
            code_secret: code_secret_from_env()?,
        })
    }
}

/*
    Required, with no default: a default secret would be the same on
    every server that forgot to set one
*/
fn code_secret_from_env() -> Result<CodeSecret, ConfigError> {
    let raw = required("CODE_SECRET")?;
    if raw.len() < CodeSecret::MIN_LEN {
        return Err(ConfigError::Invalid(
            "CODE_SECRET",
            format!(
                "use at least {} characters (openssl rand -hex 32)",
                CodeSecret::MIN_LEN
            ),
        ));
    }
    Ok(CodeSecret::new(raw.into_bytes()))
}

/// Each lifetime in its natural unit, so `.env` reads plainly. Unset means
/// the default in `Lifetimes::default()`.
fn lifetimes_from_env() -> Result<Lifetimes, ConfigError> {
    let d = Lifetimes::default();
    let lifetimes = Lifetimes {
        access: duration(
            "ACCESS_TOKEN_MINUTES",
            d.access.num_minutes(),
            Duration::try_minutes,
        )?,
        refresh: duration(
            "REFRESH_TOKEN_DAYS",
            d.refresh.num_days(),
            Duration::try_days,
        )?,
    };
    // An access token outliving its refresh token makes refresh pointless.
    if lifetimes.access >= lifetimes.refresh {
        return Err(ConfigError::Invalid(
            "ACCESS_TOKEN_MINUTES",
            "must be shorter than REFRESH_TOKEN_DAYS".into(),
        ));
    }
    Ok(lifetimes)
}

/// A whole number above 0, turned into a Duration by `unit`
/// (`Duration::try_minutes` etc., which return None instead of panicking
/// on a number too big to fit).
fn duration(
    key: &'static str,
    default: i64,
    unit: fn(i64) -> Option<Duration>,
) -> Result<Duration, ConfigError> {
    let n: i64 = parsed(key, &default.to_string())?;
    if n <= 0 {
        return Err(ConfigError::Invalid(key, "must be more than 0".into()));
    }
    unit(n).ok_or_else(|| ConfigError::Invalid(key, "too large".into()))
}

fn required(key: &'static str) -> Result<String, ConfigError> {
    std::env::var(key).map_err(|_| ConfigError::Missing(key))
}

fn parsed<T: std::str::FromStr>(key: &'static str, default: &str) -> Result<T, ConfigError>
where
    T::Err: std::fmt::Display,
{
    let raw = std::env::var(key).unwrap_or_else(|_| default.to_owned());
    raw.parse()
        .map_err(|e: T::Err| ConfigError::Invalid(key, e.to_string()))
}
