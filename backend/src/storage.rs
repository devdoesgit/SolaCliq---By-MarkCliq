/*
    Files in Cloudflare R2 (phase 7)
    --------------------------------------------------------------------
    - files never pass through the API: it signs a URL, and the app or
      website sends the file straight to R2 (PUT) or reads it (GET)
    - a signed URL works for 15 minutes, for that one file and method.
      The PUT URL also signs the type and size the client declared, so R2
      refuses a different file in its place
    - signing is AWS Signature V4 (R2 speaks the S3 API), computed here
      with the key: no network call. Region `auto`, path-style URLs:
      https://<account>.r2.cloudflarestorage.com/<bucket>/<key>
    - the bucket is private: without a signature, R2 refuses every read
*/

use chrono::{DateTime, Duration, Utc};
use hmac::{Hmac, KeyInit, Mac};
use sha2::{Digest, Sha256};

// How long a signed URL works.
pub const URL_LIFETIME: Duration = Duration::minutes(15);

// R2 settings (config.rs, the four R2_* variables).
#[derive(Clone)]
pub struct Storage {
    account_id: String,
    bucket: String,
    access_key_id: String,
    secret_access_key: String,
}

// Never prints the secret, even in a debug log.
impl std::fmt::Debug for Storage {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Storage")
            .field("account_id", &self.account_id)
            .field("bucket", &self.bucket)
            .finish_non_exhaustive()
    }
}

// A signed upload: PUT the file to `url`, sending `headers` exactly.
#[derive(Debug)]
pub struct SignedPut {
    pub url: String,
    pub headers: Vec<(&'static str, String)>,
    pub expires_at: DateTime<Utc>,
}

impl Storage {
    pub fn new(
        account_id: String,
        bucket: String,
        access_key_id: String,
        secret_access_key: String,
    ) -> Self {
        Self {
            account_id,
            bucket,
            access_key_id,
            secret_access_key,
        }
    }

    pub fn bucket(&self) -> &str {
        &self.bucket
    }

    fn host(&self) -> String {
        format!("{}.r2.cloudflarestorage.com", self.account_id)
    }

    fn path(&self, key: &str) -> String {
        format!("/{}/{}", self.bucket, key)
    }

    /*
        Upload one file. Content-Type and Content-Length are signed: the
        client sends the type it declared, and its HTTP library sends the
        file's real length, which must match the declared size
    */
    pub fn put_url(
        &self,
        key: &str,
        content_type: &str,
        size: i64,
        now: DateTime<Utc>,
    ) -> SignedPut {
        let url = presign(&Request {
            method: "PUT",
            host: &self.host(),
            path: &self.path(key),
            region: "auto",
            access_key_id: &self.access_key_id,
            secret_access_key: &self.secret_access_key,
            headers: &[
                ("content-length", &size.to_string()),
                ("content-type", content_type),
            ],
            now,
            expires: URL_LIFETIME,
        });
        SignedPut {
            url,
            headers: vec![("Content-Type", content_type.to_owned())],
            expires_at: now + URL_LIFETIME,
        }
    }

    // Read one file, for 15 minutes.
    pub fn get_url(&self, key: &str, now: DateTime<Utc>) -> String {
        presign(&Request {
            method: "GET",
            host: &self.host(),
            path: &self.path(key),
            region: "auto",
            access_key_id: &self.access_key_id,
            secret_access_key: &self.secret_access_key,
            headers: &[],
            now,
            expires: URL_LIFETIME,
        })
    }
}

// What a presigned URL is for. `headers`: besides `host`, sorted by name.
struct Request<'a> {
    method: &'a str,
    host: &'a str,
    path: &'a str,
    region: &'a str,
    access_key_id: &'a str,
    secret_access_key: &'a str,
    headers: &'a [(&'a str, &'a str)],
    now: DateTime<Utc>,
    expires: Duration,
}

