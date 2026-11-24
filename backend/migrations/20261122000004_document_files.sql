/*
    Several files per KYC document (F5)
    --------------------------------------------------------------------
    - a document stays one row (one status, one note); its 1 to 5 files
      are here, in the order the agent added them
    - `side` labels an Aadhaar's front and back; never required
    - a replaced set keeps its rows (`replaced_at`) instead of being
      unlinked: deleting a customer's KYC must find every file they ever
      sent, and an unlinked upload can't be traced back to them
*/
CREATE TYPE document_side AS ENUM ('front', 'back');

ALTER TABLE documents ADD CONSTRAINT documents_org_id_id_key UNIQUE (org_id, id);

CREATE TABLE document_files (
    org_id       uuid           NOT NULL,
    document_id  uuid           NOT NULL,
    upload_id    uuid           NOT NULL,
    position     smallint       NOT NULL CHECK (position BETWEEN 1 AND 5),
    side         document_side,
    replaced_at  timestamptz,
    PRIMARY KEY (org_id, upload_id),
    FOREIGN KEY (org_id, document_id) REFERENCES documents (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, upload_id) REFERENCES uploads (org_id, id)
);

-- The current set: one file at each position.
CREATE UNIQUE INDEX document_files_current ON document_files (document_id, position)
    WHERE replaced_at IS NULL;
CREATE INDEX document_files_document ON document_files (org_id, document_id);

ALTER TABLE document_files ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_files_company ON document_files TO solacliq_app
    USING (org_id = app_org_id()) WITH CHECK (org_id = app_org_id());

INSERT INTO document_files (org_id, document_id, upload_id, position)
SELECT org_id, id, upload_id, 1 FROM documents;

ALTER TABLE documents DROP COLUMN upload_id;
