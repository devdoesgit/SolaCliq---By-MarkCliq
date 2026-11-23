# F5 Documents: several files, up to 50 MB

Status: built 2026-11-22: the 50 MB limit, and 1 to 5 files per document
on the server, in the app and on the admin website. Not yet run on a
phone or against real R2 (the emulator checks under Tests).

## Goal

What the owner asked on 2026-11-22:

- "yeah upto 5 files": each KYC document holds up to 5 files, with
  Aadhaar's front and back as two labelled slots.
- "dont put a limit on documents that might be big", then later that
  day "for now lets limit docs to 50mb": 50 MB a file.
- From the same day: nothing about a file blocks a flow. The admin
  judges what it shows.

## Today

- One file per document: `documents.upload_id`, one row per
  `(customer_id, kind)`. An agent photographing an Aadhaar card can send
  one side; a land deed, one page.
- 50 MB for a KYC document, in four places: the app
  (`UploadRepository.maxKycBytes`), the server (`uploads.rs`,
  MAX_KYC_MB), the database (`uploads.size_bytes` CHECK) and the contract.
- An upload gets 2 minutes plus a second per 64 KB, so 50 MB works from
  about 0.5 Mbps.
- The app reads the whole file into memory (`UploadFile.bytes`): fine
  for one 50 MB file, not for five picked together.

## In scope

### Several files per document

- A document stays one row, with one status and one admin note. Its
  files go in a new table.
- 1 to 5 files, in the order added. Photos and PDFs can be mixed.
- **Aadhaar:** "Front" and "Back" slots, then "Add more". One file is
  enough to continue: an e-Aadhaar PDF has both sides, and a required
  Back would block it.
- Each file shows its own progress, retry and remove until submitted.
  The document counts as added once one file is up. Review waits while
  any is still uploading.
- The admin returns a whole document. The agent's replacement is a new
  set of 1 to 5 files; the old files stay in R2 as the record, as now.

### Size (the limit is built)

- KYC: 50 MB a file. Receipts and proof photos 10 MB, logos 1 MB.
- With several files, the app streams from each file's path and never
  holds them in memory. Previews decode at thumbnail size.
- The time limit on an upload becomes an idle one: it fails after 60
  seconds with no bytes moving, and can be cancelled or retried (with a
  new URL).

## Data (a new migration; none edited)

```sql
CREATE TABLE document_files (
    org_id      uuid     NOT NULL,
    document_id uuid     NOT NULL,
    upload_id   uuid     NOT NULL,
    position    smallint NOT NULL CHECK (position BETWEEN 1 AND 5),
    side        document_side,               -- 'front', 'back' or empty
    PRIMARY KEY (document_id, position),
    UNIQUE (org_id, upload_id)
);
```

- Composite foreign keys on `org_id` to `documents` and `uploads`; row
  level security with the company policy.
- Each `documents.upload_id` is copied in as position 1, then dropped.

## Contract

```yaml
DocumentFile:
  type: object
  required: [upload_id]
  properties:
    upload_id: { $ref: "#/components/schemas/Id" }
    side: { type: string, enum: [front, back] }

# CustomerRegistrationCreate.documents[]: was {kind, upload_id}
required: [kind, files]
properties:
  kind: { $ref: "#/components/schemas/KycKind" }
  files:
    type: array
    minItems: 1
    maxItems: 5
    items: { $ref: "#/components/schemas/DocumentFile" }

# DocumentReplace: was {upload_id}
required: [files]

```

Errors: 422 on `documents` (or `files`) for none, over five, or the same
upload twice. One file that didn't arrive refuses the whole request with
nothing attached, as now.

## Tests

- Backend: 1 and 5 files accepted; 0, 6 and a repeat refused; another
  agent's or company's file refused with nothing kept; a replacement
  swaps the whole set; existing rows survive the migration.
- App: front only, back only, and both; remove and retry one file;
  review waits for uploads; a big file is never read into memory.
- Emulator, against R2's dev bucket: five 50 MB PDFs, a throttled
  connection past 2 minutes, a dropped connection then retry.

## Not in scope

Resuming a half-sent file, uploading with the app closed, compressing
PDFs, the admin's document viewer (with the website).

## As built

- **Decisions (taken as recommended, owner's "do whatever remains",
  2026-11-22):** old builds break now (API and APK go out together);
  receipts stay 10 MB.
- **One change from the spec's table:** a replaced set keeps its rows,
  marked `replaced_at`, instead of being unlinked. Otherwise deleting a
  customer's KYC (retention) couldn't find the files they sent earlier.
  Files replaced before this migration can't be traced to a customer
  (staging data only).
- Review waits while a file uploads; a failed file doesn't block once
  another of that document is up.
- A storage billing alert in Cloudflare is still worth setting (owner).
