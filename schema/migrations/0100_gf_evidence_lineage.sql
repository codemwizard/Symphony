-- Migration 0100: Green Finance Evidence Lineage Graph
-- Phase 0 schema for the GF evidence lineage domain. Depends on 0097 (projects), 0099 (monitoring_records).

CREATE TABLE public.evidence_nodes (
    evidence_node_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    monitoring_record_id UUID REFERENCES public.monitoring_records(monitoring_record_id) ON DELETE RESTRICT,
    node_type TEXT NOT NULL,
    node_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.evidence_edges (
    evidence_edge_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    source_node_id UUID NOT NULL REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT,
    target_node_id UUID NOT NULL REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT,
    edge_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT no_self_loop CHECK (source_node_id <> target_node_id)
);

-- Indexes for performance
CREATE INDEX idx_evidence_nodes_tenant_id ON evidence_nodes(tenant_id);
CREATE INDEX idx_evidence_nodes_project_id ON evidence_nodes(project_id);
CREATE INDEX idx_evidence_edges_tenant_id ON evidence_edges(tenant_id);
CREATE INDEX idx_evidence_edges_source ON evidence_edges(source_node_id);
CREATE INDEX idx_evidence_edges_target ON evidence_edges(target_node_id);

-- RLS for tenant isolation
ALTER TABLE public.evidence_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_nodes FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_evidence_nodes ON public.evidence_nodes
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

ALTER TABLE public.evidence_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_edges FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_evidence_edges ON public.evidence_edges
    FOR ALL TO PUBLIC
    USING (EXISTS (
        SELECT 1 FROM public.evidence_nodes
        WHERE evidence_nodes.evidence_node_id = evidence_edges.source_node_id
          AND evidence_nodes.tenant_id = public.current_tenant_id_or_null()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.evidence_nodes
        WHERE evidence_nodes.evidence_node_id = evidence_edges.source_node_id
          AND evidence_nodes.tenant_id = public.current_tenant_id_or_null()
    ));

-- Revoke-first privilege posture
REVOKE ALL ON TABLE evidence_nodes FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE evidence_nodes TO symphony_command;
GRANT ALL ON TABLE evidence_nodes TO symphony_control;

REVOKE ALL ON TABLE evidence_edges FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE evidence_edges TO symphony_command;
GRANT ALL ON TABLE evidence_edges TO symphony_control;
