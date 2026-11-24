/*
    Agreeing to the terms (F16)
    --------------------------------------------------------------------
    - TERMS_VERSION: the version of the Terms of Use and Privacy Policy
      (`legal/`) in force. Raise it only for a change that matters (new
      data collected, a new use, a new provider), not a wording fix:
      everyone is asked again after their next login
    - every agreement is a new row in `agreements`; nothing is updated
    - where people agree: sign-up and company registration send
      `terms_version`; everyone else (accounts someone made for them,
      and everyone after a raise) through `POST /me/terms`
*/

use axum::http::StatusCode;
use serde::Serialize;
use sqlx::PgConnection;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::{error::ApiError, rate_limit::ClientIp};

pub const TERMS_VERSION: i32 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "agreement_document", rename_all = "snake_case")]
pub enum Document {
    // The Terms of Use and the Privacy Policy, agreed together.
    Terms,
    // The Company Terms, agreed by an owner for their company.
    CompanyTerms,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "agreement_source", rename_all = "snake_case")]
pub enum Source {
    Signup,
    OrgRegistration,
    App,
}

/*
    The version a sign-up or registration says the person ticked
    --------------------------------------------------------------------
    - left out, or above the current one: 422 `terms.required`
    - an older one is fine: the app showed it, it's recorded as it is,
      and `/me` asks again after login
*/
pub fn check_sent(version: Option<i32>) -> Result<i32, ApiError> {
    match version {
        Some(v) if (1..=TERMS_VERSION).contains(&v) => Ok(v),
        _ => Err(required()),
    }
}

/// `POST /me/terms` takes only the version in force.
pub fn check_current(version: i32) -> Result<i32, ApiError> {
    if version == TERMS_VERSION {
        Ok(version)
    } else {
        Err(required())
    }
}

fn required() -> ApiError {
    ApiError::new(
        StatusCode::UNPROCESSABLE_ENTITY,
        "terms.required",
        "Agree to the Terms of Use and Privacy Policy to continue",
    )
    .field("terms_version", "Tick to agree to continue.")
}

/// One agreement to write.
pub struct Agreement<'a> {
    pub user_id: Uuid,
    pub document: Document,
    // `CompanyTerms` only.
    pub org_id: Option<Uuid>,
    pub version: i32,
    pub source: Source,
    pub ip: &'a ClientIp,
}

/*
    Adds the row, in the caller's transaction, so the agreement exists
    exactly when the account (or company) it belongs to does. The IP is
    kept only if it parses as one ("unknown" in tests becomes empty)
*/
pub async fn record(conn: &mut PgConnection, a: Agreement<'_>) -> Result<(), sqlx::Error> {
    let ip =
        a.ip.0
            .parse::<std::net::IpAddr>()
            .ok()
            .map(|ip| ip.to_string());
    sqlx::query(
        "INSERT INTO agreements (id, user_id, document, org_id, version, source, ip)
         VALUES ($1, $2, $3, $4, $5, $6, $7::inet)",
    )
    .bind(Uuid::now_v7())
    .bind(a.user_id)
    .bind(a.document)
    .bind(a.org_id)
    .bind(a.version)
    .bind(a.source)
    .bind(ip)
    .execute(conn)
    .await?;
    Ok(())
}

/// The contract's `TermsStatus`, in `/me`.
#[derive(Debug, Serialize, ToSchema)]
pub struct TermsStatus {
    /// The latest version the person agreed to; left out if never.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub accepted_version: Option<i32>,
    pub current_version: i32,
}

pub async fn status(conn: &mut PgConnection, user_id: Uuid) -> Result<TermsStatus, sqlx::Error> {
    let accepted_version: Option<i32> = sqlx::query_scalar(
        "SELECT max(version) FROM agreements WHERE user_id = $1 AND document = 'terms'",
    )
    .bind(user_id)
    .fetch_one(conn)
    .await?;
    Ok(TermsStatus {
        accepted_version,
        current_version: TERMS_VERSION,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sent_version_must_exist() {
        assert!(check_sent(None).is_err());
        assert!(check_sent(Some(0)).is_err());
        assert!(check_sent(Some(TERMS_VERSION + 1)).is_err());
        assert_eq!(check_sent(Some(TERMS_VERSION)).unwrap(), TERMS_VERSION);
    }

    #[test]
    fn app_agrees_only_to_the_current_version() {
        assert!(check_current(TERMS_VERSION).is_ok());
        assert!(check_current(TERMS_VERSION + 1).is_err());
    }
}
