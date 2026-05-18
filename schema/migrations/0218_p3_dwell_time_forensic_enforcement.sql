-- Migration: 0218_p3_dwell_time_forensic_enforcement.sql
-- Task: TSK-P3-WP-010
-- Description: Establish replay-derived dwell-time forensic findings using
--              declared temporal policy inputs and persisted record context.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_dwell_finding_state'
    ) THEN
        CREATE TYPE public.p3_dwell_finding_state AS ENUM (
            'within_window',
            'flagged',
            'blocked'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_dwell_time_policy_inputs (
    dwell_time_policy_input_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_key text NOT NULL UNIQUE,
    max_dwell interval NOT NULL,
    breach_state public.p3_dwell_finding_state NOT NULL,
    source_authority_lineage_id uuid NOT NULL REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid NOT NULL REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(policy_key) <> ''),
    CHECK (max_dwell > interval '0 seconds'),
    CHECK (breach_state IN ('flagged', 'blocked'))
);

CREATE TABLE IF NOT EXISTS public.p3_dwell_time_findings (
    dwell_time_finding_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_key text NOT NULL,
    dwell_time_policy_input_id uuid NOT NULL REFERENCES public.p3_dwell_time_policy_inputs (dwell_time_policy_input_id),
    current_state text NOT NULL,
    started_at timestamptz NOT NULL,
    evaluated_at timestamptz NOT NULL,
    elapsed_duration interval NOT NULL,
    threshold_duration interval NOT NULL,
    finding_state public.p3_dwell_finding_state NOT NULL,
    tie_break_key text NOT NULL,
    supersedes_dwell_time_finding_id uuid REFERENCES public.p3_dwell_time_findings (dwell_time_finding_id),
    lineage_provenance_id uuid NOT NULL DEFAULT gen_random_uuid(),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(subject_key) <> ''),
    CHECK (btrim(current_state) <> ''),
    CHECK (evaluated_at >= started_at),
    CHECK (elapsed_duration >= interval '0 seconds'),
    CHECK (threshold_duration > interval '0 seconds'),
    CHECK (btrim(tie_break_key) <> '')
);

CREATE INDEX IF NOT EXISTS idx_p3_dwell_time_findings_subject
    ON public.p3_dwell_time_findings (subject_key, evaluated_at DESC, tie_break_key);

CREATE OR REPLACE VIEW public.p3_dwell_time_manifest AS
SELECT
    f.dwell_time_finding_id,
    f.subject_key,
    f.current_state,
    f.started_at,
    f.evaluated_at,
    f.elapsed_duration,
    f.threshold_duration,
    f.finding_state,
    f.tie_break_key,
    f.lineage_provenance_id,
    f.recorded_at,
    p.policy_key,
    p.max_dwell,
    p.breach_state,
    a.authority_key,
    policy_artifact.artifact_key
FROM public.p3_dwell_time_findings f
JOIN public.p3_dwell_time_policy_inputs p
  ON p.dwell_time_policy_input_id = f.dwell_time_policy_input_id
JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = p.source_authority_lineage_id
JOIN public.p3_policy_artifacts policy_artifact
  ON policy_artifact.policy_artifact_id = p.source_policy_artifact_id;

CREATE OR REPLACE FUNCTION public.p3_deny_dwell_time_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 dwell-time findings are append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3017';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_dwell_time_policy_inputs_mutation ON public.p3_dwell_time_policy_inputs;
CREATE TRIGGER trg_deny_p3_dwell_time_policy_inputs_mutation
BEFORE UPDATE OR DELETE ON public.p3_dwell_time_policy_inputs
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_dwell_time_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_dwell_time_findings_mutation ON public.p3_dwell_time_findings;
CREATE TRIGGER trg_deny_p3_dwell_time_findings_mutation
BEFORE UPDATE OR DELETE ON public.p3_dwell_time_findings
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_dwell_time_mutation();

CREATE OR REPLACE FUNCTION public.p3_record_dwell_time_finding(
    p_policy_key text,
    p_subject_key text,
    p_current_state text,
    p_started_at timestamptz,
    p_evaluated_at timestamptz,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_policy public.p3_dwell_time_policy_inputs%ROWTYPE;
    v_elapsed interval;
    v_state public.p3_dwell_finding_state;
    v_id uuid;
BEGIN
    SELECT *
    INTO v_policy
    FROM public.p3_dwell_time_policy_inputs
    WHERE policy_key = p_policy_key;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'dwell-time policy input missing: %', p_policy_key
            USING ERRCODE = 'P3012';
    END IF;

    IF p_evaluated_at < p_started_at THEN
        RAISE EXCEPTION 'evaluated_at precedes started_at for %', p_subject_key
            USING ERRCODE = 'P3012';
    END IF;

    v_elapsed := p_evaluated_at - p_started_at;
    v_state := CASE
        WHEN v_elapsed > v_policy.max_dwell THEN v_policy.breach_state
        ELSE 'within_window'::public.p3_dwell_finding_state
    END;

    INSERT INTO public.p3_dwell_time_findings (
        subject_key,
        dwell_time_policy_input_id,
        current_state,
        started_at,
        evaluated_at,
        elapsed_duration,
        threshold_duration,
        finding_state,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_subject_key,
        v_policy.dwell_time_policy_input_id,
        p_current_state,
        p_started_at,
        p_evaluated_at,
        v_elapsed,
        v_policy.max_dwell,
        v_state,
        p_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING dwell_time_finding_id INTO v_id;

    RETURN v_id;
END;
$$;

COMMENT ON TABLE public.p3_dwell_time_policy_inputs IS
    'Declared temporal policy inputs for replay-derived dwell-time evaluation.';

COMMENT ON TABLE public.p3_dwell_time_findings IS
    'Replay-derived dwell-time forensic findings preserving historical truth and explicit evaluation points.';

