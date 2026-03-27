-- Migration 0090: Green Finance Phase 1 Functions - Evidence Lineage
-- SECURITY DEFINER functions with hardened search_path

-- Function to attach evidence (create evidence node)
CREATE OR REPLACE FUNCTION attach_evidence(
    p_tenant_id UUID,
    p_project_id UUID DEFAULT NULL,
    p_evidence_class TEXT,
    p_document_type TEXT,
    p_file_hash_sha256 TEXT DEFAULT NULL,
    p_storage_reference TEXT DEFAULT NULL,
    p_uploaded_by TEXT DEFAULT current_user,
    p_metadata_json JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_evidence_node_id UUID;
    v_valid_class BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Tenant ID is required';
    END IF;
    
    IF p_evidence_class IS NULL OR trim(p_evidence_class) = '' THEN
        RAISE EXCEPTION 'GF002', 'Evidence class is required';
    END IF;
    
    IF p_document_type IS NULL OR trim(p_document_type) = '' THEN
        RAISE EXCEPTION 'GF003', 'Document type is required';
    END IF;
    
    -- Validate evidence class against universal taxonomy
    IF p_evidence_class IN (
        'RAW_SOURCE', 
        'ATTESTED_SOURCE', 
        'NORMALIZED_RECORD', 
        'ANALYST_FINDING',
        'VERIFIER_FINDING', 
        'REGULATORY_EXPORT', 
        'ISSUANCE_ARTIFACT'
    ) THEN
        v_valid_class := true;
    ELSE
        v_valid_class := false;
    END IF;
    
    IF NOT v_valid_class THEN
        RAISE EXCEPTION 'GF004', 'Invalid evidence class: %', p_evidence_class;
    END IF;
    
    -- Validate project exists if provided
    IF p_project_id IS NOT NULL THEN
        PERFORM 1 FROM asset_batches 
        WHERE project_id = p_project_id 
        AND tenant_id = p_tenant_id
        AND asset_type = 'PROJECT';
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'GF005', 'Project not found or does not belong to tenant';
        END IF;
    END IF;
    
    -- Insert evidence node
    INSERT INTO evidence_nodes (
        tenant_id,
        project_id,
        evidence_class,
        document_type,
        file_hash_sha256,
        storage_reference,
        uploaded_by,
        uploaded_at,
        metadata_json
    ) VALUES (
        p_tenant_id,
        p_project_id,
        p_evidence_class,
        p_document_type,
        p_file_hash_sha256,
        p_storage_reference,
        p_uploaded_by,
        now(),
        p_metadata_json
    ) RETURNING evidence_node_id INTO v_evidence_node_id;
    
    RETURN v_evidence_node_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to link evidence to a governed record
CREATE OR REPLACE FUNCTION link_evidence_to_record(
    p_tenant_id UUID,
    p_evidence_node_id UUID,
    p_target_record_type TEXT,
    p_target_record_id UUID,
    p_edge_type TEXT,
    p_created_by TEXT DEFAULT current_user
)
RETURNS UUID AS $$
DECLARE
    v_evidence_edge_id UUID;
    v_node_exists BOOLEAN;
    v_node_tenant_id UUID;
    v_valid_edge_type BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Tenant ID is required';
    END IF;
    
    IF p_evidence_node_id IS NULL THEN
        RAISE EXCEPTION 'GF006', 'Evidence node ID is required';
    END IF;
    
    IF p_target_record_type IS NULL OR trim(p_target_record_type) = '' THEN
        RAISE EXCEPTION 'GF007', 'Target record type is required';
    END IF;
    
    IF p_target_record_id IS NULL THEN
        RAISE EXCEPTION 'GF008', 'Target record ID is required';
    END IF;
    
    IF p_edge_type IS NULL OR trim(p_edge_type) = '' THEN
        RAISE EXCEPTION 'GF009', 'Edge type is required';
    END IF;
    
    -- Validate edge type against allowed values
    IF p_edge_type IN (
        'SUPPORTS',
        'REFUTES',
        'DOCUMENTS',
        'VALIDATES',
        'ATTESTS_TO',
        'DERIVED_FROM',
        'CORROBORATES'
    ) THEN
        v_valid_edge_type := true;
    ELSE
        v_valid_edge_type := false;
    END IF;
    
    IF NOT v_valid_edge_type THEN
        RAISE EXCEPTION 'GF010', 'Invalid edge type: %', p_edge_type;
    END IF;
    
    -- Check if evidence node exists and get its tenant
    SELECT tenant_id INTO v_node_tenant_id
    FROM evidence_nodes
    WHERE evidence_node_id = p_evidence_node_id;
    
    IF v_node_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF011', 'Evidence node not found';
    END IF;
    
    -- Enforce tenant isolation
    IF v_node_tenant_id != p_tenant_id THEN
        RAISE EXCEPTION 'GF012', 'Cross-tenant evidence linkage not allowed';
    END IF;
    
    -- Validate target record exists based on type
    CASE p_target_record_type
        WHEN 'PROJECT' THEN
            PERFORM 1 FROM asset_batches 
            WHERE project_id = p_target_record_id 
            AND tenant_id = p_tenant_id
            AND asset_type = 'PROJECT';
            IF NOT FOUND THEN
                RAISE EXCEPTION 'GF013', 'Target project not found';
            END IF;
        WHEN 'MONITORING_RECORD' THEN
            PERFORM 1 FROM monitoring_records 
            WHERE monitoring_record_id = p_target_record_id 
            AND tenant_id = p_tenant_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'GF014', 'Target monitoring record not found';
            END IF;
        WHEN 'ASSET_BATCH' THEN
            PERFORM 1 FROM asset_batches 
            WHERE asset_batch_id = p_target_record_id 
            AND tenant_id = p_tenant_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'GF015', 'Target asset batch not found';
            END IF;
        WHEN 'EVIDENCE_NODE' THEN
            PERFORM 1 FROM evidence_nodes 
            WHERE evidence_node_id = p_target_record_id 
            AND tenant_id = p_tenant_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'GF016', 'Target evidence node not found';
            END IF;
        ELSE
            RAISE EXCEPTION 'GF017', 'Unsupported target record type: %', p_target_record_type;
    END CASE;
    
    -- Prevent self-loop (node linking to itself)
    IF p_target_record_type = 'EVIDENCE_NODE' AND p_target_record_id = p_evidence_node_id THEN
        RAISE EXCEPTION 'GF018', 'Self-loop not allowed in evidence lineage';
    END IF;
    
    -- Insert evidence edge
    INSERT INTO evidence_edges (
        source_node_id,
        target_node_id,
        edge_type,
        created_by,
        created_at
    ) VALUES (
        p_evidence_node_id,
        p_target_record_id,
        p_edge_type,
        p_created_by,
        now()
    ) RETURNING evidence_edge_id INTO v_evidence_edge_id;
    
    RETURN v_evidence_edge_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query evidence lineage
CREATE OR REPLACE FUNCTION query_evidence_lineage(
    p_tenant_id UUID,
    p_source_node_id UUID DEFAULT NULL,
    p_target_record_id UUID DEFAULT NULL,
    p_record_type TEXT DEFAULT NULL,
    p_edge_type_filter TEXT DEFAULT NULL,
    p_evidence_class_filter TEXT DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    evidence_edge_id UUID,
    source_node_id UUID,
    target_node_id UUID,
    edge_type TEXT,
    created_at TIMESTAMPTZ,
    created_by TEXT,
    source_evidence_class TEXT,
    source_document_type TEXT,
    source_uploaded_at TIMESTAMPTZ,
    source_uploaded_by TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ee.evidence_edge_id,
        ee.source_node_id,
        ee.target_node_id,
        ee.edge_type,
        ee.created_at,
        ee.created_by,
        en_source.evidence_class as source_evidence_class,
        en_source.document_type as source_document_type,
        en_source.uploaded_at as source_uploaded_at,
        en_source.uploaded_by as source_uploaded_by
    FROM evidence_edges ee
    JOIN evidence_nodes en_source ON ee.source_node_id = en_source.evidence_node_id
    WHERE en_source.tenant_id = p_tenant_id
    AND (p_source_node_id IS NULL OR ee.source_node_id = p_source_node_id)
    AND (p_target_record_id IS NULL OR ee.target_node_id = p_target_record_id)
    AND (p_edge_type_filter IS NULL OR ee.edge_type = p_edge_type_filter)
    AND (p_evidence_class_filter IS NULL OR en_source.evidence_class = p_evidence_class_filter)
    ORDER BY ee.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to get evidence node details
CREATE OR REPLACE FUNCTION get_evidence_node(
    p_tenant_id UUID,
    p_evidence_node_id UUID
)
RETURNS TABLE (
    evidence_node_id UUID,
    tenant_id UUID,
    project_id UUID,
    evidence_class TEXT,
    document_type TEXT,
    file_hash_sha256 TEXT,
    storage_reference TEXT,
    uploaded_by TEXT,
    uploaded_at TIMESTAMPTZ,
    metadata_json JSONB
) AS $$
DECLARE
    v_node_exists BOOLEAN;
BEGIN
    -- Check if node exists and belongs to tenant
    SELECT EXISTS (
        SELECT 1 FROM evidence_nodes
        WHERE evidence_node_id = p_evidence_node_id
        AND tenant_id = p_tenant_id
    ) INTO v_node_exists;
    
    IF NOT v_node_exists THEN
        RAISE EXCEPTION 'GF019', 'Evidence node not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        en.evidence_node_id,
        en.tenant_id,
        en.project_id,
        en.evidence_class,
        en.document_type,
        en.file_hash_sha256,
        en.storage_reference,
        en.uploaded_by,
        en.uploaded_at,
        en.metadata_json
    FROM evidence_nodes en
    WHERE en.evidence_node_id = p_evidence_node_id
    AND en.tenant_id = p_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to list evidence by project
CREATE OR REPLACE FUNCTION list_project_evidence(
    p_tenant_id UUID,
    p_project_id UUID,
    p_evidence_class_filter TEXT DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    evidence_node_id UUID,
    evidence_class TEXT,
    document_type TEXT,
    file_hash_sha256 TEXT,
    uploaded_by TEXT,
    uploaded_at TIMESTAMPTZ,
    metadata_json JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        en.evidence_node_id,
        en.evidence_class,
        en.document_type,
        en.file_hash_sha256,
        en.uploaded_by,
        en.uploaded_at,
        en.metadata_json
    FROM evidence_nodes en
    WHERE en.tenant_id = p_tenant_id
    AND (p_project_id IS NULL OR en.project_id = p_project_id)
    AND (p_evidence_class_filter IS NULL OR en.evidence_class = p_evidence_class_filter)
    ORDER BY en.uploaded_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION attach_evidence TO authenticated_role;
GRANT EXECUTE ON FUNCTION attach_evidence TO system_role;
GRANT EXECUTE ON FUNCTION link_evidence_to_record TO authenticated_role;
GRANT EXECUTE ON FUNCTION link_evidence_to_record TO system_role;
GRANT EXECUTE ON FUNCTION query_evidence_lineage TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_evidence_lineage TO system_role;
GRANT EXECUTE ON FUNCTION get_evidence_node TO authenticated_role;
GRANT EXECUTE ON FUNCTION get_evidence_node TO system_role;
GRANT EXECUTE ON FUNCTION list_project_evidence TO authenticated_role;
GRANT EXECUTE ON FUNCTION list_project_evidence TO system_role;
