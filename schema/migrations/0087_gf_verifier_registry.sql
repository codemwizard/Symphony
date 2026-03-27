-- Migration 0087: Green Finance Verifier Registry
-- Phase 1 policy table for verifier registration and Regulation 26 compliance

-- Create verifier_registry table
CREATE TABLE IF NOT EXISTS public.verifier_registry (
  -- Primary identifier
  verifier_id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
  
  -- Tenant and jurisdiction context
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  jurisdiction_code TEXT NOT NULL,
  
  -- Verifier information
  verifier_name TEXT NOT NULL,
  role_type TEXT NOT NULL CHECK (
    role_type IN ('VALIDATOR', 'VERIFIER', 'VALIDATOR_VERIFIER')
  ),
  
  -- Accreditation details
  accreditation_reference TEXT NOT NULL,
  accreditation_authority TEXT NOT NULL,
  accreditation_expiry DATE NOT NULL,
  
  -- Scope definitions (JSONB arrays for flexibility)
  methodology_scope JSONB NOT NULL DEFAULT '[]',
  jurisdiction_scope JSONB NOT NULL DEFAULT '[]',
  
  -- Status and deactivation
  is_active BOOLEAN NOT NULL DEFAULT false,
  deactivated_at TIMESTAMPTZ NULL,
  deactivation_reason TEXT NULL,
  
  -- Audit trail
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT NOT NULL DEFAULT CURRENT_USER
);

-- Create verifier_project_assignments table for tracking project assignments
CREATE TABLE IF NOT EXISTS public.verifier_project_assignments (
  -- Primary identifier
  assignment_id UUID PRIMARY KEY DEFAULT public.uuid_generate_v4(),
  
  -- Assignment relationship
  verifier_id UUID NOT NULL REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT,
  project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
  
  -- Assignment details
  assigned_role TEXT NOT NULL CHECK (
    assigned_role IN ('VALIDATOR', 'VERIFIER')
  ),
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by TEXT NOT NULL DEFAULT CURRENT_USER
);

