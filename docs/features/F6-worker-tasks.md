# F6 Worker tasks and proof photos

Status: `building`. Spec drafted 2026-10-26 from the owner's iOS v2 worker
designs (SolaCliq Login canvas: Tasks, Task, Proof camera, Submit,
Submitted, Approved, Returned, Report a problem, Reported, Cancelled,
History). **Waiting for the owner's review** of this spec and of the
endpoints below; the mobile side is built against the mock meanwhile.

Mobile first: the worker's screens now; the admin's task screens (create,
assign, review, return, approve, cancel; designs "Admin2 Tasks") in the
admin phase.

## Goal

A worker sees the day's work, goes to the site, proves each step with
geotagged photos from the live camera, ticks the checklist and sends the
task for approval. The admin approves it (moving the customer to the next
install stage), returns it with a note, or decides what happens after a
reported problem. Every step is kept in the task's history.

## Lifecycle

`assigned` → (photos + checklist) → `submitted` → `approved` (final), or
`returned` → (retake) → `submitted` again. The admin can cancel any open
task (`cancelled`, final). A worker can report a problem on an `assigned`
task; it stays `assigned` with `problem` set until the admin reschedules,
reassigns or cancels it.

## In scope

**Backend (owner):** the `tasks` endpoints in `api/openapi.yaml`:

- `GET /orgs/{org_id}/tasks?view=today|upcoming|done`
- `GET /orgs/{org_id}/tasks/{task_id}` and `.../history`
- `POST .../photos` (one slot; replaces on retake; carries GPS, accuracy,
  time and a mocked-location flag; server flags far, inaccurate or mocked
  captures for the admin, never refuses)
- `PUT .../checklist/{item_id}`, `POST .../submit` (needs all photos and
  checklist; locks photos), `POST .../problems`, `POST .../messages`
- `GET /orgs/{org_id}/me/stats` for the profile.
- `POST /uploads` gains purpose `proof`.

**Mobile (Claude):**

- Worker home: "To submit" tile, rows open their task, bell with a dot
  when there are unread notifications.
- Tasks tab: Today, Upcoming (by day), Done (approved and cancelled; they
  open their history).
- Task: customer with call and directions, admin note, stage bar, photo
  slots, checklist; each status shows its banner (submitted, returned,
  problem sent, cancelled) or the approval with the next task.
- Proof camera: live camera only, one slot at a time with its hint, GPS
  and accuracy shown, distance from the site, thumbnails of the slots.
- Submit with an optional note; report a problem (reason, note, optional
  photo); reply to the admin on a returned task.
- History: the task's timeline.
- Raised tab "Upload proof": the camera for the next task with photos
  missing, else the Tasks tab.
- Profile tab: name, role, company, this month's stats; workspaces, help,
  log out. Personal details and ID documents are shown as coming soon.

## Not in scope

Offline queueing of photos (a retry on failure only), editing a submitted
task, workers creating or cancelling tasks, push notifications (F12).

## Related

- Expenses list and detail with "Upload new receipt" (F7, same designs).
- In-app notifications list and "Read all" (part of F12, worker only now).
- Expenses can now link to a task (`task_id`).

## Open

- Whether the photo slots and checklist are set per task by the admin or
  per stage in the org's stage template (the contract allows either).
- Reverse geocoding for the place name on the camera; the app shows the
  distance from the customer's site instead.

## Notes (mobile build, 2026-10-26)

Built against the mock and checked on the emulator against each design.
Where the app differs from the design (see `decisions.md`, 2026-10-26):
no gallery or flip button on the proof camera; "On hold" for a task with a
reported problem; task screens open over the tab bar; no task search. The
app keeps the worker's photo and checklist progress locally while the
mock, which keeps no state, returns the task unchanged.
