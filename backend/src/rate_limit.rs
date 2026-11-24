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
      on a restart only resets the windows. Expired windows are dropped
      as the map grows (at most once a second), and past `MAX_KEYS` a key
      not seen before is refused, so memory stays bounded whatever
      callers send
    - an IPv6 address counts by its /64: one host gets a whole /64, so
      counting each address would give it endless keys
    - the client's IP is `X-Real-IP` when the request came through Caddy
      (a trusted proxy), else the connection's address (see `ClientIp`)
*/

use std::{
    collections::HashMap,
    net::{IpAddr, Ipv6Addr, SocketAddr},
    sync::{Mutex, OnceLock},
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
    // Code emails (forgot password), per IP.
    CodeEmailByIp,
    /*
        Code emails, per email and kind, whether or not it has an account.
        With 5 tries a code, this bounds guessing one person's code from
        any number of addresses to 15 an hour
    */
    CodeEmailByEmail,
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
    /*
        POST /uploads, per account. Generous for a day of site photos;
        stops a script from filling the bucket
    */
    UploadByUser,
    /*
        POST /leads, per company, counted once the key is right. A busy
        campaign stays far below it; a leaked key can't fill the
        company's list
    */
    LeadByOrg,
    /*
        POST /leads with a wrong key, per IP. Counted apart from
        `LeadByOrg`, so wrong keys can't use up a company's leads; not
        on every lead, as one landing-page server sends many companies'
    */
    LeadBadKeyByIp,
    // Sending a member's invite again (F21), per address.
    InviteByEmail,
}

impl Rule {
    // How many requests per how long.
    fn limit(self) -> (u32, Duration) {
        const MINUTE: u64 = 60;
        const HOUR: u64 = 60 * MINUTE;
        let (count, seconds) = match self {
            /*
                30, not 10: Indian mobile networks put many phones behind
                one address, and a team sets up on one Wi-Fi. Guessing is
                bounded per email
            */
            Rule::SignupByIp => (30, HOUR),
            Rule::LoginByIp => (30, 15 * MINUTE),
            Rule::LoginByEmail => (10, 15 * MINUTE),
            Rule::CodeEmailByIp => (30, HOUR),
            Rule::CodeEmailByEmail => (3, HOUR),
            Rule::CodeCheckByIp => (30, 15 * MINUTE),
            Rule::RegistrationByIp => (5, HOUR),
            Rule::QuoteByUser => (5, 24 * HOUR),
            Rule::AlreadyRegisteredByEmail => (1, HOUR),
            Rule::UploadByUser => (200, HOUR),
            Rule::LeadByOrg => (300, HOUR),
            Rule::LeadBadKeyByIp => (20, HOUR),
            Rule::InviteByEmail => (3, HOUR),
        };
        (count, Duration::from_secs(seconds))
    }
}

struct Window {
    started: Instant,
    count: u32,
}

// Past this many keys, expired windows are dropped (at most once a second).
const PRUNE_AT: usize = 10_000;
/*
    Past this many live keys, a key not seen before is refused (429) until
    some expire: a flood of made-up keys can't grow the map without end.
    About 100 bytes each, so some 20 MB at most
*/
const MAX_KEYS: usize = 200_000;
const PRUNE_EVERY: Duration = Duration::from_secs(1);

struct Windows {
    map: HashMap<(Rule, String), Window>,
    pruned: Option<Instant>,
}

pub struct Limiter {
    // Off in tests that aren't about limits: they all share one "IP".
    enabled: bool,
    windows: Mutex<Windows>,
}

impl Limiter {
    pub fn new() -> Self {
        Self::with(true)
    }

    // Allows everything. For tests.
    pub fn disabled() -> Self {
        Self::with(false)
    }

