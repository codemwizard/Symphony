-- Migration 0099: Green Finance Monitoring Records (Append-Only Event Ledger)
-- Phase 0 schema for the GF monitoring domain. Depends on 0097 (projects).

CREATE TABLE public.monitoring_records (
    monitoring_record_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    record_type TEXT NOT NULL,
    record_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_monitoring_records_tenant_id ON monitoring_records(tenant_id);
CREATE INDEX idx_monitoring_records_project_id ON monitoring_records(project_id);

-- RLS for tenant isolation (canonical 0059 pattern)
ALTER TABLE public.monitoring_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monitoring_records FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_monitoring_records ON public.monitoring_records
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Revoke-first privilege posture — append-only: no UPDATE, no DELETE for runtime role
REVOKE ALL ON TABLE monitoring_records FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE monitoring_records TO symphony_command;
GRANT ALL ON TABLE monitoring_records TO symphony_control;
