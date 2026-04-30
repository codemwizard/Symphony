-- Migration: 0182_wave8_restore_crypto_hardfail.sql
-- Task: TSK-P2-W8-DB-006
-- Purpose: Reassert fail-closed crypto posture at tip of history, superseding 0178-0180 regressions
-- Dependencies: TSK-P2-W8-DB-006
-- Type: Forward-only migration

-- Reassert the cryptographic enforcement function with hard-fail posture
-- This supersedes the placeholder-success posture inherited through 0178-0180
-- The function is restored to the fail-closed state established in 0177
CREATE OR REPLACE FUNCTION public.wave8_cryptographic_enforcement()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    signer_public_key bytea;
    signer_authorized boolean;
    verification_result boolean;
BEGIN
    -- Validate signature fields are present
    IF NEW.signature_bytes IS NULL THEN
        RAISE EXCEPTION 'Signature bytes are required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7807'; -- Wave 8: signature missing or malformed
    END IF;
    
    IF NEW.signer_key_id IS NULL OR NEW.signer_key_id = '' THEN
        RAISE EXCEPTION 'Signer key_id is required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7807';
    END IF;
    
    IF NEW.signer_key_version IS NULL OR NEW.signer_key_version = '' THEN
        RAISE EXCEPTION 'Signer key_version is required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7807';
    END IF;
    
    -- Resolve signer from authoritative signer resolution surface
    SELECT public_key_bytes, is_authorized INTO signer_public_key, signer_authorized
    FROM resolve_authoritative_signer(
        NEW.signer_key_id,
        NEW.signer_key_version,
        NEW.project_id,
        NULL -- entity_type for asset_batches
    );
    
    -- Check if signer is unknown
    IF signer_public_key IS NULL THEN
        RAISE EXCEPTION 'Unknown signer: key_id=%, key_version=%',
            NEW.signer_key_id, NEW.signer_key_version
        USING ERRCODE = 'P7808'; -- Wave 8: signer not found or unauthorized
    END IF;
    
    -- Check if signer is unauthorized
    IF NOT signer_authorized THEN
        RAISE EXCEPTION 'Unauthorized signer: key_id=%, key_version=%, project_id=%',
            NEW.signer_key_id, NEW.signer_key_version, NEW.project_id
        USING ERRCODE = 'P7808';
    END IF;
    
    -- Validate signature format (Ed25519 signatures are 64 bytes)
    IF length(NEW.signature_bytes) != 64 THEN
        RAISE EXCEPTION 'Invalid signature format: Ed25519 signatures must be 64 bytes, got % bytes',
            length(NEW.signature_bytes)
        USING ERRCODE = 'P7807';
    END IF;
    
    -- HARD-FAIL: Ed25519 verification primitive not available
    -- DB-006 is blocked on TSK-P2-W8-SEC-002 (PostgreSQL native Ed25519 primitive)
    -- This prevents silent acceptance of invalid signatures while SEC-002 is implemented
    -- This migration reasserts the fail-closed posture established in 0177
    -- to supersede any placeholder-success posture from 0178-0180
    RAISE EXCEPTION 'Ed25519 verification primitive not available — DB-006 blocked on SEC-002'
    USING ERRCODE = 'P7809'; -- Wave 8: signature verification failed
    
    RETURN NEW;
END;
$$;

-- Update comment to reflect supersession of 0178-0180 regressions
COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - reasserted in 0182 to supersede 0178-0180 regressions. Integrates Ed25519 verification primitive into the authoritative PostgreSQL write path. Validates signature presence, resolves signer from authoritative surface, and enforces fail-closed rejection for invalid signatures. Hard-fails until SEC-002 provides PostgreSQL native Ed25519 primitive.';
