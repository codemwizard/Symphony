-- Migration 0146: Add entity_type column to state_rules for per-domain rule scoping
-- This migration adds entity_type TEXT NOT NULL to state_rules table
-- Updates the unique constraint to include entity_type for domain-isolated rule resolution
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-02)

-- Precondition check: ensure no existing rows that would need backfill
DO $$
DECLARE row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM state_rules;
    IF row_count > 0 THEN
        RAISE EXCEPTION 'PRECONDITION: % existing rows in state_rules require explicit backfill before adding NOT NULL entity_type', row_count;
    END IF;
END $$;

-- Add entity_type column with temporary default for DDL
ALTER TABLE state_rules ADD COLUMN IF NOT EXISTS entity_type TEXT NOT NULL DEFAULT '__UNSET__';

-- Remove the temporary default
ALTER TABLE state_rules ALTER COLUMN entity_type DROP DEFAULT;

-- Drop old unique constraint (if exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'state_rules_unique_rule'
    ) THEN
        ALTER TABLE state_rules DROP CONSTRAINT state_rules_unique_rule;
    END IF;
END $$;

-- Create new unique constraint including entity_type
ALTER TABLE state_rules ADD CONSTRAINT state_rules_unique_rule UNIQUE (entity_type, from_state, to_state);
