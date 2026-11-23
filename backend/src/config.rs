//! Settings from environment variables. `.env.example` lists them all.

use std::{net::SocketAddr, path::PathBuf};

use chrono::Duration;

use crate::{bank::BankKey, codes::CodeSecret, session::Lifetimes};

#[derive(Debug, Clone)]
pub struct Config {
    // Which kind of server this is (APP_ENV). See `Environment`.
    pub environment: Environment,
    /*
        The owner's login (DATABASE_URL): migrations, the seed and admin
        commands. The same variable sqlx's tests and tools read
    */
    pub database_url: String,
    /*
        The login the server answers requests with (APP_DATABASE_URL):
        `solacliq_api`, restricted by row-level security. `serve` refuses
        to start if it could bypass that (main.rs)
    */
    pub app_database_url: String,
    pub bind_addr: SocketAddr,
    pub db_max_connections: u32,
    /// JSON log lines (production) instead of human-readable ones.
    pub log_json: bool,
    /// Mark the website's cookie `Secure` (HTTPS only). Off for local HTTP.
    pub cookie_secure: bool,
    // Delete KYC past its retention (F18). Off: only count what is due.
    pub kyc_retention: bool,
    /// How long access and refresh tokens last.
    pub session_lifetimes: Lifetimes,
    // Key for the email codes' HMAC. Required, at least 32 characters.
    pub code_secret: CodeSecret,
    /*
        Where MarkCliq is told about new company registrations
        (REVIEW_EMAIL). Required: a registration nobody hears about
        would wait forever
    */
    pub review_email: String,
    // Key for bank account numbers (BANK_KEY): 64 hex characters.
    pub bank_key: BankKey,
    /*
        Sending email through the Gmail API. None: emails only go to the
        log, which `from_env` allows in development only
    */
    pub gmail: Option<GmailConfig>,
    /*
        Cloudflare R2, for uploads (the four R2_* variables). None:
        `POST /uploads` answers 503, which `from_env` allows in
        development only
    */
    pub storage: Option<crate::storage::Storage>,
    /*
        The Firebase service account key for push notifications
        (FCM_SERVICE_ACCOUNT_KEY_FILE). None: pushes only go to the log,
        which `from_env` allows in development only
    */
    pub fcm_key_file: Option<PathBuf>,
}

/*
    Gmail API settings
    --------------------------------------------------------------------
    - MAIL_FROM: who emails come from, e.g.
      `SolaCliq <support@solacliq.markcliq.com>`. Must be a Workspace user:
      the server sends as that user
    - GOOGLE_SERVICE_ACCOUNT_KEY_FILE: path to the service account's JSON
      key. The account needs domain-wide delegation for the gmail.send
      scope (see docs/architecture.md, "Email")
*/
#[derive(Debug, Clone)]
pub struct GmailConfig {
    pub from: lettre::message::Mailbox,
    pub key_file: PathBuf,
}

/*
    Development or production (APP_ENV)
    --------------------------------------------------------------------
    - unset means production: a server that forgot to say is treated as
      the real one, so development-only tools (the seed) stay off
    - `.env.example` sets development for local work
*/
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Environment {
    Development,
    Production,
}

