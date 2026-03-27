-- Migration 0092: Green Finance Phase 1 Functions - Asset Lifecycle
-- SECURITY DEFINER functions with hardened search_path

-- Function to issue asset batches
CREATE OR REPLACE FUNCTION issue_asset_batch(
    p_project_id UUID,
    p_methodology_version_id UUID,
    p_adapter_registration_id UUID,
    p_asset_type TEXT,
    p_quantity BIGINT,
    p_unit TEXT,
    p_interpretation_pack_id UUID,
    p_vintage_start DATE DEFAULT CURRENT_DATE,
    p_vintage_end DATE DEFAULT NULL,
    p_issued_by TEXT DEFAULT current_user,
    p_metadata_json JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_asset_batch_id UUID;
    v_project_exists BOOLEAN;
    v_project_active BOOLEAN;
    v_adapter_exists BOOLEAN;
    v_pack_exists BOOLEAN;
    v_pack_confidence TEXT;
    v_checkpoint_record RECORD;
    v_unsatisfied_checkpoints TEXT[];
BEGIN
    -- Validate inputs
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Project ID is required';
    END IF;
    
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'GF002', 'Methodology version ID is required';
    END IF;
    
    IF p_adapter_registration_id IS NULL THEN
        RAISE EXCEPTION 'GF003', 'Adapter registration ID is required';
    END IF;
    
    IF p_asset_type IS NULL OR trim(p_asset_type) = '' THEN
        RAISE EXCEPTION 'GF004', 'Asset type is required';
    END IF;
    
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'GF005', 'Quantity must be positive';
    END IF;
    
    IF p_unit IS NULL OR trim(p_unit) = '' THEN
        RAISE EXCEPTION 'GF006', 'Unit is required';
    END IF;
    
    -- CRITICAL: interpretation_pack_id must NOT be NULL (INV-165 enforcement)
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'P0001', 'Interpretation pack ID is required for replayability';
    END IF;
    
    -- Check if project exists and is ACTIVE
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND status = 'ACTIVE'
        AND asset_type = 'PROJECT'
    ), EXISTS (
        SELECT 1 FROM asset_batches
        WHERE project_id = p_project_id
        AND status = 'ACTIVE'
        AND asset_type = 'PROJECT'
    ) INTO v_project_exists, v_project_active;
    
    IF NOT v_project_exists THEN
        RAISE EXCEPTION 'GF007', 'Project not found';
    END IF;
    
    IF NOT v_project_active THEN
        RAISE EXCEPTION 'GF008', 'Project must be ACTIVE to issue assets';
    END IF;
    
    -- Check if adapter exists and is active
    SELECT EXISTS (
        SELECT 1 FROM adapter_registrations
        WHERE adapter_registration_id = p_adapter_registration_id
        AND is_active = true
    ) INTO v_adapter_exists;
    
    IF NOT v_adapter_exists THEN
        RAISE EXCEPTION 'GF009', 'Adapter not found or inactive';
    END IF;
    
    -- Check interpretation pack exists and get confidence level
    SELECT EXISTS (
        SELECT 1 FROM interpretation_packs
        WHERE interpretation_pack_id = p_interpretation_pack_id
        AND effective_to IS NULL
    ), confidence_level INTO v_pack_exists, v_pack_confidence
    FROM interpretation_packs
    WHERE interpretation_pack_id = p_interpretation_pack_id
    AND effective_to IS NULL;
    
    IF NOT v_pack_exists THEN
        RAISE EXCEPTION 'GF010', 'Interpretation pack not found or inactive';
    END IF;
    
    -- Check checkpoint requirements for ACTIVE->ISSUED transition (fail-closed)
    v_unsatisfied_checkpoints := ARRAY[]::TEXT[];
    
    -- Query REQUIRED lifecycle checkpoint rules for issuance
    FOR v_checkpoint_record IN
        SELECT rc.checkpoint_id, rc.checkpoint_type, lcr.rule_status
        FROM lifecycle_checkpoint_rules lcr
        JOIN regulatory_checkpoints rc ON lcr.checkpoint_id = rc.checkpoint_id
        WHERE lcr.lifecycle_transition = 'ACTIVE->ISSUED'
        AND lcr.rule_status = 'REQUIRED'
        AND lcr.effective_from <= CURRENT_DATE
        AND (lcr.effective_to IS NULL OR lcr.effective_to > CURRENT_DATE)
    LOOP
        -- Fail-closed: REQUIRED checkpoints are unsatisfied until
        -- checkpoint_satisfaction_records lookup is implemented (FNC-007)
        v_unsatisfied_checkpoints := array_append(v_unsatisfied_checkpoints, v_checkpoint_record.checkpoint_type);
    END LOOP;
    
    -- Check CONDITIONALLY_REQUIRED checkpoints
    FOR v_checkpoint_record IN
        SELECT rc.checkpoint_id, rc.checkpoint_type, lcr.rule_status
        FROM lifecycle_checkpoint_rules lcr
        JOIN regulatory_checkpoints rc ON lcr.checkpoint_id = rc.checkpoint_id
        WHERE lcr.lifecycle_transition = 'ACTIVE->ISSUED'
        AND lcr.rule_status = 'CONDITIONALLY_REQUIRED'
        AND lcr.effective_from <= CURRENT_DATE
        AND (lcr.effective_to IS NULL OR lcr.effective_to > CURRENT_DATE)
    LOOP
        -- If interpretation pack has PENDING_CLARIFICATION, block issuance
        IF v_pack_confidence = 'PENDING_CLARIFICATION' THEN
            v_unsatisfied_checkpoints := array_append(v_unsatisfied_checkpoints, v_checkpoint_record.checkpoint_type);
        END IF;
    END LOOP;
    
    -- Block if any required checkpoints are unsatisfied
    IF array_length(v_unsatisfied_checkpoints, 1) > 0 THEN
        RAISE EXCEPTION 'GF010', 'Cannot issue: unsatisfied checkpoints: %', array_to_string(v_unsatisfied_checkpoints, ', ');
    END IF;
    
    -- Insert asset batch with ISSUED status
    INSERT INTO asset_batches (
        project_id,
        methodology_version_id,
        adapter_registration_id,
        asset_type,
        vintage_start,
        vintage_end,
        issuable_quantity,
        unit,
        status,
        issued_at,
        metadata_json
    ) VALUES (
        p_project_id,
        p_methodology_version_id,
        p_adapter_registration_id,
        p_asset_type,
        p_vintage_start,
        p_vintage_end,
        p_quantity,
        p_unit,
        'ISSUED',
        now(),
        p_metadata_json
    ) RETURNING asset_batch_id INTO v_asset_batch_id;
    
    -- Record lifecycle event
    PERFORM record_asset_lifecycle_event(
        v_asset_batch_id,
        'ACTIVE',
        'ISSUED',
        'Asset issuance',
        jsonb_build_object(
            'issued_by', p_issued_by,
            'interpretation_pack_id', p_interpretation_pack_id,
            'interpretation_pack_confidence', v_pack_confidence
        )
    );
    
    RETURN v_asset_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to retire asset batches
