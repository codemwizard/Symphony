-- Migration 0107: GF Phase 1 — Project Registration Functions
-- Implements register_project, activate_project, query_project_details, list_tenant_projects
-- Phase 1 host functions; depends on 0097 (projects), 0098 (methodology_versions),
-- 0080 (adapter_registrations), 0099 (monitoring_records).
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.

-- ── register_project ────────────────────────────────────────────────────────
-- Creates a new project in DRAFT status, validates the methodology version and
-- adapter registration are active, and records a PROJECT_REGISTRATION monitoring event.
CREATE OR REPLACE FUNCTION public.register_project(
    p_tenant_id              UUID,
    p_project_name           TEXT,
    p_jurisdiction_code      TEXT,
    p_methodology_version_id UUID
)
RETURNS TABLE(project_id UUID, status TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_project_id            UUID;
    v_adapter_registration_id UUID;
BEGIN
    -- Input validation
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_name IS NULL OR trim(p_project_name) = '' THEN
        RAISE EXCEPTION 'p_project_name is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'p_methodology_version_id is required' USING ERRCODE = 'GF004';
    END IF;

    -- Validate methodology_version is active and its adapter is active
    SELECT mv.adapter_registration_id
      INTO v_adapter_registration_id
      FROM public.methodology_versions mv
      JOIN public.adapter_registrations ar
        ON ar.adapter_registration_id = mv.adapter_registration_id
     WHERE mv.methodology_version_id = p_methodology_version_id
       AND mv.tenant_id = p_tenant_id
       AND mv.status = 'ACTIVE'
       AND ar.is_active = true
     LIMIT 1;

    IF v_adapter_registration_id IS NULL THEN
        RAISE EXCEPTION 'methodology_version not found, not active, or adapter not active'
            USING ERRCODE = 'GF005';
    END IF;

    -- Insert project in DRAFT status
    INSERT INTO public.projects (tenant_id, name, status)
    VALUES (p_tenant_id, trim(p_project_name), 'DRAFT')
    RETURNING public.projects.project_id INTO v_project_id;

    -- Record PROJECT_REGISTRATION monitoring event (defined in 0108)
    PERFORM public.record_monitoring_record(
        p_tenant_id,
        v_project_id,
        'PROJECT_REGISTRATION',
        jsonb_build_object(
            'methodology_version_id', p_methodology_version_id,
            'adapter_registration_id', v_adapter_registration_id,
            'jurisdiction_code', p_jurisdiction_code
        )
    );

    RETURN QUERY SELECT v_project_id, 'DRAFT'::TEXT;
END;
$$;

-- ── activate_project ─────────────────────────────────────────────────────────
-- Transitions a project from DRAFT to ACTIVE and records a PROJECT_ACTIVATION event.
CREATE OR REPLACE FUNCTION public.activate_project(
    p_tenant_id  UUID,
    p_project_id UUID
)
RETURNS TABLE(project_id UUID, status TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF006';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF007';
    END IF;

    -- Fetch current status
    SELECT p.status
      INTO v_current_status
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id  = p_tenant_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'project not found for tenant' USING ERRCODE = 'GF008';
    END IF;

    IF v_current_status != 'DRAFT' THEN
        RAISE EXCEPTION 'project must be in DRAFT status to activate; current=%', v_current_status
            USING ERRCODE = 'GF009';
    END IF;

    -- Delegate lifecycle transition (defined in 0110)
    PERFORM public.transition_asset_status(p_tenant_id, p_project_id, 'ACTIVE');

    -- Update project to ACTIVE
    UPDATE public.projects
       SET status = 'ACTIVE'
     WHERE project_id = p_project_id
       AND tenant_id  = p_tenant_id;

    -- Record PROJECT_ACTIVATION monitoring event (defined in 0108)
    PERFORM public.record_monitoring_record(
        p_tenant_id,
        p_project_id,
        'PROJECT_ACTIVATION',
        '{}'::jsonb
    );

    RETURN QUERY SELECT p_project_id, 'ACTIVE'::TEXT;
END;
$$;

-- ── query_project_details ────────────────────────────────────────────────────
-- Returns a single project row for the given tenant and project.
CREATE OR REPLACE FUNCTION public.query_project_details(
    p_tenant_id  UUID,
    p_project_id UUID
)
RETURNS TABLE(project_id UUID, name TEXT, status TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT p.project_id, p.name, p.status, p.created_at
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id  = p_tenant_id;
END;
$$;

-- ── list_tenant_projects ─────────────────────────────────────────────────────
-- Returns all projects for a tenant, ordered by creation time descending.
CREATE OR REPLACE FUNCTION public.list_tenant_projects(
    p_tenant_id UUID
)
RETURNS TABLE(project_id UUID, name TEXT, status TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT p.project_id, p.name, p.status, p.created_at
      FROM public.projects p
     WHERE p.tenant_id = p_tenant_id
     ORDER BY p.created_at DESC;
END;
$$;

-- ── Privileges ────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION register_project(UUID, TEXT, TEXT, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION activate_project(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION query_project_details(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION list_tenant_projects(UUID)
    TO symphony_command;
