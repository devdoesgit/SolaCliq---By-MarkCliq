# F17 Attendance

Each EPC Installer and Sales Agent marks their own working day in the
app. The company's admin sees who is working, and each month's days, on
the website. Asked by the owner on 2026-11-20; spec written and backend built the
same day.

## Goal

The admin can see who started work today and when, and hand a month's
attendance to whoever does payroll, without a register or WhatsApp
"reached" messages.

## Who

- **Marks attendance:** members with the `worker` role and members with
  the `agent` role on `salary` pay (an agent without a pay type counts as
  salaried, as everywhere else). Commission agents don't: they aren't
  bound to the company or its hours (owner, 2026-11-20). They get no
  card, and `attendance.not_tracked` (403) if they call it.
- **Monitors:** the org admin, on the website. The admin only reads: they
  don't mark, add or correct anyone's day.
- Customers and platform admins have nothing here.

## Rules

- **A day** is a start tap and, later, an end tap. It belongs to the date
  in India (IST) when it started. One day per person per date.
- **The time of a tap comes from the server's clock.** The app sends two
  times from the phone's clock: when the person tapped and when it sent
  the tap. Their gap is how long the tap waited on the phone, and it's
  right even when the phone's clock is wrong (the error is in both). The
  server counts the tap as made that long before it arrived. A slow, fast
  or changed phone clock moves nothing.
- **Taps sent later.** A tap that waited over 5 minutes (the phone was
  offline) is marked **sent late**, so the admin knows the wait is the
  phone's word. A negative wait (the clock was set back) counts as none.
  A tap more than 7 days old is refused (`attendance.too_old`, 422).
- **Retries.** A retry of the same tap (same `Idempotency-Key`) gets the
  first answer, even when sent while the first was still running.
- **The admin's list** holds installers and salaried sales who are
  members now, plus anyone with a day in the range whatever changed
  since (removed, moved to commission, another role).
- **Start day** starts the day for the tap's date. If that date already
  has a start: `attendance.already_started` (409); the app treats this as
  done and shows the day.
- **End day** ends the day of the tap's date. With no start on that date
  (or a start after the tap): `attendance.not_started` (409); already
  ended: `attendance.already_ended` (409). The app asks "End your day?"
  first, as an end can't be undone. A day doesn't cross midnight: the
  people who mark attendance work in daylight, and a 24-hour window would
  turn a forgotten end into a 23-hour day the next morning.
- **No check-out.** A day without an end shows as "no check-out" from the
  next date on. Only a late end tap sent from offline for that date can
  still end it.
- **Worked time** is the end minus the start, shown once a day has ended.
- A removed member's past days stay with the company and still show in
  the months they worked.

## API

Contract in `api/openapi.yaml`, tag `attendance`.

| Endpoint | Who | What |
|---|---|---|
| `POST /orgs/{org_id}/me/attendance/start` | installer, sales | Start day (`Idempotency-Key`; body: phone time) |
| `POST /orgs/{org_id}/me/attendance/end` | installer, sales | End day (same) |
| `GET /orgs/{org_id}/home` | installer, sales | Gains an `attendance` part: not started, working since, or ended |
| `GET /orgs/{org_id}/attendance/day?date=` | org admin | Everyone who marks attendance, with their day on that date (default today) |
| `GET /orgs/{org_id}/attendance/month?month=` | org admin | Each person's days in a month (default this month) |
| `GET /orgs/{org_id}/attendance/month.csv?month=` | org admin | The same month as CSV, one row per person per day |

The admin lists aren't paged: a company has tens of people, and a month
is at most 31 days each.

Another role calling these gets `org.role_not_allowed` (403), as
everywhere; a commission agent marking attendance gets
`attendance.not_tracked` (403).

## App

- **Home card** for installers and sales, above the tiles, from the home's
  `attendance` part:
  - not started: "Start day" pill button;
  - working: "Working since 9:12" and an "End day" button;
  - ended: "Day ended · 9:12 to 18:40 · 9 h 28 m".
- **Offline.** A tap made without a connection is kept on the phone with
  its own `Idempotency-Key` and the phone's time, and sent when the app
  can reach the server (on opening, on returning to the app, on pull to
  refresh). The card shows "Saved, will send when online" until then.
  The phone holds at most one unsent start and one unsent end.
