-- Migration 0088: Green Finance Phase 1 Functions - Project Registration
-- SECURITY DEFINER functions with hardened search_path

-- Function to register a new project
CREATE OR REPLACE FUNCTION register_project(
    p_tenant_id UUID,
    p_project_name TEXT,
    p_jurisdiction_code TEXT,
    p_methodology_version_id UUID,
    p_project_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_project_id UUID;
    v_methodology_exists BOOLEAN;
    v_adapter_active BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Tenant ID is required';
    END IF;
    
    IF p_project_name IS NULL OR trim(p_project_name) = '' THEN
        RAISE EXCEPTION 'GF002', 'Project name is required';
    END IF;
    
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'GF003', 'Jurisdiction code is required';
    END IF;
    
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'GF004', 'Methodology version ID is required';
    END IF;
    
    -- Check if methodology version exists
    SELECT EXISTS (
        SELECT 1 FROM methodology_versions 
        WHERE methodology_version_id = p_methodology_version_id
        AND is_active = true
    ) INTO v_methodology_exists;
    
    IF NOT v_methodology_exists THEN
        RAISE EXCEPTION 'GF005', 'Methodology version not found or inactive';
    END IF;
    
    -- Check if adapter is active (via methodology_version -> adapter_registration)
    SELECT EXISTS (
        SELECT 1 FROM methodology_versions mv
        JOIN adapter_registrations ar ON mv.adapter_registration_id = ar.adapter_registration_id
        WHERE mv.methodology_version_id = p_methodology_version_id
        AND ar.is_active = true
    ) INTO v_adapter_active;
    
    IF NOT v_adapter_active THEN
        RAISE EXCEPTION 'GF006', 'Adapter for methodology version is not active';
    END IF;
    
    -- Insert project with DRAFT status
    INSERT INTO asset_batches (
        tenant_id,
        project_id,
        methodology_version_id,
        asset_type,
        vintage_start,
        vintage_end,
        issuable_quantity,
        unit,
        status
    ) VALUES (
        p_tenant_id,
        uuid_generate_v4(),
        p_methodology_version_id,
        'PROJECT',
        CURRENT_DATE,
        NULL,
        0,
        'UNITS',
        'DRAFT'
    ) RETURNING project_id INTO v_project_id;
    
    -- Record monitoring event for project registration
    PERFORM record_monitoring_record(
        p_tenant_id,
        v_project_id,
        p_methodology_version_id,
        'PROJECT_REGISTRATION',
        now(),
        now(),
        'SYSTEM',
        'register_project',
        NULL,
        jsonb_build_object(
            'project_name', p_project_name,
            'jurisdiction_code', p_jurisdiction_code,
            'project_metadata', p_project_metadata
        ),
        NULL,
        NULL,
        v_project_id
    );
    
    RETURN v_project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to activate a project (transition from DRAFT to ACTIVE)
CREATE OR REPLACE FUNCTION activate_project(
    p_tenant_id UUID,
    p_project_id UUID,
    p_activation_reason TEXT DEFAULT 'Project activation'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_status TEXT;
    v_project_exists BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Tenant ID is required';
    END IF;
    
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'GF007', 'Project ID is required';
    END IF;
    
    -- Check if project exists and get current status
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND tenant_id = p_tenant_id
    ) INTO v_project_exists;
    
    IF NOT v_project_exists THEN
        RAISE EXCEPTION 'GF008', 'Project not found';
    END IF;
    
    -- Get current status
    SELECT status INTO v_current_status
    FROM asset_batches
    WHERE project_id = p_project_id
    AND tenant_id = p_tenant_id;
    
    -- Check if project is in DRAFT status
    IF v_current_status != 'DRAFT' THEN
        RAISE EXCEPTION 'GF009', 'Project must be in DRAFT status to activate (current: %)', v_current_status;
    END IF;
    
    -- Transition project to ACTIVE
    PERFORM transition_asset_status(
        p_project_id,
        'DRAFT',
        'ACTIVE',
        p_activation_reason,
        jsonb_build_object(
            'activated_at', now(),
            'activated_by', current_user
        )
    );
    
    -- Record monitoring event for project activation
    PERFORM record_monitoring_record(
        p_tenant_id,
        p_project_id,
        NULL,
        'PROJECT_ACTIVATION',
        now(),
        now(),
        'SYSTEM',
        'activate_project',
        NULL,
        jsonb_build_object(
            'activation_reason', p_activation_reason,
            'previous_status', 'DRAFT',
            'new_status', 'ACTIVE'
        ),
        NULL,
        NULL,
        p_project_id
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query project details
CREATE OR REPLACE FUNCTION query_project_details(
    p_tenant_id UUID,
    p_project_id UUID
)
RETURNS TABLE (
    project_id UUID,
    project_name TEXT,
    jurisdiction_code TEXT,
    methodology_version_id UUID,
    adapter_code TEXT,
    status TEXT,
    created_at TIMESTAMPTZ,
    vintage_start DATE,
    vintage_end DATE,
    issuable_quantity BIGINT,
    unit TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ab.project_id,
        COALESCE(ab.project_metadata->>'project_name', 'Unnamed Project') as project_name,
        ab.jurisdiction_code,
        ab.methodology_version_id,
        ar.adapter_code,
        ab.status,
        ab.created_at,
        ab.vintage_start,
        ab.vintage_end,
        ab.issuable_quantity,
        ab.unit
    FROM asset_batches ab
    JOIN methodology_versions mv ON ab.methodology_version_id = mv.methodology_version_id
    JOIN adapter_registrations ar ON mv.adapter_registration_id = ar.adapter_registration_id
    WHERE ab.project_id = p_project_id
    AND ab.tenant_id = p_tenant_id
    AND ab.asset_type = 'PROJECT';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to list projects by tenant
CREATE OR REPLACE FUNCTION list_tenant_projects(
    p_tenant_id UUID,
    p_status_filter TEXT DEFAULT NULL,
    p_jurisdiction_filter TEXT DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    project_id UUID,
    project_name TEXT,
    jurisdiction_code TEXT,
    methodology_version_id UUID,
    adapter_code TEXT,
    status TEXT,
    created_at TIMESTAMPTZ,
    vintage_start DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ab.project_id,
        COALESCE(ab.project_metadata->>'project_name', 'Unnamed Project') as project_name,
        ab.jurisdiction_code,
        ab.methodology_version_id,
        ar.adapter_code,
        ab.status,
        ab.created_at,
        ab.vintage_start
    FROM asset_batches ab
    JOIN methodology_versions mv ON ab.methodology_version_id = mv.methodology_version_id
    JOIN adapter_registrations ar ON mv.adapter_registration_id = ar.adapter_registration_id
    WHERE ab.tenant_id = p_tenant_id
    AND ab.asset_type = 'PROJECT'
    AND (p_status_filter IS NULL OR ab.status = p_status_filter)
    AND (p_jurisdiction_filter IS NULL OR ab.jurisdiction_code = p_jurisdiction_filter)
    ORDER BY ab.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION register_project TO authenticated_role;
GRANT EXECUTE ON FUNCTION register_project TO system_role;
GRANT EXECUTE ON FUNCTION activate_project TO authenticated_role;
GRANT EXECUTE ON FUNCTION activate_project TO system_role;
GRANT EXECUTE ON FUNCTION query_project_details TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_project_details TO system_role;
GRANT EXECUTE ON FUNCTION list_tenant_projects TO authenticated_role;
GRANT EXECUTE ON FUNCTION list_tenant_projects TO system_role;
