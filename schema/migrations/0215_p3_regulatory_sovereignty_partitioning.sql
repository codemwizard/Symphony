-- Migration: 0215_p3_regulatory_sovereignty_partitioning.sql
-- Task: TSK-P3-WP-007
-- Description: Establish regulator-aware partitioning, doctrine-declared
--              precedence application, and sovereignty non-collapse substrate.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_regulator_partition_state'
    ) THEN
        CREATE TYPE public.p3_regulator_partition_state AS ENUM (
            'independent_finding',
            'precedence_applied',
            'doctrine_gap'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_regulator_regimes (
    regulator_regime_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    regime_key text NOT NULL UNIQUE,
    sovereign_domain text NOT NULL,
    source_authority_lineage_id uuid REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(regime_key) <> ''),
    CHECK (btrim(sovereign_domain) <> '')
);

CREATE TABLE IF NOT EXISTS public.p3_regulator_precedence_rules (
    precedence_rule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    higher_regime_id uuid NOT NULL REFERENCES public.p3_regulator_regimes (regulator_regime_id),
    lower_regime_id uuid NOT NULL REFERENCES public.p3_regulator_regimes (regulator_regime_id),
    source_authority_lineage_id uuid NOT NULL REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid NOT NULL REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    canonical_order_at timestamptz NOT NULL,
    tie_break_key text NOT NULL,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (higher_regime_id <> lower_regime_id),
    CHECK (btrim(tie_break_key) <> '')
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_p3_regulator_precedence_pair
    ON public.p3_regulator_precedence_rules (higher_regime_id, lower_regime_id);

CREATE TABLE IF NOT EXISTS public.p3_regulator_partition_findings (
    regulator_partition_finding_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_key text NOT NULL,
    subject_regime_id uuid NOT NULL REFERENCES public.p3_regulator_regimes (regulator_regime_id),
    counterpart_regime_id uuid REFERENCES public.p3_regulator_regimes (regulator_regime_id),
    partition_state public.p3_regulator_partition_state NOT NULL,
    precedence_rule_id uuid REFERENCES public.p3_regulator_precedence_rules (precedence_rule_id),
    doctrine_gap_reason text,
    quarantine_compatible boolean NOT NULL DEFAULT true,
    canonical_order_at timestamptz NOT NULL,
    tie_break_key text NOT NULL,
    lineage_provenance_id uuid NOT NULL DEFAULT gen_random_uuid(),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(subject_key) <> ''),
    CHECK (btrim(tie_break_key) <> ''),
    CHECK (partition_state <> 'doctrine_gap' OR btrim(COALESCE(doctrine_gap_reason, '')) <> ''),
    CHECK (counterpart_regime_id IS NULL OR counterpart_regime_id <> subject_regime_id)
);

CREATE INDEX IF NOT EXISTS idx_p3_regulator_partition_findings_subject
    ON public.p3_regulator_partition_findings (subject_key, canonical_order_at, tie_break_key);

CREATE OR REPLACE VIEW public.p3_regulator_partition_manifest AS
SELECT
    f.regulator_partition_finding_id,
    f.subject_key,
    f.partition_state,
    f.doctrine_gap_reason,
    f.quarantine_compatible,
    f.canonical_order_at,
    f.tie_break_key,
    subject_regime.regime_key AS subject_regime_key,
    subject_regime.sovereign_domain AS subject_sovereign_domain,
    counterpart_regime.regime_key AS counterpart_regime_key,
    counterpart_regime.sovereign_domain AS counterpart_sovereign_domain,
    r.precedence_rule_id,
    higher_regime.regime_key AS higher_regime_key,
    lower_regime.regime_key AS lower_regime_key,
    f.lineage_provenance_id,
    f.recorded_at
FROM public.p3_regulator_partition_findings f
JOIN public.p3_regulator_regimes subject_regime
  ON subject_regime.regulator_regime_id = f.subject_regime_id
LEFT JOIN public.p3_regulator_regimes counterpart_regime
  ON counterpart_regime.regulator_regime_id = f.counterpart_regime_id
LEFT JOIN public.p3_regulator_precedence_rules r
  ON r.precedence_rule_id = f.precedence_rule_id
LEFT JOIN public.p3_regulator_regimes higher_regime
  ON higher_regime.regulator_regime_id = r.higher_regime_id
LEFT JOIN public.p3_regulator_regimes lower_regime
  ON lower_regime.regulator_regime_id = r.lower_regime_id;

CREATE OR REPLACE FUNCTION public.p3_deny_regulator_partition_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 regulator partition substrate is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3014';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_regulator_regimes_mutation ON public.p3_regulator_regimes;
CREATE TRIGGER trg_deny_p3_regulator_regimes_mutation
BEFORE UPDATE OR DELETE ON public.p3_regulator_regimes
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_regulator_partition_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_regulator_precedence_rules_mutation ON public.p3_regulator_precedence_rules;
CREATE TRIGGER trg_deny_p3_regulator_precedence_rules_mutation
BEFORE UPDATE OR DELETE ON public.p3_regulator_precedence_rules
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_regulator_partition_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_regulator_partition_findings_mutation ON public.p3_regulator_partition_findings;
CREATE TRIGGER trg_deny_p3_regulator_partition_findings_mutation
BEFORE UPDATE OR DELETE ON public.p3_regulator_partition_findings
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_regulator_partition_mutation();

