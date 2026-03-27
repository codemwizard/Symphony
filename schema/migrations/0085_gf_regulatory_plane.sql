-- Migration 0085: Green Finance Regulatory Plane
-- Phase 1 regulatory authorities and checkpoints for jurisdiction-driven compliance

-- Create regulatory_authorities table
CREATE TABLE IF NOT EXISTS public.regulatory_authorities (
  -- Primary identifier
  authority_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  
  -- Jurisdiction classification (non-nullable)
  jurisdiction_code TEXT NOT NULL,
  
  -- Legal and authority information
  legal_basis_reference TEXT NOT NULL,
  authority_type TEXT NOT NULL CHECK (
    authority_type IN ('SOVEREIGN', 'REGULATOR', 'DESIGNATED_BODY')
  ),
  authority_name TEXT NOT NULL,
  enforcement_scope TEXT NOT NULL,
  
  -- Temporal validity
  effective_from DATE NOT NULL,
  effective_to DATE NULL,
  
  -- Audit timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create regulatory_checkpoints table
CREATE TABLE IF NOT EXISTS public.regulatory_checkpoints (
  -- Primary identifier
  checkpoint_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  
  -- Jurisdiction and authority reference
  jurisdiction_code TEXT NOT NULL,
  authority_id UUID NOT NULL REFERENCES public.regulatory_authorities(authority_id) ON DELETE RESTRICT,
  
  -- Checkpoint classification
  lifecycle_transition TEXT NOT NULL,
  checkpoint_type TEXT NOT NULL CHECK (
    checkpoint_type IN (
      'REGISTRATION',
      'METHODOLOGY_APPROVAL',
      'ISSUANCE_AUTHORIZATION',
      'TRANSFER_APPROVAL',
      'EXPORT_APPROVAL',
      'RETIREMENT_RECORDING'
    )
  ),
  
  -- Checkpoint configuration
  is_mandatory BOOLEAN NOT NULL DEFAULT true,
  interpretation_pack_id UUID NULL REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE SET NULL,
  
  -- Audit timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for regulatory_authorities
CREATE INDEX IF NOT EXISTS idx_regulatory_authorities_jurisdiction ON regulatory_authorities(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_regulatory_authorities_type ON regulatory_authorities(authority_type);
CREATE INDEX IF NOT EXISTS idx_regulatory_authorities_effective_from ON regulatory_authorities(effective_from);
CREATE INDEX IF NOT EXISTS idx_regulatory_authorities_effective_to ON regulatory_authorities(effective_to) WHERE effective_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_regulatory_authorities_created_at ON regulatory_authorities(created_at);

-- Indexes for regulatory_checkpoints
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_jurisdiction ON regulatory_checkpoints(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_authority ON regulatory_checkpoints(authority_id);
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_transition ON regulatory_checkpoints(lifecycle_transition);
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_type ON regulatory_checkpoints(checkpoint_type);
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_mandatory ON regulatory_checkpoints(is_mandatory);
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_interpretation ON regulatory_checkpoints(interpretation_pack_id) WHERE interpretation_pack_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_created_at ON regulatory_checkpoints(created_at);

-- Composite index for efficient checkpoint lookup
CREATE INDEX IF NOT EXISTS idx_regulatory_checkpoints_lookup ON regulatory_checkpoints(
    jurisdiction_code, 
    lifecycle_transition, 
    checkpoint_type
) WHERE is_mandatory = true;

-- RLS for regulatory_authorities (canonical jurisdiction pattern)
ALTER TABLE public.regulatory_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_authorities FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_regulatory_authorities ON public.regulatory_authorities
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- RLS for regulatory_checkpoints (canonical jurisdiction pattern)
ALTER TABLE public.regulatory_checkpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_checkpoints FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_regulatory_checkpoints ON public.regulatory_checkpoints
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- Append-only trigger for regulatory_authorities
CREATE OR REPLACE FUNCTION regulatory_authorities_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'regulatory_authorities is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER regulatory_authorities_append_only
    BEFORE UPDATE OR DELETE ON regulatory_authorities
    FOR EACH ROW
    EXECUTE FUNCTION regulatory_authorities_append_only_trigger();

-- Append-only trigger for regulatory_checkpoints
CREATE OR REPLACE FUNCTION regulatory_checkpoints_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'regulatory_checkpoints is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER regulatory_checkpoints_append_only
    BEFORE UPDATE OR DELETE ON regulatory_checkpoints
    FOR EACH ROW
    EXECUTE FUNCTION regulatory_checkpoints_append_only_trigger();

-- Function to create regulatory authority
CREATE OR REPLACE FUNCTION create_regulatory_authority(
    p_jurisdiction_code TEXT,
    p_legal_basis_reference TEXT,
    p_authority_type TEXT,
    p_authority_name TEXT,
    p_enforcement_scope TEXT,
    p_effective_from DATE,
    p_effective_to DATE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_authority_id UUID;
BEGIN
    -- Validate jurisdiction_code is not null
    IF p_jurisdiction_code IS NULL OR p_jurisdiction_code = '' THEN
        RAISE EXCEPTION 'jurisdiction_code cannot be null or empty';
    END IF;
    
    INSERT INTO regulatory_authorities (
        jurisdiction_code,
        legal_basis_reference,
        authority_type,
        authority_name,
        enforcement_scope,
        effective_from,
        effective_to
    ) VALUES (
        p_jurisdiction_code,
        p_legal_basis_reference,
        p_authority_type,
        p_authority_name,
        p_enforcement_scope,
        p_effective_from,
        p_effective_to
    ) RETURNING authority_id INTO v_authority_id;
    
    RETURN v_authority_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to create regulatory checkpoint
CREATE OR REPLACE FUNCTION create_regulatory_checkpoint(
    p_jurisdiction_code TEXT,
    p_authority_id UUID,
    p_lifecycle_transition TEXT,
    p_checkpoint_type TEXT,
    p_is_mandatory BOOLEAN DEFAULT true,
    p_interpretation_pack_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_checkpoint_id UUID;
BEGIN
    -- Validate jurisdiction_code is not null
    IF p_jurisdiction_code IS NULL OR p_jurisdiction_code = '' THEN
        RAISE EXCEPTION 'jurisdiction_code cannot be null or empty';
    END IF;
    
    -- Validate authority exists
    IF NOT EXISTS (
        SELECT 1 FROM regulatory_authorities 
        WHERE authority_id = p_authority_id
        AND jurisdiction_code = p_jurisdiction_code
    ) THEN
        RAISE EXCEPTION 'Authority not found or jurisdiction mismatch';
    END IF;
    
    INSERT INTO regulatory_checkpoints (
        jurisdiction_code,
        authority_id,
        lifecycle_transition,
        checkpoint_type,
        is_mandatory,
        interpretation_pack_id
    ) VALUES (
        p_jurisdiction_code,
        p_authority_id,
        p_lifecycle_transition,
        p_checkpoint_type,
        p_is_mandatory,
        p_interpretation_pack_id
    ) RETURNING checkpoint_id INTO v_checkpoint_id;
    
    RETURN v_checkpoint_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query regulatory checkpoints for jurisdiction
CREATE OR REPLACE FUNCTION query_regulatory_checkpoints(
    p_jurisdiction_code TEXT,
    p_lifecycle_transition TEXT DEFAULT NULL,
    p_include_inactive BOOLEAN DEFAULT false
)
RETURNS TABLE (
    checkpoint_id UUID,
    authority_id UUID,
    authority_name TEXT,
    authority_type TEXT,
    checkpoint_type TEXT,
    is_mandatory BOOLEAN,
    interpretation_pack_id UUID,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rc.checkpoint_id,
        rc.authority_id,
        ra.authority_name,
        ra.authority_type,
        rc.checkpoint_type,
        rc.is_mandatory,
        rc.interpretation_pack_id,
        rc.created_at
    FROM regulatory_checkpoints rc
    JOIN regulatory_authorities ra ON rc.authority_id = ra.authority_id
    WHERE rc.jurisdiction_code = p_jurisdiction_code
    AND (p_lifecycle_transition IS NULL OR rc.lifecycle_transition = p_lifecycle_transition)
    AND (p_include_inactive = true OR (ra.effective_to IS NULL AND CURRENT_DATE >= ra.effective_from))
    ORDER BY rc.checkpoint_type, rc.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke-first privilege posture
REVOKE ALL ON TABLE regulatory_authorities FROM PUBLIC;
REVOKE ALL ON TABLE regulatory_checkpoints FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE regulatory_authorities TO authenticated_role;
GRANT SELECT, INSERT ON TABLE regulatory_checkpoints TO authenticated_role;
GRANT ALL ON TABLE regulatory_authorities TO system_role;
GRANT ALL ON TABLE regulatory_checkpoints TO system_role;
GRANT EXECUTE ON FUNCTION create_regulatory_authority TO authenticated_role;
GRANT EXECUTE ON FUNCTION create_regulatory_authority TO system_role;
GRANT EXECUTE ON FUNCTION create_regulatory_checkpoint TO authenticated_role;
GRANT EXECUTE ON FUNCTION create_regulatory_checkpoint TO system_role;
GRANT EXECUTE ON FUNCTION query_regulatory_checkpoints TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_regulatory_checkpoints TO system_role;
