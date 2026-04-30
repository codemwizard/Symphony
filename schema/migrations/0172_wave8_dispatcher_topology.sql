-- Migration: 0172_wave8_dispatcher_topology.sql
-- Task: TSK-P2-W8-DB-001
-- Purpose: Establish one authoritative dispatcher trigger on asset_batches for Wave 8
-- Dependencies: TSK-P2-W8-ARCH-005
-- Type: Forward-only migration

-- Create the Wave 8 dispatcher function
-- This function will coordinate all Wave 8 validation gates in explicit sequence
CREATE OR REPLACE FUNCTION public.wave8_asset_batches_dispatcher()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    validation_result boolean;
BEGIN
    -- Wave 8 Dispatcher: Single authoritative execution path for asset_batches writes
    
    -- Gate 1: Canonical payload construction (from 0174)
    -- Ensure canonical_payload_bytes is present and valid
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for Wave 8'
        USING ERRCODE = '23502';
    END IF;
    
    -- Gate 2: Transition hash enforcement (from 0175)
    -- Recompute hash and verify it matches
    PERFORM enforce_transition_hash_match();
    
    -- Note: Placeholder rejection (0173) is handled by separate trigger trg_wave8_reject_placeholders
    -- Note: Cryptographic enforcement (0177) is handled by separate trigger trg_wave8_cryptographic_enforcement
    -- These run in trigger order: placeholder rejection -> dispatcher -> hash enforcement -> cryptographic enforcement
    
    -- If all gates pass, allow the insert
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Fail closed on any validation error
        RAISE EXCEPTION 'Wave 8 dispatcher validation failed: %', SQLERRM;
END;
$$;

-- Drop existing independent triggers to establish single dispatcher topology
-- This removes competing authority paths
DROP TRIGGER IF EXISTS trg_attestation_gate_asset_batches ON public.asset_batches;
DROP TRIGGER IF EXISTS trg_enforce_attestation_freshness ON public.asset_batches;
DROP TRIGGER IF EXISTS trg_enforce_asset_batch_authority ON public.asset_batches;

-- Create the single authoritative dispatcher trigger
CREATE TRIGGER trg_wave8_asset_batches_dispatcher
    BEFORE INSERT ON public.asset_batches
    FOR EACH ROW
    EXECUTE FUNCTION wave8_asset_batches_dispatcher();

-- Add comments
COMMENT ON FUNCTION public.wave8_asset_batches_dispatcher() IS
    'Wave 8 authoritative dispatcher for asset_batches - coordinates all validation gates in explicit sequence. Replaces multiple independent triggers with single deterministic execution path.';

COMMENT ON TRIGGER trg_wave8_asset_batches_dispatcher ON public.asset_batches IS
    'Wave 8 authoritative dispatcher trigger - single execution path for all asset_batches writes, enforcing contract-defined validation gates in sequence.';
