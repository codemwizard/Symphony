-- Migration 0113: GF Phase 1 — Confidence Enforcement Constraint
-- Implements database-level enforcement that prevents asset batch lifecycle
-- transitions to ISSUED status unless required confidence scores from
-- authority decisions meet the mathematical threshold (0.95 / 95%).
-- This is a fail-closed gate: missing authority decisions block issuance.
-- Depends on 0101 (asset_lifecycle_events, asset_batches),
-- 0110 (authority_decisions, attempt_lifecycle_transition).
-- Trigger: SECURITY DEFINER with hardened search_path per INV-008.

-- ── enforce_confidence_before_issuance trigger function ──────────────────────
-- Fires BEFORE INSERT on asset_lifecycle_events.
-- When event_type = 'STATUS_CHANGE' and event_payload_json->>'to_status' = 'ISSUED',
-- it validates that the aggregate confidence score for the batch from
-- authority_decisions meets the required threshold.
CREATE OR REPLACE FUNCTION public.enforce_confidence_before_issuance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_confidence_score  NUMERIC;
    v_required_threshold NUMERIC := 0.95;
    v_to_status         TEXT;
    v_from_status       TEXT;
    v_decision_count    INT;
    v_approved_count    INT;
BEGIN
    -- Only enforce on transitions TO 'ISSUED'
    v_to_status := NEW.event_payload_json->>'to_status';
    v_from_status := NEW.event_payload_json->>'from_status';

    IF v_to_status IS NULL OR v_to_status != 'ISSUED' THEN
        RETURN NEW;
    END IF;

    -- ── Count authority decisions for this batch ────────────────────────────
    -- A batch must have at least one APPROVED authority decision to be issued.
    SELECT COUNT(*),
           COUNT(*) FILTER (
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
           )
      INTO v_decision_count, v_approved_count
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id;

    -- ── Fail-closed: no decisions = no issuance ────────────────────────────
    IF v_decision_count = 0 THEN
        RAISE EXCEPTION 'CONF001: No authority decisions found for batch %. Issuance blocked (fail-closed).',
            NEW.asset_batch_id
            USING ERRCODE = 'GF020';
    END IF;

    IF v_approved_count = 0 THEN
        RAISE EXCEPTION 'CONF002: No APPROVED authority decisions for batch %. Issuance blocked.',
            NEW.asset_batch_id
            USING ERRCODE = 'GF021';
    END IF;

    -- ── Mathematical confidence validation ─────────────────────────────────
    -- Aggregate confidence from approved decisions. Each decision's
    -- confidence_score is stored in decision_payload_json.
    -- The confidence_score must be a value between 0 and 1.
    SELECT COALESCE(
               AVG(
                   (ad.decision_payload_json->>'confidence_score')::NUMERIC
               ),
               0
           )
      INTO v_confidence_score
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;

    -- ── Threshold enforcement ──────────────────────────────────────────────
    -- Mathematical gate: confidence_score < required_threshold => block
    IF v_confidence_score < v_required_threshold THEN
        RAISE EXCEPTION 'CONF003: Insufficient confidence for issuance. Required: %, Actual: %. Batch: %',
            v_required_threshold, v_confidence_score, NEW.asset_batch_id
            USING ERRCODE = 'GF022';
    END IF;

    RETURN NEW;
END;
$$;

-- ── Trigger on asset_lifecycle_events ────────────────────────────────────────
-- Fires BEFORE INSERT to gate new lifecycle events that transition to ISSUED.
DROP TRIGGER IF EXISTS asset_lifecycle_confidence_enforcement ON public.asset_lifecycle_events;
CREATE TRIGGER asset_lifecycle_confidence_enforcement
    BEFORE INSERT ON public.asset_lifecycle_events
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_confidence_before_issuance();

-- ── validate_confidence_score helper function ─────────────────────────────────
-- Utility function that can be called from application code to check
-- current confidence state before attempting issuance.
CREATE OR REPLACE FUNCTION public.validate_confidence_score(
    p_asset_batch_id UUID
)
RETURNS TABLE(
    confidence_score    NUMERIC,
    required_threshold  NUMERIC,
    decision_count      INT,
    approved_count      INT,
    is_sufficient       BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_confidence   NUMERIC;
    v_threshold    NUMERIC := 0.95;
    v_total        INT;
    v_approved     INT;
BEGIN
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF023';
    END IF;

    SELECT COUNT(*),
           COUNT(*) FILTER (
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
           )
      INTO v_total, v_approved
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id;

    SELECT COALESCE(
               AVG((ad.decision_payload_json->>'confidence_score')::NUMERIC),
               0
           )
      INTO v_confidence
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;

    RETURN QUERY SELECT v_confidence, v_threshold, v_total, v_approved,
                        (v_confidence >= v_threshold AND v_approved > 0);
END;
$$;

-- ── Privileges ───────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION enforce_confidence_before_issuance()
    TO symphony_command;
GRANT EXECUTE ON FUNCTION validate_confidence_score(UUID)
    TO symphony_command;
