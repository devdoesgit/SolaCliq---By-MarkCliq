# If data leaks

Half a page to follow on the day. Drafted 2026-11-22 for the lawyer to
check. "Breach": personal data seen, changed, lost or locked by someone
who shouldn't, or good reason to think so.

**Who decides.** The owner is the incident lead: decides it is a breach
and signs each message. The Grievance Officer (info@markcliq.com) takes
replies.

| By | Do |
|---|---|
| First hour | Write down when and how it was noticed. Contain it: revoke sessions, rotate the affected keys (database, R2, Gmail, FCM, code and bank keys), take the API down if it's still open. Don't delete logs |
| 6 hours | Report to CERT-In (incident@cert-in.org.in), as its 2022 directions require for a data breach |
| 24 hours | List whose data, which kinds (KYC and bank details first), which companies, since when |
| 48 hours | Tell each affected company: they are the fiduciary for their records |
| Without delay | Tell each affected person by email: what happened, what it may mean, what we did, what they can do, whom to write to. Tell the Data Protection Board what is known |
| 72 hours | The detailed report to the Data Protection Board |
| Two weeks | Cause, fix, and what changes, in `decisions.md` and here |

**Say only what is known.** No guesses at numbers or cause, no blame.
Never put the leaked data in a message.

**To prepare (owner).** Keep the companies' admin contacts and the
providers' support routes (Rackoona, Cloudflare, Google) somewhere that
doesn't depend on SolaCliq being up. Keep logs a year.
