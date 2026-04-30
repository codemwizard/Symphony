-- Migration: 0195_fix_signer_resolution_return_revoked_expired.sql
-- Task: Devin Review remediation
-- Purpose: Remove pre-filtering of revoked/expired keys from resolve_authoritative_signer()
-- Dependencies: 0191_fix_signer_resolution_add_entity_type_return.sql
-- Type: Forward-only migration
--
-- Bug: resolve_authoritative_signer() filters with:
--   AND s.is_active = true AND (s.valid_until IS NULL OR s.valid_until > now())
-- This means revoked keys (is_active=false) and expired keys (valid_until<now())
-- are never returned. The caller receives NULL (empty result set), triggering the
-- "Unknown signer" exception with P7808 instead of the correct P7813 (key lifecycle).
-- The lifecycle checks in wave8_cryptographic_enforcement() (IF NOT signer_is_active,
-- IF signer_valid_until < now()) are dead code that can never execute.
--
-- Fix: Remove is_active and valid_until filters from the main SELECT query so
-- revoked/expired keys are returned to the caller. The ambiguity check still only
-- counts active keys (multiple active keys for the same key_id/version is ambiguous).
-- The caller (enforcement function) performs the lifecycle checks and emits P7813.

CREATE OR REPLACE FUNCTION public.resolve_authoritative_signer(
    p_key_id text,
    p_key_version text,
    p_project_id uuid,
    p_entity_type text DEFAULT NULL
)
RETURNS TABLE (
    signer_id uuid,
    public_key_bytes bytea,
    scope text,
    is_authorized boolean,
    is_active boolean,
    valid_from timestamp with time zone,
    valid_until timestamp with time zone,
    superseded_by uuid,
    superseded_at timestamp with time zone,
    entity_type text
)
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    match_count int;
BEGIN
    -- Validate inputs
    IF p_key_id IS NULL OR p_key_id = '' THEN
        RAISE EXCEPTION 'key_id is required for signer resolution'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_key_version IS NULL OR p_key_version = '' THEN
        RAISE EXCEPTION 'key_version is required for signer resolution'
        USING ERRCODE = '23502';
    END IF;
    
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'project_id is required for signer resolution'
        USING ERRCODE = '23502';
    END IF;
    
    -- Check for multiple active matches (ambiguous precedence)
    -- Only active, non-expired keys count toward ambiguity
    SELECT COUNT(*) INTO match_count
    FROM public.wave8_signer_resolution
    WHERE key_id = p_key_id
    AND key_version = p_key_version
    AND is_active = true
    AND (valid_until IS NULL OR valid_until > now());
    
    IF match_count > 1 THEN
        RAISE EXCEPTION 'Ambiguous signer precedence: multiple active matches for key_id=%, key_version=%',
            p_key_id, p_key_version
        USING ERRCODE = 'P7806'; -- Wave 8: signer resolution ambiguity
    END IF;
    
    -- Return the signer matching key_id + key_version WITHOUT filtering by
    -- is_active or valid_until. The caller is responsible for lifecycle checks
    -- so it can emit the correct error code (P7813) for revoked/expired keys
    -- rather than the generic P7808 "unknown signer".
    RETURN QUERY
    SELECT 
        s.signer_id,
        s.public_key_bytes,
        s.scope,
        CASE 
            WHEN s.project_id = p_project_id AND 
                 (s.entity_type IS NULL OR s.entity_type = p_entity_type OR p_entity_type IS NULL)
            THEN true
            ELSE false
        END as is_authorized,
        s.is_active,
        s.valid_from,
        s.valid_until,
        s.superseded_by,
        s.superseded_at,
        s.entity_type
    FROM public.wave8_signer_resolution s
    WHERE s.key_id = p_key_id
    AND s.key_version = p_key_version
    ORDER BY s.is_active DESC, s.valid_from DESC
    LIMIT 1;
    
    -- If no rows returned, the signer is truly unknown (P7808).
    -- If a row is returned with is_active=false or valid_until<now(),
    -- the caller handles it with the correct lifecycle error code (P7813).
END;
$$;

COMMENT ON FUNCTION public.resolve_authoritative_signer(text, text, uuid, text) IS
    'Wave 8 authoritative signer resolution function - fixed in 0195 to return revoked/expired keys so the caller can emit P7813 (lifecycle) instead of P7808 (unknown). Returns at most one row: prefers active keys, falls back to most recent inactive. Empty set means truly unknown signer.';
