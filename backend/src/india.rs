/*
    Indian time
    --------------------------------------------------------------------
    - India is UTC+5:30 all year (no daylight saving), so a fixed offset
      is exact
    - a person's "today" is the date in India, whatever the server's
      clock says: an installer's day, an expense's day, a month's start
    - the database keeps UTC (`timestamptz`); convert only to read a date
      or show a time
*/

use chrono::{DateTime, FixedOffset, NaiveDate, NaiveTime, TimeZone, Utc};

pub fn offset() -> FixedOffset {
    FixedOffset::east_opt(5 * 3600 + 30 * 60).expect("a valid offset")
}

// This moment on India's clock.
pub fn now(utc: DateTime<Utc>) -> DateTime<FixedOffset> {
    utc.with_timezone(&offset())
}

// The date in India at this moment.
pub fn date(utc: DateTime<Utc>) -> NaiveDate {
    now(utc).date_naive()
}

// Midnight starting this date in India, in UTC.
pub fn midnight(date: NaiveDate) -> DateTime<Utc> {
    offset()
        .from_local_datetime(&date.and_time(NaiveTime::MIN))
        .single()
        .expect("India has no clock changes")
        .with_timezone(&Utc)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_date_turns_at_midnight_in_india() {
        // 18:29 UTC is 23:59 in India; 18:30 is the next day.
        let before = Utc.with_ymd_and_hms(2026, 12, 1, 18, 29, 0).unwrap();
        let after = Utc.with_ymd_and_hms(2026, 12, 1, 18, 30, 0).unwrap();
        assert_eq!(date(before).to_string(), "2026-12-01");
        assert_eq!(date(after).to_string(), "2026-12-02");
        assert_eq!(midnight(date(after)), after);
    }
}
