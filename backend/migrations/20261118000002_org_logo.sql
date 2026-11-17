/*
    Company logos (F15)
    --------------------------------------------------------------------
    - the logo the company's admin uploaded, shown in the app wherever
      the company appears. Null: the app shows the company's initials
    - a key in R2 under the company's own prefix, like every file of
      the company: orgs/<org_id>/logo/<upload_id>
    - the `orgs` row-level security policies already cover it
*/

ALTER TABLE orgs ADD COLUMN logo_key text
    CHECK (logo_key LIKE 'orgs/' || id || '/logo/%');
