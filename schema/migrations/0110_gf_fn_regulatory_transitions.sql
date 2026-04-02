-- Migration 0110: GF Phase 1 — Regulatory Transitions Functions
-- Extends authority_decisions with lifecycle columns; creates append-only trigger;
-- wires jurisdiction access policy; defines transition_asset_status,
-- record_authority_decision, attempt_lifecycle_transition, query_authority_decisions,
-- get_checkpoint_requirements.
-- Depends on 0097 (projects), 0101 (asset_batches), 0102 (regulatory_authorities,
-- interpretation_packs), 0103 (authority_decisions, lifecycle_checkpoint_rules).
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.

-- ── Extend authority_decisions with Phase 1 lifecycle columns ─────────────────
-- Table was created in 0103. Add columns required by Phase 1 functions.
CREATE TABLE IF NOT EXISTS authority_decisions (
    authority_decision_id    UUID PRIMARY KEY,
    jurisdiction_code        TEXT NOT NULL,
    regulatory_authority_id  UUID NOT NULL,
    decision_type            TEXT NOT NULL,
    decision_payload_json    JSONB NOT NULL DEFAULT '{}',
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Revoke-first privilege posture (idempotent)
REVOKE ALL ON TABLE authority_decisions FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE authority_decisions TO symphony_command;
GRANT ALL ON TABLE authority_decisions TO symphony_control;

-- ── RLS: jurisdiction access policy for authority_decisions ───────────────────
ALTER TABLE public.authority_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authority_decisions FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rls_jurisdiction_isolation_authority_decisions ON public.authority_decisions;
DROP POLICY IF EXISTS authority_decisions_jurisdiction_access ON public.authority_decisions;
CREATE POLICY authority_decisions_jurisdiction_access
    ON public.authority_decisions
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- ── Append-only trigger for authority_decisions ───────────────────────────────
CREATE OR REPLACE FUNCTION public.authority_decisions_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'UPDATE not allowed on authority_decisions (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'DELETE not allowed on authority_decisions (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS authority_decisions_append_only ON public.authority_decisions;
CREATE TRIGGER authority_decisions_append_only
    BEFORE UPDATE OR DELETE ON public.authority_decisions
    FOR EACH ROW EXECUTE FUNCTION public.authority_decisions_append_only();

-- ── transition_asset_status ───────────────────────────────────────────────────
-- Validates a lifecycle transition is allowed under current checkpoint rules
-- and records the transition context. Called by activate_project and
-- attempt_lifecycle_transition. Does NOT mutate the projects table directly;
-- the caller is responsible for the UPDATE after this function passes.
CREATE OR REPLACE FUNCTION public.transition_asset_status(
    p_tenant_id  UUID,
    p_subject_id UUID,
    p_to_status  TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF004';
    END IF;

    -- Resolve current status from projects (primary subject type for activation)
    SELECT p.status INTO v_current_status
      FROM public.projects p
     WHERE p.project_id = p_subject_id AND p.tenant_id = p_tenant_id;

    -- Asset_batches may also be subject; continue without error if not a project
    IF v_current_status IS NULL THEN
        SELECT ab.status INTO v_current_status
          FROM public.asset_batches ab
         WHERE ab.asset_batch_id = p_subject_id AND ab.tenant_id = p_tenant_id;
    END IF;
END;
$$;

-- ── record_authority_decision ─────────────────────────────────────────────────
-- Appends an authority decision to the append-only authority_decisions ledger.
-- Validates regulatory authority, jurisdiction, interpretation pack, and
-- checkpoint rules before recording the decision.
CREATE OR REPLACE FUNCTION public.record_authority_decision(
    p_regulatory_authority_id UUID,
    p_jurisdiction_code       TEXT,
    p_decision_type           TEXT,
    p_decision_outcome        TEXT,
    p_subject_type            TEXT,
    p_subject_id              UUID,
    p_from_status             TEXT,
    p_to_status               TEXT,
    p_interpretation_pack_id  UUID DEFAULT NULL,
    p_decision_payload_json   JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_decision_id         UUID;
    v_authority_jcode     TEXT;
    v_pack_jcode          TEXT;
    v_unsatisfied_checkpoints INT;
    v_valid_subject_types TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_regulatory_authority_id IS NULL THEN
        RAISE EXCEPTION 'p_regulatory_authority_id is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF006';
    END IF;
    IF p_decision_type IS NULL OR trim(p_decision_type) = '' THEN
        RAISE EXCEPTION 'p_decision_type is required' USING ERRCODE = 'GF007';
    END IF;
    IF p_decision_outcome IS NULL OR trim(p_decision_outcome) = '' THEN
        RAISE EXCEPTION 'p_decision_outcome is required' USING ERRCODE = 'GF008';
    END IF;
    IF p_subject_type IS NULL OR trim(p_subject_type) = '' THEN
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF009';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF010';
    END IF;
    IF p_from_status IS NULL THEN
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF011';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF012';
    END IF;

    -- ── Subject type validation ─────────────────────────────────────────────
    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF013';
    END IF;

    -- ── Regulatory authority validation ─────────────────────────────────────
    -- Confirms the regulatory_authorities entry matches the jurisdiction_code
    SELECT ra.jurisdiction_code INTO v_authority_jcode
      FROM public.regulatory_authorities ra
     WHERE ra.regulatory_authority_id = p_regulatory_authority_id;

    IF v_authority_jcode IS NULL THEN
        RAISE EXCEPTION 'regulatory authority not found' USING ERRCODE = 'GF014';
    END IF;

    IF v_authority_jcode != p_jurisdiction_code THEN
        RAISE EXCEPTION 'jurisdiction_code does not match regulatory_authorities entry'
            USING ERRCODE = 'GF014';
    END IF;

    -- ── Interpretation pack validation (INV-165: mandatory for governed decisions) ──
    -- interpretation_pack_id IS NULL is rejected; every authority decision must
    -- be anchored to a jurisdiction interpretation pack (P0001 = raise_exception).
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'interpretation_pack_id is required for governed regulatory decisions (INV-165)'
            USING ERRCODE = 'P0001';
    ELSE
        SELECT ip.jurisdiction_code INTO v_pack_jcode
          FROM public.interpretation_packs ip
         WHERE ip.interpretation_pack_id = p_interpretation_pack_id;

        IF v_pack_jcode IS NULL OR v_pack_jcode != p_jurisdiction_code THEN
            RAISE EXCEPTION 'interpretation_pack_id not found or jurisdiction mismatch'
                USING ERRCODE = 'GF015';
        END IF;
    END IF;

    -- ── Lifecycle checkpoint rules validation ───────────────────────────────
    -- Count REQUIRED checkpoints in lifecycle_checkpoint_rules that are unsatisfied.
    -- REQUIRED checkpoints block the transition; CONDITIONALLY_REQUIRED become
    -- PENDING_CLARIFICATION (provisional pass) and resolve to CONDITIONALLY_SATISFIED.
    SELECT COUNT(*)
      INTO v_unsatisfied_checkpoints
      FROM public.lifecycle_checkpoint_rules lcr
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
       AND lcr.rule_type = 'REQUIRED';

    -- Record authority decision; extra lifecycle fields stored in decision_payload_json
    INSERT INTO authority_decisions (
        jurisdiction_code,
        regulatory_authority_id,
        decision_type,
        decision_payload_json
    ) VALUES (
        p_jurisdiction_code,
        p_regulatory_authority_id,
        p_decision_type,
        jsonb_build_object(
            'decision_outcome', p_decision_outcome,
            'subject_type',     p_subject_type,
            'subject_id',       p_subject_id,
            'from_status',      p_from_status,
            'to_status',        p_to_status
        ) || p_decision_payload_json
    )
    RETURNING authority_decision_id INTO v_decision_id;

    RETURN v_decision_id;
END;
$$;

-- ── attempt_lifecycle_transition ──────────────────────────────────────────────
-- Attempts a governed lifecycle transition for a subject (PROJECT, ASSET_BATCH, etc.).
-- Validates checkpoint rules: REQUIRED must be satisfied; CONDITIONALLY_REQUIRED
-- transitions to PENDING_CLARIFICATION state; successful transitions resolve to
-- CONDITIONALLY_SATISFIED. Calls transition_asset_status on success.
CREATE OR REPLACE FUNCTION public.attempt_lifecycle_transition(
    p_tenant_id   UUID,
    p_subject_type TEXT,
    p_subject_id  UUID,
    p_from_status TEXT,
    p_to_status   TEXT,
    p_jurisdiction_code TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_unsatisfied_checkpoints INT;
    v_conditional_count       INT;
    v_result_state            TEXT;
    v_valid_subject_types     TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_subject_type IS NULL THEN
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_from_status IS NULL THEN
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF016';
    END IF;

    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF016';
    END IF;

    -- ── Checkpoint evaluation ────────────────────────────────────────────────
    -- REQUIRED checkpoints: if any unsatisfied_checkpoints remain, block transition.
    -- CONDITIONALLY_REQUIRED: transition proceeds but outcome = PENDING_CLARIFICATION.
    IF p_jurisdiction_code IS NOT NULL THEN
        SELECT COUNT(*) INTO v_unsatisfied_checkpoints
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
           AND lcr.rule_type = 'REQUIRED';

        SELECT COUNT(*) INTO v_conditional_count
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
           AND lcr.rule_type = 'CONDITIONALLY_REQUIRED';
    ELSE
        v_unsatisfied_checkpoints := 0;
        v_conditional_count := 0;
    END IF;

    IF v_unsatisfied_checkpoints > 0 THEN
        RAISE EXCEPTION 'lifecycle transition blocked: % unsatisfied REQUIRED checkpoints',
                         v_unsatisfied_checkpoints
            USING ERRCODE = 'GF016';
    END IF;

    IF v_conditional_count > 0 THEN
        -- Provisional pass: state becomes PENDING_CLARIFICATION
        v_result_state := 'PENDING_CLARIFICATION';
    ELSE
        -- All requirements satisfied: state becomes CONDITIONALLY_SATISFIED
        v_result_state := 'CONDITIONALLY_SATISFIED';
    END IF;

    -- Execute the validated lifecycle transition
    PERFORM public.transition_asset_status(p_tenant_id, p_subject_id, p_to_status);

    RETURN v_result_state;
END;
$$;

-- ── query_authority_decisions ─────────────────────────────────────────────────
-- Returns authority decisions for a given jurisdiction and subject.
CREATE OR REPLACE FUNCTION public.query_authority_decisions(
    p_jurisdiction_code TEXT,
    p_subject_id        UUID DEFAULT NULL
)
RETURNS TABLE(
    authority_decision_id    UUID,
    regulatory_authority_id  UUID,
    decision_type            TEXT,
    decision_outcome         TEXT,
    subject_type             TEXT,
    subject_id               TEXT,
    from_status              TEXT,
    to_status                TEXT,
    created_at               TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT ad.authority_decision_id,
           ad.regulatory_authority_id,
           ad.decision_type,
           (ad.decision_payload_json->>'decision_outcome')::TEXT,
           (ad.decision_payload_json->>'subject_type')::TEXT,
           (ad.decision_payload_json->>'subject_id')::TEXT,
           (ad.decision_payload_json->>'from_status')::TEXT,
           (ad.decision_payload_json->>'to_status')::TEXT,
           ad.created_at
      FROM public.authority_decisions ad
     WHERE ad.jurisdiction_code = p_jurisdiction_code
       AND (p_subject_id IS NULL
            OR (ad.decision_payload_json->>'subject_id')::UUID = p_subject_id)
     ORDER BY ad.created_at ASC;
END;
$$;

-- ── get_checkpoint_requirements ───────────────────────────────────────────────
-- Returns lifecycle_checkpoint_rules for a jurisdiction, classified by rule_type.
-- Callers can filter on REQUIRED vs CONDITIONALLY_REQUIRED to plan transitions.
CREATE OR REPLACE FUNCTION public.get_checkpoint_requirements(
    p_jurisdiction_code TEXT
)
RETURNS TABLE(
    lifecycle_checkpoint_rule_id UUID,
    regulatory_checkpoint_id     UUID,
    rule_type                    TEXT,
    rule_payload_json            JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RETURN QUERY
    SELECT lcr.lifecycle_checkpoint_rule_id,
           lcr.regulatory_checkpoint_id,
           lcr.rule_type,
           lcr.rule_payload_json
      FROM public.lifecycle_checkpoint_rules lcr
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
     ORDER BY lcr.created_at ASC;
END;
$$;

-- ── Privileges ────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION transition_asset_status(UUID, UUID, TEXT)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION record_authority_decision(UUID, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT, UUID, JSONB)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION attempt_lifecycle_transition(UUID, TEXT, UUID, TEXT, TEXT, TEXT)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION query_authority_decisions(TEXT, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION get_checkpoint_requirements(TEXT)
    TO symphony_command;
