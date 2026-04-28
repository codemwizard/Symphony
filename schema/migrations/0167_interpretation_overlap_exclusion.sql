-- Migration: 0167_interpretation_overlap_exclusion.sql
-- Task: TSK-P2-PREAUTH-007-10
-- Description: Add exclusion constraints to prevent historical overlapping of interpretation packs
-- Work Item: tsk_p2_preauth_007_10_work_item_01
-- Depends on: 0116 (temporal columns), 0102 (base table)

-- Ensure btree_gist extension is available for exclusion constraints
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Add exclusion constraint to prevent overlapping interpretation packs
-- for the same jurisdiction and pack_type (domain) over time
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'no_overlapping_interpretation_packs'
    ) THEN
        ALTER TABLE public.interpretation_packs
        ADD CONSTRAINT no_overlapping_interpretation_packs
        EXCLUDE USING gist (
            jurisdiction_code WITH =,
            pack_type WITH =,
            tstzrange(effective_from, effective_to) WITH &&
        );
    END IF;
END
$$;

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT no_overlapping_interpretation_packs ON public.interpretation_packs IS
    'Prevents overlapping interpretation pack validity periods for the same jurisdiction and pack_type (domain)';
