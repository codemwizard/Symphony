-- Migration 0121: Create data_authority_level ENUM type and add columns
-- Tasks: TSK-P2-PREAUTH-006A-01, TSK-P2-PREAUTH-006A-02, TSK-P2-PREAUTH-006A-03, TSK-P2-PREAUTH-006A-04
-- Phase: PRE-PHASE2

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'data_authority_level') THEN
        CREATE TYPE public.data_authority_level AS ENUM (
            'phase1_indicative_only',
            'non_reproducible',
            'derived_unverified',
            'policy_bound_unsigned',
            'authoritative_signed',
            'superseded',
            'invalidated'
        );
    END IF;
END $$;

-- EXPAND PHASE: Add nullable columns
ALTER TABLE monitoring_records
ADD COLUMN IF NOT EXISTS data_authority public.data_authority_level,
ADD COLUMN IF NOT EXISTS audit_grade BOOLEAN,
ADD COLUMN IF NOT EXISTS authority_explanation TEXT;

ALTER TABLE asset_batches
ADD COLUMN IF NOT EXISTS data_authority public.data_authority_level,
ADD COLUMN IF NOT EXISTS audit_grade BOOLEAN,
ADD COLUMN IF NOT EXISTS authority_explanation TEXT;

-- BACKFILL: Set default values for existing data
UPDATE monitoring_records
SET data_authority = 'phase1_indicative_only',
    audit_grade = false,
    authority_explanation = 'Phase 1 data - no execution binding'
WHERE data_authority IS NULL;

UPDATE asset_batches
SET data_authority = 'phase1_indicative_only',
    audit_grade = false,
    authority_explanation = 'Phase 1 data - no execution binding'
WHERE data_authority IS NULL;

-- CONTRACT PHASE: Set NOT NULL constraints
ALTER TABLE monitoring_records
ALTER COLUMN data_authority SET NOT NULL,
ALTER COLUMN audit_grade SET NOT NULL,
ALTER COLUMN authority_explanation SET NOT NULL;

ALTER TABLE asset_batches
ALTER COLUMN data_authority SET NOT NULL,
ALTER COLUMN audit_grade SET NOT NULL,
ALTER COLUMN authority_explanation SET NOT NULL;
