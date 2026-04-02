-- Migration 0109: GF Phase 1 — Evidence Lineage Functions
-- Implements attach_evidence, link_evidence_to_record, query_evidence_lineage,
-- get_evidence_node, list_project_evidence.
-- Depends on 0097 (projects), 0099 (monitoring_records), 0100 (evidence_nodes/edges),
-- 0101 (asset_batches).
-- Append-only: evidence_nodes and evidence_edges only receive INSERT operations.
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.

-- ── Evidence class taxonomy (universal, sector-neutral) ──────────────────────
-- Valid evidence_class values: RAW_SOURCE, ATTESTED_SOURCE, NORMALIZED_RECORD,
-- ANALYST_FINDING, VERIFIER_FINDING, REGULATORY_EXPORT, ISSUANCE_ARTIFACT

-- ── Edge type taxonomy ────────────────────────────────────────────────────────
-- Valid edge_type values: SUPPORTS, REFUTES, DOCUMENTS, VALIDATES,
-- ATTESTS_TO, DERIVED_FROM, CORROBORATES

-- ── Target record type taxonomy ───────────────────────────────────────────────
-- Valid target_record_type values: PROJECT, MONITORING_RECORD, ASSET_BATCH,
-- EVIDENCE_NODE

-- ── attach_evidence ──────────────────────────────────────────────────────────
-- Creates an evidence_node in the append-only lineage graph.
-- Validates evidence class, document type, and target record existence.
-- Append-only invariant: only INSERT operations are permitted on the evidence tables.
CREATE OR REPLACE FUNCTION public.attach_evidence(
    p_tenant_id          UUID,
    p_project_id         UUID,
    p_evidence_class     TEXT,
    p_document_type      TEXT,
    p_target_record_type TEXT,
    p_target_record_id   UUID,
    p_node_payload_json  JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_evidence_node_id      UUID;
    v_monitoring_record_id  UUID := NULL;
    v_valid_classes         TEXT[] := ARRAY[
        'RAW_SOURCE', 'ATTESTED_SOURCE', 'NORMALIZED_RECORD',
        'ANALYST_FINDING', 'VERIFIER_FINDING', 'REGULATORY_EXPORT', 'ISSUANCE_ARTIFACT'
    ];
    v_valid_target_types    TEXT[] := ARRAY[
        'PROJECT', 'MONITORING_RECORD', 'ASSET_BATCH', 'EVIDENCE_NODE'
    ];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_evidence_class IS NULL OR trim(p_evidence_class) = '' THEN
        RAISE EXCEPTION 'p_evidence_class is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_document_type IS NULL OR trim(p_document_type) = '' THEN
        RAISE EXCEPTION 'p_document_type is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_target_record_type IS NULL OR trim(p_target_record_type) = '' THEN
        RAISE EXCEPTION 'p_target_record_type is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_target_record_id IS NULL THEN
        RAISE EXCEPTION 'p_target_record_id is required' USING ERRCODE = 'GF006';
    END IF;

    -- ── Evidence class validation ───────────────────────────────────────────
    IF NOT (p_evidence_class = ANY(v_valid_classes)) THEN
        RAISE EXCEPTION 'Invalid evidence class: %; must be one of %',
                         p_evidence_class, v_valid_classes
            USING ERRCODE = 'GF007';
    END IF;

    -- ── Target record type validation ───────────────────────────────────────
    IF NOT (p_target_record_type = ANY(v_valid_target_types)) THEN
        RAISE EXCEPTION 'Invalid target record type: %', p_target_record_type
            USING ERRCODE = 'GF008';
    END IF;

    -- ── Validate target record exists and belongs to tenant ─────────────────
    IF p_target_record_type = 'PROJECT' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.projects
             WHERE project_id = p_target_record_id AND tenant_id = p_tenant_id
        ) THEN
            RAISE EXCEPTION 'target PROJECT not found for tenant' USING ERRCODE = 'GF009';
        END IF;

    ELSIF p_target_record_type = 'MONITORING_RECORD' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.monitoring_records mr
             WHERE mr.monitoring_record_id = p_target_record_id
               AND mr.tenant_id = p_tenant_id
               AND mr.project_id = p_project_id
        ) THEN
            RAISE EXCEPTION 'target MONITORING_RECORD not found for project/tenant'
                USING ERRCODE = 'GF010';
        END IF;
        v_monitoring_record_id := p_target_record_id;

    ELSIF p_target_record_type = 'ASSET_BATCH' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.asset_batches ab
             WHERE ab.asset_batch_id = p_target_record_id
               AND ab.tenant_id = p_tenant_id
               AND ab.project_id = p_project_id
        ) THEN
            RAISE EXCEPTION 'target ASSET_BATCH not found for project/tenant'
                USING ERRCODE = 'GF011';
        END IF;

    ELSIF p_target_record_type = 'EVIDENCE_NODE' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.evidence_nodes en
             WHERE en.evidence_node_id = p_target_record_id
               AND en.tenant_id = p_tenant_id
        ) THEN
            RAISE EXCEPTION 'target EVIDENCE_NODE not found for tenant'
                USING ERRCODE = 'GF012';
        END IF;
    END IF;

    -- ── Insert evidence node (append-only) ──────────────────────────────────
    INSERT INTO evidence_nodes (
        tenant_id,
        project_id,
        monitoring_record_id,
        node_type,
        node_payload_json
    ) VALUES (
        p_tenant_id,
        p_project_id,
        v_monitoring_record_id,
        p_evidence_class,
        p_node_payload_json
    )
    RETURNING evidence_node_id INTO v_evidence_node_id;

    RETURN v_evidence_node_id;
