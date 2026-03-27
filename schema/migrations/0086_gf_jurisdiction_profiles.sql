-- Migration 0086: Green Finance Jurisdiction Profiles and Checkpoint Rules
-- Phase 1 jurisdiction profiles and lifecycle checkpoint rules for regulatory compliance

-- Create jurisdiction_profiles table
CREATE TABLE IF NOT EXISTS public.jurisdiction_profiles (
  -- Primary identifier
  profile_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  
  -- Jurisdiction classification (non-nullable and unique)
  jurisdiction_code TEXT NOT NULL UNIQUE,
  
  -- Country information
  country_name TEXT NOT NULL,
  national_registry_reference TEXT NULL,
  
  -- Article 6 participation status
  article6_participant BOOLEAN NOT NULL DEFAULT false,
  
  -- Profile status
  profile_status TEXT NOT NULL CHECK (
    profile_status IN ('ACTIVE', 'SUSPENDED', 'DRAFT')
  ),
  
  -- Temporal validity
  effective_from DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create lifecycle_checkpoint_rules table
CREATE TABLE IF NOT EXISTS public.lifecycle_checkpoint_rules (
  -- Primary identifier
  rule_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  
  -- Jurisdiction and lifecycle classification
  jurisdiction_code TEXT NOT NULL,
  lifecycle_transition TEXT NOT NULL,
  checkpoint_id UUID NOT NULL REFERENCES public.regulatory_checkpoints(checkpoint_id) ON DELETE RESTRICT,
  
  -- Rule configuration
  rule_status TEXT NOT NULL CHECK (
    rule_status IN (
      'REQUIRED',
      'CONDITIONALLY_REQUIRED',
      'WAIVED_FOR_PILOT',
      'PENDING_AUTHORITY_CLARIFICATION'
    )
  ),
  interpretation_pack_id UUID NOT NULL REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT,
  
  -- Temporal validity
  effective_from TIMESTAMPTZ NOT NULL,
  effective_to TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Uniqueness constraint for active rules
  CONSTRAINT lifecycle_checkpoint_rules_unique_active 
    UNIQUE (jurisdiction_code, lifecycle_transition, checkpoint_id) 
    WHERE (effective_to IS NULL)
);

-- Indexes for jurisdiction_profiles
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_jurisdiction ON jurisdiction_profiles(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_country ON jurisdiction_profiles(country_name);
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_status ON jurisdiction_profiles(profile_status);
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_article6 ON jurisdiction_profiles(article6_participant);
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_effective_from ON jurisdiction_profiles(effective_from);
CREATE INDEX IF NOT EXISTS idx_jurisdiction_profiles_created_at ON jurisdiction_profiles(created_at);

-- Indexes for lifecycle_checkpoint_rules
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_jurisdiction ON lifecycle_checkpoint_rules(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_transition ON lifecycle_checkpoint_rules(lifecycle_transition);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_checkpoint ON lifecycle_checkpoint_rules(checkpoint_id);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_status ON lifecycle_checkpoint_rules(rule_status);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_interpretation ON lifecycle_checkpoint_rules(interpretation_pack_id);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_effective_from ON lifecycle_checkpoint_rules(effective_from);
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_effective_to ON lifecycle_checkpoint_rules(effective_to) WHERE effective_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_created_at ON lifecycle_checkpoint_rules(created_at);

-- Composite index for active rule lookup
CREATE INDEX IF NOT EXISTS idx_lifecycle_checkpoint_rules_active_lookup ON lifecycle_checkpoint_rules(
    jurisdiction_code,
    lifecycle_transition,
    rule_status
) WHERE effective_to IS NULL;

-- RLS for jurisdiction_profiles (canonical jurisdiction pattern)
ALTER TABLE public.jurisdiction_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jurisdiction_profiles FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_jurisdiction_profiles ON public.jurisdiction_profiles
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- RLS for lifecycle_checkpoint_rules (canonical jurisdiction pattern)
ALTER TABLE public.lifecycle_checkpoint_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lifecycle_checkpoint_rules FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_lifecycle_checkpoint_rules ON public.lifecycle_checkpoint_rules
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- Append-only trigger for jurisdiction_profiles
CREATE OR REPLACE FUNCTION jurisdiction_profiles_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'jurisdiction_profiles is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER jurisdiction_profiles_append_only
    BEFORE UPDATE OR DELETE ON jurisdiction_profiles
    FOR EACH ROW
    EXECUTE FUNCTION jurisdiction_profiles_append_only_trigger();

-- Append-only trigger for lifecycle_checkpoint_rules
CREATE OR REPLACE FUNCTION lifecycle_checkpoint_rules_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'lifecycle_checkpoint_rules is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER lifecycle_checkpoint_rules_append_only
    BEFORE UPDATE OR DELETE ON lifecycle_checkpoint_rules
    FOR EACH ROW
    EXECUTE FUNCTION lifecycle_checkpoint_rules_append_only_trigger();

-- Function to create jurisdiction profile
CREATE OR REPLACE FUNCTION create_jurisdiction_profile(
    p_jurisdiction_code TEXT,
    p_country_name TEXT,
    p_national_registry_reference TEXT DEFAULT NULL,
    p_article6_participant BOOLEAN DEFAULT false,
    p_profile_status TEXT DEFAULT 'DRAFT',
    p_effective_from DATE DEFAULT CURRENT_DATE
)
RETURNS UUID AS $$
DECLARE
    v_profile_id UUID;
BEGIN
    -- Validate jurisdiction_code is not null
    IF p_jurisdiction_code IS NULL OR p_jurisdiction_code = '' THEN
        RAISE EXCEPTION 'jurisdiction_code cannot be null or empty';
    END IF;
    
    INSERT INTO jurisdiction_profiles (
        jurisdiction_code,
        country_name,
        national_registry_reference,
        article6_participant,
        profile_status,
        effective_from
    ) VALUES (
        p_jurisdiction_code,
        p_country_name,
        p_national_registry_reference,
        p_article6_participant,
        p_profile_status,
        p_effective_from
    ) RETURNING profile_id INTO v_profile_id;
    
    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to create lifecycle checkpoint rule
CREATE OR REPLACE FUNCTION create_lifecycle_checkpoint_rule(
    p_jurisdiction_code TEXT,
    p_lifecycle_transition TEXT,
    p_checkpoint_id UUID,
    p_rule_status TEXT,
    p_interpretation_pack_id UUID,
    p_effective_from TIMESTAMPTZ DEFAULT NOW(),
    p_effective_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_rule_id UUID;
BEGIN
    -- Validate jurisdiction_code is not null
    IF p_jurisdiction_code IS NULL OR p_jurisdiction_code = '' THEN
        RAISE EXCEPTION 'jurisdiction_code cannot be null or empty';
    END IF;
    
    -- Validate checkpoint exists
    IF NOT EXISTS (
        SELECT 1 FROM regulatory_checkpoints 
        WHERE checkpoint_id = p_checkpoint_id
        AND jurisdiction_code = p_jurisdiction_code
    ) THEN
        RAISE EXCEPTION 'Checkpoint not found or jurisdiction mismatch';
    END IF;
    
    INSERT INTO lifecycle_checkpoint_rules (
        jurisdiction_code,
        lifecycle_transition,
        checkpoint_id,
        rule_status,
        interpretation_pack_id,
        effective_from,
        effective_to
    ) VALUES (
        p_jurisdiction_code,
        p_lifecycle_transition,
        p_checkpoint_id,
        p_rule_status,
        p_interpretation_pack_id,
        p_effective_from,
        p_effective_to
    ) RETURNING rule_id INTO v_rule_id;
    
    RETURN v_rule_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query active checkpoint rules for jurisdiction
CREATE OR REPLACE FUNCTION query_active_checkpoint_rules(
    p_jurisdiction_code TEXT,
    p_lifecycle_transition TEXT DEFAULT NULL
)
RETURNS TABLE (
    rule_id UUID,
    lifecycle_transition TEXT,
    checkpoint_id UUID,
    checkpoint_type TEXT,
    rule_status TEXT,
    interpretation_pack_id UUID,
    authority_name TEXT,
    effective_from TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lcr.rule_id,
        lcr.lifecycle_transition,
        lcr.checkpoint_id,
        rc.checkpoint_type,
        lcr.rule_status,
        lcr.interpretation_pack_id,
        ra.authority_name,
        lcr.effective_from
    FROM lifecycle_checkpoint_rules lcr
    JOIN regulatory_checkpoints rc ON lcr.checkpoint_id = rc.checkpoint_id
    JOIN regulatory_authorities ra ON rc.authority_id = ra.authority_id
    WHERE lcr.jurisdiction_code = p_jurisdiction_code
    AND lcr.effective_to IS NULL
    AND (p_lifecycle_transition IS NULL OR lcr.lifecycle_transition = p_lifecycle_transition)
    AND rc.effective_to IS NULL
    AND ra.effective_to IS NULL
    ORDER BY lcr.lifecycle_transition, rc.checkpoint_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to get jurisdiction profile with regulatory summary
CREATE OR REPLACE FUNCTION query_jurisdiction_profile_summary(
    p_jurisdiction_code TEXT
)
RETURNS TABLE (
    profile_id UUID,
    country_name TEXT,
    profile_status TEXT,
    article6_participant BOOLEAN,
    effective_from DATE,
    active_authorities BIGINT,
    active_checkpoints BIGINT,
    active_rules BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jp.profile_id,
        jp.country_name,
        jp.profile_status,
        jp.article6_participant,
        jp.effective_from,
        (SELECT COUNT(*) FROM regulatory_authorities ra 
         WHERE ra.jurisdiction_code = p_jurisdiction_code 
         AND ra.effective_to IS NULL) as active_authorities,
        (SELECT COUNT(*) FROM regulatory_checkpoints rc 
         WHERE rc.jurisdiction_code = p_jurisdiction_code 
         AND rc.created_at >= jp.effective_from) as active_checkpoints,
        (SELECT COUNT(*) FROM lifecycle_checkpoint_rules lcr 
         WHERE lcr.jurisdiction_code = p_jurisdiction_code 
         AND lcr.effective_to IS NULL) as active_rules
    FROM jurisdiction_profiles jp
    WHERE jp.jurisdiction_code = p_jurisdiction_code
    AND jp.effective_to IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke-first privilege posture
REVOKE ALL ON TABLE jurisdiction_profiles FROM PUBLIC;
REVOKE ALL ON TABLE lifecycle_checkpoint_rules FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE jurisdiction_profiles TO authenticated_role;
GRANT SELECT, INSERT ON TABLE lifecycle_checkpoint_rules TO authenticated_role;
GRANT ALL ON TABLE jurisdiction_profiles TO system_role;
GRANT ALL ON TABLE lifecycle_checkpoint_rules TO system_role;
GRANT EXECUTE ON FUNCTION create_jurisdiction_profile TO authenticated_role;
GRANT EXECUTE ON FUNCTION create_jurisdiction_profile TO system_role;
GRANT EXECUTE ON FUNCTION create_lifecycle_checkpoint_rule TO authenticated_role;
GRANT EXECUTE ON FUNCTION create_lifecycle_checkpoint_rule TO system_role;
GRANT EXECUTE ON FUNCTION query_active_checkpoint_rules TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_active_checkpoint_rules TO system_role;
GRANT EXECUTE ON FUNCTION query_jurisdiction_profile_summary TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_jurisdiction_profile_summary TO system_role;
