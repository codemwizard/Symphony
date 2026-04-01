-- Migration 0087: Green Finance Verifier Registry
-- Phase 0 schema for verifier_registry and verifier_project_assignments.
-- Enforces SI Regulation 23 (accreditation) and Regulation 26 (validator/verifier separation).
-- Depends on 0097 (projects).

CREATE TABLE public.verifier_registry (
    verifier_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    jurisdiction_code TEXT NOT NULL,
    verifier_name TEXT NOT NULL,
    role_type TEXT NOT NULL CHECK (role_type IN ('VALIDATOR', 'VERIFIER', 'VALIDATOR_VERIFIER')),
    accreditation_reference TEXT NOT NULL,
    accreditation_authority TEXT NOT NULL,
    accreditation_expiry DATE NOT NULL,
    methodology_scope JSONB NOT NULL DEFAULT '[]',
    jurisdiction_scope JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN NOT NULL DEFAULT false,
    deactivated_at TIMESTAMPTZ,
    deactivation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT verifier_deactivation_consistency CHECK (
        (is_active = true AND deactivated_at IS NULL AND deactivation_reason IS NULL) OR
        (is_active = false AND deactivated_at IS NOT NULL AND deactivation_reason IS NOT NULL)
    )
);

CREATE TABLE public.verifier_project_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    verifier_id UUID NOT NULL REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT,
    project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    assigned_role TEXT NOT NULL CHECK (assigned_role IN ('VALIDATOR', 'VERIFIER')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT verifier_project_role_unique UNIQUE (verifier_id, project_id, assigned_role)
);

-- Indexes for performance
CREATE INDEX idx_verifier_registry_tenant_id ON verifier_registry(tenant_id);
CREATE INDEX idx_verifier_registry_jurisdiction ON verifier_registry(jurisdiction_code);
CREATE INDEX idx_verifier_project_assignments_verifier ON verifier_project_assignments(verifier_id);
CREATE INDEX idx_verifier_project_assignments_project ON verifier_project_assignments(project_id);

-- Append-only trigger function
CREATE OR REPLACE FUNCTION public.gf_verifier_tables_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION 'Table % is append-only', TG_TABLE_NAME
            USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER verifier_registry_no_mutate
    BEFORE UPDATE OR DELETE ON public.verifier_registry
    FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();

CREATE TRIGGER verifier_project_assignments_no_mutate
    BEFORE UPDATE OR DELETE ON public.verifier_project_assignments
    FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();

-- Regulation 26 separation enforcement function
CREATE OR REPLACE FUNCTION public.check_reg26_separation(
    p_verifier_id UUID,
    p_project_id UUID,
    p_requested_role TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_requested_role = 'VERIFIER' THEN
        IF EXISTS (
            SELECT 1 FROM public.verifier_project_assignments
            WHERE verifier_id = p_verifier_id
              AND project_id = p_project_id
              AND assigned_role = 'VALIDATOR'
        ) THEN
            RAISE EXCEPTION
                'Regulation 26 violation: validator cannot verify the same project (verifier_id=%, project_id=%)',
                p_verifier_id, p_project_id
                USING ERRCODE = 'GF001';
        END IF;
    END IF;
END;
$$;

-- RLS for tenant isolation
ALTER TABLE public.verifier_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_registry FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_verifier_registry ON public.verifier_registry
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

ALTER TABLE public.verifier_project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_project_assignments FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_verifier_project_assignments ON public.verifier_project_assignments
    FOR ALL TO PUBLIC
    USING (EXISTS (
        SELECT 1 FROM public.verifier_registry
        WHERE verifier_registry.verifier_id = verifier_project_assignments.verifier_id
          AND verifier_registry.tenant_id = public.current_tenant_id_or_null()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.verifier_registry
        WHERE verifier_registry.verifier_id = verifier_project_assignments.verifier_id
          AND verifier_registry.tenant_id = public.current_tenant_id_or_null()
    ));

-- Revoke-first privilege posture
REVOKE ALL ON TABLE verifier_registry FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE verifier_registry TO symphony_command;
GRANT ALL ON TABLE verifier_registry TO symphony_control;

REVOKE ALL ON TABLE verifier_project_assignments FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE verifier_project_assignments TO symphony_command;
GRANT ALL ON TABLE verifier_project_assignments TO symphony_control;

REVOKE ALL ON FUNCTION public.check_reg26_separation(UUID, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_reg26_separation(UUID, UUID, TEXT) TO symphony_command;
GRANT EXECUTE ON FUNCTION public.check_reg26_separation(UUID, UUID, TEXT) TO symphony_control;