CREATE OR REPLACE FUNCTION retire_asset_batch(
    p_asset_batch_id UUID,
    p_quantity BIGINT,
    p_retirement_reason TEXT,
    p_interpretation_pack_id UUID,
    p_retired_by TEXT DEFAULT current_user,
    p_claim_reference TEXT DEFAULT NULL,
    p_certificate_reference TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_retirement_event_id UUID;
    v_asset_exists BOOLEAN;
    v_asset_status TEXT;
    v_issuable_quantity BIGINT;
    v_total_retired BIGINT;
    v_remaining_quantity BIGINT;
    v_tenant_id UUID;
BEGIN
    -- Validate inputs
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'GF011', 'Asset batch ID is required';
    END IF;
    
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'GF012', 'Retirement quantity must be positive';
    END IF;
    
    IF p_retirement_reason IS NULL OR trim(p_retirement_reason) = '' THEN
        RAISE EXCEPTION 'GF013', 'Retirement reason is required';
    END IF;
    
    -- CRITICAL: interpretation_pack_id must NOT be NULL (INV-165 enforcement)
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'P0001', 'Interpretation pack ID is required for replayability';
    END IF;
    
    -- Check if asset batch exists and get details
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE asset_batch_id = p_asset_batch_id
    ), status, issuable_quantity, tenant_id
    INTO v_asset_exists, v_asset_status, v_issuable_quantity, v_tenant_id
    FROM asset_batches
    WHERE asset_batch_id = p_asset_batch_id;
    
    IF NOT v_asset_exists THEN
        RAISE EXCEPTION 'GF014', 'Asset batch not found';
    END IF;
    
    -- Check if asset is in ISSUED status
    IF v_asset_status != 'ISSUED' THEN
        RAISE EXCEPTION 'GF015', 'Asset must be ISSUED to retire (current: %)', v_asset_status;
    END IF;
    
    -- Calculate total retired quantity
    SELECT COALESCE(SUM(retired_quantity), 0) INTO v_total_retired
    FROM retirement_events
    WHERE asset_batch_id = p_asset_batch_id;
    
    -- Calculate remaining quantity
    v_remaining_quantity := v_issuable_quantity - v_total_retired;
    
    -- Enforce quantity guard
    IF p_quantity > v_remaining_quantity THEN
        RAISE EXCEPTION 'GF016', 'Retirement quantity (%) exceeds remaining quantity (%)', p_quantity, v_remaining_quantity;
    END IF;
    
    -- Insert retirement event
    INSERT INTO retirement_events (
        tenant_id,
        asset_batch_id,
        claim_reference,
        retired_quantity,
        retirement_reason,
        certificate_reference,
        retired_at
    ) VALUES (
        v_tenant_id,
        p_asset_batch_id,
        p_claim_reference,
        p_quantity,
        p_retirement_reason,
        p_certificate_reference,
        now()
    ) RETURNING retirement_event_id INTO v_retirement_event_id;
    
    -- Update asset status if fully retired
    IF (v_total_retired + p_quantity) >= v_issuable_quantity THEN
        UPDATE asset_batches
        SET status = 'RETIRED'
        WHERE asset_batch_id = p_asset_batch_id;
        
        -- Record lifecycle event for status change
        PERFORM record_asset_lifecycle_event(
            p_asset_batch_id,
            'ISSUED',
            'RETIRED',
            'Asset fully retired',
            jsonb_build_object(
                'retired_by', p_retired_by,
                'interpretation_pack_id', p_interpretation_pack_id,
                'total_retired', v_total_retired + p_quantity,
                'retirement_event_id', v_retirement_event_id
            )
        );
    ELSE
        -- Record partial retirement event
        PERFORM record_asset_lifecycle_event(
            p_asset_batch_id,
            'ISSUED',
            'ISSUED',
            'Partial retirement',
            jsonb_build_object(
                'retired_by', p_retired_by,
                'interpretation_pack_id', p_interpretation_pack_id,
                'retired_quantity', p_quantity,
                'retirement_event_id', v_retirement_event_id,
                'remaining_quantity', v_remaining_quantity - p_quantity
            )
        );
    END IF;
    
    RETURN v_retirement_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Helper function to record asset lifecycle events
