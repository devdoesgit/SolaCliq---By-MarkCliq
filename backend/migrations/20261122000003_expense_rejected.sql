/*
    An expense can be rejected (W5)
    --------------------------------------------------------------------
    - final, with the admin's reason; `needs_fix` stays for what the
      person can still put right
*/
ALTER TYPE expense_status ADD VALUE IF NOT EXISTS 'rejected';
