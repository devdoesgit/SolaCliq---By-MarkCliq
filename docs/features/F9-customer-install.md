# F9 Customer: my install and payments (phase 10)

Status: `built` (customer side), 2026-11-17, run end to end in the app.
Spec 2026-11-17; the owner agreed the three decisions below the same
day. The app's screens (Home, Track, Payments)
are built against the mock; this is the backend behind them, endpoints
#43–44 (`backend-handoff.md`, M6).

## Goal

A customer follows their install in the app: where it stands (7
stages), who comes next and when, the price, the subsidy, and the
payment plan. When a payment is due they pay it by UPI or bank transfer,
outside the app, and tell the company they paid ("claimed"); the company
confirms it on the website. The app never handles money.

## Who

Customers (`customer` role), their own install in that company only.
The company's side (setting the price and plan, moving stages,
confirming payments, handover) comes with the admin website; the seed
writes installs meanwhile.

## The install

One per customer, made when the company takes them on (the admin
website; the seed now). It holds:

- **total** (paise): the system's price;
- **subsidy** (paise): PM Surya Ghar, paid by the government to the
  customer. **Decided:** worked out from the government table by
  default (homes only: ₹30,000 per kW for the first 2 kW, ₹18,000 for
  the 3rd, ₹78,000 at most), and the admin can change it;
- **payment plan**: **decided default** (provisional until the pilot
  vendor confirms): advance 30%, on installation 60%, on handover 10%,
  each with a label, a due date or a "when" line, and a status;
- **handed over on**: the handover date, once done.

Stages come from the customer record (phase 9): the stage they're at,
from 1 to 7 (Site survey … Handover). The next visit comes from the
customer's next open task (phase 8): its title, time, and the worker's
name and phone.

## My install (#43)

`GET /orgs/{org_id}/my-install`:

- `stages`: each `done` (before the current one), `next` (the current
  one; `done` too once handed over) or `upcoming`. The next stage's
  `detail` is its visit ("Thu 23 Oct, 11:00 · Vikram Rana"), the
  handover's its date.
- `next_visit`: the next open task for this customer, if any.
- `payments`: in plan order. `detail`: "Due 31 Oct" (due), "Sent 17 Nov,
  the company confirms" (claimed), "Paid 17 Nov" (paid), or the plan's
  line ("After panels are fixed") for later ones.
- `upi_uri`: pays the first due payment through any UPI app, when the
  company has a UPI id. **Decided:** companies get a UPI id field now;
  the admin sets it on the website's settings later; without one the
  app offers bank transfer only.
- 404 `install.not_started` before the company has set up the install
  (a registration still in review): the app says "Your install is being
  set up".

## Claiming a payment (#44)

`POST .../my-install/payments/{payment_id}/claim` with `method`
(`upi` or `bank_transfer`), idempotent:

- only a `due` payment of the caller's own install (409
  `payment.not_due` otherwise; 404 for anyone else's);
- → `claimed`, with the method and time. The company sees it on the
  website and marks it `paid`; paying the advance then makes the agent's
  commission `payable` (both with the admin website).

## The customer's home

Built from the install: the stage ("2 of 7 stages"), tiles for the next
visit and the payment due, the install bar, and rows for documents and
tracking. Before the install exists it keeps saying it's being set up.

## Not in scope

The admin's side; live energy after handover (needs inverter data:
after handover the home says "Handed over on …" without live numbers);
notifications for visits and payments (with the admin's actions).
