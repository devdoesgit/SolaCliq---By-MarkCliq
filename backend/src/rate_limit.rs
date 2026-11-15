/*
    Rate limits on the public endpoints
    --------------------------------------------------------------------
    - why: sign-up, log in, codes and company registration need no
      account, and most of them send an email. Every email shares the
      Workspace sender's daily cap (about 2,000), so without limits a
      script could use it up and real people's codes would stop
      arriving; log in could be guessed at without end
    - each `Rule` allows so many requests per key (an IP address or an
      email) per window; past that, 429 `auth.too_many_attempts` with
      `Retry-After`
    - counts live in memory: one API process (one VPS), and losing them
      on a restart only resets the windows. Old windows are dropped as
      the map grows, so memory stays bounded
    - the client's IP is `X-Real-IP`, which nginx sets to the real
      address (see `ClientIp`); without it, the connection's address
*/

use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::Mutex,
    time::{Duration, Instant},
};

use axum::{
    extract::{ConnectInfo, FromRequestParts},
    http::request::Parts,
};

use crate::{codes::too_many_attempts, error::ApiError};

// What is being limited, and by which key.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Rule {
    // POST /auth/signup, per IP.
    SignupByIp,
    // POST /auth/login, per IP and per email (guessing one account).
    LoginByIp,
    LoginByEmail,
    // Code emails (resend, forgot password), per IP.
    CodeEmailByIp,
    // Code checks (verify, reset), per IP. Each code also allows 5 tries.
    CodeCheckByIp,
    // POST /org-registrations, per IP.
    RegistrationByIp,
    /*
        "You already have an account", per email. Over the limit it is
        skipped without a word: the answer to sign-up stays the same
    */
    AlreadyRegisteredByEmail,
}

impl Rule {
    // How many requests per how long.
    fn limit(self) -> (u32, Duration) {
        const MINUTE: u64 = 60;
        const HOUR: u64 = 60 * MINUTE;
        let (count, seconds) = match self {
            Rule::SignupByIp => (10, HOUR),
            Rule::LoginByIp => (30, 15 * MINUTE),
            Rule::LoginByEmail => (10, 15 * MINUTE),
            Rule::CodeEmailByIp => (10, HOUR),
            Rule::CodeCheckByIp => (30, 15 * MINUTE),
            Rule::RegistrationByIp => (5, HOUR),
            Rule::AlreadyRegisteredByEmail => (1, HOUR),
        };
        (count, Duration::from_secs(seconds))
    }
}

struct Window {
    started: Instant,
    count: u32,
}

// Past this many keys, expired windows are dropped before adding one.
const PRUNE_AT: usize = 10_000;

pub struct Limiter {
    // Off in tests that aren't about limits: they all share one "IP".
    enabled: bool,
    windows: Mutex<HashMap<(Rule, String), Window>>,
}

impl Limiter {
    pub fn new() -> Self {
        Self {
            enabled: true,
            windows: Mutex::new(HashMap::new()),
        }
    }

    // Allows everything. For tests.
    pub fn disabled() -> Self {
        Self {
            enabled: false,
            windows: Mutex::new(HashMap::new()),
        }
    }

    // Counts one request; 429 with `Retry-After` when over the limit.
    pub fn check(&self, rule: Rule, key: &str) -> Result<(), ApiError> {
        match self.take(rule, key) {
            None => Ok(()),
            Some(wait) => {
                tracing::warn!(?rule, %key, "rate limited");
                Err(too_many_attempts()
                    .detail("Too many requests. Wait a little, then try again.")
                    .retry_after(wait.as_secs().max(1)))
            }
        }
    }

    // Counts one request; false when over the limit.
    pub fn allow(&self, rule: Rule, key: &str) -> bool {
        self.take(rule, key).is_none()
    }

    // None when allowed; otherwise how long until the window resets.
    fn take(&self, rule: Rule, key: &str) -> Option<Duration> {
        if !self.enabled {
            return None;
        }
        let (max, period) = rule.limit();
        let now = Instant::now();
        let mut windows = self.windows.lock().unwrap_or_else(|e| e.into_inner());
        if windows.len() >= PRUNE_AT {
            windows.retain(|(rule, _), w| now.duration_since(w.started) < rule.limit().1);
        }
        let window = windows.entry((rule, key.to_lowercase())).or_insert(Window {
            started: now,
            count: 0,
        });
        if now.duration_since(window.started) >= period {
            window.started = now;
            window.count = 0;
        }
        if window.count >= max {
            return Some(period - now.duration_since(window.started));
        }
        window.count += 1;
        None
    }
}

impl Default for Limiter {
    fn default() -> Self {
        Self::new()
    }
}

/*
    The caller's IP address, as text
    --------------------------------------------------------------------
    - `X-Real-IP` first: in production nginx sets it to the real client
      address (`proxy_set_header X-Real-IP $remote_addr;`), replacing
      anything the client sent, and the API listens on 127.0.0.1 only
    - otherwise the connection's address (local development)
    - neither (tests calling the router directly): "unknown"
*/
pub struct ClientIp(pub String);

impl<S: Send + Sync> FromRequestParts<S> for ClientIp {
    type Rejection = std::convert::Infallible;

    async fn from_request_parts(parts: &mut Parts, _: &S) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get("x-real-ip")
            .and_then(|v| v.to_str().ok())
            .map(str::trim)
            .filter(|v| !v.is_empty())
            .map(str::to_owned);
        let connection = parts
            .extensions
            .get::<ConnectInfo<SocketAddr>>()
            .map(|ConnectInfo(addr)| addr.ip().to_string());
        Ok(ClientIp(
            header.or(connection).unwrap_or_else(|| "unknown".into()),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn allows_up_to_the_limit_then_refuses() {
        let l = Limiter::new();
        for _ in 0..5 {
            assert!(l.allow(Rule::RegistrationByIp, "1.2.3.4"));
        }
        assert!(!l.allow(Rule::RegistrationByIp, "1.2.3.4"));
        // Another key, or another rule, has its own count.
        assert!(l.allow(Rule::RegistrationByIp, "5.6.7.8"));
        assert!(l.allow(Rule::SignupByIp, "1.2.3.4"));
    }

    #[test]
    fn emails_count_the_same_whatever_their_case() {
        let l = Limiter::new();
        assert!(l.allow(Rule::AlreadyRegisteredByEmail, "Asha@Example.com"));
        assert!(!l.allow(Rule::AlreadyRegisteredByEmail, "asha@example.com"));
    }

    #[test]
    fn over_the_limit_is_429_with_retry_after() {
        let l = Limiter::new();
        assert!(l.check(Rule::AlreadyRegisteredByEmail, "a").is_ok());
        let response = axum::response::IntoResponse::into_response(
            l.check(Rule::AlreadyRegisteredByEmail, "a").unwrap_err(),
        );
        assert_eq!(response.status(), 429);
        let wait: u64 = response.headers()["retry-after"]
            .to_str()
            .unwrap()
            .parse()
            .unwrap();
        assert!((1..=3600).contains(&wait));
    }

    #[test]
    fn disabled_allows_everything() {
        let l = Limiter::disabled();
        for _ in 0..100 {
            assert!(l.allow(Rule::RegistrationByIp, "x"));
        }
    }
}