CREATE OR REPLACE FUNCTION public.p3_assert_regulator_rule_applicability(
    p_context_regime_key text,
    p_rule_regime_key text
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_context_regime_key IS NULL
       OR p_rule_regime_key IS NULL
       OR btrim(p_context_regime_key) = ''
       OR btrim(p_rule_regime_key) = '' THEN
        RAISE EXCEPTION 'context and rule regime keys are required'
            USING ERRCODE = 'P3001';
    END IF;

    IF p_context_regime_key <> p_rule_regime_key THEN
        RAISE EXCEPTION 'cross-regime rule application blocked: context=% rule=%',
            p_context_regime_key,
            p_rule_regime_key
            USING ERRCODE = 'P3001';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_regulator_partition_finding(
    p_subject_key text,
    p_context_regime_key text,
    p_rule_regime_key text,
    p_canonical_order_at timestamptz,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_subject_regime_id uuid;
    v_id uuid;
BEGIN
    PERFORM public.p3_assert_regulator_rule_applicability(
        p_context_regime_key,
        p_rule_regime_key
    );

    SELECT regulator_regime_id
    INTO v_subject_regime_id
    FROM public.p3_regulator_regimes
    WHERE regime_key = p_context_regime_key;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'unknown regulator regime: %', p_context_regime_key
            USING ERRCODE = 'P3001';
    END IF;

    INSERT INTO public.p3_regulator_partition_findings (
        subject_key,
        subject_regime_id,
        partition_state,
        canonical_order_at,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_subject_key,
        v_subject_regime_id,
        'independent_finding',
        p_canonical_order_at,
        p_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING regulator_partition_finding_id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_resolve_regulator_precedence(
    p_subject_key text,
    p_primary_regime_key text,
    p_secondary_regime_key text,
    p_canonical_order_at timestamptz,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_primary_id uuid;
    v_secondary_id uuid;
    v_rule_id uuid;
    v_id uuid;
BEGIN
    SELECT regulator_regime_id
    INTO v_primary_id
    FROM public.p3_regulator_regimes
    WHERE regime_key = p_primary_regime_key;

    SELECT regulator_regime_id
    INTO v_secondary_id
    FROM public.p3_regulator_regimes
    WHERE regime_key = p_secondary_regime_key;

    IF v_primary_id IS NULL OR v_secondary_id IS NULL THEN
        RAISE EXCEPTION 'unknown regulator regime pair: %, %', p_primary_regime_key, p_secondary_regime_key
            USING ERRCODE = 'P3001';
    END IF;

    SELECT precedence_rule_id
    INTO v_rule_id
    FROM public.p3_regulator_precedence_rules
    WHERE higher_regime_id = v_primary_id
      AND lower_regime_id = v_secondary_id;

    IF v_rule_id IS NULL THEN
        INSERT INTO public.p3_regulator_partition_findings (
            subject_key,
            subject_regime_id,
            counterpart_regime_id,
            partition_state,
            canonical_order_at,
            tie_break_key,
            lineage_provenance_id
        ) VALUES
        (
            p_subject_key,
            v_primary_id,
            v_secondary_id,
            'independent_finding',
            p_canonical_order_at,
            p_tie_break_key || ':primary',
            p_lineage_provenance_id
        ),
        (
            p_subject_key,
            v_secondary_id,
            v_primary_id,
            'independent_finding',
            p_canonical_order_at,
            p_tie_break_key || ':secondary',
            p_lineage_provenance_id
        );

        INSERT INTO public.p3_regulator_partition_findings (
            subject_key,
            subject_regime_id,
            counterpart_regime_id,
            partition_state,
            doctrine_gap_reason,
            canonical_order_at,
            tie_break_key,
            lineage_provenance_id
        ) VALUES (
            p_subject_key,
            v_primary_id,
            v_secondary_id,
            'doctrine_gap',
            'undeclared_precedence',
            p_canonical_order_at,
            p_tie_break_key || ':gap',
            p_lineage_provenance_id
        )
        RETURNING regulator_partition_finding_id INTO v_id;

        RETURN v_id;
    END IF;

    INSERT INTO public.p3_regulator_partition_findings (
        subject_key,
        subject_regime_id,
        counterpart_regime_id,
        partition_state,
        precedence_rule_id,
        canonical_order_at,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_subject_key,
        v_primary_id,
        v_secondary_id,
        'precedence_applied',
        v_rule_id,
        p_canonical_order_at,
        p_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING regulator_partition_finding_id INTO v_id;

    RETURN v_id;
END;
$$;

COMMENT ON TABLE public.p3_regulator_regimes IS
    'Phase 3 regulator sovereignty substrate. Distinct sovereign regimes remain separately addressable and replay-addressable.';

COMMENT ON TABLE public.p3_regulator_precedence_rules IS
    'Doctrine-declared regulator precedence rules. Only explicit rules may drive precedence application.';

COMMENT ON TABLE public.p3_regulator_partition_findings IS
    'Replay-derived regulator partition findings preserving sovereignty non-collapse, explicit precedence, and doctrine-gap handling.';