CREATE OR REPLACE FUNCTION record_asset_lifecycle_event(
    p_asset_batch_id UUID,
    p_from_status TEXT,
    p_to_status TEXT,
    p_event_reason TEXT,
    p_event_payload_json JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_asset_exists BOOLEAN;
BEGIN
    -- Check if asset batch exists
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE asset_batch_id = p_asset_batch_id
    ) INTO v_asset_exists;
    
    IF NOT v_asset_exists THEN
        RAISE EXCEPTION 'GF017', 'Asset batch not found';
    END IF;
    
    -- Insert lifecycle event
    INSERT INTO asset_lifecycle_events (
        asset_batch_id,
        from_status,
        to_status,
        event_reason,
        event_payload_json,
        performed_by,
        occurred_at
    ) VALUES (
        p_asset_batch_id,
        p_from_status,
        p_to_status,
        p_event_reason,
        p_event_payload_json,
        current_user,
        now()
    ) RETURNING asset_lifecycle_event_id INTO v_event_id;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query asset batch details
CREATE OR REPLACE FUNCTION query_asset_batch(
    p_asset_batch_id UUID
)
RETURNS TABLE (
    asset_batch_id UUID,
    project_id UUID,
    methodology_version_id UUID,
    adapter_registration_id UUID,
    asset_type TEXT,
    vintage_start DATE,
    vintage_end DATE,
    issuable_quantity BIGINT,
    unit TEXT,
    status TEXT,
    issued_at TIMESTAMPTZ,
    total_retired BIGINT,
    remaining_quantity BIGINT,
    metadata_json JSONB
) AS $$
DECLARE
    v_asset_exists BOOLEAN;
    v_total_retired BIGINT;
