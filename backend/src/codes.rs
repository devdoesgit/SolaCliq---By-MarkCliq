/*
    6-digit codes sent by email (phase 3b)
    --------------------------------------------------------------------
    - used for: resetting (or first setting) an account's password, table
      email_codes. Sign-up's codes have no account yet: signup.rs, which
      shares the secret, the limits and the email
    - a code's life:
        1. issue: makes a code, stores its HMAC, returns the code to email
        2. check: counts a try and compares; a right code gives a `Checked`
        3. consume: deletes the code, inside the caller's transaction,
           together with the change the code allows (set the password),
           so both happen or neither does
*/

use std::{fmt, sync::Arc};

use axum::http::StatusCode;
use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

use crate::{
    PRODUCT_NAME,
    error::ApiError,
    mail::{
        Email,
        template::{self as t, EmailPage},
    },
};

// How long a code works.
pub const TTL_MINUTES: i32 = 5;
// Tries per code, right or wrong. The next one is refused with 429.
pub const MAX_ATTEMPTS: i32 = 5;
// No new code within this many seconds of the last one (no inbox flooding).
pub const COOLDOWN_SECONDS: i32 = 60;

// What a code is for, as its email words it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Purpose {
    SignUp,
    ResetPassword,
}

// `email_codes.purpose`: the one kind that belongs to an account.
const RESET: &str = "reset_password";

/*
    The key for the codes' HMAC (CODE_SECRET)
    --------------------------------------------------------------------
    - never stored in the database, so a copy of the database alone can't
      reverse a code
    - `Debug` is written by hand and prints no bytes, so anything that
      logs the config can't leak the secret
*/
#[derive(Clone)]
pub struct CodeSecret(Arc<[u8]>);

impl CodeSecret {
    // Shortest secret accepted. `openssl rand -hex 32` gives 64.
    pub const MIN_LEN: usize = 32;

    pub fn new(bytes: impl Into<Arc<[u8]>>) -> Self {
        Self(bytes.into())
    }

    // HMAC-SHA256 of `code` with this secret, ready to finish or compare.
    fn mac(&self, code: &str) -> Hmac<Sha256> {
        let mut mac =
            Hmac::<Sha256>::new_from_slice(&self.0).expect("HMAC accepts a key of any length");
        mac.update(code.as_bytes());
        mac
    }

    // What's stored for a code.
    pub(crate) fn hash(&self, code: &str) -> Vec<u8> {
        self.mac(code).finalize().into_bytes().to_vec()
    }

    // In constant time: how long it takes doesn't depend on how much matches.
    pub(crate) fn matches(&self, code: &str, hash: &[u8]) -> bool {
        self.mac(code).verify_slice(hash).is_ok()
    }
}

impl fmt::Debug for CodeSecret {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("CodeSecret(hidden)")
    }
}

/*
    Make a new code
    --------------------------------------------------------------------
    - replaces any earlier code for the same purpose: the old one stops
      working and the try count starts again
    - Some(code) -> email it
    - None -> a code went out less than COOLDOWN_SECONDS ago; nothing
      changed and nothing should be sent. Callers still answer 202, so
      the cooldown doesn't reveal whether the email has an account
*/
pub async fn issue(
    db: &PgPool,
    secret: &CodeSecret,
    user_id: Uuid,
) -> Result<Option<String>, ApiError> {
    let code = new_code()?;
    let hash = secret.hash(&code);

    /*
        the cooldown is the WHERE on the update: an existing row younger
        than the cooldown is left alone, so rows_affected is 0. One
        statement, so two requests at once can't both get past it
    */
    let stored = sqlx::query(
        "INSERT INTO email_codes (user_id, purpose, code_hash, expires_at)
         VALUES ($1, $2, $3, now() + $4 * interval '1 minute')
         ON CONFLICT (user_id, purpose) DO UPDATE
            SET code_hash = EXCLUDED.code_hash,
                attempts = 0,
                expires_at = EXCLUDED.expires_at,
                created_at = now()
          WHERE email_codes.created_at <= now() - $5 * interval '1 second'",
    )
    .bind(user_id)
    .bind(RESET)
    .bind(hash)
    .bind(TTL_MINUTES)
    .bind(COOLDOWN_SECONDS)
    .execute(db)
    .await?
    .rows_affected()
        == 1;

    if !stored {
        tracing::info!(%user_id, "code not sent: cooldown");
        return Ok(None);
    }
    Ok(Some(code))
}

