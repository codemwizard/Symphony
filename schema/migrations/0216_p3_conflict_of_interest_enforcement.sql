-- Migration: 0216_p3_conflict_of_interest_enforcement.sql
-- Task: TSK-P3-WP-008
-- Description: Establish conflict-of-interest and verifier independence
--              enforcement anchored to persisted relationship and authority records.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_conflict_relationship_kind'
    ) THEN
        CREATE TYPE public.p3_conflict_relationship_kind AS ENUM (
            'same_actor',
            'declared_relationship_conflict',
            'authority_overlap'
        );
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_verifier_independence_state'
    ) THEN
        CREATE TYPE public.p3_verifier_independence_state AS ENUM (
            'independent',
            'rejected_conflict'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_conflict_relationships (
    conflict_relationship_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    left_actor_id uuid NOT NULL,
    right_actor_id uuid NOT NULL,
    conflict_relationship_kind public.p3_conflict_relationship_kind NOT NULL,
    asset_key text,
    source_authority_lineage_id uuid REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    conflict_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (left_actor_id <> right_actor_id),
    CHECK (asset_key IS NULL OR btrim(asset_key) <> ''),
    CHECK (jsonb_typeof(conflict_metadata) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_conflict_relationships_actor_pair
    ON public.p3_conflict_relationships (left_actor_id, right_actor_id, conflict_relationship_kind);

CREATE TABLE IF NOT EXISTS public.p3_verifier_independence_records (
    verifier_independence_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_key text NOT NULL,
    asset_key text NOT NULL,
    submitter_actor_id uuid NOT NULL,
    verifier_actor_id uuid NOT NULL,
    independence_state public.p3_verifier_independence_state NOT NULL,
    source_conflict_relationship_id uuid REFERENCES public.p3_conflict_relationships (conflict_relationship_id),
    source_authority_lineage_id uuid REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    tie_break_key text NOT NULL,
    lineage_provenance_id uuid NOT NULL DEFAULT gen_random_uuid(),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(decision_key) <> ''),
    CHECK (btrim(asset_key) <> ''),
    CHECK (btrim(tie_break_key) <> '')
);

CREATE INDEX IF NOT EXISTS idx_p3_verifier_independence_records_decision
    ON public.p3_verifier_independence_records (decision_key, asset_key, recorded_at DESC);

CREATE OR REPLACE VIEW public.p3_verifier_independence_manifest AS
SELECT
    r.verifier_independence_record_id,
    r.decision_key,
    r.asset_key,
    r.submitter_actor_id,
    r.verifier_actor_id,
    r.independence_state,
    r.source_conflict_relationship_id,
    c.conflict_relationship_kind,
    c.asset_key AS conflict_asset_key,
    r.source_authority_lineage_id,
    a.authority_key,
    r.source_policy_artifact_id,
    p.artifact_key,
    r.tie_break_key,
    r.lineage_provenance_id,
    r.recorded_at
FROM public.p3_verifier_independence_records r
LEFT JOIN public.p3_conflict_relationships c
  ON c.conflict_relationship_id = r.source_conflict_relationship_id
LEFT JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = r.source_authority_lineage_id
LEFT JOIN public.p3_policy_artifacts p
  ON p.policy_artifact_id = r.source_policy_artifact_id;

CREATE OR REPLACE FUNCTION public.p3_deny_coi_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 conflict-of-interest substrate is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3015';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_conflict_relationships_mutation ON public.p3_conflict_relationships;
CREATE TRIGGER trg_deny_p3_conflict_relationships_mutation
BEFORE UPDATE OR DELETE ON public.p3_conflict_relationships
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_coi_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_verifier_independence_records_mutation ON public.p3_verifier_independence_records;
CREATE TRIGGER trg_deny_p3_verifier_independence_records_mutation
BEFORE UPDATE OR DELETE ON public.p3_verifier_independence_records
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_coi_mutation();

CREATE OR REPLACE FUNCTION public.p3_declare_conflict_relationship(
    p_left_actor_id uuid,
    p_right_actor_id uuid,
    p_conflict_relationship_kind public.p3_conflict_relationship_kind,
    p_asset_key text,
    p_source_authority_lineage_id uuid,
    p_source_policy_artifact_id uuid,
    p_conflict_metadata jsonb,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_left uuid;
    v_right uuid;
    v_id uuid;
BEGIN
    IF p_left_actor_id::text < p_right_actor_id::text THEN
        v_left := p_left_actor_id;
        v_right := p_right_actor_id;
    ELSE
        v_left := p_right_actor_id;
        v_right := p_left_actor_id;
    END IF;

    INSERT INTO public.p3_conflict_relationships (
        left_actor_id,
        right_actor_id,
        conflict_relationship_kind,
        asset_key,
        source_authority_lineage_id,
        source_policy_artifact_id,
        conflict_metadata,
        lineage_provenance_id
    ) VALUES (
        v_left,
        v_right,
        p_conflict_relationship_kind,
        p_asset_key,
        p_source_authority_lineage_id,
        p_source_policy_artifact_id,
        COALESCE(p_conflict_metadata, '{}'::jsonb),
        p_lineage_provenance_id
    )
    RETURNING conflict_relationship_id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_assert_verifier_independence(
    p_decision_key text,
    p_asset_key text,
    p_submitter_actor_id uuid,
    p_verifier_actor_id uuid,
    p_source_authority_lineage_id uuid,
    p_source_policy_artifact_id uuid,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_left uuid;
    v_right uuid;
    v_conflict_id uuid;
    v_id uuid;
BEGIN
    IF p_submitter_actor_id = p_verifier_actor_id THEN
        RAISE EXCEPTION 'submitter and verifier must differ for asset %', p_asset_key
            USING ERRCODE = 'GF001';
    END IF;

    IF p_submitter_actor_id::text < p_verifier_actor_id::text THEN
        v_left := p_submitter_actor_id;
        v_right := p_verifier_actor_id;
    ELSE
        v_left := p_verifier_actor_id;
        v_right := p_submitter_actor_id;
    END IF;

    SELECT conflict_relationship_id
    INTO v_conflict_id
    FROM public.p3_conflict_relationships
    WHERE left_actor_id = v_left
      AND right_actor_id = v_right
      AND (asset_key IS NULL OR asset_key = p_asset_key)
    ORDER BY declared_at DESC, conflict_relationship_id
    LIMIT 1;

    IF v_conflict_id IS NOT NULL THEN
        RAISE EXCEPTION 'declared conflict of interest prevents verification for asset %', p_asset_key
            USING ERRCODE = 'GF001';
    END IF;

    INSERT INTO public.p3_verifier_independence_records (
        decision_key,
        asset_key,
        submitter_actor_id,
        verifier_actor_id,
        independence_state,
        source_authority_lineage_id,
        source_policy_artifact_id,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_decision_key,
        p_asset_key,
        p_submitter_actor_id,
        p_verifier_actor_id,
        'independent',
        p_source_authority_lineage_id,
        p_source_policy_artifact_id,
        p_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING verifier_independence_record_id INTO v_id;

    RETURN v_id;
END;
$$;

COMMENT ON TABLE public.p3_conflict_relationships IS
    'Persisted relationship-conflict declarations anchoring conflict-of-interest enforcement to recorded facts rather than runtime-only trust state.';

COMMENT ON TABLE public.p3_verifier_independence_records IS
    'Replay-visible verifier-independence records proving submitter/verifier separation for a decision or asset context.';

