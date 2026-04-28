-- Migration 0154: Enforce NOT NULL on state_current.last_transition_id
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-14)

-- Obtain an ACCESS EXCLUSIVE lock to enforce strict write isolation during the precondition check and ALTER.
-- This prevents a race condition where a row is inserted between the check and the ALTER.
LOCK TABLE state_current IN ACCESS EXCLUSIVE MODE;

DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count
    FROM state_current
    WHERE last_transition_id IS NULL;

    IF null_count > 0 THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: % rows in state_current have NULL last_transition_id. Backfill required before migration.', null_count;
    END IF;
END $$;

ALTER TABLE state_current
ALTER COLUMN last_transition_id SET NOT NULL;