END;
$$;

-- ── link_evidence_to_record ───────────────────────────────────────────────────
-- Creates a directed evidence_edge between two evidence_nodes in the same tenant.
-- Enforces: no self-loops, no cross-tenant linkage, valid edge types.
CREATE OR REPLACE FUNCTION public.link_evidence_to_record(
    p_tenant_id             UUID,
    p_evidence_node_id      UUID,
    p_target_evidence_node_id UUID,
    p_edge_type             TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_edge_id          UUID;
    v_source_tenant    UUID;
    v_target_tenant    UUID;
    v_valid_edge_types TEXT[] := ARRAY[
        'SUPPORTS', 'REFUTES', 'DOCUMENTS', 'VALIDATES',
        'ATTESTS_TO', 'DERIVED_FROM', 'CORROBORATES'
    ];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF013';
    END IF;
    IF p_evidence_node_id IS NULL THEN
        RAISE EXCEPTION 'p_evidence_node_id is required' USING ERRCODE = 'GF014';
    END IF;
    IF p_target_evidence_node_id IS NULL THEN
        RAISE EXCEPTION 'p_target_evidence_node_id is required' USING ERRCODE = 'GF015';
    END IF;
    IF p_edge_type IS NULL OR trim(p_edge_type) = '' THEN
        RAISE EXCEPTION 'p_edge_type is required' USING ERRCODE = 'GF016';
    END IF;

    -- ── Edge type validation ────────────────────────────────────────────────
    IF NOT (p_edge_type = ANY(v_valid_edge_types)) THEN
        RAISE EXCEPTION 'Invalid edge type: %', p_edge_type USING ERRCODE = 'GF017';
    END IF;

    -- ── Self-loop prevention ────────────────────────────────────────────────
    IF p_evidence_node_id = p_target_evidence_node_id THEN
        RAISE EXCEPTION 'Self-loop not allowed: source and target evidence_node_id are identical'
            USING ERRCODE = 'GF018';
    END IF;

    -- ── Cross-tenant linkage prevention ────────────────────────────────────
    SELECT en.tenant_id INTO v_source_tenant
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_evidence_node_id;

    IF v_source_tenant IS NULL THEN
        RAISE EXCEPTION 'source evidence node not found' USING ERRCODE = 'GF019';
    END IF;

    IF v_source_tenant != p_tenant_id THEN
        RAISE EXCEPTION 'cross-tenant linkage prevented: source tenant_id != p_tenant_id'
            USING ERRCODE = 'GF019';
    END IF;

    SELECT en.tenant_id INTO v_target_tenant
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_target_evidence_node_id;

    IF v_target_tenant IS NULL OR v_target_tenant != p_tenant_id THEN
        RAISE EXCEPTION 'cross-tenant linkage prevented: target tenant_id != p_tenant_id'
            USING ERRCODE = 'GF019';
    END IF;

    -- ── Insert evidence edge (append-only) ──────────────────────────────────
    INSERT INTO evidence_edges (
        tenant_id,
        source_node_id,
        target_node_id,
        edge_type
    ) VALUES (
        p_tenant_id,
        p_evidence_node_id,
        p_target_evidence_node_id,
        p_edge_type
    )
    RETURNING evidence_edge_id INTO v_edge_id;

    RETURN v_edge_id;
END;
$$;

-- ── query_evidence_lineage ────────────────────────────────────────────────────
-- Returns all evidence nodes and their outbound edges for a project.
CREATE OR REPLACE FUNCTION public.query_evidence_lineage(
    p_tenant_id  UUID,
    p_project_id UUID
)
RETURNS TABLE(
    evidence_node_id UUID,
    node_type        TEXT,
    monitoring_record_id UUID,
    evidence_edge_id UUID,
    source_node_id   UUID,
    target_node_id   UUID,
    edge_type        TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.node_type,
           en.monitoring_record_id,
           ee.evidence_edge_id,
           ee.source_node_id,
           ee.target_node_id,
           ee.edge_type
      FROM public.evidence_nodes en
      LEFT JOIN public.evidence_edges ee
             ON ee.source_node_id = en.evidence_node_id
            AND ee.tenant_id      = en.tenant_id
     WHERE en.tenant_id  = p_tenant_id
       AND en.project_id = p_project_id
     ORDER BY en.created_at ASC;
END;
$$;

-- ── get_evidence_node ─────────────────────────────────────────────────────────
-- Returns a single evidence node for a tenant.
CREATE OR REPLACE FUNCTION public.get_evidence_node(
    p_tenant_id      UUID,
    p_evidence_node_id UUID
)
RETURNS TABLE(
    evidence_node_id     UUID,
    project_id           UUID,
    monitoring_record_id UUID,
    node_type            TEXT,
    node_payload_json    JSONB,
    created_at           TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.project_id,
           en.monitoring_record_id,
           en.node_type,
           en.node_payload_json,
           en.created_at
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_evidence_node_id
       AND en.tenant_id        = p_tenant_id;
END;
$$;

-- ── list_project_evidence ─────────────────────────────────────────────────────
-- Returns all evidence nodes for a project in append order.
CREATE OR REPLACE FUNCTION public.list_project_evidence(
    p_tenant_id  UUID,
    p_project_id UUID
)
RETURNS TABLE(
    evidence_node_id     UUID,
    node_type            TEXT,
    monitoring_record_id UUID,
    created_at           TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.node_type,
           en.monitoring_record_id,
           en.created_at
      FROM public.evidence_nodes en
     WHERE en.tenant_id  = p_tenant_id
       AND en.project_id = p_project_id
     ORDER BY en.created_at ASC;
END;
$$;

-- ── Privileges ────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION attach_evidence(UUID, UUID, TEXT, TEXT, TEXT, UUID, JSONB)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION link_evidence_to_record(UUID, UUID, UUID, TEXT)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION query_evidence_lineage(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION get_evidence_node(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION list_project_evidence(UUID, UUID)
    TO symphony_command;
