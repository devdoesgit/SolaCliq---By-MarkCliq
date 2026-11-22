# F5 Documents: several files, any size

Status: `spec`, waiting for the owner's review (2026-11-22). No code yet.
The contract below moves into `api/openapi.yaml` when approved: put
there earlier, the generated clients would no longer match the code.

## Goal

What the owner asked on 2026-11-22:

- "yeah upto 5 files": each KYC document holds up to 5 files, with
  Aadhaar's front and back as two labelled slots.
- "dont put a limit on documents that might be big": no 10 MB cap.
- From the same day: nothing about a file blocks a flow. The admin
  judges what it shows.

## Today

- One file per document: `documents.upload_id`, one row per
  `(customer_id, kind)`. An agent photographing an Aadhaar card can send
  one side; a land deed, one page.
- 10 MB, in four places: the app (`UploadRepository.maxBytes`), the
  server (`uploads.rs`, MAX_BYTES), the database (`uploads.size_bytes`
  CHECK) and the contract (`maximum: 10485760`).
- Removing those alone isn't enough:
  - the app reads the whole file into memory (`UploadFile.bytes`), so a
    big PDF can crash a cheap phone;
  - the transfer stops after 2 minutes (`sendTimeout`), about 15 MB on
    a 1 Mbps connection.

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

### No size limit

- KYC and receipts: no limit of ours. Storage's own is 5 GB for one
  PUT; past it the app says so.
- Logos stay at 1 MB. Proof photos stay at 10 MB (the live camera's
  JPEGs are far under it).
- The app streams from the file's path and never holds it in memory.
  Previews decode at thumbnail size.
- No total timeout. An upload fails only after 60 seconds with no bytes
  moving, and can be cancelled or retried (with a new URL).
- The 15-minute URL only has to be valid when the upload starts.

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
- `uploads.size_bytes`: at least 1; up to 5 GB for `kyc` and `receipt`,
  10 MB for `proof`, 1 MB for `logo`.

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

# UploadCreate.size_bytes: no 10 MB maximum
type: integer
format: int64
minimum: 1
maximum: 5368709120
```

Errors: 422 on `documents` (or `files`) for none, over five, or the same
upload twice. One file that didn't arrive refuses the whole request with
nothing attached, as now.

## Tests

- Backend: 1 and 5 files accepted; 0, 6 and a repeat refused; another
  agent's or company's file refused with nothing kept; a replacement
  swaps the whole set; existing rows survive the migration; a 200 MB
  upload is signed.
- App: front only, back only, and both; remove and retry one file;
  review waits for uploads; a big file is never read into memory.
- Emulator, against R2's dev bucket: a 100 MB PDF, a throttled
  connection past 2 minutes, a dropped connection then retry.

## Not in scope

Resuming a half-sent file, uploading with the app closed, compressing
PDFs, the admin's document viewer (with the website).

## For the owner to decide

1. **Old staging builds** send `upload_id` and would fail to register a
   customer. Recommended: break it now, before go-live, and update them.
2. **Storage abuse.** With no cap, one member could send up to 200
   files of 5 GB in an hour (the rate limit). Recommended: accept it for
   the pilot and set a billing alert in Cloudflare.
3. **Receipts** lose the cap too, but stay one file each. Recommended:
   yes, as they share the upload code.
