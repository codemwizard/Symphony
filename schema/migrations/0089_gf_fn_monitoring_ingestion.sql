-- Migration 0089: Green Finance Phase 1 Function - Monitoring Record Ingestion
-- SECURITY DEFINER function with hardened search_path and strict payload neutrality

-- Function to record monitoring events with strict payload validation
CREATE OR REPLACE FUNCTION record_monitoring_record(
    p_tenant_id UUID,
    p_project_id UUID,
    p_methodology_version_id UUID,
    p_record_type TEXT,
    p_event_timestamp TIMESTAMPTZ,
    p_entry_timestamp TIMESTAMPTZ DEFAULT now(),
    p_entry_method TEXT DEFAULT 'SYSTEM',
    p_entry_operator_id TEXT DEFAULT NULL,
    p_source_reference TEXT DEFAULT NULL,
    p_record_payload_json JSONB,
    p_payload_schema_reference_id UUID DEFAULT NULL,
    p_instruction_id UUID DEFAULT NULL,
    p_correlation_id TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_monitoring_record_id UUID;
    v_project_exists BOOLEAN;
    v_project_active BOOLEAN;
    v_methodology_matches BOOLEAN;
    v_payload_schema_valid BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Tenant ID is required';
    END IF;
    
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'GF002', 'Project ID is required';
    END IF;
    
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'GF003', 'Methodology version ID is required';
    END IF;
    
    IF p_record_type IS NULL OR trim(p_record_type) = '' THEN
        RAISE EXCEPTION 'GF004', 'Record type is required';
    END IF;
    
    IF p_event_timestamp IS NULL THEN
        RAISE EXCEPTION 'GF005', 'Event timestamp is required';
    END IF;
    
    -- Payload validation - never reference specific field names
    IF p_record_payload_json IS NULL THEN
        RAISE EXCEPTION 'GF006', 'Record payload JSON is required';
    END IF;
    
    -- Check payload is a JSON object (never extract specific fields)
    IF jsonb_typeof(p_record_payload_json) != 'object' THEN
        RAISE EXCEPTION 'GF007', 'Record payload must be a JSON object';
    END IF;
    
    -- Schema reference validation (required for structured payloads)
    IF p_payload_schema_reference_id IS NULL THEN
        RAISE EXCEPTION 'GF008', 'Payload schema reference ID is required';
    END IF;
    
    -- Check if project exists and belongs to tenant
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND tenant_id = p_tenant_id
        AND asset_type = 'PROJECT'
    ) INTO v_project_exists;
    
    IF NOT v_project_exists THEN
        RAISE EXCEPTION 'GF009', 'Project not found or does not belong to tenant';
    END IF;
    
    -- Check if project is ACTIVE
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND tenant_id = p_tenant_id
        AND status = 'ACTIVE'
        AND asset_type = 'PROJECT'
    ) INTO v_project_active;
    
    IF NOT v_project_active THEN
        RAISE EXCEPTION 'GF010', 'Project must be ACTIVE to record monitoring events';
    END IF;
    
    -- Check if methodology version matches project
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND tenant_id = p_tenant_id
        AND methodology_version_id = p_methodology_version_id
        AND asset_type = 'PROJECT'
    ) INTO v_methodology_matches;
    
    IF NOT v_methodology_matches THEN
        RAISE EXCEPTION 'GF011', 'Methodology version does not match project';
    END IF;
    
    -- Validate schema reference exists (if provided)
    IF p_payload_schema_reference_id IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1 FROM schema_registry
            WHERE schema_id = p_payload_schema_reference_id
            AND is_active = true
        ) INTO v_payload_schema_valid;
        
        IF NOT v_payload_schema_valid THEN
            RAISE EXCEPTION 'GF012', 'Payload schema reference not found or inactive';
        END IF;
    END IF;
    
    -- Insert monitoring record
    INSERT INTO monitoring_records (
        tenant_id,
        project_id,
        methodology_version_id,
        record_type,
        event_timestamp,
        entry_timestamp,
        entry_method,
        entry_operator_id,
        source_reference,
        record_payload_json,
        payload_schema_reference_id,
        instruction_id,
        correlation_id
    ) VALUES (
        p_tenant_id,
        p_project_id,
        p_methodology_version_id,
        p_record_type,
        p_event_timestamp,
        p_entry_timestamp,
        p_entry_method,
        p_entry_operator_id,
        p_source_reference,
        p_record_payload_json,
        p_payload_schema_reference_id,
        p_instruction_id,
        p_correlation_id
    ) RETURNING monitoring_record_id INTO v_monitoring_record_id;
    
    RETURN v_monitoring_record_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query monitoring records with filtering
