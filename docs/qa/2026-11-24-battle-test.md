# Battle test: every endpoint, every role (2026-11-23 to 24)

Asked by the owner before deploy: act as every kind of user, test every
feature, endpoint and edge case, and give a green light only if it all
works. Run overnight on this machine against the release build of the
API, Postgres and the dev R2 bucket, in a throwaway database (`e2e`).
The preview database was not touched; it was restored after.

## Result

**Green, with no app or server bug found.** The fixes made were to the
API contract (7 response descriptions the server already behaved by)
and to the app's end-to-end test script. Nothing in how the server,
website or app behaves changed.

| Check | Who | Result |
|---|---|---|
| Role gate: all 102 operations × 10 people | admin, 2 installers, commission and salaried agents, customer, another company's admin, personal account, platform admin, logged out | 863 calls: every wrong role and non-member refused (322 `org.role_not_allowed`, 231 `org.not_member`, 92 `401`, 12 `platform.not_admin`), every allowed call let in, **0 server errors** |
| Another company's records | the other company's admin, with Example Solar's ids and valid bodies | 25 of 25 refused (404); nothing leaked |
| A colleague's records | a second installer on the first's task; the salaried agent on the commission agent's customer, lead and expense | 13 of 13 refused (404) |
| Fuzzing (Schemathesis 4.34, the contract as source) | admin, installer, both agents, customer; company and own records pinned | ~28,600 generated requests: **0 server errors**; findings were contract gaps only (below) |
| Website end to end (Chrome) | admin, with the app's people acting through the API | 176 of 176 checks, 59 of 59 site API calls, 4 widths, 0 accessibility findings, 0 server errors |
| Website, every screen (Firefox) | admin | 54 of 54 |
| Dates in another time zone | admin, in a New York and an India browser, past midnight in India | 10 screens, 261 dates: identical in both |
| App end to end, on the emulator against the real API | installer, salaried sales, commission agent, customer | 6 of 6 flows (new: an agent works a lead) |
| App by hand, on the emulator | a new homeowner | code-first sign-up (terms refused until ticked), account deletion (wrong password refused, then erased; the login no longer works) |
| Server tests | | 335 passed, clippy clean |
| Website tests | | 164 passed, types and lint clean |
| App tests | | 403 passed, analyze clean |
| Generated clients, contract lint | | current; Spectral clean; code and contract now agree on every operation's response codes |

## Fixed

| # | What | Fix |
|---|---|---|
| B-01 | Log in, forgot password and sign-up verify answer 422 to a request with no JSON; the contract didn't list 422 | Listed in the contract and the handlers' annotations |
| B-02 | The team list answers 422 to a bad page cursor; contract didn't list it | Listed |
| B-03 | Ticking a checklist item and claiming a payment answer 422 to a bad body; not listed | Listed |
| B-04 | A platform company's `owner` was marked required; it's absent for a company with no admin | Optional in the contract, with when it's absent |
| B-05 | The installers' task list listed a 404 it never sends | Removed |
| T-01 | App test script: "Done" on the password now logs in by itself, the script also tapped Log in | The script lets "Done" submit |
| T-02 | App test script: a saved session from an earlier run is refused a moment after start, logging the app out; the script tapped in between | Waits for that first |
| T-03 | App test script: a screen that never settles hung the run for 25 minutes | Taps give up after 10 s with a message |
| T-05 | Website suite: its India-time check looked for today's day number anywhere on the page, and passed before midnight only because "Today 23:52" contains 23 | Checks the full date under All details; the screens themselves were proved in both time zones (above) |
| T-04 | App test script: "Save note" sits under the pinned Call bar until the page is scrolled to its end (as on every page with a pinned button); the script's tap called the lead | Scrolls to the end first, as a person does |

The contract changes regenerate the app and website clients (only
`PlatformOrg.owner` became optional); neither uses it.

## Not bugs (checked)

- The salaried agent reaching `/platform/orgs`: the browser suite makes
  that account a platform admin to approve its test company.
- A stage named "Rajinder Kaur (illustrative)" on the customer's home:
  the fuzzer renamed the test company's stages. Any text up to 40
  characters is a valid stage name.
- "Too many tries" on log in during repeated runs: the log-in rate limit.
- The emulator crashing on install: the known gfxstream `TextureResize`
  fault (`mobile/CLAUDE.md`) when a build installs over a running app.
  Each run now cold-boots the emulator.

## Not covered

- The real server: real email (Gmail), the production bucket, push
  through FCM to a real phone, HTTPS and Caddy there. First run on the
  server is the proof.
- Load: about 100 customers and 50 people looked and behaved fine; no
  load test.
- Physical phones and iPhones (Android emulator only); Safari.
- The release (not debug) app build.
- CI on GitHub: nothing pushed yet.

## Rerunning

The scripts live outside the repo, in `~/.cache/solacliq-qa/`:
`full-run.sh` (website, Chrome), `web/driver/firefox.js`,
`battle/battle.py` (role gate and isolation), `battle/fuzz.sh <role>
<email>` (Schemathesis), `app-e2e.sh` (app flows on a cold-booted
emulator). The app flows themselves are in
`mobile/integration_test/flows_test.dart`.
