//! Password rules and hashing. Passwords are never stored or logged; only
//! the Argon2id hash is.

use std::sync::LazyLock;

use argon2::{
    Argon2,
    password_hash::{PasswordHasher, PasswordVerifier, phc::PasswordHash},
};

use crate::error::ApiError;

/// The contract's rule: 8 to 128 characters, at least one a number.
pub fn is_strong_enough(password: &str) -> bool {
    let len = password.chars().count();
    (8..=128).contains(&len) && password.chars().any(|c| c.is_ascii_digit())
}

/// Hashes a password with a fresh random salt

/// Argon2 is slow on purpose (that's what makes stolen hashes hard to
/// crack), so it runs on tokio's blocking thread pool. Doing it directly in
/// an async handler would stall every other request on that thread.
pub async fn hash(password: String) -> Result<String, ApiError> {
    tokio::task::spawn_blocking(move || {
        Argon2::default()
            .hash_password(password.as_bytes())
            .map(|h| h.to_string())
    })
    .await
    // Two things can fail: the thread itself (`.await`) and the hashing.
    // Neither should happen; log it and answer 500.
    .map_err(|e| {
        tracing::error!(error = %e, "hash task failed");
        ApiError::internal()
    })?
    .map_err(|e| {
        tracing::error!(error = %e, "hashing failed");
        ApiError::internal()
    })
}

/// A hash of nothing in particular, checked when the email has no account,
/// so "no such email" takes as long as "wrong password". Made once, on the
/// first login (`LazyLock` runs the closure the first time it's used).
static DUMMY_HASH: LazyLock<String> = LazyLock::new(|| {
    Argon2::default()
        .hash_password(b"not-a-real-password-0")
        .expect("hashing a constant")
        .to_string()
});

/// Whether `password` matches the stored hash. With no hash (unknown
/// email), checks against a dummy and returns false, taking the same time.
pub async fn verify(password: String, stored: Option<String>) -> Result<bool, ApiError> {
    tokio::task::spawn_blocking(move || {
        let real = stored.is_some();
        let hash = stored.unwrap_or_else(|| DUMMY_HASH.clone());
        let Ok(parsed) = PasswordHash::new(&hash) else {
            tracing::error!("stored password hash is not a valid PHC string");
            return false;
        };
        let matches = Argon2::default()
            .verify_password(password.as_bytes(), &parsed)
            .is_ok();
        real && matches
    })
    .await
    .map_err(|e| {
        tracing::error!(error = %e, "verify task failed");
        ApiError::internal()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strength() {
        assert!(is_strong_enough("sunlight1"));
        assert!(!is_strong_enough("short1")); // under 8
        assert!(!is_strong_enough("no-numbers-here")); // no digit
        assert!(!is_strong_enough(&"a1".repeat(65))); // 130, over 128
    }

    #[tokio::test]
    async fn hashes_are_salted() {
        let a = hash("sunlight1".into()).await.unwrap();
        let b = hash("sunlight1".into()).await.unwrap();
        assert!(a.starts_with("$argon2id$"));
        assert_ne!(a, b, "same password, different salt, different hash");
    }

    #[tokio::test]
    async fn verifies() {
        let h = hash("sunlight1".into()).await.unwrap();
        assert!(verify("sunlight1".into(), Some(h.clone())).await.unwrap());
        assert!(!verify("sunlight2".into(), Some(h)).await.unwrap());
        assert!(!verify("sunlight1".into(), None).await.unwrap());
    }
}
