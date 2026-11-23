#!/usr/bin/env python3
"""
Builds the Postman collection from the API contract
--------------------------------------------------------------------
- `make postman` (or `python3 api/postman/generate.py`) writes
  `api/postman/SolaCliq.postman_collection.json` from `api/openapi.yaml`
- the folders follow one install's life against the seeded local API:
  log in as each role, the admin sets up work, the installer does it,
  the agent registers a customer, the customer claims a payment, the
  admin decides. Run top to bottom after `cargo run -- seed`, every
  request passes (README.md)
- every request checks its status against the contract, and the whole
  collection fails on any 5xx: it doubles as a smoke test
- requests that need a file (proof photos, receipts, KYC) upload one
  first in their pre-request script: POST /uploads, then PUT a small
  file to the signed R2 URL, as the app does
- an endpoint added to the contract without a request below still lands
  in "Not arranged yet", with a body made from its schema, and the
  generator says so
"""

import json
import re
import sys
import uuid
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
SPEC = yaml.safe_load((ROOT / "api/openapi.yaml").read_text())
OUT = ROOT / "api/postman/SolaCliq.postman_collection.json"

# Fixed ids from backend/src/seed.rs (illustrative data).
SEED = {
    "org_id": "01928f6e-0000-7000-8000-0000000000a1",  # Example Solar
    "task_problem": "01928f6e-0000-7000-8000-000000000a03",  # Priya, assigned
    "task_cancel": "01928f6e-0000-7000-8000-000000000a04",  # assigned
    "expense_in_review": "01928f6e-0000-7000-8000-0000000000f1",  # EXP-0001
    "expense_needs_fix": "01928f6e-0000-7000-8000-0000000000f3",  # EXP-0002
    "customer_payable": "01928f6e-0000-7000-8000-0000000000c1",  # Rajinder
    "customer_needs_fix": "01928f6e-0000-7000-8000-0000000000c2",  # Sunita
    "customer_in_review": "01928f6e-0000-7000-8000-0000000000c3",  # Arjun
    "customer_to_reject": "01928f6e-0000-7000-8000-0000000000c5",  # Kiran
    "customer_approved": "01928f6e-0000-7000-8000-0000000000c6",  # Gurpreet
    "payment_due": "01928f6e-0000-7000-8000-000000000211",  # Rajinder, due
    "payment_later": "01928f6e-0000-7000-8000-000000000212",  # Rajinder, later
}

ROLES = {
    "worker": ("ravi@example.com", "Ravi, installer"),
    "agent": ("meena@example.com", "Meena, sales agent (commission)"),
    "customer": ("rajinder@example.com", "Rajinder, customer"),
    "admin": ("dev@example.com", "Dev, the company's admin"),
}

# ---------------------------------------------------------------- spec

OPS = {}
for path, item in SPEC["paths"].items():
    for method, op in item.items():
        if method in ("get", "post", "put", "delete", "patch"):
            OPS[op["operationId"]] = (method.upper(), path, op)
USED = set()


def schema(name):
    return SPEC["components"]["schemas"][name]


def resolve(s):
    while isinstance(s, dict) and "$ref" in s:
        s = schema(s["$ref"].split("/")[-1])
    return s


def first_enum(name, prefer=None):
    values = resolve(schema(name))["enum"]
    return prefer if prefer in values else values[0]


def expected_status(op):
    return int(sorted(k for k in op["responses"] if str(k).startswith("2"))[0])


def idempotent(op):
    return any(
        p.get("$ref", "").endswith("/IdempotencyKey") or p.get("name") == "Idempotency-Key"
        for p in op.get("parameters", [])
    )