CREATE OR REPLACE FUNCTION query_monitoring_records(
    p_tenant_id UUID,
    p_project_id UUID DEFAULT NULL,
    p_record_type_filter TEXT DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    monitoring_record_id UUID,
    project_id UUID,
    methodology_version_id UUID,
    record_type TEXT,
    event_timestamp TIMESTAMPTZ,
    entry_timestamp TIMESTAMPTZ,
    entry_method TEXT,
    entry_operator_id TEXT,
    source_reference TEXT,
    payload_schema_reference_id UUID,
    instruction_id UUID,
    correlation_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mr.monitoring_record_id,
        mr.project_id,
        mr.methodology_version_id,
        mr.record_type,
        mr.event_timestamp,
        mr.entry_timestamp,
        mr.entry_method,
        mr.entry_operator_id,
        mr.source_reference,
        mr.payload_schema_reference_id,
        mr.instruction_id,
        mr.correlation_id
    FROM monitoring_records mr
    WHERE mr.tenant_id = p_tenant_id
    AND (p_project_id IS NULL OR mr.project_id = p_project_id)
    AND (p_record_type_filter IS NULL OR mr.record_type = p_record_type_filter)
    AND (p_start_date IS NULL OR mr.event_timestamp >= p_start_date)
    AND (p_end_date IS NULL OR mr.event_timestamp <= p_end_date)
    ORDER BY mr.event_timestamp DESC, mr.entry_timestamp DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to get monitoring record with payload (for adapters)
CREATE OR REPLACE FUNCTION get_monitoring_record_payload(
    p_tenant_id UUID,
    p_monitoring_record_id UUID
)
RETURNS TABLE (
    monitoring_record_id UUID,
    project_id UUID,
    methodology_version_id UUID,
    record_type TEXT,
    event_timestamp TIMESTAMPTZ,
    record_payload_json JSONB,
    payload_schema_reference_id UUID
) AS $$
DECLARE
    v_record_exists BOOLEAN;
BEGIN
    -- Check if record exists and belongs to tenant
    SELECT EXISTS (
        SELECT 1 FROM monitoring_records
        WHERE monitoring_record_id = p_monitoring_record_id
        AND tenant_id = p_tenant_id
    ) INTO v_record_exists;
    
    IF NOT v_record_exists THEN
        RAISE EXCEPTION 'GF013', 'Monitoring record not found';
    END IF;
    
    RETURN QUERY
    SELECT 
        mr.monitoring_record_id,
        mr.project_id,
        mr.methodology_version_id,
        mr.record_type,
        mr.event_timestamp,
        mr.record_payload_json,
        mr.payload_schema_reference_id
    FROM monitoring_records mr
    WHERE mr.monitoring_record_id = p_monitoring_record_id
    AND mr.tenant_id = p_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to validate payload against schema (adapter callable)
CREATE OR REPLACE FUNCTION validate_payload_against_schema(
    p_payload_json JSONB,
    p_schema_reference_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_schema_exists BOOLEAN;
    v_validation_result BOOLEAN DEFAULT true;
BEGIN
    -- Check if schema exists
    SELECT EXISTS (
        SELECT 1 FROM schema_registry
        WHERE schema_id = p_schema_reference_id
        AND is_active = true
    ) INTO v_schema_exists;
    
    IF NOT v_schema_exists THEN
        RAISE EXCEPTION 'GF014', 'Schema reference not found or inactive';
    END IF;
    
    -- Note: Actual schema validation would be handled by adapter layer
    -- This function only validates the schema reference exists
    -- The adapter would implement the specific validation logic
    
    RETURN v_validation_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION record_monitoring_record TO authenticated_role;
GRANT EXECUTE ON FUNCTION record_monitoring_record TO system_role;
GRANT EXECUTE ON FUNCTION query_monitoring_records TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_monitoring_records TO system_role;
GRANT EXECUTE ON FUNCTION get_monitoring_record_payload TO authenticated_role;
GRANT EXECUTE ON FUNCTION get_monitoring_record_payload TO system_role;
GRANT EXECUTE ON FUNCTION validate_payload_against_schema TO authenticated_role;
GRANT EXECUTE ON FUNCTION validate_payload_against_schema TO system_role;
