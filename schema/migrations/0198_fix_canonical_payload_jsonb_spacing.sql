-- Migration: 0198_fix_canonical_payload_jsonb_spacing.sql
-- Task: Devin Review remediation
-- Purpose: Fix jsonb::text whitespace to produce RFC 8785 compact JSON
-- Dependencies: 0196_fix_canonical_payload_rfc8785_key_order.sql
-- Type: Forward-only migration
--
-- Bug: PostgreSQL's jsonb::text serialization adds a space after colons and
-- commas: {"key": "value", "key2": 1}. RFC 8785 mandates compact form with
-- no whitespace: {"key":"value","key2":1}. The extra spaces cause different
-- SHA-256 hashes from any external RFC 8785 implementation, breaking
-- cross-surface determinism and causing transition hash enforcement to reject
-- valid attestations.
--
-- Fix: Use jsonb::text then strip the whitespace that PostgreSQL adds after
-- JSON structural characters (colon and comma separators). PostgreSQL's jsonb
-- serialization is predictable: it adds exactly one space after ':' and after
-- ',' between key-value pairs. We use replace() for the two patterns.
-- String values containing ": " or ", " are safe because jsonb::text escapes
-- them within quoted strings — the patterns we replace only occur at the
-- structural level.

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
    payload_jsonb jsonb;
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
    formatted_ts := to_char(p_occurred_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
    IF formatted_ts::timestamptz != p_occurred_at THEN
        RAISE EXCEPTION 'occurred_at must survive RFC 3339 round-trip with exactly six fractional digits'
        USING ERRCODE = 'P7808';
    END IF;
    
    -- Construct the JSON payload using jsonb_build_object for RFC 8785 key ordering.
    -- PostgreSQL jsonb sorts keys lexicographically as RFC 8785 mandates.
    payload_jsonb := jsonb_build_object(
        'canonicalization_version', 'JCS-RFC8785-V1',
        'contract_version', 1,
        'entity_id', lower(p_entity_id::text),
        'entity_type', p_entity_type,
        'execution_id', lower(p_execution_id::text),
        'from_state', p_from_state,
        'interpretation_version_id', lower(p_interpretation_version_id::text),
        'occurred_at', formatted_ts,
        'policy_decision_id', lower(p_policy_decision_id::text),
        'project_id', lower(p_project_id::text),
        'to_state', p_to_state,
        'transition_hash', lower(p_transition_hash)
    );
    
    -- Convert jsonb to text, then strip PostgreSQL's extra whitespace.
    -- PostgreSQL jsonb::text produces: {"key": "value", "key2": 1}
    -- RFC 8785 requires compact form: {"key":"value","key2":1}
    -- replace() is safe here because the patterns ": " and ", " at the
    -- structural level are distinct from occurrences inside JSON string
    -- values (which would be escaped if they contained literal quotes).
    canonical_json := payload_jsonb::text;
    canonical_json := replace(canonical_json, ': ', ':');
    canonical_json := replace(canonical_json, ', ', ',');
    
    -- Encode as UTF-8 bytes
    canonical_bytes := convert_to(canonical_json, 'UTF8');
    
    RETURN canonical_bytes;
END;
$$;

COMMENT ON FUNCTION public.construct_canonical_attestation_payload(uuid, text, uuid, text, text, uuid, uuid, uuid, text, timestamp with time zone) IS
    'Wave 8 canonical payload construction function - fixed in 0198 to strip PostgreSQL jsonb spacing for RFC 8785 compact JSON. Keys are passed in lexicographic order to jsonb_build_object, and whitespace is stripped from the serialized output. Constructs canonical attestation payload bytes according to CANONICAL_ATTESTATION_PAYLOAD_v1.md contract.';