def synth(s, name=""):
    """A body from a schema, for endpoints no request below covers."""
    s = resolve(s)
    for key in ("example",):
        if key in s:
            return s[key]
    if s.get("examples"):
        return s["examples"][0]
    if "enum" in s:
        return s["enum"][0]
    t = s.get("type")
    if isinstance(t, list):
        t = next((x for x in t if x != "null"), "string")
    if t == "object" or "properties" in s:
        req = s.get("required", list(s.get("properties", {})))
        return {k: synth(v, k) for k, v in s.get("properties", {}).items() if k in req}
    if t == "array":
        return [synth(s.get("items", {}), name)]
    if t in ("integer", "number"):
        return s.get("minimum", 1) or 1
    if t == "boolean":
        return True
    fmt = s.get("format")
    if fmt == "uuid":
        return str(uuid.UUID(int=0))
    if fmt == "date":
        return "{{today}}"
    if fmt == "date-time":
        return "{{tomorrow}}"
    if fmt == "email":
        return "someone@example.com"
    return "illustrative"


# ------------------------------------------------------------- scripts

# Shared by every pre-request script: dates and a unique suffix per run.
COMMON_PRE = """
const ist = new Date(Date.now() + 5.5 * 3600 * 1000);
pm.variables.set('today', ist.toISOString().slice(0, 10));
pm.variables.set('now', new Date().toISOString());
pm.variables.set('tomorrow', new Date(Date.now() + 86400000).toISOString());
pm.variables.set('in_ten_days', new Date(Date.now() + 10 * 86400000).toISOString().slice(0, 10));
if (!pm.collectionVariables.get('run')) pm.collectionVariables.set('run', String(Date.now()).slice(-8));
"""

# Uploads `n` small files as the app does, then calls done(ids).
UPLOAD_JS = """
function uploadFiles(token, purpose, contentType, n, done) {
  const ids = [];
  const one = () => {
    if (ids.length === n) return done(ids);
    const body = 'SolaCliq Postman test file (illustrative) ' + Date.now() + ' ' + ids.length;
    pm.sendRequest({
      url: pm.variables.get('baseUrl') + '/orgs/' + pm.variables.get('org_id') + '/uploads',
      method: 'POST',
      header: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + pm.variables.get(token) },
      body: { mode: 'raw', raw: JSON.stringify({ content_type: contentType, size_bytes: body.length, purpose }) },
    }, (err, res) => {
      if (err || res.code !== 201) { console.error('upload ticket failed', err || res.text()); return; }
      const ticket = res.json();
      pm.sendRequest({
        url: ticket.url,
        method: ticket.method,
        header: Object.entries(ticket.headers).map(([key, value]) => ({ key, value })),
        body: { mode: 'raw', raw: body },
      }, (err2, res2) => {
        if (err2 || res2.code >= 300) { console.error('file PUT failed', err2 || res2.code); return; }
        ids.push(ticket.upload_id);
        one();
      });
    });
  };
  one();
}
"""


def upload_pre(token, purpose, content_type, sets):
    """Uploads len(sets) files and stores their ids in those variables."""
    assigns = "".join(f"  pm.variables.set('{v}', ids[{i}]);\n" for i, v in enumerate(sets))
    return UPLOAD_JS + (
        f"uploadFiles('{token}', '{purpose}', '{content_type}', {len(sets)}, (ids) => {{\n"
        f"{assigns}}});\n"
    )


# A valid GSTIN for a new company each run (checksum as in backend/src/gstin.rs).
GSTIN_PRE = """
const CH = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const run = pm.collectionVariables.get('run');
const letters = run.split('').map((d) => 'ABCDEFGHIJ'[Number(d)]).join('');
const first14 = '03' + 'AAA' + letters.slice(0, 1) + 'P' + run.slice(-4) + 'Q' + '1' + 'Z';
let sum = 0;
for (let i = 0; i < 14; i++) {
  const p = CH.indexOf(first14[i]) * (i % 2 === 0 ? 1 : 2);
  sum += Math.floor(p / 36) + (p % 36);
}
pm.variables.set('gstin', first14 + CH[(36 - (sum % 36)) % 36]);
"""


def save_js(saves):
    lines = [f"pm.collectionVariables.set('{k}', {v});" for k, v in saves.items()]
    return "if (pm.response.code < 300) {\n  const json = pm.response.json();\n  " + "\n  ".join(lines) + "\n}\n"


