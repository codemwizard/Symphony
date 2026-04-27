-- Migration 0159: Enforce NOT NULL on state_transitions.interpretation_version_id
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-17c-alpha)
-- Depends on: 0158 (backfill completed)

-- Pre-check: abort if any NULL rows still exist
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM state_transitions WHERE interpretation_version_id IS NULL LIMIT 1) THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: NULL interpretation_version_id rows exist';
    END IF;
END $$;

ALTER TABLE state_transitions ALTER COLUMN interpretation_version_id SET NOT NULL;
