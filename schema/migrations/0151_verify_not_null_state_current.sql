-- Migration 0151: Verify NOT NULL constraint on state_current.current_state
-- Migration 0138 already created current_state VARCHAR NOT NULL on line 10.
-- This migration verifies the constraint exists and only adds it if missing.
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-07)

-- Assert NOT NULL constraint exists. If not, add it.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'state_current'
               AND column_name = 'current_state'
               AND is_nullable = 'YES') THEN
        ALTER TABLE state_current ALTER COLUMN current_state SET NOT NULL;
        RAISE NOTICE 'NOT NULL constraint added to state_current.current_state';
    ELSE
        RAISE NOTICE 'NOT NULL constraint already present on state_current.current_state';
    END IF;
END $$;
