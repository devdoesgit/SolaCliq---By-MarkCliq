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
    - the client's IP is `X-Real-IP` when the request came through nginx
      on this machine, else the connection's address (see `ClientIp`)
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
        POST /quote-requests, per account. Each emails MarkCliq, and a
        free account is enough to send one
    */
    QuoteByUser,
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
            Rule::QuoteByUser => (5, 24 * HOUR),
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
    - `X-Real-IP` only when the connection comes from this machine: in
      production that's nginx, which sets it to the real client address
      (`proxy_set_header X-Real-IP $remote_addr;`). From anywhere else
      the header is ignored, so a client can't pick its own IP to dodge
      the limits
    - otherwise the connection's address
    - no connection info at all (tests calling the router directly): the
      header, or "unknown"
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
        let peer = parts
            .extensions
            .get::<ConnectInfo<SocketAddr>>()
            .map(|ConnectInfo(addr)| addr.ip());
        let ip = match peer {
            Some(peer) if peer.is_loopback() => header.unwrap_or_else(|| peer.to_string()),
            Some(peer) => peer.to_string(),
            None => header.unwrap_or_else(|| "unknown".into()),
        };
        Ok(ClientIp(ip))
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

    async fn ip(peer: Option<&str>, header: Option<&str>) -> String {
        let mut req = axum::http::Request::builder();
        if let Some(h) = header {
            req = req.header("x-real-ip", h);
        }
        let (mut parts, ()) = req.body(()).unwrap().into_parts();
        if let Some(p) = peer {
            parts
                .extensions
                .insert(ConnectInfo::<SocketAddr>(p.parse().unwrap()));
        }
        ClientIp::from_request_parts(&mut parts, &())
            .await
            .unwrap()
            .0
    }

    #[tokio::test]
    async fn x_real_ip_is_trusted_only_from_this_machine() {
        // Through nginx on this machine: the header is the client.
        assert_eq!(
            ip(Some("127.0.0.1:5000"), Some("203.0.113.9")).await,
            "203.0.113.9"
        );
        // Straight from the internet: a made-up header is ignored.
        assert_eq!(
            ip(Some("198.51.100.7:5000"), Some("1.2.3.4")).await,
            "198.51.100.7"
        );
        // Local, without nginx: the connection itself.
        assert_eq!(ip(Some("127.0.0.1:5000"), None).await, "127.0.0.1");
    }

    #[test]
    fn disabled_allows_everything() {
        let l = Limiter::disabled();
        for _ in 0..100 {
            assert!(l.allow(Rule::RegistrationByIp, "x"));
        }
    }
}
