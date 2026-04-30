-- Migration: 0184_wave8_timestamp_branch_enforcement.sql
-- Task: TSK-P2-W8-DB-007b
-- Purpose: Restate timestamp enforcement as DB-007b-owned closure evidence
-- Dependencies: TSK-P2-W8-DB-007b
-- Type: Forward-only migration

-- Update the cryptographic enforcement function to add timestamp integrity enforcement
-- This isolates timestamp enforcement into DB-007b-owned closure evidence
-- Extracted from 0181 mixed-domain implementation
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
    payload_occurred_at text;
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
    
    -- Enforce timestamp integrity as distinct failure domain (DB-007b)
    -- Extract occurred_at from canonical payload and compare against persisted value
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for timestamp integrity enforcement'
        USING ERRCODE = 'P7811'; -- Wave 8: timestamp integrity failure
    END IF;
    
    payload_occurred_at := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'occurred_at';
    
    IF payload_occurred_at IS NULL THEN
        RAISE EXCEPTION 'occurred_at missing from canonical payload'
        USING ERRCODE = 'P7811';
    END IF;
    
    IF payload_occurred_at::timestamptz != NEW.occurred_at THEN
        RAISE EXCEPTION 'Timestamp mismatch: canonical payload occurred_at=% does not match persisted occurred_at=%',
            payload_occurred_at, NEW.occurred_at
        USING ERRCODE = 'P7811';
    END IF;
    
    -- HARD-FAIL: Ed25519 verification primitive not available
    -- DB-006 is blocked on TSK-P2-W8-SEC-002 (PostgreSQL native Ed25519 primitive)
    RAISE EXCEPTION 'Ed25519 verification primitive not available — DB-006 blocked on SEC-002'
    USING ERRCODE = 'P7809'; -- Wave 8: signature verification failed
    
    RETURN NEW;
END;
$$;

-- Update comment to reflect DB-007b ownership
COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - updated in 0184 to add DB-007b timestamp integrity enforcement. Extracts occurred_at from canonical_payload_bytes and compares against persisted value to prevent timestamp regeneration attacks. Hard-fails until SEC-002 provides PostgreSQL native Ed25519 primitive.';
