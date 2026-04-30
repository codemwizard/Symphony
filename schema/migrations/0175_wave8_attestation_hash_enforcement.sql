-- Migration: 0175_wave8_attestation_hash_enforcement.sql
-- Task: TSK-P2-W8-DB-004
-- Purpose: Recompute authoritative attestation hash at DB write boundary and hard-reject mismatches
-- Dependencies: TSK-P2-W8-ARCH-002, TSK-P2-W8-DB-003
-- Type: Forward-only migration

-- Create the transition hash recomputation function
-- This function recomputes the transition hash from the canonical payload bytes
-- using the exact rules defined in TRANSITION_HASH_CONTRACT.md
CREATE OR REPLACE FUNCTION public.recompute_transition_hash(
    p_canonical_payload_bytes bytea
)
RETURNS text
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    canonical_json text;
    hash_bytes bytea;
    hash_hex text;
BEGIN
    -- Validate input is not null
    IF p_canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for hash recomputation'
        USING ERRCODE = '23502';
    END IF;
    
    -- Decode bytes to JSON
    canonical_json := convert_from(p_canonical_payload_bytes, 'UTF8');
    
    -- Validate JSON is not null
    IF canonical_json IS NULL THEN
        RAISE EXCEPTION 'Failed to decode canonical payload bytes'
        USING ERRCODE = 'P7804';
    END IF;
    
    -- Compute SHA-256 hash of canonical bytes
    hash_bytes := digest(p_canonical_payload_bytes, 'sha256');
    
    -- Encode as lowercase hex
    hash_hex := lower(encode(hash_bytes, 'hex'));
    
    -- Validate hash is exactly 64 characters
    IF length(hash_hex) != 64 THEN
        RAISE EXCEPTION 'Hash recomputation failed: invalid hash length'
        USING ERRCODE = 'P7804';
    END IF;
    
    RETURN hash_hex;
END;
$$;

-- Create the hash enforcement function
-- This function enforces fail-closed rejection when caller-supplied hash does not match recomputed hash
CREATE OR REPLACE FUNCTION public.enforce_transition_hash_match()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    recomputed_hash text;
BEGIN
    -- Skip enforcement if transition_hash is null (should not happen after DB-002)
    IF NEW.transition_hash IS NULL THEN
        RAISE EXCEPTION 'transition_hash is required for Wave 8 enforcement'
        USING ERRCODE = '23502';
    END IF;
    
    -- Skip enforcement if canonical_payload_bytes is null (should not happen after DB-003)
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'canonical_payload_bytes is required for hash recomputation'
        USING ERRCODE = '23502';
    END IF;
    
    -- Recompute hash from canonical payload bytes
    recomputed_hash := recompute_transition_hash(NEW.canonical_payload_bytes);
    
    -- Compare caller-supplied hash with recomputed hash
    IF NEW.transition_hash != recomputed_hash THEN
        RAISE EXCEPTION 'Transition hash mismatch: caller-supplied % does not match recomputed %',
            NEW.transition_hash, recomputed_hash
        USING ERRCODE = 'P7805'; -- Wave 8: transition hash mismatch during replay verification
    END IF;
    
    RETURN NEW;
END;
$$;

-- Add hash enforcement trigger to asset_batches
-- This trigger enforces hash recomputation at the authoritative boundary
DROP TRIGGER IF EXISTS trg_enforce_transition_hash_match ON public.asset_batches;
CREATE TRIGGER trg_enforce_transition_hash_match
    BEFORE INSERT OR UPDATE ON public.asset_batches
    FOR EACH ROW
    EXECUTE FUNCTION enforce_transition_hash_match();

-- Add comments
COMMENT ON FUNCTION public.recompute_transition_hash(bytea) IS
    'Wave 8 transition hash recomputation function - recomputes hash from canonical payload bytes using SHA-256 per TRANSITION_HASH_CONTRACT.md.';

COMMENT ON FUNCTION public.enforce_transition_hash_match() IS
    'Wave 8 hash enforcement function - enforces fail-closed rejection when caller-supplied hash does not match recomputed authoritative hash.';

COMMENT ON TRIGGER trg_enforce_transition_hash_match ON public.asset_batches IS
    'Wave 8 hash enforcement trigger - recomputes and validates transition hash at asset_batches write boundary, rejecting tampered hashes.';