# ------------------------------------------------------------ requests


def req(name, op_id, role=None, body=None, path=None, query=None, saves=None,
        pre="", expect=None, note=""):
    method, url_path, op = OPS[op_id]
    USED.add(op_id)
    # Never leave out a body the contract requires.
    rb = op.get("requestBody", {})
    if body is None and rb.get("required"):
        body = synth(rb["content"]["application/json"]["schema"])
    path = path or {}
    url = re.sub(r"\{(\w+)\}", lambda m: path.get(m.group(1), "{{" + m.group(1) + "}}"), url_path)
    raw = "{{baseUrl}}" + url
    if query:
        raw += "?" + "&".join(f"{k}={v}" for k, v in query.items())
    headers = []
    if body is not None:
        headers.append({"key": "Content-Type", "value": "application/json"})
    if idempotent(op):
        headers.append({"key": "Idempotency-Key", "value": "{{$guid}}"})
    status = expect or expected_status(op)
    who = ROLES[role][1] if role in ROLES else ("no login" if role is None else role)
    desc = f"**{op.get('summary', op_id)}** (`{op_id}`) · as {who}\n\n" + op.get("description", "")
    if note:
        desc = note + "\n\n" + desc
    tests = f"pm.test('status is {status}', () => pm.response.to.have.status({status}));\n"
    if saves:
        tests += save_js(saves)
    request = {
        "method": method,
        "header": headers,
        "url": {
            "raw": raw,
            "host": ["{{baseUrl}}"],
            "path": [p for p in url.split("/") if p],
            **({"query": [{"key": k, "value": str(v)} for k, v in query.items()]} if query else {}),
        },
        "description": desc.strip(),
        "auth": (
            {"type": "noauth"}
            if role is None
            else {"type": "bearer", "bearer": [{"key": "token", "value": "{{token_" + role + "}}", "type": "string"}]}
        ),
    }
    if body is not None:
        request["body"] = {"mode": "raw", "raw": json.dumps(body, indent=2, ensure_ascii=False),
                           "options": {"raw": {"language": "json"}}}
    events = [{"listen": "test", "script": {"type": "text/javascript", "exec": tests.splitlines()}}]
    if pre:
        events.insert(0, {"listen": "prerequest", "script": {"type": "text/javascript", "exec": pre.strip().splitlines()}})
    return {"name": name, "request": request, "event": events}


def login(role):
    email, who = ROLES[role]
    return req(
        f"Log in as {who}", "login", None,
        {"email": email, "password": "{{password}}", "client": "app"},
        saves={f"token_{role}": "json.tokens.access_token",
               f"refresh_{role}": "json.tokens.refresh_token",
               f"{role}_id": "json.user.id"},
    )


def folder(name, items, description=""):
    return {"name": name, "item": items, "description": description}


S = SEED
proof = lambda slot: {  # noqa: E731
    "slot_id": slot, "upload_id": "{{proof_upload_id}}", "taken_at": "{{now}}",
    "lat": 30.7046, "lng": 76.7179, "accuracy_m": 8, "mocked_location": False,
}