impl std::str::FromStr for Environment {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "development" => Ok(Environment::Development),
            "production" => Ok(Environment::Production),
            other => Err(format!("\"{other}\"; use development or production")),
        }
    }
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
            environment: parsed("APP_ENV", "production")?,
            database_url: required("DATABASE_URL")?,
            app_database_url: required("APP_DATABASE_URL")?,
            bind_addr: parsed("BIND_ADDR", "127.0.0.1:8080")?,
            db_max_connections: parsed("DB_MAX_CONNECTIONS", "10")?,
            log_json: parsed("LOG_JSON", "false")?,
            cookie_secure: parsed("COOKIE_SECURE", "true")?,
            kyc_retention: parsed("KYC_RETENTION", "false")?,
            session_lifetimes: lifetimes_from_env()?,
            code_secret: code_secret_from_env()?,
            review_email: review_email_from_env()?,
            bank_key: BankKey::from_hex(&required("BANK_KEY")?).ok_or_else(|| {
                ConfigError::Invalid(
                    "BANK_KEY",
                    "use 64 hex characters (openssl rand -hex 32)".into(),
                )
            })?,
            gmail: gmail_from_env()?,
            storage: storage_from_env()?,
            fcm_key_file: std::env::var("FCM_SERVICE_ACCOUNT_KEY_FILE")
                .ok()
                .filter(|v| !v.trim().is_empty())
                .map(PathBuf::from),
        })
        .and_then(Self::check_mail)
        .and_then(Self::check_storage)
        .and_then(Self::check_push)
    }

    /*
        A production server must really send email: with only the log,
        sign-up codes would reach nobody
    */
    fn check_mail(self) -> Result<Self, ConfigError> {
        if self.environment == Environment::Production && self.gmail.is_none() {
            return Err(ConfigError::Missing(
                "MAIL_FROM (production sends email through the Gmail API)",
            ));
        }
        Ok(self)
    }

    // A production server must really send push notifications.
    fn check_push(self) -> Result<Self, ConfigError> {
        if self.environment == Environment::Production && self.fcm_key_file.is_none() {
            return Err(ConfigError::Missing(
                "FCM_SERVICE_ACCOUNT_KEY_FILE (production sends push notifications)",
            ));
        }
        Ok(self)
    }

    // A production server must store the photos and documents it's sent.
    fn check_storage(self) -> Result<Self, ConfigError> {
        if self.environment == Environment::Production && self.storage.is_none() {
            return Err(ConfigError::Missing(
                "R2_ACCOUNT_ID (production stores uploads in R2)",
            ));
        }
        Ok(self)
    }
}

/*
    All four R2 settings, or none
    --------------------------------------------------------------------
    - R2_ACCOUNT_ID, R2_BUCKET: where (not secret)
    - R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY: an R2 API token's S3 key
      pair, limited to that one bucket with Object Read & Write
*/
fn storage_from_env() -> Result<Option<crate::storage::Storage>, ConfigError> {
    const KEYS: [&str; 4] = [
        "R2_ACCOUNT_ID",
        "R2_BUCKET",
        "R2_ACCESS_KEY_ID",
        "R2_SECRET_ACCESS_KEY",
    ];
    let values: Vec<Option<String>> = KEYS
        .iter()
        .map(|k| std::env::var(k).ok().filter(|v| !v.trim().is_empty()))
        .collect();
    if values.iter().all(Option::is_none) {
        return Ok(None);
    }
    if let Some(i) = values.iter().position(Option::is_none) {
        return Err(ConfigError::Missing(KEYS[i]));
    }
    let [account, bucket, key_id, secret] =
        <[Option<String>; 4]>::try_from(values).expect("four values");
    Ok(Some(crate::storage::Storage::new(
        account.unwrap().trim().to_owned(),
        bucket.unwrap().trim().to_owned(),
        key_id.unwrap().trim().to_owned(),
        secret.unwrap().trim().to_owned(),
    )))
}

// Both settings, or neither (emails go to the log).
fn gmail_from_env() -> Result<Option<GmailConfig>, ConfigError> {
    let from = std::env::var("MAIL_FROM").ok().filter(|v| !v.is_empty());
    let key_file = std::env::var("GOOGLE_SERVICE_ACCOUNT_KEY_FILE")
        .ok()
        .filter(|v| !v.is_empty());
    match (from, key_file) {
        (None, None) => Ok(None),
        (Some(_), None) => Err(ConfigError::Missing("GOOGLE_SERVICE_ACCOUNT_KEY_FILE")),
        (None, Some(_)) => Err(ConfigError::Missing("MAIL_FROM")),
        (Some(from), Some(key_file)) => Ok(Some(GmailConfig {
            from: from.parse().map_err(|e: lettre::address::AddressError| {
                ConfigError::Invalid("MAIL_FROM", e.to_string())
            })?,
            key_file: key_file.into(),
        })),
    }
}

fn review_email_from_env() -> Result<String, ConfigError> {
    let email = crate::validate::normalize_email(&required("REVIEW_EMAIL")?);
    if !crate::validate::looks_like_email(&email) {
        return Err(ConfigError::Invalid(
            "REVIEW_EMAIL",
            "not an email address".into(),
        ));
    }
    Ok(email)
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
