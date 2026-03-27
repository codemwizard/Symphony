-- Migration 0091: Green Finance Phase 1 Functions - Regulatory Transitions
-- SECURITY DEFINER functions with hardened search_path

-- Create authority_decisions table (referenced by functions)
CREATE TABLE IF NOT EXISTS public.authority_decisions (
    -- Primary identifier
    decision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Authority and jurisdiction context
    regulatory_authority_id UUID NOT NULL REFERENCES public.regulatory_authorities(authority_id) ON DELETE RESTRICT,
    jurisdiction_code TEXT NOT NULL,
    
    -- Decision details
    decision_type TEXT NOT NULL,
    decision_outcome TEXT NOT NULL,
    decision_reason TEXT,
    
    -- Subject reference (what this decision applies to)
    subject_type TEXT NOT NULL CHECK (subject_type IN ('PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE')),
    subject_id UUID NOT NULL,
    
    -- Interpretation context for replayability
    interpretation_pack_id UUID NOT NULL REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT,
    
    -- Audit trail
    decision_maker TEXT NOT NULL DEFAULT current_user,
    decision_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    decision_document_reference TEXT,
    metadata_json JSONB DEFAULT '{}'
);

-- Indexes for authority_decisions
CREATE INDEX IF NOT EXISTS idx_authority_decisions_authority ON authority_decisions(regulatory_authority_id);
CREATE INDEX IF NOT EXISTS idx_authority_decisions_jurisdiction ON authority_decisions(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_authority_decisions_subject ON authority_decisions(subject_type, subject_id);
CREATE INDEX IF NOT EXISTS idx_authority_decisions_interpretation ON authority_decisions(interpretation_pack_id);
CREATE INDEX IF NOT EXISTS idx_authority_decisions_timestamp ON authority_decisions(decision_timestamp);
CREATE INDEX IF NOT EXISTS idx_authority_decisions_type ON authority_decisions(decision_type);

-- RLS for authority_decisions (canonical jurisdiction pattern)
ALTER TABLE public.authority_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authority_decisions FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_authority_decisions ON public.authority_decisions
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- Append-only trigger for authority_decisions
CREATE OR REPLACE FUNCTION authority_decisions_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'authority_decisions is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER authority_decisions_append_only
    BEFORE UPDATE OR DELETE ON authority_decisions
    FOR EACH ROW
    EXECUTE FUNCTION authority_decisions_append_only_trigger();

-- Function to record authority decisions
CREATE OR REPLACE FUNCTION record_authority_decision(
    p_regulatory_authority_id UUID,
    p_jurisdiction_code TEXT,
    p_decision_type TEXT,
    p_decision_outcome TEXT,
    p_decision_reason TEXT DEFAULT NULL,
    p_subject_type TEXT,
    p_subject_id UUID,
    p_interpretation_pack_id UUID,
    p_decision_maker TEXT DEFAULT current_user,
    p_decision_document_reference TEXT DEFAULT NULL,
    p_metadata_json JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_decision_id UUID;
    v_authority_exists BOOLEAN;
    v_pack_exists BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_regulatory_authority_id IS NULL THEN
        RAISE EXCEPTION 'GF001', 'Regulatory authority ID is required';
    END IF;
    
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'GF002', 'Jurisdiction code is required';
    END IF;
    
    IF p_decision_type IS NULL OR trim(p_decision_type) = '' THEN
        RAISE EXCEPTION 'GF003', 'Decision type is required';
    END IF;
    
    IF p_decision_outcome IS NULL OR trim(p_decision_outcome) = '' THEN
        RAISE EXCEPTION 'GF004', 'Decision outcome is required';
    END IF;
    
    IF p_subject_type IS NULL OR trim(p_subject_type) = '' THEN
        RAISE EXCEPTION 'GF005', 'Subject type is required';
    END IF;
    
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'GF006', 'Subject ID is required';
    END IF;
    
    -- CRITICAL: interpretation_pack_id must NOT be NULL (INV-165 enforcement)
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'P0001', 'Interpretation pack ID is required for replayability';
    END IF;
    
    -- Validate subject_type
    IF p_subject_type NOT IN ('PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE') THEN
        RAISE EXCEPTION 'GF007', 'Invalid subject type: %', p_subject_type;
    END IF;
    
    -- Check if regulatory authority exists
    SELECT EXISTS (
        SELECT 1 FROM regulatory_authorities
        WHERE authority_id = p_regulatory_authority_id
        AND jurisdiction_code = p_jurisdiction_code
    ) INTO v_authority_exists;
    
    IF NOT v_authority_exists THEN
        RAISE EXCEPTION 'GF008', 'Regulatory authority not found in jurisdiction';
    END IF;
    
    -- Check if interpretation pack exists
    SELECT EXISTS (
        SELECT 1 FROM interpretation_packs
        WHERE interpretation_pack_id = p_interpretation_pack_id
        AND jurisdiction_code = p_jurisdiction_code
        AND effective_to IS NULL
    ) INTO v_pack_exists;
    
    IF NOT v_pack_exists THEN
        RAISE EXCEPTION 'GF009', 'Interpretation pack not found or inactive';
    END IF;
    
    -- Insert authority decision
    INSERT INTO authority_decisions (
        regulatory_authority_id,
        jurisdiction_code,
        decision_type,
        decision_outcome,
        decision_reason,
        subject_type,
        subject_id,
        interpretation_pack_id,
        decision_maker,
        decision_document_reference,
        metadata_json
    ) VALUES (
        p_regulatory_authority_id,
        p_jurisdiction_code,
        p_decision_type,
        p_decision_outcome,
        p_decision_reason,
        p_subject_type,
        p_subject_id,
        p_interpretation_pack_id,
        p_decision_maker,
        p_decision_document_reference,
        p_metadata_json
    ) RETURNING decision_id INTO v_decision_id;
    
    RETURN v_decision_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to attempt lifecycle transitions with checkpoint validation
CREATE OR REPLACE FUNCTION attempt_lifecycle_transition(
    p_subject_id UUID,
    p_subject_type TEXT,
    p_from_status TEXT,
    p_to_status TEXT,
    p_interpretation_pack_id UUID,
    p_performed_by TEXT DEFAULT current_user,
    p_transition_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_pack_exists BOOLEAN;
    v_pack_confidence TEXT;
    v_checkpoint_record RECORD;
    v_unsatisfied_checkpoints TEXT[];
    v_checkpoint_satisfaction_state TEXT;
    v_provisional_reason TEXT;
BEGIN
    -- Validate inputs
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'GF010', 'Subject ID is required';
    END IF;
    
    IF p_subject_type IS NULL OR trim(p_subject_type) = '' THEN
        RAISE EXCEPTION 'GF011', 'Subject type is required';
    END IF;
    
    IF p_from_status IS NULL OR trim(p_from_status) = '' THEN
        RAISE EXCEPTION 'GF012', 'From status is required';
    END IF;
    
    IF p_to_status IS NULL OR trim(p_to_status) = '' THEN
        RAISE EXCEPTION 'GF013', 'To status is required';
    END IF;
    
    -- CRITICAL: interpretation_pack_id must NOT be NULL (INV-165 enforcement)
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'P0001', 'Interpretation pack ID is required for replayability';
    END IF;
    
    -- Validate subject_type
    IF p_subject_type NOT IN ('PROJECT', 'ASSET_BATCH') THEN
        RAISE EXCEPTION 'GF014', 'Invalid subject type for lifecycle transition: %', p_subject_type;
    END IF;
    
    -- Check if interpretation pack exists and get confidence level
    SELECT EXISTS (
        SELECT 1 FROM interpretation_packs
        WHERE interpretation_pack_id = p_interpretation_pack_id
        AND effective_to IS NULL
    ), confidence_level INTO v_pack_exists, v_pack_confidence
    FROM interpretation_packs
    WHERE interpretation_pack_id = p_interpretation_pack_id
    AND effective_to IS NULL;
    
    IF NOT v_pack_exists THEN
        RAISE EXCEPTION 'GF015', 'Interpretation pack not found or inactive';
    END IF;
    
    -- Check checkpoint requirements for this transition
    v_unsatisfied_checkpoints := ARRAY[]::TEXT[];
    v_checkpoint_satisfaction_state := 'SATISFIED';
    v_provisional_reason := NULL;
    
    -- Query lifecycle checkpoint rules for this transition
    FOR v_checkpoint_record IN 
        SELECT lcp.checkpoint_id, lcp.checkpoint_type, lcp.rule_status
        FROM lifecycle_checkpoint_rules lcr
        JOIN regulatory_checkpoints lcp ON lcr.checkpoint_id = lcp.checkpoint_id
        WHERE lcr.lifecycle_transition = p_from_status || '->' || p_to_status
        AND lcr.rule_status = 'REQUIRED'
        AND lcr.effective_from <= CURRENT_DATE
        AND (lcr.effective_to IS NULL OR lcr.effective_to > CURRENT_DATE)
    LOOP
        -- Check if checkpoint is satisfied (would query checkpoint_satisfaction_records in real implementation)
        -- For now, we'll assume unsatisfied for REQUIRED checkpoints
        v_unsatisfied_checkpoints := array_append(v_unsatisfied_checkpoints, v_checkpoint_record.checkpoint_type);
    END LOOP;
    
    -- Check CONDITIONALLY_REQUIRED checkpoints
    FOR v_checkpoint_record IN 
        SELECT lcp.checkpoint_id, lcp.checkpoint_type, lcr.rule_status
        FROM lifecycle_checkpoint_rules lcr
        JOIN regulatory_checkpoints lcp ON lcr.checkpoint_id = lcp.checkpoint_id
        WHERE lcr.lifecycle_transition = p_from_status || '->' || p_to_status
        AND lcr.rule_status = 'CONDITIONALLY_REQUIRED'
        AND lcr.effective_from <= CURRENT_DATE
        AND (lcr.effective_to IS NULL OR lcr.effective_to > CURRENT_DATE)
    LOOP
        -- If interpretation pack has PENDING_CLARIFICATION, allow provisional pass
        IF v_pack_confidence = 'PENDING_CLARIFICATION' THEN
            v_checkpoint_satisfaction_state := 'CONDITIONALLY_SATISFIED';
            v_provisional_reason := 'PENDING_CLARIFICATION';
        ELSE
            v_unsatisfied_checkpoints := array_append(v_unsatisfied_checkpoints, v_checkpoint_record.checkpoint_type);
        END IF;
    END LOOP;
    
    -- Fail if REQUIRED checkpoints are unsatisfied
    IF array_length(v_unsatisfied_checkpoints, 1) > 0 THEN
        RAISE EXCEPTION 'GF016', 'Transition blocked by unsatisfied checkpoints: %', array_to_string(v_unsatisfied_checkpoints, ', ');
    END IF;
    
    -- Perform the lifecycle transition using existing function
    PERFORM transition_asset_status(
        p_subject_id,
        p_from_status,
        p_to_status,
        p_transition_reason,
        jsonb_build_object(
            'performed_by', p_performed_by,
            'interpretation_pack_id', p_interpretation_pack_id,
            'checkpoint_satisfaction_state', v_checkpoint_satisfaction_state,
            'provisional_reason', v_provisional_reason
        )
    );
    
    -- Get the event_id from the lifecycle event (would be returned by transition function in real implementation)
    SELECT asset_lifecycle_event_id INTO v_event_id
    FROM asset_lifecycle_events
    WHERE asset_batch_id = p_subject_id
    AND from_status = p_from_status
    AND to_status = p_to_status
    ORDER BY occurred_at DESC
    LIMIT 1;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to query authority decisions
CREATE OR REPLACE FUNCTION query_authority_decisions(
    p_jurisdiction_code TEXT DEFAULT NULL,
    p_regulatory_authority_id UUID DEFAULT NULL,
    p_subject_type TEXT DEFAULT NULL,
    p_subject_id UUID DEFAULT NULL,
    p_decision_type TEXT DEFAULT NULL,
    p_interpretation_pack_id UUID DEFAULT NULL,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    decision_id UUID,
    regulatory_authority_id UUID,
    jurisdiction_code TEXT,
    decision_type TEXT,
    decision_outcome TEXT,
    decision_reason TEXT,
    subject_type TEXT,
    subject_id UUID,
    interpretation_pack_id UUID,
    decision_maker TEXT,
    decision_timestamp TIMESTAMPTZ,
    decision_document_reference TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ad.decision_id,
        ad.regulatory_authority_id,
        ad.jurisdiction_code,
        ad.decision_type,
        ad.decision_outcome,
        ad.decision_reason,
        ad.subject_type,
        ad.subject_id,
        ad.interpretation_pack_id,
        ad.decision_maker,
        ad.decision_timestamp,
        ad.decision_document_reference
    FROM authority_decisions ad
    WHERE (p_jurisdiction_code IS NULL OR ad.jurisdiction_code = p_jurisdiction_code)
    AND (p_regulatory_authority_id IS NULL OR ad.regulatory_authority_id = p_regulatory_authority_id)
    AND (p_subject_type IS NULL OR ad.subject_type = p_subject_type)
    AND (p_subject_id IS NULL OR ad.subject_id = p_subject_id)
    AND (p_decision_type IS NULL OR ad.decision_type = p_decision_type)
    AND (p_interpretation_pack_id IS NULL OR ad.interpretation_pack_id = p_interpretation_pack_id)
    ORDER BY ad.decision_timestamp DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to get checkpoint requirements for a transition
CREATE OR REPLACE FUNCTION get_checkpoint_requirements(
    p_from_status TEXT,
    p_to_status TEXT,
    p_jurisdiction_code TEXT DEFAULT NULL
)
RETURNS TABLE (
    checkpoint_id UUID,
    checkpoint_type TEXT,
    rule_status TEXT,
    is_satisfied BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lcp.checkpoint_id,
        lcp.checkpoint_type,
        lcr.rule_status,
        false as is_satisfied  -- Would be determined by querying satisfaction records
    FROM lifecycle_checkpoint_rules lcr
    JOIN regulatory_checkpoints lcp ON lcr.checkpoint_id = lcp.checkpoint_id
    WHERE lcr.lifecycle_transition = p_from_status || '->' || p_to_status
    AND (p_jurisdiction_code IS NULL OR lcr.jurisdiction_code = p_jurisdiction_code)
    AND lcr.effective_from <= CURRENT_DATE
    AND (lcr.effective_to IS NULL OR lcr.effective_to > CURRENT_DATE)
    ORDER BY lcr.rule_status DESC, lcp.checkpoint_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke-first privilege posture
REVOKE ALL ON TABLE authority_decisions FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE authority_decisions TO authenticated_role;
GRANT ALL ON TABLE authority_decisions TO system_role;
GRANT EXECUTE ON FUNCTION record_authority_decision TO authenticated_role;
GRANT EXECUTE ON FUNCTION record_authority_decision TO system_role;
GRANT EXECUTE ON FUNCTION attempt_lifecycle_transition TO authenticated_role;
GRANT EXECUTE ON FUNCTION attempt_lifecycle_transition TO system_role;
GRANT EXECUTE ON FUNCTION query_authority_decisions TO authenticated_role;
GRANT EXECUTE ON FUNCTION query_authority_decisions TO system_role;
GRANT EXECUTE ON FUNCTION get_checkpoint_requirements TO authenticated_role;
GRANT EXECUTE ON FUNCTION get_checkpoint_requirements TO system_role;
