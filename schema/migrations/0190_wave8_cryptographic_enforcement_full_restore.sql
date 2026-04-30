-- Migration: 0190_wave8_cryptographic_enforcement_full_restore.sql
-- Task: TSK-P2-W8-DB-006 (remediation)
-- Purpose: Restore all enforcement domains dropped by migration 0187
-- Dependencies: 0187_wave8_integrate_ed25519_verification.sql, 0188 (superseded columns)
-- Type: Forward-only migration
--
-- Bugs fixed:
-- 1. Migration 0187 dropped replay prevention enforcement (nonce validation + INSERT)
--    that was present in 0186.
-- 2. Migration 0187 weakened context binding from mandatory presence checks to optional
--    IS NOT NULL guards, allowing signature transplantation attacks.
-- 3. Migration 0187 dropped key lifecycle enforcement (revoked/expired/superseded checks
--    with P7813) that was present in 0181-0186.
-- 4. Migration 0187 dropped scope authorization (P7810) that was present in 0181-0186.
--
-- This migration restores all enforcement domains while retaining the Ed25519 verification
-- integration from 0187.

CREATE OR REPLACE FUNCTION public.wave8_cryptographic_enforcement()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    signer_public_key bytea;
    signer_authorized boolean;
    signer_scope text;
    signer_entity_type text;
    signer_is_active boolean;
    signer_valid_from timestamp with time zone;
    signer_valid_until timestamp with time zone;
    signer_superseded_by uuid;
    signer_superseded_at timestamp with time zone;
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
    
    -- Resolve signer from authoritative signer resolution surface with lifecycle fields
    SELECT public_key_bytes, is_authorized, scope, entity_type,
           is_active, valid_from, valid_until, superseded_by, superseded_at
    INTO signer_public_key, signer_authorized, signer_scope, signer_entity_type,
         signer_is_active, signer_valid_from, signer_valid_until, signer_superseded_by, signer_superseded_at
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
    
    -- Check if signer is unauthorized (project scope)
    IF NOT signer_authorized THEN
        RAISE EXCEPTION 'Unauthorized signer: key_id=%, key_version=%, project_id=%',
            NEW.signer_key_id, NEW.signer_key_version, NEW.project_id
        USING ERRCODE = 'P7808';
    END IF;
    
    -- Enforce key lifecycle: check if signer is revoked (is_active = false)
    IF NOT signer_is_active THEN
        RAISE EXCEPTION 'Revoked signer: key_id=%, key_version=% is revoked and cannot sign',
            NEW.signer_key_id, NEW.signer_key_version
        USING ERRCODE = 'P7813'; -- Wave 8: key lifecycle failure (revoked)
    END IF;
    
    -- Enforce key lifecycle: check if signer is expired
    IF signer_valid_until IS NOT NULL AND signer_valid_until < now() THEN
        RAISE EXCEPTION 'Expired signer: key_id=%, key_version=% expired at %',
            NEW.signer_key_id, NEW.signer_key_version, signer_valid_until
        USING ERRCODE = 'P7813'; -- Wave 8: key lifecycle failure (expired)
    END IF;
    
    -- Enforce key lifecycle: check if signer is superseded
    IF signer_superseded_by IS NOT NULL THEN
        RAISE EXCEPTION 'Superseded signer: key_id=%, key_version=% superseded by % at %',
            NEW.signer_key_id, NEW.signer_key_version, signer_superseded_by, signer_superseded_at
        USING ERRCODE = 'P7813'; -- Wave 8: key lifecycle failure (superseded)
    END IF;
    
    -- Enforce scope authorization as distinct failure domain
    IF signer_scope IS NOT NULL AND signer_scope != '' THEN
        IF signer_scope != 'wave8_global' AND signer_scope != 'asset_batches' THEN
            RAISE EXCEPTION 'Scope authorization failed: signer scope=% does not authorize asset_batches writes',
                signer_scope
            USING ERRCODE = 'P7810'; -- Wave 8: scope authorization failure
        END IF;
    END IF;
    
    -- Enforce entity-type scope authorization if signer has entity_type restriction
    IF signer_entity_type IS NOT NULL AND signer_entity_type != '' THEN
        IF NEW.batch_type IS NOT NULL AND NEW.batch_type != signer_entity_type THEN
            RAISE EXCEPTION 'Entity-type scope authorization failed: signer entity_type=% does not match batch_type=%',
                signer_entity_type, NEW.batch_type
            USING ERRCODE = 'P7810';
        END IF;
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
    payload := convert_from(NEW.canonical_payload_bytes, 'UTF8')::jsonb;
    
    -- Extract and validate entity_id (mandatory)
    payload_entity_id := payload ->> 'entity_id';
    IF payload_entity_id IS NULL OR payload_entity_id = '' THEN
        RAISE EXCEPTION 'entity_id missing from canonical payload'
        USING ERRCODE = 'P7814'; -- Wave 8: context binding failure
    END IF;
    
    IF payload_entity_id != NEW.entity_id::text THEN
        RAISE EXCEPTION 'Context binding failure: entity_id mismatch — payload=% vs persisted=%',
            payload_entity_id, NEW.entity_id
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Extract and validate execution_id (mandatory)
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
    
    -- Extract and validate policy_decision_id (mandatory)
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
    
    -- Extract and validate interpretation_version_id (mandatory)
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
    
    -- Extract and validate occurred_at for context binding (already validated for timestamp integrity)
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
    
    -- SEC-002: Ed25519 verification using PostgreSQL native primitive
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

COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - fixed in 0190 to restore all enforcement domains. Validates signature presence, resolves signer from authoritative surface, enforces key lifecycle (P7813), scope authorization (P7810), timestamp integrity (P7811), replay prevention (P7812), mandatory context binding (P7814), and Ed25519 signature verification (P7809) via wave8_crypto extension.';