folders = [
    folder("1. Start here: log in as each role", [
        req("Health (starts a new run)", "getHealth",
            pre="pm.collectionVariables.set('run', String(Date.now()).slice(-8));"),
        login("worker"), login("agent"), login("customer"), login("admin"),
        req("Who am I (Ravi)", "getMe", "worker"),
    ], "Seeded people (illustrative), password `sunlight1`. Run this folder first: it fills `token_worker`, `token_agent`, `token_customer` and `token_admin`."),

    folder("2. Company admin: set up work", [
        req("Create a task for Ravi (approved later)", "createTask", "admin", {
            "customer_id": S["customer_approved"], "title": "Net meter check (illustrative)",
            "stage_index": 5, "assignee_id": "{{worker_id}}", "due_at": "{{tomorrow}}",
            "admin_note": "Photo of the sealed meter, please.",
            "photos": [{"id": "meter", "label": "Net meter", "hint": "Seal visible"}],
            "checklist": [{"id": "seal", "text": "Meter sealed"}],
        }, saves={"new_task_id": "json.id"}),
        req("Create a second task for Ravi (sent back later)", "createTask", "admin", {
            "customer_id": S["customer_approved"], "title": "Inverter check (illustrative)",
            "stage_index": 5, "assignee_id": "{{worker_id}}", "due_at": "{{tomorrow}}",
            "photos": [{"id": "inverter", "label": "Inverter display"}],
            "checklist": [{"id": "earthing", "text": "Earthing checked"}],
        }, saves={"second_task_id": "json.id"}),
    ], "The tasks the installer works on next."),

    folder("3. Installer (Ravi)", [
        req("Home", "getOrgHome", "worker"),
        req("Tasks: today", "listMyTasks", "worker", query={"view": "today"}),
        req("Tasks: upcoming", "listMyTasks", "worker", query={"view": "upcoming"}),
        req("Tasks: done", "listMyTasks", "worker", query={"view": "done"}),
        req("Open the new task", "getTask", "worker", path={"task_id": "{{new_task_id}}"}),
        req("Tick its checklist item", "setTaskChecklistItem", "worker", {"done": True},
            path={"task_id": "{{new_task_id}}", "item_id": "seal"}),
        req("Get an upload URL (what the scripts below do first)", "createUpload", "worker",
            {"content_type": "image/jpeg", "size_bytes": 2048, "purpose": "proof"},
            note="Returns a signed R2 URL for 15 minutes. The requests that need a file do this, then PUT a small file to that URL, in their pre-request script."),
        req("Add its proof photo", "addTaskPhoto", "worker", proof("meter"),
            path={"task_id": "{{new_task_id}}"},
            pre=upload_pre("token_worker", "proof", "image/jpeg", ["proof_upload_id"])),
        req("Message the admin", "sendTaskMessage", "worker",
            {"text": "Meter sealed, photo added (illustrative)."}, path={"task_id": "{{new_task_id}}"}),
        req("Submit it", "submitTask", "worker", {"note": "All done, meter sealed (illustrative)."},
            path={"task_id": "{{new_task_id}}"}),
        req("Second task: tick", "setTaskChecklistItem", "worker", {"done": True},
            path={"task_id": "{{second_task_id}}", "item_id": "earthing"}),
        req("Second task: photo", "addTaskPhoto", "worker", proof("inverter"),
            path={"task_id": "{{second_task_id}}"},
            pre=upload_pre("token_worker", "proof", "image/jpeg", ["proof_upload_id"])),
        req("Second task: submit", "submitTask", "worker", {"note": "Inverter checked (illustrative)."},
            path={"task_id": "{{second_task_id}}"}),
        req("Report a problem on another task", "reportTaskProblem", "worker", {
            "reason": first_enum("TaskProblemReason"),
            "note": "Customer not at home (illustrative).",
        }, path={"task_id": S["task_problem"]}),
        req("Task history", "getTaskHistory", "worker", path={"task_id": "{{new_task_id}}"}),
        req("My stats", "getMyStats", "worker"),
        req("My ID documents", "listMyDocuments", "worker"),
        req("My expenses", "listMyExpenses", "worker"),
        req("Log an expense with a receipt", "createExpense", "worker", {
            "amount": 124000, "category": first_enum("ExpenseCategory", "fuel"),
            "note": "Diesel for the site van (illustrative)", "spent_on": "{{today}}",
            "receipt_upload_id": "{{receipt_upload_id}}", "task_id": "{{new_task_id}}",
        }, saves={"new_expense_id": "json.id"},
            pre=upload_pre("token_worker", "receipt", "application/pdf", ["receipt_upload_id"])),
        req("Open the expense", "getExpense", "worker", path={"expense_id": "{{new_expense_id}}"}),
        req("Fix a returned receipt", "replaceExpenseReceipt", "worker",
            {"upload_id": "{{receipt_upload_id}}", "note": "Clearer photo (illustrative)."},
            path={"expense_id": S["expense_needs_fix"]},
            pre=upload_pre("token_worker", "receipt", "application/pdf", ["receipt_upload_id"])),
    ], "Seeded worker Ravi, in Example Solar (illustrative)."),

    folder("4. Sales agent (Meena)", [
        req("Home", "getOrgHome", "agent"),
        req("Register a customer with KYC", "submitCustomerRegistration", "agent", {
            "name": "Postman Customer {{run}} (illustrative)", "phone": "9{{run}}1",
            "email": "customer{{run}}@example.com", "address": "House 9, Phase 7",
            "city": "Mohali", "pin_code": "160062", "state": "Punjab", "discom": "PSPCL",
            "consumer_number": "PM{{run}}", "sanctioned_load_kw": 5,
            "connection_type": first_enum("ConnectionType"), "proposed_kw": 5,
            "roof": first_enum("RoofType"), "subsidy": True,
            "documents": [
                {"kind": "aadhaar", "files": [{"upload_id": "{{kyc_1}}"}]},
                {"kind": "pan", "files": [{"upload_id": "{{kyc_2}}"}]},
                {"kind": "electricity_bill", "files": [{"upload_id": "{{kyc_3}}"}]},
                {"kind": "land_document", "files": [{"upload_id": "{{kyc_4}}"}]},
                {"kind": "signature", "files": [{"upload_id": "{{kyc_5}}"}]},
                {"kind": "bank_proof", "files": [{"upload_id": "{{kyc_6}}"}]},
            ],
            "consent": True, "commission": 1500000,
        }, saves={"new_customer_id": "json.id"},
            pre=upload_pre("token_agent", "kyc", "application/pdf", ["kyc_1", "kyc_2", "kyc_3", "kyc_4", "kyc_5", "kyc_6"])),
        req("My customers", "listMyCustomers", "agent"),
        req("Open a customer with a returned document", "getMyCustomer", "agent",
            path={"customer_id": S["customer_needs_fix"]}),
        req("Fix the returned document", "replaceCustomerDocument", "agent",
            {"files": [{"upload_id": "{{kyc_1}}"}]},
            path={"customer_id": S["customer_needs_fix"], "kind": "electricity_bill"},
            pre=upload_pre("token_agent", "kyc", "application/pdf", ["kyc_1"])),
    ], "Seeded agent Meena (commission)."),

    folder("5. Customer (Rajinder)", [
        req("Home", "getOrgHome", "customer"),
        req("My install", "getMyInstall", "customer"),
        req("I paid the instalment that's due", "claimInstallPayment", "customer",
            {"method": "upi"} if "requestBody" in OPS["claimInstallPayment"][2] else None,
            path={"payment_id": S["payment_due"]}),
    ], "Seeded customer Rajinder."),

    folder("6. Company admin: decide", [
        req("Review queue", "getReviewQueue", "admin"),
        req("Approve the new task", "approveTask", "admin", path={"task_id": "{{new_task_id}}"}),
        req("Send the second task back", "returnTask", "admin",
            {"note": "Display not readable, retake please (illustrative).", "retake": ["inverter"]},
            path={"task_id": "{{second_task_id}}"}),
        req("Cancel a task", "cancelTask", "admin", {"note": "Customer postponed (illustrative)."},
            path={"task_id": S["task_cancel"]}),
        req("Reschedule the task with a problem", "scheduleTask", "admin",
            {"due_at": "{{tomorrow}}", "assignee_id": None}, path={"task_id": S["task_problem"]}),
        req("Approve the new expense", "approveExpense", "admin", path={"expense_id": "{{new_expense_id}}"}),
        req("Mark it paid", "payExpense", "admin", path={"expense_id": "{{new_expense_id}}"}),
        req("Send an expense back", "returnExpense", "admin",
            {"note": "Receipt unreadable (illustrative)."}, path={"expense_id": S["expense_in_review"]}),
        req("Verify the new customer (sets up the install)", "verifyCustomer", "admin",
            {"total": 28500000, "subsidy": None}, path={"customer_id": "{{new_customer_id}}"}),
        req("Approve the agent's commission", "approveCommission", "admin",
            {"amount": None, "note": None}, path={"customer_id": "{{new_customer_id}}"}),
        req("Send one document back", "returnCustomerDocument", "admin",
            {"note": "Aadhaar photo is blurred (illustrative)."},
            path={"customer_id": S["customer_in_review"], "kind": "aadhaar"}),
        req("Reject a customer", "rejectCustomer", "admin",
            {"note": "Roof not suitable (illustrative)."}, path={"customer_id": S["customer_to_reject"]}),
        req("Pay a payable commission", "payCommission", "admin", path={"customer_id": S["customer_payable"]}),
        req("Ask for the last payment", "requestPayment", "admin", {"due_on": "{{in_ten_days}}"},
            path={"payment_id": S["payment_later"]}),
        req("Confirm the claimed payment", "confirmPayment", "admin", path={"payment_id": S["payment_due"]}),
        req("Hand over an install", "handOver", "admin", path={"customer_id": S["customer_approved"]}),
    ], "Seeded admin Dev. Acts on what folders 2–5 made."),

    folder("7. Notifications", [
        req("Ravi's notifications in the company", "listNotifications", "worker"),
        req("Mark them read", "markNotificationsRead", "worker"),
        req("Ravi's personal notifications", "listMyNotifications", "worker"),
        req("Mark personal ones read", "markMyNotificationsRead", "worker"),
        req("Save a push token (made up)", "registerMyDevice", "worker",
            {"token": "postman-test-token-{{run}}", "platform": "android"},
            note="A made-up token: the push worker's send to it fails and is logged. Use a phone's real token to test pushes."),
    ]),

    folder("8. Profile and settings (Ravi)", [
        req("My details", "getMyDetails", "worker"),
        req("Update my details", "updateMyDetails", "worker", {
            "phone": "9876500001", "address": "House 12, Sector 70, Mohali (illustrative)",
            "emergency_contact": "Sita Example, 9876500002 (illustrative)",
        }),
        req("My settings", "getMySettings", "worker"),
        req("Update my settings", "updateMySettings", "worker", {"push": True, "whatsapp": False, "sound": True}),
        req("Ask for a solar quote (Personal)", "createQuoteRequest", "worker", {
            "quote_for": first_enum("QuoteFor"), "pin_code": "160055", "city": "Mohali",
            "bill_band": first_enum("BillBand"), "roof": first_enum("RoofType"),
            "timeline": first_enum("QuoteTimeline"), "phone": "9876500001", "share_consent": True,
        }),
    ]),

    folder("9. Team (admin)", [
        req("Workers", "listMembers", "admin", query={"role": "worker"}),
        req("Add a worker", "addMember", "admin", {
            "name": "Postman Worker {{run}} (illustrative)", "email": "worker{{run}}@example.com",
            "role": "worker",
        }, saves={"new_member_id": "json.user_id"}),
        req("Remove them", "removeMember", "admin", path={"user_id": "{{new_member_id}}"}),
    ], "Adding a member emails them: run against a server whose mail goes to the log (README.md)."),

    folder("10. Company registration and MarkCliq review", [
        req("Register a company", "registerOrg", None, {
            "legal_name": "Postman Solar {{run}} Private Limited (illustrative)",
            "trade_name": "Postman Solar {{run}} (illustrative)",
            "business_type": first_enum("BusinessType"), "gstin": "{{gstin}}", "terms_version": 1,
            "address_line_1": "Plot 7, Industrial Area", "city": "Mohali", "pin_code": "160055",
            "owner_name": "Postman Owner (illustrative)", "email": "owner{{run}}@example.com",
            "phone": "8{{run}}1",
        }, pre=GSTIN_PRE),
        req("Pending companies", "listPlatformOrgs", "admin", query={"status": "pending"},
            saves={"pending_org_id": "(json.items.find((o) => o.gstin === pm.variables.get('gstin')) || json.items[0]).id"},
            note="Needs Dev to be a platform admin: `cargo run -- make-platform-admin dev@example.com` once."),
        req("Open it", "getPlatformOrg", "admin", path={"org_id": "{{pending_org_id}}"}),
        req("Reject it", "setPlatformOrgStatus", "admin",
            {"status": "rejected", "note": "Test registration from Postman (illustrative)."},
            path={"org_id": "{{pending_org_id}}"}),
    ], "Registering emails MarkCliq's review inbox and the owner: run against a server whose mail goes to the log (README.md)."),

    folder("11. Sessions", [
        req("Refresh Ravi's tokens", "refreshSession", None, {"refresh_token": "{{refresh_worker}}"},
            saves={"token_worker": "json.access_token", "refresh_worker": "json.refresh_token"}),
        req("Website log in (cookie)", "login", None,
            {"email": "dev@example.com", "password": "{{password}}", "client": "web"},
            note="The website's way: a session cookie instead of tokens. Postman keeps the cookie for localhost."),
        req("Who am I (by the cookie)", "getMe", None),
        req("Log out (cookie)", "logout", None),
        req("Log Ravi out", "logout", "worker"),
    ]),

    folder("12. By hand: sign up and passwords", [
        req("Sign up: send the code", "signup", None, {"email": "{{email}}"}),
        req("Sign up: enter the code (from the email)", "verifySignup", None, {"email": "{{email}}", "code": "{{code}}"},
            saves={"signup_token": "json.signup_token"}),
        req("Sign up: the details", "completeSignup", None, {"signup_token": "{{signup_token}}", "name": "Asha Example (illustrative)", "password": "{{new_password}}", "terms_version": 1}),
        req("Forgot password", "forgotPassword", None, {"email": "{{email}}"}),
        req("Reset password (code from the email)", "resetPassword", None,
            {"email": "{{email}}", "code": "{{code}}", "new_password": "{{new_password}}"}),
    ], "These send real emails and need the code from them: set `email` to an inbox you read, then `code`. Not part of the automatic run."),
]