/*
    AWS Signature V4, query-string form
    --------------------------------------------------------------------
    1. canonical request: method, path, the X-Amz-* query, the signed
       headers, and UNSIGNED-PAYLOAD (the body isn't known yet)
    2. string to sign: the algorithm, time, scope, and the request's hash
    3. signing key: HMAC chain of the secret over date, region, service
    4. the signature goes on the URL as X-Amz-Signature
*/
fn presign(r: &Request) -> String {
    let date_time = r.now.format("%Y%m%dT%H%M%SZ").to_string();
    let date = &date_time[..8];
    let scope = format!("{date}/{}/s3/aws4_request", r.region);

    let mut headers: Vec<(&str, &str)> = r.headers.to_vec();
    headers.push(("host", r.host));
    headers.sort_by_key(|(name, _)| *name);
    let signed_headers = headers
        .iter()
        .map(|(name, _)| *name)
        .collect::<Vec<_>>()
        .join(";");
    let canonical_headers: String = headers
        .iter()
        .map(|(name, value)| format!("{name}:{}\n", value.trim()))
        .collect();

    // Already in name order, as the canonical form requires.
    let query = format!(
        "X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential={}&X-Amz-Date={date_time}\
         &X-Amz-Expires={}&X-Amz-SignedHeaders={}",
        encode(&format!("{}/{scope}", r.access_key_id)),
        r.expires.num_seconds(),
        encode(&signed_headers),
    );
    let path = r.path.split('/').map(encode).collect::<Vec<_>>().join("/");

    let canonical_request = format!(
        "{}\n{path}\n{query}\n{canonical_headers}\n{signed_headers}\nUNSIGNED-PAYLOAD",
        r.method
    );
    let string_to_sign = format!(
        "AWS4-HMAC-SHA256\n{date_time}\n{scope}\n{}",
        hex(&Sha256::digest(canonical_request.as_bytes()))
    );

    let key = hmac(format!("AWS4{}", r.secret_access_key).as_bytes(), date);
    let key = hmac(&key, r.region);
    let key = hmac(&key, "s3");
    let key = hmac(&key, "aws4_request");
    let signature = hex(&hmac(&key, &string_to_sign));

    format!(
        "https://{}{path}?{query}&X-Amz-Signature={signature}",
        r.host
    )
}

fn hmac(key: &[u8], data: &str) -> Vec<u8> {
    let mut mac = Hmac::<Sha256>::new_from_slice(key).expect("HMAC accepts a key of any length");
    mac.update(data.as_bytes());
    mac.finalize().into_bytes().to_vec()
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

// URI-encodes everything but A–Z a–z 0–9 - _ . ~, as SigV4 requires.
fn encode(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                (b as char).to_string()
            }
            _ => format!("%{b:02X}"),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    /*
        AWS's published example ("Authenticating Requests: Using Query
        Parameters", S3 docs): a GET of test.txt, valid 24 hours. If the
        signing is right, the signature matches theirs exactly
    */
    #[test]
    fn matches_the_aws_example() {
        let url = presign(&Request {
            method: "GET",
            host: "examplebucket.s3.amazonaws.com",
            path: "/test.txt",
            region: "us-east-1",
            access_key_id: "AKIAIOSFODNN7EXAMPLE",
            secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            headers: &[],
            now: Utc.with_ymd_and_hms(2013, 5, 24, 0, 0, 0).unwrap(),
            expires: Duration::hours(24),
        });
        assert!(
            url.ends_with(
                "X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404"
            ),
            "{url}"
        );
    }

    #[test]
    fn a_put_url_signs_type_and_size() {
        let storage = Storage::new("acct".into(), "bucket".into(), "AK".into(), "SK".into());
        let now = Utc.with_ymd_and_hms(2026, 11, 16, 12, 0, 0).unwrap();
        let put = storage.put_url("proof/abc", "image/jpeg", 1234, now);
        assert!(
            put.url
                .starts_with("https://acct.r2.cloudflarestorage.com/bucket/proof/abc?")
        );
        assert!(
            put.url
                .contains("X-Amz-SignedHeaders=content-length%3Bcontent-type%3Bhost")
        );
        assert!(put.url.contains("X-Amz-Expires=900"));
        assert_eq!(put.headers, [("Content-Type", "image/jpeg".to_owned())]);
        assert_eq!(put.expires_at, now + URL_LIFETIME);
    }

    #[test]
    fn debug_hides_the_secret() {
        let storage = Storage::new(
            "acct".into(),
            "bucket".into(),
            "AK".into(),
            "very-secret".into(),
        );
        assert!(!format!("{storage:?}").contains("very-secret"));
    }
}