-- Indexes for verifier_registry
CREATE INDEX IF NOT EXISTS idx_verifier_registry_tenant_id ON verifier_registry(tenant_id);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_jurisdiction ON verifier_registry(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_role_type ON verifier_registry(role_type);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_active ON verifier_registry(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_verifier_registry_expiry ON verifier_registry(accreditation_expiry);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_cert_ref ON verifier_registry(accreditation_reference);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_created_at ON verifier_registry(created_at);

-- JSONB indexes for scope queries
CREATE INDEX IF NOT EXISTS idx_verifier_registry_methodology_gin ON verifier_registry USING GIN (methodology_scope);
CREATE INDEX IF NOT EXISTS idx_verifier_registry_jurisdiction_gin ON verifier_registry USING GIN (jurisdiction_scope);

-- Indexes for verifier_project_assignments
CREATE INDEX IF NOT EXISTS idx_verifier_project_assignments_verifier ON verifier_project_assignments(verifier_id);
CREATE INDEX IF NOT EXISTS idx_verifier_project_assignments_project ON verifier_project_assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_verifier_project_assignments_role ON verifier_project_assignments(assigned_role);
CREATE INDEX IF NOT EXISTS idx_verifier_project_assignments_assigned_at ON verifier_project_assignments(assigned_at);

-- Composite index for Regulation 26 checks
CREATE INDEX IF NOT EXISTS idx_verifier_project_assignments_reg26 ON verifier_project_assignments(
    verifier_id, 
    project_id, 
    assigned_role
);

-- RLS for verifier_registry (canonical 0059 pattern)
ALTER TABLE public.verifier_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_registry FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_verifier_registry ON public.verifier_registry
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- RLS for verifier_project_assignments (JOIN-based tenant isolation via parent)
ALTER TABLE public.verifier_project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_project_assignments FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_verifier_project_assignments ON public.verifier_project_assignments
    FOR ALL TO PUBLIC
    USING (EXISTS (
        SELECT 1 FROM public.verifier_registry vr
        WHERE vr.verifier_id = verifier_project_assignments.verifier_id
        AND vr.tenant_id = public.current_tenant_id_or_null()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.verifier_registry vr
        WHERE vr.verifier_id = verifier_project_assignments.verifier_id
        AND vr.tenant_id = public.current_tenant_id_or_null()
    ));

-- Append-only trigger for verifier_registry
CREATE OR REPLACE FUNCTION verifier_registry_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'verifier_registry is append-only - DELETE operations not allowed';
    END IF;
    
    -- Allow UPDATE only for deactivation and accreditation updates
    IF TG_OP = 'UPDATE' THEN
        IF OLD.is_active = true AND NEW.is_active = false THEN
            -- Allow deactivation
            NEW.deactivated_at = NOW();
            RETURN NEW;
        ELSIF OLD.accreditation_expiry != NEW.accreditation_expiry THEN
            -- Allow accreditation expiry updates
            RETURN NEW;
        ELSIF OLD.methodology_scope != NEW.methodology_scope THEN
            -- Allow methodology scope updates
            RETURN NEW;
        ELSIF OLD.jurisdiction_scope != NEW.jurisdiction_scope THEN
            -- Allow jurisdiction scope updates
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'verifier_registry only allows deactivation, accreditation expiry, or scope updates';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER verifier_registry_append_only
    BEFORE UPDATE OR DELETE ON verifier_registry
    FOR EACH ROW
    EXECUTE FUNCTION verifier_registry_append_only_trigger();

-- Append-only trigger for verifier_project_assignments
CREATE OR REPLACE FUNCTION verifier_project_assignments_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'verifier_project_assignments is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER verifier_project_assignments_append_only
    BEFORE UPDATE OR DELETE ON verifier_project_assignments
    FOR EACH ROW
    EXECUTE FUNCTION verifier_project_assignments_append_only_trigger();

-- Regulation 26 separation-of-duties check function
CREATE OR REPLACE FUNCTION check_reg26_separation(
    p_verifier_id UUID,
    p_project_id UUID,
    p_requested_role TEXT
)
RETURNS void AS $$
DECLARE
    v_validator_assignment_count INT;
BEGIN
    -- Only check for VERIFIER role (Regulation 26 applies to verifiers)
    IF p_requested_role != 'VERIFIER' THEN
        RETURN;
    END IF;
    
    -- Check if verifier was previously assigned as VALIDATOR to this project
    SELECT COUNT(*) INTO v_validator_assignment_count
    FROM verifier_project_assignments
    WHERE verifier_id = p_verifier_id
    AND project_id = p_project_id
    AND assigned_role = 'VALIDATOR';
    
    -- If found, raise Regulation 26 violation
    IF v_validator_assignment_count > 0 THEN
        RAISE EXCEPTION 'GF001', 'Regulation 26 violation: validator cannot verify the same project';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to register a verifier
CREATE OR REPLACE FUNCTION register_verifier(
    p_tenant_id UUID,
    p_jurisdiction_code TEXT,
    p_verifier_name TEXT,
    p_role_type TEXT,
    p_accreditation_reference TEXT,
    p_accreditation_authority TEXT,
    p_accreditation_expiry DATE,
    p_methodology_scope JSONB DEFAULT '[]',
    p_jurisdiction_scope JSONB DEFAULT '[]'
)
RETURNS UUID AS $$
DECLARE
    v_verifier_id UUID;
BEGIN
    -- Validate inputs
    IF p_role_type NOT IN ('VALIDATOR', 'VERIFIER', 'VALIDATOR_VERIFIER') THEN
        RAISE EXCEPTION 'Invalid role_type: %', p_role_type;
    END IF;
    
    IF p_accreditation_expiry <= CURRENT_DATE THEN
        RAISE EXCEPTION 'Accreditation expiry must be in the future';
    END IF;
    
    -- Insert verifier
    INSERT INTO verifier_registry (
        tenant_id,
        jurisdiction_code,
        verifier_name,
        role_type,
        accreditation_reference,
        accreditation_authority,
        accreditation_expiry,
        methodology_scope,
        jurisdiction_scope
    ) VALUES (
        p_tenant_id,
        p_jurisdiction_code,
        p_verifier_name,
        p_role_type,
        p_accreditation_reference,
        p_accreditation_authority,
        p_accreditation_expiry,
        p_methodology_scope,
        p_jurisdiction_scope
    ) RETURNING verifier_id INTO v_verifier_id;
    
    RETURN v_verifier_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to assign verifier to project
CREATE OR REPLACE FUNCTION assign_verifier_to_project(
    p_verifier_id UUID,
    p_project_id UUID,
    p_assigned_role TEXT
)
RETURNS UUID AS $$
DECLARE
    v_assignment_id UUID;
    v_verifier_tenant_id UUID;
BEGIN
    -- Get verifier tenant for validation
    SELECT tenant_id INTO v_verifier_tenant_id
    FROM verifier_registry
    WHERE verifier_id = p_verifier_id
    AND is_active = true;
    
    IF v_verifier_tenant_id IS NULL THEN
        RAISE EXCEPTION 'Active verifier not found';
    END IF;
    
    -- Check Regulation 26 separation before assignment
    PERFORM check_reg26_separation(p_verifier_id, p_project_id, p_assigned_role);
    
    -- Insert assignment
    INSERT INTO verifier_project_assignments (
        verifier_id,
        project_id,
        assigned_role
    ) VALUES (
        p_verifier_id,
        p_project_id,
        p_assigned_role
    ) RETURNING assignment_id INTO v_assignment_id;
    
    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query active verifiers
CREATE OR REPLACE FUNCTION query_active_verifiers(
    p_tenant_id UUID,
    p_jurisdiction_code TEXT DEFAULT NULL,
    p_role_type TEXT DEFAULT NULL,
    p_methodology_filter JSONB DEFAULT NULL
)
RETURNS TABLE (
    verifier_id UUID,
    verifier_name TEXT,
    role_type TEXT,
    accreditation_reference TEXT,
    accreditation_authority TEXT,
    accreditation_expiry DATE,
    methodology_scope JSONB,
    jurisdiction_scope JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vr.verifier_id,
        vr.verifier_name,
        vr.role_type,
        vr.accreditation_reference,
        vr.accreditation_authority,
        vr.accreditation_expiry,
        vr.methodology_scope,
        vr.jurisdiction_scope,
        vr.created_at
    FROM verifier_registry vr
    WHERE vr.tenant_id = p_tenant_id
    AND vr.is_active = true
    AND vr.accreditation_expiry > CURRENT_DATE
    AND (p_jurisdiction_code IS NULL OR vr.jurisdiction_code = p_jurisdiction_code)
    AND (p_role_type IS NULL OR vr.role_type = p_role_type)
    AND (p_methodology_filter IS NULL OR vr.methodology_scope @> p_methodology_filter)
    ORDER BY vr.verifier_name, vr.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke-first privilege posture
REVOKE ALL ON TABLE verifier_registry FROM PUBLIC;
REVOKE ALL ON TABLE verifier_project_assignments FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON TABLE verifier_registry TO authenticated_role;
GRANT SELECT, INSERT ON TABLE verifier_project_assignments TO authenticated_role;
GRANT ALL ON TABLE verifier_registry TO system_role;
GRANT ALL ON TABLE verifier_project_assignments TO system_role;
GRANT EXECUTE ON FUNCTION register_verifier TO authenticated_role;
GRANT EXECUTE ON FUNCTION register_verifier TO system_role;
GRANT EXECUTE ON FUNCTION assign_verifier_to_project TO authenticated_role;
GRANT EXECUTE ON FUNCTION assign_verifier_to_project TO system_role;
GRANT EXECUTE ON FUNCTION query_active_verifiers TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_active_verifiers TO system_role;
GRANT EXECUTE ON FUNCTION check_reg26_separation TO authenticated_role;
GRANT EXECUTE ON FUNCTION check_reg26_separation TO system_role;
