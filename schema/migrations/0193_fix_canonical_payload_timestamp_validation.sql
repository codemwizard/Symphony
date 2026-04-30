-- Migration: 0193_fix_canonical_payload_timestamp_validation.sql
-- Task: Devin Review remediation
-- Purpose: Fix no-op timestamp validation in construct_canonical_attestation_payload
-- Dependencies: 0174_wave8_canonical_payload.sql
-- Type: Forward-only migration
--
-- Bug: In migration 0174 at line 116, the timestamp validation compares
-- to_char(p_occurred_at, fmt) != to_char(p_occurred_at, fmt) — the exact same
-- expression on both sides. This always evaluates to false, making the
-- validation a no-op that never rejects any timestamp.
--
-- Fix: Replace the self-comparison with a round-trip validation that ensures
-- the timestamp survives canonical formatting without loss. The formatted UTC
-- string is parsed back to timestamptz and compared against the original value.

CREATE OR REPLACE FUNCTION public.construct_canonical_attestation_payload(
    p_project_id uuid,
    p_entity_type text,
    p_entity_id uuid,
    p_from_state text,
    p_to_state text,
    p_execution_id uuid,
    p_interpretation_version_id uuid,
    p_policy_decision_id uuid,
    p_transition_hash text,
    p_occurred_at timestamp with time zone
)
RETURNS bytea
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    payload_json json;
    canonical_json text;
    canonical_bytes bytea;
    formatted_ts text;
BEGIN
    -- Validate required fields are not null
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'project_id is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_entity_type IS NULL OR p_entity_type = '' THEN
        RAISE EXCEPTION 'entity_type is required and must be non-empty'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_entity_id IS NULL THEN
        RAISE EXCEPTION 'entity_id is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_from_state IS NULL OR p_from_state = '' THEN
        RAISE EXCEPTION 'from_state is required and must be non-empty'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_to_state IS NULL OR p_to_state = '' THEN
        RAISE EXCEPTION 'to_state is required and must be non-empty'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_execution_id IS NULL THEN
        RAISE EXCEPTION 'execution_id is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_interpretation_version_id IS NULL THEN
        RAISE EXCEPTION 'interpretation_version_id is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_policy_decision_id IS NULL THEN
        RAISE EXCEPTION 'policy_decision_id is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_transition_hash IS NULL OR p_transition_hash = '' THEN
        RAISE EXCEPTION 'transition_hash is required and must be non-empty'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_occurred_at IS NULL THEN
        RAISE EXCEPTION 'occurred_at is required for canonical payload'
        USING ERRCODE = '23502';
    END IF;
    
    -- Validate UUIDs are in lowercase canonical form
    IF p_project_id::text != lower(p_project_id::text) THEN
        RAISE EXCEPTION 'project_id must be in lowercase canonical form'
        USING ERRCODE = 'P7804';
    END IF;
    
    IF p_entity_id::text != lower(p_entity_id::text) THEN
        RAISE EXCEPTION 'entity_id must be in lowercase canonical form'
        USING ERRCODE = 'P7804';
    END IF;
    
    IF p_execution_id::text != lower(p_execution_id::text) THEN
        RAISE EXCEPTION 'execution_id must be in lowercase canonical form'
        USING ERRCODE = 'P7804';
    END IF;
    
    IF p_interpretation_version_id::text != lower(p_interpretation_version_id::text) THEN
        RAISE EXCEPTION 'interpretation_version_id must be in lowercase canonical form'
        USING ERRCODE = 'P7804';
    END IF;
    
    IF p_policy_decision_id::text != lower(p_policy_decision_id::text) THEN
        RAISE EXCEPTION 'policy_decision_id must be in lowercase canonical form'
        USING ERRCODE = 'P7804';
    END IF;
    
    -- Validate transition_hash is lowercase hex and exactly 64 characters
    IF p_transition_hash !~ '^[0-9a-f]{64}$' THEN
        RAISE EXCEPTION 'transition_hash must be lowercase hexadecimal string, exactly 64 characters'
        USING ERRCODE = 'P7804';
    END IF;
    
    -- Validate occurred_at round-trips through RFC 3339 canonical format
    -- Format to UTC with exactly six fractional digits, then parse back
    -- and compare to detect any precision or timezone conversion loss
    formatted_ts := to_char(p_occurred_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
    IF formatted_ts::timestamptz != p_occurred_at THEN
        RAISE EXCEPTION 'occurred_at must survive RFC 3339 round-trip with exactly six fractional digits'
        USING ERRCODE = 'P7808';
    END IF;
    
    -- Construct the JSON payload with exact field set and ordering from contract
    -- Field order: contract_version, canonicalization_version, project_id, entity_type, entity_id,
    -- from_state, to_state, execution_id, interpretation_version_id, policy_decision_id,
    -- transition_hash, occurred_at
    payload_json := json_build_object(
        'contract_version', 1,
        'canonicalization_version', 'JCS-RFC8785-V1',
        'project_id', lower(p_project_id::text),
        'entity_type', p_entity_type,
        'entity_id', lower(p_entity_id::text),
        'from_state', p_from_state,
        'to_state', p_to_state,
        'execution_id', lower(p_execution_id::text),
        'interpretation_version_id', lower(p_interpretation_version_id::text),
        'policy_decision_id', lower(p_policy_decision_id::text),
        'transition_hash', lower(p_transition_hash),
        'occurred_at', to_char(p_occurred_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
    );
    
    -- Canonicalize using RFC 8785 (JSON Canonicalization Scheme)
    -- PostgreSQL jsonb automatically sorts keys, but we need to preserve exact ordering
    -- For now, we use json_build_object which preserves order in recent PostgreSQL versions
    canonical_json := payload_json::text;
    
    -- Encode as UTF-8 bytes
    canonical_bytes := convert_to(canonical_json, 'UTF8');
    
    RETURN canonical_bytes;
END;
$$;

COMMENT ON FUNCTION public.construct_canonical_attestation_payload(uuid, text, uuid, text, text, uuid, uuid, uuid, text, timestamp with time zone) IS
    'Wave 8 canonical payload construction function - fixed in 0193 to correct no-op timestamp validation. Now validates occurred_at survives RFC 3339 round-trip. Constructs canonical attestation payload bytes according to CANONICAL_ATTESTATION_PAYLOAD_v1.md contract.';
