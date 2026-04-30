-- Migration: 0176_wave8_signer_resolution_surface.sql
-- Task: TSK-P2-W8-DB-005
-- Purpose: Expose one semantically closed authoritative signer-resolution surface with explicit precedence law
-- Dependencies: TSK-P2-W8-ARCH-003, TSK-P2-W8-ARCH-005
-- Type: Forward-only migration

-- Create the authoritative signer resolution table
-- This table provides one deterministic signer-resolution surface for Wave 8 verification
CREATE TABLE IF NOT EXISTS public.wave8_signer_resolution (
    signer_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    key_id text NOT NULL,
    key_version text NOT NULL,
    public_key_bytes bytea NOT NULL,
    project_id uuid NOT NULL,
    entity_type text,
    scope text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    valid_from timestamp with time zone NOT NULL DEFAULT now(),
    valid_until timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    
    -- Enforce semantically closed lookup behavior
    CONSTRAINT wave8_signer_key_unique UNIQUE (key_id, key_version),
    CONSTRAINT wave8_signer_scope_not_null CHECK (scope IS NOT NULL AND scope != ''),
    CONSTRAINT wave8_signer_public_key_not_null CHECK (public_key_bytes IS NOT NULL),
    CONSTRAINT wave8_signer_active_period CHECK (
        (is_active = false) OR 
        (valid_from IS NOT NULL AND (valid_until IS NULL OR valid_until > now()))
    )
);

-- Create index for fast signer lookup by key_id and key_version
CREATE INDEX idx_wave8_signer_lookup ON public.wave8_signer_resolution (key_id, key_version) WHERE is_active = true;

-- Create index for project-scoped signer lookup
CREATE INDEX idx_wave8_signer_project ON public.wave8_signer_resolution (project_id, entity_type) WHERE is_active = true;

-- Create the authoritative signer resolution function
-- This function provides one deterministic signer-resolution surface with explicit precedence law
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
    superseded_at timestamp with time zone
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
        s.superseded_at
    FROM public.wave8_signer_resolution s
    WHERE s.key_id = p_key_id
    AND s.key_version = p_key_version
    AND s.is_active = true
    AND (s.valid_until IS NULL OR s.valid_until > now());
    
    -- If no rows returned, the function returns empty set (unknown signer)
    -- The caller must distinguish unknown vs unauthorized based on is_authorized
END;
$$;

-- Add comments
COMMENT ON TABLE public.wave8_signer_resolution IS
    'Wave 8 authoritative signer resolution surface - provides one deterministic signer-resolution surface with explicit precedence law. Enforces semantically closed lookup behavior with no fallback or implicit inheritance.';

COMMENT ON FUNCTION public.resolve_authoritative_signer(text, text, uuid, text) IS
    'Wave 8 authoritative signer resolution function - resolves signer identity with explicit precedence law. Hard-fails on ambiguous precedence (multiple active matches). Returns empty set for unknown signer, is_authorized=false for unauthorized signer.';

COMMENT ON CONSTRAINT wave8_signer_key_unique ON public.wave8_signer_resolution IS
    'Wave 8 constraint: Ensures key_id and key_version combination is unique to prevent ambiguous signer resolution.';

COMMENT ON CONSTRAINT wave8_signer_scope_not_null ON public.wave8_signer_resolution IS
    'Wave 8 constraint: Scope must be non-null and non-empty to prevent null-derived authorization semantics.';

COMMENT ON CONSTRAINT wave8_signer_active_period ON public.wave8_signer_resolution IS
    'Wave 8 constraint: Active signers must have valid_from set and valid_until either null or in the future.';
