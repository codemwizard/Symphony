-- Migration: 0191_fix_signer_resolution_add_entity_type_return.sql
-- Task: Devin Review remediation
-- Purpose: Add entity_type to resolve_authoritative_signer() RETURNS TABLE
-- Dependencies: 0176_wave8_signer_resolution_surface.sql, 0190
-- Type: Forward-only migration
--
-- Bug: Migration 0190 (wave8_cryptographic_enforcement) SELECTs entity_type
-- from resolve_authoritative_signer(), but the function's RETURNS TABLE
-- (defined in 0176) does not include entity_type. This causes:
--   ERROR: column "entity_type" does not exist
-- on every asset_batches INSERT, breaking the entire Wave 8 write path.
--
-- Fix: Redefine resolve_authoritative_signer() to include entity_type in
-- RETURNS TABLE and in the SELECT clause.

DROP FUNCTION IF EXISTS public.resolve_authoritative_signer(text, text, uuid, text);

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
    
    -- Return the signer if found and authorized
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
    AND s.is_active = true
    AND (s.valid_until IS NULL OR s.valid_until > now());
    
    -- If no rows returned, the function returns empty set (unknown signer)
    -- The caller must distinguish unknown vs unauthorized based on is_authorized
END;
$$;

COMMENT ON FUNCTION public.resolve_authoritative_signer(text, text, uuid, text) IS
    'Wave 8 authoritative signer resolution function - fixed in 0191 to include entity_type in return columns. Resolves signer identity with explicit precedence law. Hard-fails on ambiguous precedence (multiple active matches). Returns empty set for unknown signer, is_authorized=false for unauthorized signer.';
