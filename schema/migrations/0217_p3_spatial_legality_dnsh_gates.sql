-- Migration: 0217_p3_spatial_legality_dnsh_gates.sql
-- Task: TSK-P3-WP-009
-- Description: Establish authoritative spatial legality and DNSH gating with
--              declared dataset versions and replay-stable comparison rules.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_spatial_gate_state'
    ) THEN
        CREATE TYPE public.p3_spatial_gate_state AS ENUM (
            'admissible',
            'dns_harm_blocked',
            'doctrine_gap_blocked'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_spatial_dataset_declarations (
    spatial_dataset_declaration_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dataset_key text NOT NULL,
    dataset_version text NOT NULL,
    source_table_name text NOT NULL DEFAULT 'public.protected_areas',
    comparison_rule text NOT NULL,
    doctrine_gap_blocking boolean NOT NULL DEFAULT false,
    source_authority_lineage_id uuid NOT NULL REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid NOT NULL REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    replay_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (dataset_key, dataset_version),
    CHECK (btrim(dataset_key) <> ''),
    CHECK (btrim(dataset_version) <> ''),
    CHECK (btrim(source_table_name) <> ''),
    CHECK (btrim(comparison_rule) <> ''),
    CHECK (jsonb_typeof(replay_metadata) = 'object')
);

CREATE TABLE IF NOT EXISTS public.p3_spatial_legality_findings (
    spatial_legality_finding_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_key text NOT NULL,
    spatial_dataset_declaration_id uuid NOT NULL REFERENCES public.p3_spatial_dataset_declarations (spatial_dataset_declaration_id),
    subject_geometry geometry(Polygon,4326) NOT NULL,
    gate_state public.p3_spatial_gate_state NOT NULL,
    policy_reference text NOT NULL,
    tie_break_key text NOT NULL,
    lineage_provenance_id uuid NOT NULL DEFAULT gen_random_uuid(),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(subject_key) <> ''),
    CHECK (btrim(policy_reference) <> ''),
    CHECK (btrim(tie_break_key) <> '')
);

CREATE INDEX IF NOT EXISTS idx_p3_spatial_legality_findings_subject
    ON public.p3_spatial_legality_findings (subject_key, recorded_at DESC, tie_break_key);

CREATE INDEX IF NOT EXISTS idx_p3_spatial_legality_findings_geom
    ON public.p3_spatial_legality_findings USING gist (subject_geometry);

CREATE OR REPLACE VIEW public.p3_spatial_legality_manifest AS
SELECT
    f.spatial_legality_finding_id,
    f.subject_key,
    f.gate_state,
    f.policy_reference,
    f.tie_break_key,
    f.lineage_provenance_id,
    f.recorded_at,
    d.dataset_key,
    d.dataset_version,
    d.source_table_name,
    d.comparison_rule,
    d.doctrine_gap_blocking,
    d.replay_metadata,
    a.authority_key,
    p.artifact_key
FROM public.p3_spatial_legality_findings f
JOIN public.p3_spatial_dataset_declarations d
  ON d.spatial_dataset_declaration_id = f.spatial_dataset_declaration_id
JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = d.source_authority_lineage_id
JOIN public.p3_policy_artifacts p
  ON p.policy_artifact_id = d.source_policy_artifact_id;

CREATE OR REPLACE FUNCTION public.p3_deny_spatial_legality_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 spatial legality substrate is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3016';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_spatial_dataset_declarations_mutation ON public.p3_spatial_dataset_declarations;
CREATE TRIGGER trg_deny_p3_spatial_dataset_declarations_mutation
BEFORE UPDATE OR DELETE ON public.p3_spatial_dataset_declarations
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_spatial_legality_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_spatial_legality_findings_mutation ON public.p3_spatial_legality_findings;
CREATE TRIGGER trg_deny_p3_spatial_legality_findings_mutation
BEFORE UPDATE OR DELETE ON public.p3_spatial_legality_findings
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_spatial_legality_mutation();

CREATE OR REPLACE FUNCTION public.p3_assert_spatial_legality(
    p_subject_key text,
    p_subject_geometry geometry,
    p_dataset_key text,
    p_dataset_version text,
    p_policy_reference text,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_declaration public.p3_spatial_dataset_declarations%ROWTYPE;
    v_id uuid;
BEGIN
    SELECT *
    INTO v_declaration
    FROM public.p3_spatial_dataset_declarations
    WHERE dataset_key = p_dataset_key
      AND dataset_version = p_dataset_version;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'spatial dataset declaration missing for %@%', p_dataset_key, p_dataset_version
            USING ERRCODE = 'P3011';
    END IF;

    IF v_declaration.doctrine_gap_blocking THEN
        RAISE EXCEPTION 'spatial doctrine gap blocks admissibility for %@%', p_dataset_key, p_dataset_version
            USING ERRCODE = 'P3011';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.protected_areas pa
        WHERE ST_Intersects(pa.geom, p_subject_geometry)
    ) THEN
        RAISE EXCEPTION 'GF057: DNSH violation: subject geometry intersects protected area'
            USING ERRCODE = 'GF057';
    END IF;

    INSERT INTO public.p3_spatial_legality_findings (
        subject_key,
        spatial_dataset_declaration_id,
        subject_geometry,
        gate_state,
        policy_reference,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_subject_key,
        v_declaration.spatial_dataset_declaration_id,
        p_subject_geometry,
        'admissible',
        p_policy_reference,
        p_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING spatial_legality_finding_id INTO v_id;

    RETURN v_id;
END;
$$;

COMMENT ON TABLE public.p3_spatial_dataset_declarations IS
    'Replay-addressable spatial dataset declarations with explicit versions, comparison rules, and doctrine-gap blocking posture.';

COMMENT ON TABLE public.p3_spatial_legality_findings IS
    'Authoritative replay-derived spatial legality and DNSH findings for declared subject geometries.';

