"""Writes SolaCliq-production-check.postman_collection.json.

The first check on the live server (deploy/README.md, step 11): your own
account, one company, its approval, and a file to R2. It uses no seed and
no made-up people: every value is yours, filled into the collection's
variables in Postman. Run: python3 api/postman/make_production_check.py
"""

import json
from pathlib import Path

OUT = Path(__file__).with_name("SolaCliq-production-check.postman_collection.json")


def request(name, method, path, body=None, test="", auth=True, description=""):
    headers = [{"key": "Content-Type", "value": "application/json"}] if body else []
    if auth:
        headers.append({"key": "Authorization", "value": "Bearer {{token}}"})
    item = {
        "name": name,
        "request": {
            "method": method,
            "header": headers,
            "url": "{{baseUrl}}" + path,
            "description": description,
        },
        "event": [{"listen": "test", "script": {"type": "text/javascript", "exec": test.strip().splitlines()}}],
    }
    if body is not None:
        item["request"]["body"] = {"mode": "raw", "raw": json.dumps(body, indent=2)}
    return item


def expect(code):
    return f"pm.test('answers {code}', () => pm.response.to.have.status({code}));\n"


SAVE_TOKEN = """
if (pm.response.code === 200) {
  pm.collectionVariables.set('token', pm.response.json().tokens.access_token);
}
"""

ME = """
pm.test('answers 200', () => pm.response.to.have.status(200));
const me = pm.response.json();
console.log('platform admin:', me.is_platform_admin);
me.memberships.forEach((m) => console.log('member of', m.org.name, '(' + m.org.status + ') as', m.role));
const mine = me.memberships.find((m) => m.role === 'org_admin');
if (mine) pm.collectionVariables.set('org_id', mine.org.id);
"""

PENDING = """
pm.test('answers 200', () => pm.response.to.have.status(200));
const email = pm.collectionVariables.get('email').toLowerCase();
const org = pm.response.json().items.find((o) => (o.owner || {}).email === email);
pm.test('your company is waiting', () => pm.expect(org, 'no pending company owned by ' + email).to.exist);
if (org) pm.collectionVariables.set('org_id', org.id);
"""

# A real PUT to the signed R2 link the API gave: proves the token, the
# bucket name and the account. The file is never attached to anything,
# so the API's sweep deletes it within a day.
R2 = """
pm.test('answers 201', () => pm.response.to.have.status(201));
const ticket = pm.response.json();
pm.sendRequest({
  url: ticket.url,
  method: ticket.method,
  header: Object.entries(ticket.headers).map(([key, value]) => ({ key, value })),
  body: { mode: 'raw', raw: pm.collectionVariables.get('r2_test_body') },
}, (err, res) => {
  pm.test('R2 stored the file', () => {
    pm.expect(err, String(err)).to.be.null;
    pm.expect(res.code, res.text()).to.be.below(300);
  });
});
"""

R2_BODY = "SolaCliq production check: a test file, deleted by itself."

collection = {
    "info": {
        "name": "SolaCliq production check",
        "description": (
            "The first check on the live server (deploy/README.md, step 11). Fill in the "
            "collection's variables with your own details; run the requests in order. "
            "No seed, no made-up people. Afterwards clear `password` and `code`."
        ),
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    "variable": [
        {"key": "baseUrl", "value": "https://solacliq.markcliq.com/api/v1"},
        {"key": "email", "value": ""},
        {"key": "name", "value": ""},
        {"key": "phone", "value": "", "description": "10 digits, no +91"},
        {"key": "password", "value": "", "description": "8+ characters with a number. Clear it after."},
        {"key": "code", "value": "", "description": "The 6 digits from the sign-up email"},
        {"key": "legal_name", "value": ""},
        {"key": "trade_name", "value": ""},
        {"key": "business_type", "value": "proprietorship"},
        {"key": "gstin", "value": ""},
        {"key": "address_line_1", "value": ""},
        {"key": "city", "value": ""},
        {"key": "pin_code", "value": ""},
        {"key": "signup_token", "value": ""},
        {"key": "token", "value": ""},
        {"key": "org_id", "value": ""},
        {"key": "r2_test_body", "value": R2_BODY},
    ],
    "item": [
        {"name": "0 Is it up", "item": [
            request("Health", "GET", "/health", auth=False,
                    test=expect(200) + "pm.test('database ok', () => pm.expect(pm.response.json().database).to.eql('ok'));"),
        ]},
        {"name": "1 Your account", "description": "1a–1c once, to sign up. If you already have an account, go to 1d.", "item": [
            request("1a Send the sign-up code", "POST", "/auth/signup", {"email": "{{email}}"}, expect(202), auth=False,
                    description="Emails a 6-digit code. Put it in the `code` variable."),
            request("1b Check the code", "POST", "/auth/signup/verify", {"email": "{{email}}", "code": "{{code}}"},
                    expect(200) + "if (pm.response.code === 200) pm.collectionVariables.set('signup_token', pm.response.json().signup_token);",
                    auth=False),
            request("1c Finish signing up", "POST", "/auth/signup/complete",
                    {"signup_token": "{{signup_token}}", "name": "{{name}}", "phone": "{{phone}}",
                     "password": "{{password}}", "terms_version": 1},
                    expect(200) + SAVE_TOKEN, auth=False),
            request("1d Log in", "POST", "/auth/login",
                    {"email": "{{email}}", "password": "{{password}}", "client": "app"},
                    expect(200) + SAVE_TOKEN, auth=False,
                    description="The token lasts 15 minutes: run this again when a request answers 401."),
            request("1e Who am I", "GET", "/me", test=ME),
        ]},
        {"name": "2 A company", "description": (
            "Before 2b, on the server: make your account the platform admin "
            "(docker compose ... exec api solacliq-api make-platform-admin <email>)."), "item": [
            request("2a Register the company", "POST", "/org-registrations",
                    {"terms_version": 1, "legal_name": "{{legal_name}}", "trade_name": "{{trade_name}}",
                     "business_type": "{{business_type}}", "gstin": "{{gstin}}",
                     "address_line_1": "{{address_line_1}}", "city": "{{city}}", "pin_code": "{{pin_code}}",
                     "owner_name": "{{name}}", "email": "{{email}}", "phone": "{{phone}}"},
                    expect(202) + "console.log('MarkCliq should now get the review email at info@markcliq.com');",
                    auth=False, description="You are its owner: the same email as your account."),
            request("2b Companies waiting", "GET", "/platform/orgs?status=pending", test=PENDING),
            request("2c Approve it", "POST", "/platform/orgs/{{org_id}}/status", {"status": "active"},
                    expect(200) + "pm.test('now active', () => pm.expect(pm.response.json().status).to.eql('active'));"),
        ]},
        {"name": "3 As its admin", "item": [
            request("3a Who am I now", "GET", "/me",
                    test=ME + "\npm.test('admin of the company', () => pm.expect(mine).to.exist);"),
            request("3b The company's overview", "GET", "/orgs/{{org_id}}/admin/overview", test=expect(200)),
            request("3c A file to R2", "POST", "/orgs/{{org_id}}/uploads",
                    {"content_type": "image/png", "size_bytes": len(R2_BODY), "purpose": "logo"}, test=R2,
                    description="Asks the API for an upload link, then sends a small test file to it."),
        ]},
    ],
}

OUT.write_text(json.dumps(collection, indent=2) + "\n")
print(f"Wrote {OUT}")
