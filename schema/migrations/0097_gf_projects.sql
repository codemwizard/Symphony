-- Migration 0097: Green Finance Projects (Root Foundation)
-- Phase 0 foundational schema for the projects domain

CREATE TABLE public.projects (
    project_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_projects_tenant_id ON projects(tenant_id);

-- RLS for tenant isolation (canonical 0059 pattern)
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_projects ON public.projects
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Revoke-first privilege posture
REVOKE ALL ON TABLE projects FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON TABLE projects TO symphony_command;
GRANT ALL ON TABLE projects TO symphony_control;
