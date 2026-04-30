-- Migration: 0187_wave8_integrate_ed25519_verification.sql
-- Task: TSK-P2-W8-DB-006
-- Purpose: Integrate SEC-002 Ed25519 verification primitive into wave8_cryptographic_enforcement
-- Dependencies: TSK-P2-W8-SEC-002 (wave8_crypto extension)
-- Type: Forward-only migration

-- Update the cryptographic enforcement function to use SEC-002 Ed25519 verification
-- This replaces the hard-fail posture with actual signature verification
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
    payload_entity_id text;
    payload_execution_id text;
    payload_policy_decision_id text;
    payload_interpretation_version_id text;
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
    
    -- Validate canonical payload is present
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for signature verification'
        USING ERRCODE = 'P7807';
    END IF;
    
    -- Enforce timestamp integrity (DB-007b)
    payload_occurred_at := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'occurred_at';
    
    IF payload_occurred_at IS NULL THEN
        RAISE EXCEPTION 'occurred_at missing from canonical payload'
        USING ERRCODE = 'P7811'; -- Wave 8: timestamp integrity failure
    END IF;
    
    IF payload_occurred_at::timestamptz != NEW.occurred_at THEN
        RAISE EXCEPTION 'Timestamp mismatch: canonical payload occurred_at=% does not match persisted occurred_at=%',
            payload_occurred_at, NEW.occurred_at
        USING ERRCODE = 'P7811';
    END IF;
    
    -- Enforce context binding (DB-009)
    payload_entity_id := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'entity_id';
    payload_execution_id := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'execution_id';
    payload_policy_decision_id := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'policy_decision_id';
    payload_interpretation_version_id := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb ->> 'interpretation_version_id';
    
    IF payload_entity_id IS NOT NULL AND payload_entity_id::text != NEW.entity_id::text THEN
        RAISE EXCEPTION 'Context binding violation: canonical payload entity_id=% does not match persisted entity_id=%',
            payload_entity_id, NEW.entity_id
        USING ERRCODE = 'P7812'; -- Wave 8: context binding failure
    END IF;
    
    IF payload_execution_id IS NOT NULL AND payload_execution_id::text != NEW.execution_id::text THEN
        RAISE EXCEPTION 'Context binding violation: canonical payload execution_id=% does not match persisted execution_id=%',
            payload_execution_id, NEW.execution_id
        USING ERRCODE = 'P7812';
    END IF;
    
    IF payload_policy_decision_id IS NOT NULL AND payload_policy_decision_id::text != NEW.policy_decision_id::text THEN
        RAISE EXCEPTION 'Context binding violation: canonical payload policy_decision_id=% does not match persisted policy_decision_id=%',
            payload_policy_decision_id, NEW.policy_decision_id
        USING ERRCODE = 'P7812';
    END IF;
    
    IF payload_interpretation_version_id IS NOT NULL AND payload_interpretation_version_id::text != NEW.interpretation_version_id::text THEN
        RAISE EXCEPTION 'Context binding violation: canonical payload interpretation_version_id=% does not match persisted interpretation_version_id=%',
            payload_interpretation_version_id, NEW.interpretation_version_id
        USING ERRCODE = 'P7812';
    END IF;
    
    -- SEC-002: Ed25519 verification using PostgreSQL native primitive
    -- This replaces the hard-fail posture with actual cryptographic verification
    verification_result := ed25519_verify(
        NEW.canonical_payload_bytes,
        NEW.signature_bytes,
        signer_public_key
    );
    
    IF NOT verification_result THEN
        RAISE EXCEPTION 'Ed25519 signature verification failed: invalid signature for signer key_id=%, key_version=%',
            NEW.signer_key_id, NEW.signer_key_version
        USING ERRCODE = 'P7809'; -- Wave 8: signature verification failed
    END IF;
    
    RETURN NEW;
END;
$$;

-- Update comment to reflect SEC-002 integration
COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - integrated SEC-002 Ed25519 verification in 0187. Uses PostgreSQL native ed25519_verify() function for cryptographic signature verification. Validates signature presence, resolves signer from authoritative surface, enforces timestamp integrity (DB-007b), context binding (DB-009), and performs Ed25519 signature verification using libsodium via wave8_crypto extension.';
