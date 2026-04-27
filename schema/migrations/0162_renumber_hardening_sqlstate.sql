-- 0162_renumber_hardening_sqlstate.sql
-- Evict legacy P7601 error to P7504 per DRD-P2-W6-REM-16c

BEGIN;

CREATE OR REPLACE FUNCTION public.issue_adjustment_with_recipient(
  p_parent_instruction_id text,
  p_recipient text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  RAISE EXCEPTION 'ADJUSTMENT_RECIPIENT_NOT_PERMITTED' USING ERRCODE = 'P7504';
END;
$$;

COMMIT;
