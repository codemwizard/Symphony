-- Migration: 0177_wave8_crypto_boundary_enforcement.sql
-- Task: TSK-P2-W8-DB-006
-- Purpose: Integrate Ed25519 verification primitive into asset_batches dispatcher path
-- Dependencies: TSK-P2-W8-DB-004, TSK-P2-W8-DB-005, TSK-P2-W8-SEC-001
-- Type: Forward-only migration

-- Create the cryptographic enforcement function
-- This function integrates the Ed25519 verification primitive into the dispatcher path
CREATE OR REPLACE FUNCTION public.wave8_cryptographic_enforcement()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    signer_record record;
    verification_result boolean;
    public_key_bytes bytea;
    signature_bytes bytea;
    message_bytes bytea;
BEGIN
    -- Validate required cryptographic fields are present
    IF NEW.signature IS NULL OR NEW.signature = '' THEN
        RAISE EXCEPTION 'Signature is required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7807'; -- Wave 8: missing or malformed signature
    END IF;
    
    IF NEW.signer_key_id IS NULL OR NEW.signer_key_id = '' THEN
        RAISE EXCEPTION 'Signer key ID is required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7809'; -- Wave 8: signer key scope invalid
    END IF;
    
    IF NEW.signer_key_version IS NULL OR NEW.signer_key_version = '' THEN
        RAISE EXCEPTION 'Signer key version is required for Wave 8 cryptographic enforcement'
        USING ERRCODE = 'P7809'; -- Wave 8: signer key scope invalid
    END IF;
    
    -- Resolve the authoritative signer
    SELECT * INTO signer_record
    FROM resolve_authoritative_signer(
        NEW.signer_key_id,
        NEW.signer_key_version,
        NEW.project_id,
        NULL -- entity_type not needed for signature verification
    );
    
    -- Check if signer was found
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown signer: key_id=%, key_version=%',
            NEW.signer_key_id, NEW.signer_key_version
        USING ERRCODE = 'P7810'; -- Wave 8: signer key not found
    END IF;
    
    -- Check if signer is authorized for this project
    IF NOT signer_record.is_authorized THEN
        RAISE EXCEPTION 'Unauthorized signer: key_id=% is not authorized for project=%',
            NEW.signer_key_id, NEW.project_id
        USING ERRCODE = 'P7811'; -- Wave 8: signer precedence violation
    END IF;
    
    -- Check if signer is active
    IF NOT signer_record.is_active THEN
        RAISE EXCEPTION 'Inactive signer: key_id=%, key_version=%',
            NEW.signer_key_id, NEW.signer_key_version
        USING ERRCODE = 'P7812'; -- Wave 8: signer key not active
    END IF;
    
    -- Prepare cryptographic verification
    public_key_bytes := signer_record.public_key_bytes;
    signature_bytes := decode(NEW.signature, 'hex');
    message_bytes := NEW.canonical_payload_bytes;
    
    -- Validate signature format (hex string, 64 bytes for Ed25519)
    IF NEW.signature !~ '^[0-9a-f]{64}$' THEN
        RAISE EXCEPTION 'Invalid signature format: must be 64-character hex string'
        USING ERRCODE = 'P7808'; -- Wave 8: timestamp or replay validation failure
    END IF;
    
    -- Validate public key format (32 bytes for Ed25519)
    IF length(public_key_bytes) != 32 THEN
        RAISE EXCEPTION 'Invalid public key format: must be 32 bytes'
        USING ERRCODE = 'P7813'; -- Wave 8: unavailable cryptographic provider
    END IF;
    
    -- Perform Ed25519 verification using the SEC-001 primitive
    -- This calls the external verification primitive that was proven in SEC-000/SEC-001
    BEGIN
        -- Call the verification primitive with the exact bytes
        SELECT verification_success INTO verification_result
        FROM verify_ed25519_contract_bytes(
            public_key_bytes,
            signature_bytes,
            message_bytes
        );
        
        -- Check verification result
        IF verification_result IS NULL THEN
            RAISE EXCEPTION 'Cryptographic verification returned null result'
            USING ERRCODE = 'P7813'; -- Wave 8: unavailable cryptographic provider
        ELSIF verification_result = false THEN
            RAISE EXCEPTION 'Cryptographic verification failed: invalid signature'
            USING ERRCODE = 'P7814'; -- Wave 8: signature verification failed
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Handle cryptographic provider unavailability
        IF SQLSTATE = 'P7813' OR SQLERRM LIKE '%unavailable%' OR SQLERRM LIKE '%provider%' THEN
            RAISE EXCEPTION 'Cryptographic provider unavailable: %', SQLERRM
            USING ERRCODE = 'P7813'; -- Wave 8: unavailable cryptographic provider
        ELSE
            -- Re-raise other cryptographic errors
            RAISE EXCEPTION 'Cryptographic verification error: %', SQLERRM
            USING ERRCODE = 'P7814'; -- Wave 8: signature verification failed
        END IF;
    END;
    
    -- If we reach here, cryptographic verification passed
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Fail closed on any cryptographic error
        RAISE EXCEPTION 'Wave 8 cryptographic enforcement failed: %', SQLERRM
        USING ERRCODE = SQLSTATE;
END;
$$;

-- Create the cryptographic enforcement trigger
-- This trigger integrates into the asset_batches dispatcher path
DROP TRIGGER IF EXISTS trg_wave8_cryptographic_enforcement ON public.asset_batches;
CREATE TRIGGER trg_wave8_cryptographic_enforcement
    BEFORE INSERT ON public.asset_batches
    FOR EACH ROW
    EXECUTE FUNCTION wave8_cryptographic_enforcement();

-- Add comments
COMMENT ON FUNCTION public.wave8_cryptographic_enforcement() IS
    'Wave 8 cryptographic enforcement function - integrates Ed25519 verification primitive into asset_batches dispatcher path. Validates signer resolution, signature format, and performs cryptographic verification with fail-closed rejection.';

COMMENT ON TRIGGER trg_wave8_cryptographic_enforcement ON public.asset_batches IS
    'Wave 8 cryptographic enforcement trigger - enforces Ed25519 signature verification inside authoritative boundary. Rejects invalid signatures and unavailable-crypto states with registered failure modes.';

-- Note: The trigger order is important:
-- 1. trg_wave8_reject_placeholders (from 0173) - rejects placeholder values
-- 2. trg_wave8_asset_batches_dispatcher (from 0172) - canonical payload construction
-- 3. trg_enforce_transition_hash_match (from 0175) - hash recomputation
-- 4. trg_wave8_cryptographic_enforcement (this migration) - signature verification
-- This ensures cryptographic verification happens after all structural validation passes.
