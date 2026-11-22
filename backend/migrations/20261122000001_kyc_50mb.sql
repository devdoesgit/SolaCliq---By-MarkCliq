/*
    KYC documents up to 50 MB (owner, 2026-11-22)
    --------------------------------------------------------------------
    - a scanned land deed can pass 10 MB; other files keep 10 MB
    - logos: the API holds them to 1 MB, as before
*/

ALTER TABLE uploads DROP CONSTRAINT uploads_size_bytes_check;
ALTER TABLE uploads ADD CONSTRAINT uploads_size_bytes_check CHECK (
    size_bytes BETWEEN 1 AND CASE purpose WHEN 'kyc' THEN 52428800 ELSE 10485760 END
);
