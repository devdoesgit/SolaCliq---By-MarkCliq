/*
    Paging for lists (`?cursor=&limit=`)
    --------------------------------------------------------------------
    - keyset pagination: a page ends at its last row's (created_at, id),
      and the next page starts after it. Unlike OFFSET, rows added while
      someone pages through don't shift onto the next page twice
    - lists are newest first; SQL compares `(created_at, id) < ($a, $b)`,
      which orders like a dictionary: by time, then by id for rows made
      in the same microsecond
    - a list fetches `limit + 1` rows; the extra one only says whether
      there is a next page (`Page::finish`)
*/

use chrono::{DateTime, Utc};
use serde::Serialize;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::error::{ApiError, ApiResult};

pub const DEFAULT_LIMIT: i64 = 25;
pub const MAX_LIMIT: i64 = 100;

// The contract's `PageInfo`.
#[derive(Debug, Serialize, ToSchema)]
pub struct PageInfo {
    // Pass as `cursor` for the next page; null on the last page.
    pub next_cursor: Option<String>,
}

/*
    Where a page ends
    --------------------------------------------------------------------
    - written as "<microseconds since 1970>.<uuid>"
    - clients treat it as opaque and send it back unchanged
*/
#[derive(Debug, Clone, Copy)]
pub struct Cursor {
    pub created_at: DateTime<Utc>,
    pub id: Uuid,
}

impl Cursor {
    pub fn encode(self) -> String {
        format!("{}.{}", self.created_at.timestamp_micros(), self.id)
    }

    pub fn parse(raw: &str) -> ApiResult<Self> {
        let invalid =
            || ApiError::validation(Vec::new()).field("cursor", "Start from the first page.");
        let (micros, id) = raw.split_once('.').ok_or_else(invalid)?;
        let created_at = micros
            .parse()
            .ok()
            .and_then(DateTime::from_timestamp_micros)
            .ok_or_else(invalid)?;
        let id = Uuid::parse_str(id).map_err(|_| invalid())?;
        Ok(Cursor { created_at, id })
    }
}

// A list request's `cursor` and `limit`, checked.
#[derive(Debug, Clone, Copy)]
pub struct Page {
    pub limit: i64,
    pub after: Option<Cursor>,
}

impl Page {
    // `limit` defaults to 25 and must be 1 to 100 (else 422).
    pub fn new(cursor: Option<&str>, limit: Option<i64>) -> ApiResult<Self> {
        let limit = limit.unwrap_or(DEFAULT_LIMIT);
        if !(1..=MAX_LIMIT).contains(&limit) {
            return Err(
                ApiError::validation(Vec::new()).field("limit", format!("Use 1 to {MAX_LIMIT}."))
            );
        }
        Ok(Page {
            limit,
            after: cursor.map(Cursor::parse).transpose()?,
        })
    }

    // Rows to fetch: one more than the page, to see if another follows.
    pub fn fetch(self) -> i64 {
        self.limit + 1
    }

    pub fn after_time(self) -> Option<DateTime<Utc>> {
        self.after.map(|c| c.created_at)
    }

    pub fn after_id(self) -> Option<Uuid> {
        self.after.map(|c| c.id)
    }

    /*
        Cuts the extra row off and makes the next cursor from the last row
        kept. `key` reads a row's (created_at, id)
    */
    pub fn finish<T>(self, rows: &mut Vec<T>, key: impl Fn(&T) -> Cursor) -> PageInfo {
        if rows.len() as i64 <= self.limit {
            return PageInfo { next_cursor: None };
        }
        rows.truncate(self.limit as usize);
        PageInfo {
            next_cursor: rows.last().map(|r| key(r).encode()),
        }
    }
}
