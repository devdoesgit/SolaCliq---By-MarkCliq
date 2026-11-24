/*
    Company logos (F15): a new kind of upload
    --------------------------------------------------------------------
    - its own migration: Postgres can't use a new enum value in the same
      transaction that adds it
*/

ALTER TYPE upload_purpose ADD VALUE 'logo';
