-- Migration: 0164_registry_supersession_constraints.sql
-- Task: TSK-P2-PREAUTH-007-07
-- Description: Add unique constraints for linear supersession and execution constraints for checksum/freshness
-- Work Item: tsk_p2_preauth_007_07_work_item_01, tsk_p2_preauth_007_07_work_item_02

-- Work Item 01: Add unique constraints to enforce linear supersession (no forks)
-- Ensure that an invariant can only be superseded by one successor at a time
-- This prevents forking of the supersession chain
CREATE UNIQUE INDEX idx_unique_superseded_by ON invariant_registry(superseded_by) WHERE superseded_by IS NOT NULL;

-- Work Item 02: Add registry execution constraints for checksum and freshness
-- Ensure checksum is not null and follows format (already exists from 0163)
-- Add constraint to ensure created_at is not null (already exists from 0163)
-- Add constraint to ensure invariant_id is unique (already exists from 0163)

-- Add constraint to ensure superseded_by references a valid invariant_id
-- This is already enforced by the foreign key constraint from 0163

-- Add constraint to prevent self-supersession
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'no_self_supersession' 
    AND conrelid = 'invariant_registry'::regclass
  ) THEN
    ALTER TABLE invariant_registry 
    ADD CONSTRAINT no_self_supersession 
    CHECK (id != superseded_by OR superseded_by IS NULL);
  END IF;
END $$;

-- Add comment for the new index and constraint
COMMENT ON INDEX idx_unique_superseded_by IS 'Enforces linear supersession - each invariant can only be superseded by one successor at a time';
COMMENT ON CONSTRAINT no_self_supersession ON invariant_registry IS 'Prevents an invariant from superseding itself';
