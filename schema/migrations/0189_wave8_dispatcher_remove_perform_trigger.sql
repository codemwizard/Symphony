-- Migration: 0189_wave8_dispatcher_remove_perform_trigger.sql
-- Task: TSK-P2-W8-DB-001 (remediation)
-- Purpose: Fix dispatcher calling trigger function via PERFORM
-- Dependencies: 0172_wave8_dispatcher_topology.sql, 0175_wave8_attestation_hash_enforcement.sql
-- Type: Forward-only migration
--
-- Bug: Migration 0172 calls enforce_transition_hash_match() via PERFORM, but that function
-- is defined as RETURNS TRIGGER and depends on NEW context. Trigger functions cannot be
-- called as ordinary SQL functions. The hash enforcement already runs via its own trigger
-- (trg_enforce_transition_hash_match from 0175), so the dispatcher should not call it directly.
-- Fix: Redefine the dispatcher without the PERFORM call.

CREATE OR REPLACE FUNCTION public.wave8_asset_batches_dispatcher()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Wave 8 Dispatcher: Single authoritative execution path for asset_batches writes
    
    -- Gate 1: Canonical payload construction (from 0174)
    -- Ensure canonical_payload_bytes is present and valid
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for Wave 8'
        USING ERRCODE = '23502';
    END IF;
    
    -- Gate 2: Transition hash enforcement (from 0175)
    -- Note: enforce_transition_hash_match() is a trigger function (RETURNS TRIGGER) and
    -- runs via its own trigger trg_enforce_transition_hash_match. It cannot be called
    -- via PERFORM. Hash enforcement is handled by the dedicated trigger.
    
    -- If all dispatcher-owned gates pass, allow the insert
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Fail closed on any validation error
        RAISE EXCEPTION 'Wave 8 dispatcher validation failed: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.wave8_asset_batches_dispatcher() IS
    'Wave 8 authoritative dispatcher for asset_batches - coordinates validation gates. Fixed in 0189 to remove invalid PERFORM call on trigger function enforce_transition_hash_match (hash enforcement runs via dedicated trigger trg_enforce_transition_hash_match).';
