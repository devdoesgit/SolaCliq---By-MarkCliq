/*
    Password rules and hashing
    ----------------------------------------------------------------------
    - passwords are never stored or logged; only the Argon2id hash is
    - every hash and check takes about 19 MB and some CPU, on purpose:
      that's what makes stolen hashes slow to crack. So only a few run at
      once (`SLOTS`); a request that can't get a slot within `WAIT`
      answers 503 `service.busy` instead of piling up, so a flood of
      log-ins from many addresses can't run the server out of memory
*/

use std::{sync::LazyLock, time::Duration};

use tokio::sync::Semaphore;

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

/*
    How many hashes or checks run at once: twice the CPUs, at least 4.
    Some 19 MB each, so a few hundred MB at most
*/
static SLOTS: LazyLock<Semaphore> = LazyLock::new(|| {
    let cpus = std::thread::available_parallelism().map_or(2, |n| n.get());
    Semaphore::new((cpus * 2).max(4))
});

// How long a request waits for a slot before answering 503.
const WAIT: Duration = Duration::from_secs(5);

async fn slot() -> Result<tokio::sync::SemaphorePermit<'static>, ApiError> {
    match tokio::time::timeout(WAIT, SLOTS.acquire()).await {
        Ok(Ok(permit)) => Ok(permit),
        _ => {
            tracing::warn!("password hashing is full; answering 503");
            Err(ApiError::busy())
        }
    }
}

/*
    Hashes a password with a fresh random salt. On tokio's blocking pool:
    directly in an async handler it would stall every other request on
    that thread. The slot is held until the hash is done, even if the
    request gave up meanwhile
*/
pub async fn hash(password: String) -> Result<String, ApiError> {
    let permit = slot().await?;
    tokio::task::spawn_blocking(move || {
        let _permit = permit;
        Argon2::default()
            .hash_password(password.as_bytes())
            .map(|h| h.to_string())
    })
    .await
    /*
        Two things can fail: the thread itself (`.await`) and the hashing.
        Neither should happen; log it and answer 500.
    */
    .map_err(|e| {
        tracing::error!(error = %e, "hash task failed");
        ApiError::internal()
    })?
    .map_err(|e| {
        tracing::error!(error = %e, "hashing failed");
        ApiError::internal()
    })
}

/*
    A hash of nothing in particular, checked when the email has no account,
    so "no such email" takes as long as "wrong password". Made once, on the
    first login (`LazyLock` runs the closure the first time it's used)
*/
static DUMMY_HASH: LazyLock<String> = LazyLock::new(|| {
    Argon2::default()
        .hash_password(b"not-a-real-password-0")
        .expect("hashing a constant")
        .to_string()
});

/*
    Whether `password` matches the stored hash. With no hash (unknown
    email), checks against a dummy and returns false, taking the same time
*/
pub async fn verify(password: String, stored: Option<String>) -> Result<bool, ApiError> {
    let permit = slot().await?;
    tokio::task::spawn_blocking(move || {
        let _permit = permit;
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