/*
    Proof that a code was right. Only `check` makes one, so `consume`
    can't be called without checking first.
*/
#[derive(Debug)]
pub struct Checked {
    user_id: Uuid,
    hash: Vec<u8>,
}

impl Checked {
    pub fn user_id(&self) -> Uuid {
        self.user_id
    }
}

/*
    Count one try and compare the code
    --------------------------------------------------------------------
    - not 6 digits, wrong, no live code (none sent, expired, already
      used, tries used up), or no account for the email -> 400
      auth.code_invalid. One answer for all, so guesses can't tell an
      email with an account from one without: only some emails ever have
      a code, so "expired" or "tries used up" would give those away
      (QA-08, 2026-11-22). The app's wording covers every case
    - right -> Checked
*/
pub async fn check(
    db: &PgPool,
    secret: &CodeSecret,
    user_id: Option<Uuid>,
    code: &str,
) -> Result<Checked, ApiError> {
    if !is_six_digits(code) {
        return Err(code_invalid());
    }
    let Some(user_id) = user_id else {
        return Err(code_invalid());
    };

    /*
        count the try first, in its own statement (not in the caller's
        transaction), so a wrong guess stays counted even though the
        request then fails. `attempts < MAX` in the WHERE makes the limit
        hold even for guesses sent at the same moment
    */
    let row: Option<(Vec<u8>,)> = sqlx::query_as(
        "UPDATE email_codes SET attempts = attempts + 1
         WHERE user_id = $1 AND purpose = $2
           AND expires_at > now() AND attempts < $3
         RETURNING code_hash",
    )
    .bind(user_id)
    .bind(RESET)
    .bind(MAX_ATTEMPTS)
    .fetch_optional(db)
    .await?;

    // No row: no live code, or its tries are used up. Not told apart.
    let Some((hash,)) = row else {
        return Err(code_invalid());
    };

    if !secret.matches(code, &hash) {
        return Err(code_invalid());
    }
    Ok(Checked { user_id, hash })
}

/*
    Use up a checked code
    --------------------------------------------------------------------
    - deletes it, so it works once; run it inside the caller's transaction
    - matches on the hash, so a code replaced since `check` (a resend in
      between) isn't used up by mistake
    - that case, or another request using this code first ->
      400 auth.code_invalid, as every other bad code
*/
pub async fn consume(conn: &mut PgConnection, checked: Checked) -> Result<(), ApiError> {
    let deleted = sqlx::query(
        "DELETE FROM email_codes
         WHERE user_id = $1 AND purpose = $2 AND code_hash = $3",
    )
    .bind(checked.user_id)
    .bind(RESET)
    .bind(&checked.hash)
    .execute(conn)
    .await?
    .rows_affected();
    if deleted == 0 {
        return Err(code_invalid());
    }
    Ok(())
}

