-- Migration 0101: Green Finance Asset Lifecycle Tables
-- Phase 0 schema for the GF lifecycle domain. Depends on 0097 (projects).

CREATE TABLE public.asset_batches (
    asset_batch_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    batch_type TEXT NOT NULL,
    quantity NUMERIC NOT NULL CHECK (quantity > 0),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'ACTIVE', 'RETIRED', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.asset_lifecycle_events (
    lifecycle_event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    asset_batch_id UUID NOT NULL REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT,
    event_type TEXT NOT NULL,
    event_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.retirement_events (
    retirement_event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    asset_batch_id UUID NOT NULL REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT,
    retired_quantity NUMERIC NOT NULL CHECK (retired_quantity > 0),
    retirement_reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_asset_batches_tenant_id ON asset_batches(tenant_id);
CREATE INDEX idx_asset_batches_project_id ON asset_batches(project_id);
CREATE INDEX idx_asset_lifecycle_events_tenant_id ON asset_lifecycle_events(tenant_id);
CREATE INDEX idx_asset_lifecycle_events_batch_id ON asset_lifecycle_events(asset_batch_id);
CREATE INDEX idx_retirement_events_tenant_id ON retirement_events(tenant_id);
CREATE INDEX idx_retirement_events_batch_id ON retirement_events(asset_batch_id);

-- RLS for tenant isolation
ALTER TABLE public.asset_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_batches FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_asset_batches ON public.asset_batches
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

ALTER TABLE public.asset_lifecycle_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_lifecycle_events FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_asset_lifecycle_events ON public.asset_lifecycle_events
    FOR ALL TO PUBLIC
    USING (EXISTS (
        SELECT 1 FROM public.asset_batches
        WHERE asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id
          AND asset_batches.tenant_id = public.current_tenant_id_or_null()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.asset_batches
        WHERE asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id
          AND asset_batches.tenant_id = public.current_tenant_id_or_null()
    ));

ALTER TABLE public.retirement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retirement_events FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_retirement_events ON public.retirement_events
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Revoke-first privilege posture
REVOKE ALL ON TABLE asset_batches FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE asset_batches TO symphony_command;
GRANT ALL ON TABLE asset_batches TO symphony_control;

REVOKE ALL ON TABLE asset_lifecycle_events FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE asset_lifecycle_events TO symphony_command;
GRANT ALL ON TABLE asset_lifecycle_events TO symphony_control;

REVOKE ALL ON TABLE retirement_events FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE retirement_events TO symphony_command;
GRANT ALL ON TABLE retirement_events TO symphony_control;