# Endpoints in the contract that no request above covers.
missing = [op_id for op_id in OPS if op_id not in USED]
if missing:
    print("not arranged yet (bodies made from the schema):", ", ".join(missing), file=sys.stderr)
    items = []
    for op_id in missing:
        method, _, op = OPS[op_id]
        content = op.get("requestBody", {}).get("content", {}).get("application/json")
        body = synth(content["schema"]) if content else None
        items.append(req(op_id, op_id, "admin", body))
    folders.append(folder("Not arranged yet", items, "New in the contract; check the role and body."))

collection = {
    "info": {
        "name": "SolaCliq API (local)",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        "description": (
            "Generated from `api/openapi.yaml` by `api/postman/generate.py` (`make postman`); "
            "don't edit by hand. Every person, company and value here is illustrative.\n\n"
            "Against the seeded local API: `cargo run -- seed`, then run the folders in order. "
            "See `api/postman/README.md`."
        ),
    },
    "variable": [
        {"key": "baseUrl", "value": "http://localhost:8080/api/v1"},
        {"key": "password", "value": "sunlight1"},
        {"key": "org_id", "value": SEED["org_id"]},
        *({"key": f"token_{r}", "value": ""} for r in ROLES),
        {"key": "email", "value": "tester1@example.com"},
        {"key": "new_password", "value": "moonlight44"},
        {"key": "code", "value": ""},
        {"key": "run", "value": ""},
    ],
    "event": [
        {"listen": "prerequest", "script": {"type": "text/javascript", "exec": COMMON_PRE.strip().splitlines()}},
        {"listen": "test", "script": {"type": "text/javascript", "exec": [
            "pm.test('no server error', () => pm.expect(pm.response.code).to.be.below(500));"]}},
    ],
    "item": folders,
}

OUT.write_text(json.dumps(collection, indent=2, ensure_ascii=False) + "\n")
print(f"wrote {OUT.relative_to(ROOT)}: {sum(len(f['item']) for f in folders)} requests, "
      f"{len(USED)} of {len(OPS)} operations")