/*
    The email that carries a code: plain text and HTML. The look of the
    big services' code emails: the code large in a card, how long it
    lasts, a don't-share line. The only emails with the sun dot
*/
pub fn email(to: &str, purpose: Purpose, code: &str) -> Email {
    let (subject, heading, intro, reason) = match purpose {
        Purpose::SignUp => (
            format!("Your {PRODUCT_NAME} verification code"),
            "Verify your email",
            format!("Here is your {PRODUCT_NAME} verification code:"),
            format!(
                "You're receiving this email because this address was used to \
                 sign up for {PRODUCT_NAME}. If this wasn't you, ignore this email."
            ),
        ),
        Purpose::ResetPassword => (
            format!("Your {PRODUCT_NAME} password code"),
            "Set your password",
            format!("Here is your code to set your {PRODUCT_NAME} password:"),
            format!(
                "You're receiving this email because a password code was \
                 requested for your {PRODUCT_NAME} account. If this wasn't you, \
                 ignore this email: your password stays as it is."
            ),
        ),
    };
    let valid = format!("{TTL_MINUTES} minutes");
    let card = [
        t::para(&intro),
        t::code(code),
        t::para_html(&format!(
            "This code is valid for {} and can only be used once.",
            t::bold(&valid)
        )),
        t::para_html(&format!(
            "{} MarkCliq will never ask for it on the phone or on WhatsApp.",
            t::bold("Please don't share this code with anyone:")
        )),
        t::sign_off(),
    ]
    .concat();
    Email {
        to: to.to_owned(),
        subject,
        body: format!(
            "{intro} {code}\n\
             This code is valid for {valid} and can only be used once.\n\n\
             Please don't share this code with anyone: MarkCliq will never ask \
             for it on the phone or on WhatsApp.\n\n{}\n\n{reason}\n",
            t::sign_off_text()
        ),
        html: Some(t::page(EmailPage {
            preheader: None,
            sun_dot: true,
            badge: None,
            heading,
            card,
            note: Some(&reason),
        })),
    }
}

// A uniformly random 6-digit code, "000000" to "999999".
pub(crate) fn new_code() -> Result<String, ApiError> {
    /*
        4_294_000_000 is the largest multiple of 1,000,000 that fits in a
        u32. Draws at or above it are thrown away, so every code is equally
        likely (a plain `% 1_000_000` would favour low codes slightly)
    */
    const LIMIT: u32 = 4_294_000_000;
    loop {
        let mut bytes = [0u8; 4];
        getrandom::fill(&mut bytes).map_err(|e| {
            tracing::error!(error = %e, "no randomness");
            ApiError::internal()
        })?;
        let n = u32::from_le_bytes(bytes);
        if n < LIMIT {
            return Ok(format!("{:06}", n % 1_000_000));
        }
    }
}

pub(crate) fn is_six_digits(code: &str) -> bool {
    code.len() == 6 && code.bytes().all(|b| b.is_ascii_digit())
}

pub fn code_invalid() -> ApiError {
    ApiError::new(
        StatusCode::BAD_REQUEST,
        "auth.code_invalid",
        "Wrong or expired code",
    )
    .detail("Check the code, or request a new one.")
}

pub fn too_many_attempts() -> ApiError {
    ApiError::new(
        StatusCode::TOO_MANY_REQUESTS,
        "auth.too_many_attempts",
        "Too many tries",
    )
    .detail("Request a new code.")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn codes_are_six_digits() {
        for _ in 0..1000 {
            let code = new_code().unwrap();
            assert!(is_six_digits(&code), "{code}");
        }
    }

    #[test]
    fn format_check() {
        assert!(is_six_digits("004821"));
        assert!(!is_six_digits("48213"));
        assert!(!is_six_digits("4821300"));
        assert!(!is_six_digits("48a213"));
        assert!(!is_six_digits("４８２１３０")); // full-width digits
    }

    #[test]
    fn mac_depends_on_the_secret() {
        let a = CodeSecret::new(b"a".repeat(32)).mac("123456").finalize();
        let b = CodeSecret::new(b"b".repeat(32)).mac("123456").finalize();
        assert_ne!(a.into_bytes(), b.into_bytes());
    }

    #[test]
    fn debug_hides_the_secret() {
        let s = CodeSecret::new(b"supersecret".repeat(4));
        assert_eq!(format!("{s:?}"), "CodeSecret(hidden)");
    }
}