BEGIN
    -- Check if asset batch exists
    SELECT EXISTS (
        SELECT 1 FROM asset_batches
        WHERE asset_batch_id = p_asset_batch_id
    ) INTO v_asset_exists;
    
    IF NOT v_asset_exists THEN
        RAISE EXCEPTION 'GF018', 'Asset batch not found';
    END IF;
    
    -- Calculate total retired quantity
    SELECT COALESCE(SUM(retired_quantity), 0) INTO v_total_retired
    FROM retirement_events
    WHERE asset_batch_id = p_asset_batch_id;
    
    RETURN QUERY
    SELECT 
        ab.asset_batch_id,
        ab.project_id,
        ab.methodology_version_id,
        ab.adapter_registration_id,
        ab.asset_type,
        ab.vintage_start,
        ab.vintage_end,
        ab.issuable_quantity,
        ab.unit,
        ab.status,
        ab.issued_at,
        v_total_retired,
        ab.issuable_quantity - v_total_retired,
        ab.metadata_json
    FROM asset_batches ab
    WHERE ab.asset_batch_id = p_asset_batch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to list asset batches by project
CREATE OR REPLACE FUNCTION list_project_asset_batches(
    p_project_id UUID,
    p_status_filter TEXT DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    asset_batch_id UUID,
    asset_type TEXT,
    vintage_start DATE,
    issuable_quantity BIGINT,
    unit TEXT,
    status TEXT,
    issued_at TIMESTAMPTZ,
    total_retired BIGINT,
    remaining_quantity BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ab.asset_batch_id,
        ab.asset_type,
        ab.vintage_start,
        ab.issuable_quantity,
        ab.unit,
        ab.status,
        ab.issued_at,
        COALESCE(SUM(re.retired_quantity), 0) as total_retired,
        ab.issuable_quantity - COALESCE(SUM(re.retired_quantity), 0) as remaining_quantity
    FROM asset_batches ab
    LEFT JOIN retirement_events re ON ab.asset_batch_id = re.asset_batch_id
    WHERE ab.project_id = p_project_id
    AND (p_status_filter IS NULL OR ab.status = p_status_filter)
    GROUP BY ab.asset_batch_id, ab.asset_type, ab.vintage_start, ab.issuable_quantity, ab.unit, ab.status, ab.issued_at
    ORDER BY ab.issued_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION issue_asset_batch TO authenticated_role;
GRANT EXECUTE ON FUNCTION issue_asset_batch TO system_role;
GRANT EXECUTE ON FUNCTION retire_asset_batch TO authenticated_role;
GRANT EXECUTE ON FUNCTION retire_asset_batch TO system_role;
GRANT EXECUTE ON FUNCTION record_asset_lifecycle_event TO authenticated_role;
GRANT EXECUTE ON FUNCTION record_asset_lifecycle_event TO system_role;
GRANT EXECUTE ON FUNCTION query_asset_batch TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_asset_batch TO system_role;
GRANT EXECUTE ON FUNCTION list_project_asset_batches TO authenticated_role;
GRANT EXECUTE ON FUNCTION list_project_asset_batches TO system_role;
