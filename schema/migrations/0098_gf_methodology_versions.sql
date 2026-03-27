-- Migration 0098: Green Finance Methodology Versions (Root Foundation)
-- Phase 0 foundational schema for the methodology versions domain

CREATE TABLE IF NOT EXISTS public.methodology_versions (
    methodology_version_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    adapter_registration_id UUID NOT NULL REFERENCES public.adapter_registrations(adapter_registration_id) ON DELETE RESTRICT,
    version TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'ACTIVE', 'DEPRECATED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_methodology_versions_tenant_id ON methodology_versions(tenant_id);

-- RLS for tenant isolation (canonical 0059 pattern)
ALTER TABLE public.methodology_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.methodology_versions FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_methodology_versions ON public.methodology_versions
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Revoke-first privilege posture
REVOKE ALL ON TABLE methodology_versions FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON TABLE methodology_versions TO symphony_command;
GRANT ALL ON TABLE methodology_versions TO symphony_control;
