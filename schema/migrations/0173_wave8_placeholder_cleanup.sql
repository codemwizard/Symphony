-- Migration: 0173_wave8_placeholder_cleanup.sql
-- Task: TSK-P2-W8-DB-002
-- Purpose: Remove placeholder and legacy compatibility postures before Wave 8
-- Dependencies: TSK-P2-W8-DB-001, TSK-P2-W8-ARCH-002, TSK-P2-W8-ARCH-003
-- Type: Forward-only migration

-- Step 1: Drop signature placeholder trigger on state_transitions
-- This removes the legacy compatibility posture that adds PLACEHOLDER_PENDING_SIGNING_CONTRACT prefix
DROP TRIGGER IF EXISTS tr_add_signature_placeholder ON public.state_transitions;
DROP FUNCTION IF EXISTS add_signature_placeholder_posture();

-- Step 2: Add CHECK constraint to reject placeholder transition_hash values
-- This prevents any transition_hash starting with "PLACEHOLDER_" from being accepted
ALTER TABLE public.state_transitions
ADD CONSTRAINT no_placeholder_transition_hash
CHECK (transition_hash IS NULL OR transition_hash NOT LIKE 'PLACEHOLDER_%');

-- Step 3: Add CHECK constraint to reject non_reproducible data_authority values
-- This enforces the Wave 8 requirement that data_authority must be reproducible
ALTER TABLE public.state_transitions
ADD CONSTRAINT no_non_reproducible_data_authority
CHECK (data_authority IS NULL OR data_authority != 'non_reproducible');

-- Step 4: Update Wave 8 dispatcher to reject placeholder-style writes
-- This adds a gate to the dispatcher that checks for placeholder values
CREATE OR REPLACE FUNCTION public.wave8_reject_placeholders()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Reject placeholder transition_hash values
    IF NEW.transition_hash LIKE 'PLACEHOLDER_%' THEN
        RAISE EXCEPTION 'Placeholder transition_hash values are not permitted in Wave 8: %', NEW.transition_hash
        USING ERRCODE = 'P7804'; -- Wave 8: transition hash input invalid
    END IF;
    
    -- Reject non_reproducible data_authority values
    IF NEW.data_authority = 'non_reproducible' THEN
        RAISE EXCEPTION 'non_reproducible data_authority is not permitted in Wave 8'
        USING ERRCODE = 'P7815'; -- Wave 8: data authority derivation failure
    END IF;
    
    RETURN NEW;
END;
$$;

-- Add comments
COMMENT ON CONSTRAINT no_placeholder_transition_hash ON public.state_transitions IS
    'Wave 8 constraint: Rejects placeholder transition_hash values (e.g., PLACEHOLDER_PENDING_SIGNING_CONTRACT:) to ensure canonicalization determinism.';

COMMENT ON CONSTRAINT no_non_reproducible_data_authority ON public.state_transitions IS
    'Wave 8 constraint: Rejects non_reproducible data_authority values to enforce reproducibility requirement.';

COMMENT ON FUNCTION public.wave8_reject_placeholders() IS
    'Wave 8 placeholder rejection function - rejects placeholder-style values to prevent contamination of canonicalization and signature semantics.';

-- Add trigger for placeholder rejection
DROP TRIGGER IF EXISTS trg_wave8_reject_placeholders ON public.asset_batches;
CREATE TRIGGER trg_wave8_reject_placeholders
    BEFORE INSERT ON public.asset_batches
    FOR EACH ROW
    EXECUTE FUNCTION wave8_reject_placeholders();

COMMENT ON TRIGGER trg_wave8_reject_placeholders ON public.asset_batches IS
    'Wave 8 placeholder rejection trigger - enforces rejection of placeholder transition_hash and non_reproducible data_authority values.';
