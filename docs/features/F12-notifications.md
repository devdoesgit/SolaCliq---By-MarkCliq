# F12 Notifications: push

Status: `building`. In-app notifications are built (phase 6: the
`notifications` table, `GET /me/notifications`, settings). This spec adds
**push**, drafted 2026-11-15. **Waiting for the owner's review** of this
spec and of `PUT /me/device` in `api/openapi.yaml`.

## Goal

When the server writes a notification (a task assigned, a document
returned, a quote sent), the person's phone shows it within seconds, even
with the app closed. Tapping it opens the screen it's about. Nothing new
to read: a push is only a doorbell for a notification that is already in
the in-app list.

## How it works

```
 app                          our server                     Firebase (FCM)
  │ log in                       │                                │
  │── get FCM token ────────────────────────────────────────────▶│
  │◀──────────────────────────────────────────── token ──────────│
  │── PUT /me/device {token} ──▶│ devices: token → this session  │
  │                              │                                │
  │        (later) a task is assigned:                           │
  │                              │ INSERT notification            │
  │                              │ push worker picks it up        │
  │                              │── messages:send (token) ─────▶│
  │◀──────────────────────────────────────────── shows it ───────│
  │ tap → opens the task         │                                │
```

- **Firebase only delivers.** It doesn't know who our users are; our
  server keeps which token belongs to which login and asks Firebase to
  send to each one.
- **A token belongs to a session** (one login on one phone). Logging out,
  a password reset or "log out everywhere" revokes the session, and its
  token gets no more pushes. No separate "unregister" call is needed.
- **A token moves to whoever logged in on that phone last.** Two people
  sharing a phone never get each other's pushes.

## In scope

**Backend**

- `PUT /me/device` `{token, platform: android}` → 204: saves the push
  token for the caller's session (replaces this session's earlier token;
  takes the token from any other session that had it). App sessions only.
- `devices` table: `token` primary key, `session_id` unique (FK to
  `sessions`), `user_id`, `platform`, `updated_at`.
- `notifications.pushed_at`: set when the push worker has handled a row.
- **Push worker** (a background task in the API process):
  1. every 2 seconds, claims up to 50 notifications with `pushed_at` empty
     (`FOR UPDATE SKIP LOCKED`, so two servers never send one twice), and
     marks them handled;
  2. skips the person if their `push` setting is off, and notifications
     older than 10 minutes (a late doorbell is worse than none);
  3. sends one FCM message per live device: the session not revoked and
     its refresh token not expired;
  4. deletes a device FCM answers `UNREGISTERED` for (app uninstalled).
- **FCM HTTP v1 API** with a service-account key
  (`FCM_SERVICE_ACCOUNT_KEY_FILE`; the project id is read from it), scope
  `firebase.messaging`. The Google sign-in code is shared with the Gmail
  mailer (moved to `src/google.rs`).
- Without the key, development logs each push instead of sending it;
  production refuses to start without it, like email.

**The push message** (what the app receives)

```json
{
  "notification": {"title": "New task", "body": "Panel install at Sharma residence"},
  "data": {
    "notification_id": "…", "kind": "task_assigned",
    "org_id": "…", "task_id": "…"
  },
  "android": {"priority": "high", "notification": {"channel_id": "updates"}}
}
```

- `title`, `body` and the ids are the notification row's. `org_id` is
  missing for the Personal workspace; only the ids the row has are sent.
- Channel `updates` makes a sound; `updates_silent` doesn't. Which one
  comes from the person's `sound` setting.
- Nothing secret goes in a push (no codes, no bank details): Google
  carries it.

**App (Android)**

- `firebase_core` + `firebase_messaging`; `google-services.json` with the
  three app ids (`com.markcliq.solacliq`, `.stg`, `.dev`).
- After log in (and on each app start while logged in): get the token,
  `PUT /me/device`. Again whenever Firebase hands out a new token.
- **Permission** (Android 13+): the system prompt, once, the first time a
  home screen opens after log in. If it's denied, the Push notifications
  switch in settings says to turn it on in Android settings and opens
  them.
- **Tap:** opens the notification's screen (the same mapping the
  notifications list uses), switching workspace to `org_id` first. Works
  from a closed app (`getInitialMessage`) and a backgrounded one
  (`onMessageOpenedApp`).
- **App open (foreground):** no system banner; the bell's unread dot and
  the list refresh.
- The two channels are created at start, named "Updates" and "Updates
  (silent)".

## Out of scope

- iPhone (needs an Apple developer account and an APNs key; the pilot is
  the Android APK).
- Pushes to the admin website. Notifications for org admins (a problem
  reported, a task or KYC submitted, a payment claimed) are rows like any
  other, shown on the website's notifications (built with the website);
  admins check the site, so no push or email for them (owner, 2026-11-15).
- Grouping, images, actions on the notification, quiet hours.
- Retrying a failed push: the notification is still in the in-app list.

## Setup (owner)

1. console.firebase.google.com → **Add project** "SolaCliq" under
   MarkCliq's Google account (Analytics off).
2. **Add app → Android** three times: `com.markcliq.solacliq`,
   `com.markcliq.solacliq.stg`, `com.markcliq.solacliq.dev`. Skip the
   SDK steps. Then download `google-services.json` once (it lists all
   three) and tell me where it is. It's git-ignored.
3. Project settings → **Service accounts** → **Generate new private
   key**. Save the JSON outside the repo and tell me the path; don't
   paste it. Keep it separate from the Gmail key: each can do one thing.

## Acceptance checks

- A notification written for a logged-in person shows on their phone
  within 5 seconds, app closed or in the background; tapping it opens
  its screen in the right workspace.
- With `push` off, or after log out, nothing arrives.
- Logging in as someone else on the same phone moves the pushes to them.
- Uninstalling the app removes the device row after the next push.
- Test: the worker's choice of devices and its handling of FCM's answers
  (against a stand-in for FCM), and `PUT /me/device`.

## Notes

- One Firebase project for all three app ids, not one per environment:
  one key, one console; tokens are per app install, so a dev server can't
  reach production phones it never got a token from.
- Claimed-then-sent means a server crash mid-send loses that push (never
  sends it twice). Acceptable: the in-app list is the record.