    fn with(enabled: bool) -> Self {
        Self {
            enabled,
            windows: Mutex::new(Windows {
                map: HashMap::new(),
                pruned: None,
            }),
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

    // 429 if the key is already over the limit, without counting a request.
    pub fn check_not_over(&self, rule: Rule, key: &str) -> Result<(), ApiError> {
        if !self.enabled {
            return Ok(());
        }
        let (max, period) = rule.limit();
        let now = Instant::now();
        let windows = self.windows.lock().unwrap_or_else(|e| e.into_inner());
        match windows.map.get(&(rule, limit_key(key))) {
            Some(w) if now.duration_since(w.started) < period && w.count >= max => {
                tracing::warn!(?rule, %key, "rate limited");
                Err(too_many_attempts()
                    .detail("Too many requests. Wait a little, then try again.")
                    .retry_after((period - now.duration_since(w.started)).as_secs().max(1)))
            }
            _ => Ok(()),
        }
    }

    // None when allowed; otherwise how long until the window resets.
    fn take(&self, rule: Rule, key: &str) -> Option<Duration> {
        if !self.enabled {
            return None;
        }
        let (max, period) = rule.limit();
        let now = Instant::now();
        let mut guard = self.windows.lock().unwrap_or_else(|e| e.into_inner());
        let windows = &mut *guard;
        let due = windows
            .pruned
            .is_none_or(|at| now.duration_since(at) >= PRUNE_EVERY);
        if windows.map.len() >= PRUNE_AT && due {
            windows
                .map
                .retain(|(rule, _), w| now.duration_since(w.started) < rule.limit().1);
            windows.pruned = Some(now);
        }
        let id = (rule, limit_key(key));
        if windows.map.len() >= MAX_KEYS && !windows.map.contains_key(&id) {
            tracing::warn!(?rule, "rate limiter full; refusing a new key");
            return Some(PRUNE_EVERY);
        }
        let window = windows.map.entry(id).or_insert(Window {
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
    What a key counts as: emails whatever their case, an IPv6 address by
    its /64 (the block one host or home gets), anything else as it is
*/
fn limit_key(key: &str) -> String {
    match key.parse::<Ipv6Addr>() {
        Ok(ip) if ip.to_ipv4_mapped().is_none() => {
            let net = u128::from(ip) & (u128::MAX << 64);
            format!("{}/64", Ipv6Addr::from(net))
        }
        _ => key.to_lowercase(),
    }
}

/*
    A network the API trusts to say who the client is: an address, or an
    address and prefix ("172.16.0.0/12")
*/
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Net {
    addr: IpAddr,
    prefix: u8,
}

impl Net {
    fn contains(&self, ip: IpAddr) -> bool {
        // An IPv4 client may arrive as an IPv4-mapped IPv6 address.
        let ip = match ip {
            IpAddr::V6(v6) => v6.to_ipv4_mapped().map_or(ip, IpAddr::V4),
            v4 => v4,
        };
        match (self.addr, ip) {
            (IpAddr::V4(net), IpAddr::V4(ip)) => {
                let mask = u32::MAX
                    .checked_shl(32 - u32::from(self.prefix))
                    .unwrap_or(0);
                u32::from(net) & mask == u32::from(ip) & mask
            }
            (IpAddr::V6(net), IpAddr::V6(ip)) => {
                let mask = u128::MAX
                    .checked_shl(128 - u32::from(self.prefix))
                    .unwrap_or(0);
                u128::from(net) & mask == u128::from(ip) & mask
            }
            _ => false,
        }
    }
}

impl std::str::FromStr for Net {
    type Err = String;

    fn from_str(text: &str) -> Result<Self, String> {
        let text = text.trim();
        let (addr, prefix) = text.split_once('/').unwrap_or((text, ""));
        let addr: IpAddr = addr
            .parse()
            .map_err(|_| format!("{text:?} isn't an IP address or network"))?;
        let max = if addr.is_ipv4() { 32 } else { 128 };
        let prefix = if prefix.is_empty() {
            max
        } else {
            prefix
                .parse::<u8>()
                .ok()
                .filter(|p| *p <= max)
                .ok_or_else(|| format!("{text:?} has a bad prefix"))?
        };
        Ok(Self { addr, prefix })
    }
}

/*
    Parses TRUSTED_PROXIES: networks separated by commas, empty for none.
    Loopback is always trusted
*/
pub fn parse_proxies(text: &str) -> Result<Vec<Net>, String> {
    text.split(',')
        .filter(|part| !part.trim().is_empty())
        .map(str::parse)
        .collect()
}

static TRUSTED: OnceLock<Vec<Net>> = OnceLock::new();

// Set once at start (main.rs), from TRUSTED_PROXIES.
pub fn trust_proxies(nets: Vec<Net>) {
    let _ = TRUSTED.set(nets);
}

fn trusted(peer: IpAddr) -> bool {
    peer.is_loopback()
        || peer.to_canonical().is_loopback()
        || TRUSTED
            .get()
            .is_some_and(|nets| nets.iter().any(|n| n.contains(peer)))
}

/*
    Who the client is, given the connection's address and `X-Real-IP`
    ----------------------------------------------------------------------
    - from a trusted proxy (loopback, or TRUSTED_PROXIES): the header,
      which Caddy sets to the real client
    - from anywhere else: the connection, and the header is ignored, so a
      client can't pick its own IP to dodge the limits
    - no connection info (tests calling the router directly): the header
*/
fn client_ip(peer: Option<IpAddr>, header: Option<String>) -> String {
    match peer {
        Some(peer) if trusted(peer) => header.unwrap_or_else(|| peer.to_string()),
        Some(peer) => peer.to_string(),
        None => header.unwrap_or_else(|| "unknown".into()),
    }
}

/*
    The caller's IP address, as text
    --------------------------------------------------------------------
    - `X-Real-IP` only when the connection comes from a trusted proxy: in
      production that's Caddy, which sets it to the real client address
      (`header_up X-Real-IP {remote_host}`, deploy/Caddyfile)
    - Caddy runs on the VPS and the API in Docker, so Caddy's connections
      reach the API from Docker's network, not loopback:
      TRUSTED_PROXIES (deploy/compose.yml) names those networks. Without
      it every client would look like the one Docker gateway and share
      one set of limits
    - see `client_ip` for the rest
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
        Ok(ClientIp(client_ip(peer, header)))
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

    #[test]
    fn x_real_ip_is_trusted_from_a_named_proxy_network() {
        /*
            Caddy on the VPS, the API in Docker: Caddy's connection arrives
            from Docker's gateway, as in production
        */
        let docker: Vec<Net> = parse_proxies("172.16.0.0/12, 192.168.0.0/16").unwrap();
        let from = |peer: &str, nets: &[Net]| {
            let peer: IpAddr = peer.parse().unwrap();
            nets.iter().any(|n| n.contains(peer))
        };
        assert!(from("172.18.0.1", &docker));
        assert!(from("::ffff:172.18.0.1", &docker));
        assert!(!from("172.32.0.1", &docker));
        assert!(!from("203.0.113.9", &docker));
        assert!(parse_proxies("").unwrap().is_empty());
        assert!(parse_proxies("10.0.0.0/33").is_err());
        assert!(parse_proxies("not an ip").is_err());
        assert_eq!(
            parse_proxies("fd00::/8").unwrap()[0],
            "fd00::/8".parse::<Net>().unwrap()
        );
    }

    #[test]
    fn two_visitors_through_docker_count_apart() {
        /*
            The bug the review found: without the trusted network, both
            visitors came out as the gateway and shared one limit
        */
        trust_proxies(parse_proxies("172.16.0.0/12").unwrap());
        let gateway = Some("172.18.0.1".parse().unwrap());
        assert_eq!(client_ip(gateway, Some("49.36.1.1".into())), "49.36.1.1");
        assert_eq!(client_ip(gateway, Some("49.36.2.2".into())), "49.36.2.2");
        // Not a trusted network: the header is still ignored.
        assert_eq!(
            client_ip(
                Some("198.51.100.7".parse().unwrap()),
                Some("1.2.3.4".into())
            ),
            "198.51.100.7"
        );
    }

    #[test]
    fn an_ipv6_host_counts_as_its_64() {
        let l = Limiter::new();
        for i in 0..5 {
            assert!(l.allow(Rule::RegistrationByIp, &format!("2001:db8:1:2::{i}")));
        }
        assert!(!l.allow(Rule::RegistrationByIp, "2001:db8:1:2:ffff::1"));
        // Another /64 has its own count.
        assert!(l.allow(Rule::RegistrationByIp, "2001:db8:1:3::1"));
    }

    #[test]
    fn a_full_limiter_refuses_new_keys_but_keeps_counting_old_ones() {
        let l = Limiter::new();
        {
            let mut w = l.windows.lock().unwrap();
            let now = Instant::now();
            for i in 0..MAX_KEYS {
                w.map.insert(
                    (Rule::LeadByOrg, i.to_string()),
                    Window {
                        started: now,
                        count: 0,
                    },
                );
            }
        }
        assert!(!l.allow(Rule::LoginByIp, "203.0.113.9"));
        assert!(l.allow(Rule::LeadByOrg, "7"));
        assert_eq!(l.windows.lock().unwrap().map.len(), MAX_KEYS);
    }

    #[test]
    fn checking_without_counting() {
        let l = Limiter::new();
        for _ in 0..20 {
            assert!(l.check_not_over(Rule::LeadBadKeyByIp, "1.2.3.4").is_ok());
            assert!(l.allow(Rule::LeadBadKeyByIp, "1.2.3.4"));
        }
        assert!(l.check_not_over(Rule::LeadBadKeyByIp, "1.2.3.4").is_err());
        assert!(l.check_not_over(Rule::LeadBadKeyByIp, "5.6.7.8").is_ok());
    }

    #[tokio::test]
    async fn x_real_ip_is_trusted_only_from_this_machine() {
        // Through Caddy on this machine: the header is the client.
        assert_eq!(
            ip(Some("127.0.0.1:5000"), Some("203.0.113.9")).await,
            "203.0.113.9"
        );
        // Straight from the internet: a made-up header is ignored.
        assert_eq!(
            ip(Some("198.51.100.7:5000"), Some("1.2.3.4")).await,
            "198.51.100.7"
        );
        // Local, without Caddy: the connection itself.
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