- Every button has a `Key` and a Semantics label; 48 px targets.

## Website (org admin)

- **Attendance → Today:** each person with their status (working since,
  ended with hours, not started, no check-out from yesterday), sent-late
  taps marked. A date picker shows other days.
- **Attendance → Month:** a grid of people × days (worked, no check-out,
  nothing), days and hours per person, and "Download CSV".
- Read only: no edit buttons.

## Data

`attendance_days`: `id`, `org_id`, `user_id`, `work_date` (IST date),
`started_at`, `start_phone_at`, `start_sent_late`, `ended_at`,
`end_phone_at`, `end_sent_late`, `created_at`. One row per
(`org_id`, `user_id`, `work_date`). Row-level security like every
company table. No location, no photo.

`docs/data-policy.md` gains: attendance holds only the start and end
times (and the phone's times) of each day, seen by the person and their
company's admin.

## Not in scope

- Location or selfies at a tap (`decisions.md`, 2026-11-20).
- The admin marking or correcting days.
- Leave, holidays, half days, shifts, overtime, payroll.
- Reminders to start or end the day.
- The person's own attendance history in the app.

## Open

- **The 5-minute and 7-day limits** are first guesses; easy to change on
  the server.

## Tests

- Backend `tests/attendance.rs` (17): start and end; one start and one
  end a day; no check-out the next day, and today still starts; a wrong
  phone clock (3 hours fast, 10 minutes slow) moves nothing; an offline
  tap counts from when it was made, on a slow phone too; yesterday's end
  sent today ends yesterday; an end before the start, a week-old tap, a
  clock set back; a retry gets the first answer, also while the first
  is still running; two taps at once make one day; roles (commission,
  customer, admin refused; views the admin's only); a removed member and
  a suspended company can't tap; moving to commission stops marking and
  keeps the days; each company's days are its own, for a person in two;
  the day list by name, with removed members and changed roles; the
  month's edges, totals and CSV text; bad requests change nothing.
- Unit tests in `src/routes/attendance.rs` and `src/india.rs`: the
  clock arithmetic and its limits (5 minutes, 7 days), statuses, months,
  CSV cells, the India date at midnight.
- The race test was checked by switching the fix off: it fails then.
- App: the home card's three states, the end confirmation, an offline
  tap kept and sent once (in order, start before end), `already_started`
  treated as done.

## Notes (backend, 2026-11-20)

- `src/routes/attendance.rs`, table `attendance_days` (migration
  `20261120000002_attendance.sql`). The home's card comes from
  `attendance::home_card`.
- The India-time helper that was copied into seven files is now one,
  `src/india.rs`.
- Agents always have a pay type in the database, so "an agent without
  one counts as salaried" only guards the app's reading of old data.
- The CSV puts a `'` before a name starting with `=`, `+`, `-` or `@`,
  so a spreadsheet can't run it as a formula.

## Notes (app, 2026-11-22)

- `lib/attendance/`: `AttendanceRepository` keeps unsent taps in secure
  storage (`attendance_outbox`), per person and company, and sends them
  oldest first with the tap's key and time; the time of sending is read
  on each try. No signal, a server error, a login being renewed or
  "slow down" keep the tap and stop there, so an end never goes before
  its start; any other refusal drops the tap and the card says why.
  "Already started" or "already ended" counts as done.
- `AttendanceCubit` shows a tap at once, then saves and sends it;
  retries every 30 seconds while the card is open and when the app
  comes back to the front. Today is India's date, as on the server.
- Checked on the emulator against the local API: a start tapped in
  airplane mode was saved, sent by itself 31 seconds after the network
  came back, and recorded within 0.05 s of the tap; End day asks first.
- `make app-e2e` has two attendance flows (an installer starts and ends
  the day; salaried sales see the card, commission agents don't). The
  seed clears the company's days and adds illustrative past ones.
- Secure storage takes a second or two to write on Android, so the card
  changes before the save, not after.

## Notes (website, 2026-11-22)

- Built in W6 (`admin/src/features/attendance/`): Today with a date
  picker, Month as a grid, CSV.
