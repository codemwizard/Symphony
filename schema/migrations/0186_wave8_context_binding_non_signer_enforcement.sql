-- Migration: 0186_wave8_context_binding_non_signer_enforcement.sql
-- Task: TSK-P2-W8-DB-009
-- Purpose: Restate context binding as DB-009-owned closure evidence
-- Dependencies: TSK-P2-W8-DB-009
-- Type: Forward-only migration

-- Update the cryptographic enforcement function to add context binding enforcement
-- This isolates context binding into DB-009-owned closure evidence
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
    payload jsonb;
    payload_entity_id text;
    payload_execution_id text;
    payload_policy_decision_id text;
    payload_interpretation_version_id text;
    payload_occurred_at_tz timestamp with time zone;
    nonce_inserted boolean;
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
    
    -- Enforce replay prevention as distinct failure domain (DB-007c)
    IF NEW.attestation_nonce IS NULL OR NEW.attestation_nonce = '' THEN
        RAISE EXCEPTION 'Attestation nonce is required for replay prevention'
        USING ERRCODE = 'P7812'; -- Wave 8: replay prevention failure
    END IF;
    
    INSERT INTO public.wave8_attestation_nonces (nonce)
    VALUES (NEW.attestation_nonce)
    ON CONFLICT (nonce) DO NOTHING;
    
    GET DIAGNOSTICS nonce_inserted = ROW_COUNT;
    
    IF nonce_inserted = 0 THEN
        RAISE EXCEPTION 'Replay detected: nonce % has been used previously', NEW.attestation_nonce
        USING ERRCODE = 'P7812';
    END IF;
    
    -- Enforce context binding as distinct failure domain (DB-009)
    IF NEW.canonical_payload_bytes IS NULL THEN
        RAISE EXCEPTION 'Canonical payload bytes are required for context binding'
        USING ERRCODE = 'P7814'; -- Wave 8: context binding failure
    END IF;
    
    payload := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb;
    
    -- Extract and compare entity_id
    payload_entity_id := payload ->> 'entity_id';
    IF payload_entity_id IS NULL OR payload_entity_id = '' THEN
        RAISE EXCEPTION 'entity_id missing from canonical payload'
        USING ERRCODE = 'P7814';
    END IF;
    
    IF payload_entity_id != NEW.entity_id::text THEN
        RAISE EXCEPTION 'Context binding failure: entity_id mismatch — payload=% vs persisted=%',
            payload_entity_id, NEW.entity_id
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Extract and compare execution_id
    payload_execution_id := payload ->> 'execution_id';
    IF payload_execution_id IS NULL OR payload_execution_id = '' THEN
        RAISE EXCEPTION 'execution_id missing from canonical payload'
        USING ERRCODE = 'P7814';
    END IF;
    
    IF payload_execution_id != NEW.execution_id::text THEN
        RAISE EXCEPTION 'Context binding failure: execution_id mismatch — payload=% vs persisted=%',
            payload_execution_id, NEW.execution_id
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Extract and compare policy_decision_id
    payload_policy_decision_id := payload ->> 'policy_decision_id';
    IF payload_policy_decision_id IS NULL OR payload_policy_decision_id = '' THEN
        RAISE EXCEPTION 'policy_decision_id missing from canonical payload'
        USING ERRCODE = 'P7814';
    END IF;
    
    IF payload_policy_decision_id != NEW.policy_decision_id::text THEN
        RAISE EXCEPTION 'Context binding failure: policy_decision_id mismatch — payload=% vs persisted=%',
            payload_policy_decision_id, NEW.policy_decision_id
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Extract and compare interpretation_version_id
    payload_interpretation_version_id := payload ->> 'interpretation_version_id';
    IF payload_interpretation_version_id IS NULL OR payload_interpretation_version_id = '' THEN
        RAISE EXCEPTION 'interpretation_version_id missing from canonical payload'
        USING ERRCODE = 'P7814';
    END IF;
    
    IF payload_interpretation_version_id != NEW.interpretation_version_id::text THEN
        RAISE EXCEPTION 'Context binding failure: interpretation_version_id mismatch — payload=% vs persisted=%',
            payload_interpretation_version_id, NEW.interpretation_version_id
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Extract and compare occurred_at (already validated above, but also check for context binding)
    payload_occurred_at_tz := (payload ->> 'occurred_at')::timestamptz;
    IF payload_occurred_at_tz IS NULL THEN
        RAISE EXCEPTION 'occurred_at missing from canonical payload for context binding'
        USING ERRCODE = 'P7814';
    END IF;
    
    IF payload_occurred_at_tz != NEW.occurred_at THEN
        RAISE EXCEPTION 'Context binding failure: occurred_at mismatch — payload=% vs persisted=%',
            payload_occurred_at_tz, NEW.occurred_at
        USING ERRCODE = 'P7814';
    END IF;
    
    -- HARD-FAIL: Ed25519 verification primitive not available
    -- DB-006 is blocked on TSK-P2-W8-SEC-002 (PostgreSQL native Ed25519 primitive)
    RAISE EXCEPTION 'Ed25519 verification primitive not available — DB-006 blocked on SEC-002'
    USING ERRCODE = 'P7809'; -- Wave 8: signature verification failed
    
    RETURN NEW;
END;
$$;

-- Update comment to reflect DB-009 ownership
COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - updated in 0186 to add DB-009 context binding enforcement. Extracts context fields (entity_id, execution_id, policy_decision_id, interpretation_version_id, occurred_at) from canonical_payload_bytes and compares against persisted values to prevent signature transplantation. Hard-fails until SEC-002 provides PostgreSQL native Ed25519 primitive.';
