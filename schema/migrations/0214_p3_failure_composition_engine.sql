-- Migration: 0214_p3_failure_composition_engine.sql
-- Task: TSK-P3-WP-005
-- Description: Establish machine-readable failure composition and internal
--              provenance continuity for Phase 3 Wave 3.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_failure_category'
    ) THEN
        CREATE TYPE public.p3_failure_category AS ENUM (
            'dependency_missing',
            'dependency_illegitimate',
            'authority_scope_violation',
            'delegation_invalid',
            'contradiction_detected',
            'policy_artifact_invalid',
            'projection_context_invalid',
            'replay_reconstruction_failed',
            'evidence_lineage_break',
            'doctrine_gap_blocker'
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
          AND t.typname = 'p3_failure_severity'
    ) THEN
        CREATE TYPE public.p3_failure_severity AS ENUM (
            'blocking',
            'quarantine',
            'escalation_required',
            'warning_non_blocking'
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
          AND t.typname = 'p3_internal_boundary_kind'
    ) THEN
        CREATE TYPE public.p3_internal_boundary_kind AS ENUM (
            'lineage_to_failure',
            'projection_to_failure',
            'authority_to_failure',
            'contradiction_to_failure'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_provenance_continuity_records (
    continuity_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    boundary_kind public.p3_internal_boundary_kind NOT NULL,
    source_surface_id text NOT NULL,
    destination_surface_id text NOT NULL,
    source_record_locator text NOT NULL,
    parent_continuity_record_id uuid REFERENCES public.p3_provenance_continuity_records (continuity_record_id),
    continuity_status text NOT NULL DEFAULT 'complete',
    continuity_hash text NOT NULL,
    provenance_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    mutability_class text NOT NULL DEFAULT 'immutable_lineage',
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (continuity_status IN ('complete', 'broken')),
    CHECK (btrim(source_surface_id) <> ''),
    CHECK (btrim(destination_surface_id) <> ''),
    CHECK (btrim(source_record_locator) <> ''),
    CHECK (btrim(continuity_hash) <> ''),
    CHECK (mutability_class = 'immutable_lineage'),
    CHECK (jsonb_typeof(provenance_payload) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_provenance_continuity_boundary
    ON public.p3_provenance_continuity_records (boundary_kind, continuity_status, created_at);

CREATE TABLE IF NOT EXISTS public.p3_failure_records (
    failure_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    root_failure_record_id uuid REFERENCES public.p3_failure_records (failure_record_id),
    parent_failure_record_id uuid REFERENCES public.p3_failure_records (failure_record_id),
    failure_category public.p3_failure_category NOT NULL,
    failure_severity public.p3_failure_severity NOT NULL,
    source_contradiction_record_id uuid REFERENCES public.p3_contradiction_records (contradiction_record_id),
    source_dependency_node_id uuid REFERENCES public.p3_dependency_nodes (node_id),
    source_authority_lineage_id uuid REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    source_projection_universe_id uuid REFERENCES public.p3_projection_universes (projection_universe_id),
    source_continuity_record_id uuid REFERENCES public.p3_provenance_continuity_records (continuity_record_id),
    failure_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    ordering_key timestamptz NOT NULL DEFAULT now(),
    tie_break_key text NOT NULL,
    mutability_class text NOT NULL DEFAULT 'compensating_lineage',
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mutability_class IN ('compensating_lineage', 'immutable_lineage')),
    CHECK (btrim(tie_break_key) <> ''),
    CHECK (jsonb_typeof(failure_payload) = 'object'),
    CHECK (parent_failure_record_id IS NULL OR parent_failure_record_id <> failure_record_id)
);

CREATE INDEX IF NOT EXISTS idx_p3_failure_records_category
    ON public.p3_failure_records (failure_category, failure_severity, ordering_key);

CREATE TABLE IF NOT EXISTS public.p3_failure_continuity_compensations (
    continuity_compensation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    prior_continuity_record_id uuid NOT NULL REFERENCES public.p3_provenance_continuity_records (continuity_record_id),
    replacement_continuity_record_id uuid NOT NULL REFERENCES public.p3_provenance_continuity_records (continuity_record_id),
    compensation_reason text NOT NULL,
    mutability_class text NOT NULL DEFAULT 'compensating_lineage',
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (prior_continuity_record_id <> replacement_continuity_record_id),
    CHECK (mutability_class = 'compensating_lineage'),
    CHECK (btrim(compensation_reason) <> '')
);

CREATE OR REPLACE FUNCTION public.p3_deny_failure_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 failure composition is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3008';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_provenance_continuity_records_mutation ON public.p3_provenance_continuity_records;
CREATE TRIGGER trg_deny_p3_provenance_continuity_records_mutation
BEFORE UPDATE OR DELETE ON public.p3_provenance_continuity_records
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_failure_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_failure_records_mutation ON public.p3_failure_records;
CREATE TRIGGER trg_deny_p3_failure_records_mutation
BEFORE UPDATE OR DELETE ON public.p3_failure_records
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_failure_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_failure_continuity_compensations_mutation ON public.p3_failure_continuity_compensations;
CREATE TRIGGER trg_deny_p3_failure_continuity_compensations_mutation
BEFORE UPDATE OR DELETE ON public.p3_failure_continuity_compensations
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_failure_mutation();

CREATE OR REPLACE FUNCTION public.p3_assert_provenance_continuity(
    p_continuity_record_id uuid
)
RETURNS public.p3_provenance_continuity_records
LANGUAGE plpgsql
AS $$
DECLARE
    v_record public.p3_provenance_continuity_records%ROWTYPE;
    v_broken_count integer;
BEGIN
    WITH RECURSIVE chain AS (
        SELECT
            r.continuity_record_id,
            r.parent_continuity_record_id,
            r.continuity_status,
            r.source_surface_id,
            r.destination_surface_id,
            r.continuity_hash
        FROM public.p3_provenance_continuity_records r
        WHERE r.continuity_record_id = p_continuity_record_id

        UNION ALL

        SELECT
            parent.continuity_record_id,
            parent.parent_continuity_record_id,
            parent.continuity_status,
            parent.source_surface_id,
            parent.destination_surface_id,
            parent.continuity_hash
        FROM public.p3_provenance_continuity_records parent
        JOIN chain c
          ON parent.continuity_record_id = c.parent_continuity_record_id
    )
    SELECT COUNT(*)
    INTO v_broken_count
    FROM chain
    WHERE continuity_status <> 'complete'
       OR btrim(source_surface_id) = ''
       OR btrim(destination_surface_id) = ''
       OR btrim(continuity_hash) = '';

    IF v_broken_count > 0 THEN
        RAISE EXCEPTION 'broken provenance continuity chain for %', p_continuity_record_id
            USING ERRCODE = 'P3007';
    END IF;

    SELECT *
    INTO v_record
    FROM public.p3_provenance_continuity_records
    WHERE continuity_record_id = p_continuity_record_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'continuity record not found: %', p_continuity_record_id
            USING ERRCODE = 'P3007';
    END IF;

    RETURN v_record;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_provenance_continuity_record(
    p_boundary_kind public.p3_internal_boundary_kind,
    p_source_surface_id text,
    p_destination_surface_id text,
    p_source_record_locator text,
    p_parent_continuity_record_id uuid,
    p_continuity_status text,
    p_continuity_hash text,
    p_provenance_payload jsonb,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_id uuid;
BEGIN
    INSERT INTO public.p3_provenance_continuity_records (
        boundary_kind,
        source_surface_id,
        destination_surface_id,
        source_record_locator,
        parent_continuity_record_id,
        continuity_status,
        continuity_hash,
        provenance_payload,
        lineage_provenance_id
    ) VALUES (
        p_boundary_kind,
        p_source_surface_id,
        p_destination_surface_id,
        p_source_record_locator,
        p_parent_continuity_record_id,
        p_continuity_status,
        p_continuity_hash,
        p_provenance_payload,
        p_lineage_provenance_id
    )
    RETURNING continuity_record_id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_failure_record(
    p_failure_category public.p3_failure_category,
    p_failure_severity public.p3_failure_severity,
    p_parent_failure_record_id uuid,
    p_source_contradiction_record_id uuid,
    p_source_dependency_node_id uuid,
    p_source_authority_lineage_id uuid,
    p_source_policy_artifact_id uuid,
    p_source_projection_universe_id uuid,
    p_source_continuity_record_id uuid,
    p_failure_payload jsonb,
    p_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_root_failure_record_id uuid;
    v_failure_record_id uuid;
BEGIN
    IF p_source_continuity_record_id IS NOT NULL THEN
        PERFORM public.p3_assert_provenance_continuity(p_source_continuity_record_id);
    END IF;

    IF p_parent_failure_record_id IS NOT NULL THEN
        SELECT COALESCE(root_failure_record_id, failure_record_id)
        INTO v_root_failure_record_id
        FROM public.p3_failure_records
        WHERE failure_record_id = p_parent_failure_record_id;
    END IF;

    v_failure_record_id := gen_random_uuid();

    INSERT INTO public.p3_failure_records (
        failure_record_id,
        root_failure_record_id,
        parent_failure_record_id,
        failure_category,
        failure_severity,
        source_contradiction_record_id,
        source_dependency_node_id,
        source_authority_lineage_id,
        source_policy_artifact_id,
        source_projection_universe_id,
        source_continuity_record_id,
        failure_payload,
        tie_break_key,
        lineage_provenance_id
    ) VALUES (
        v_failure_record_id,
        COALESCE(v_root_failure_record_id, v_failure_record_id),
        p_parent_failure_record_id,
        p_failure_category,
        p_failure_severity,
        p_source_contradiction_record_id,
        p_source_dependency_node_id,
        p_source_authority_lineage_id,
        p_source_policy_artifact_id,
        p_source_projection_universe_id,
        p_source_continuity_record_id,
        COALESCE(p_failure_payload, '{}'::jsonb),
        p_tie_break_key,
        p_lineage_provenance_id
    );

    RETURN v_failure_record_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_continuity_compensation(
    p_prior_continuity_record_id uuid,
    p_replacement_continuity_record_id uuid,
    p_compensation_reason text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_id uuid;
BEGIN
    INSERT INTO public.p3_failure_continuity_compensations (
        prior_continuity_record_id,
        replacement_continuity_record_id,
        compensation_reason,
        lineage_provenance_id
    ) VALUES (
        p_prior_continuity_record_id,
        p_replacement_continuity_record_id,
        p_compensation_reason,
        p_lineage_provenance_id
    )
    RETURNING continuity_compensation_id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE VIEW public.p3_failure_composition_manifest AS
SELECT
    'failure_record'::text AS artifact_kind,
    f.failure_record_id AS artifact_id,
    f.failure_category::text AS classification,
    f.failure_severity::text AS state,
    f.mutability_class,
    f.tie_break_key,
    f.lineage_provenance_id,
    f.created_at
FROM public.p3_failure_records f

UNION ALL

SELECT
    'continuity_record'::text AS artifact_kind,
    c.continuity_record_id AS artifact_id,
    c.boundary_kind::text AS classification,
    c.continuity_status AS state,
    c.mutability_class,
    c.continuity_hash AS tie_break_key,
    c.lineage_provenance_id,
    c.created_at
FROM public.p3_provenance_continuity_records c

UNION ALL

SELECT
    'continuity_compensation'::text AS artifact_kind,
    cc.continuity_compensation_id AS artifact_id,
    'continuity_compensation'::text AS classification,
    'compensated'::text AS state,
    cc.mutability_class,
    cc.replacement_continuity_record_id::text AS tie_break_key,
    cc.lineage_provenance_id,
    cc.created_at
FROM public.p3_failure_continuity_compensations cc;

COMMENT ON TABLE public.p3_provenance_continuity_records IS
    'Replay-independent provenance continuity anchors across declared internal Phase 3 system boundaries.';

COMMENT ON TABLE public.p3_failure_records IS
    'Machine-readable append-only failure records preserving failure trees and read-only contradiction references.';

COMMENT ON TABLE public.p3_failure_continuity_compensations IS
    'Append-only compensating continuity records preserving historical continuity lineage.';

COMMENT ON FUNCTION public.p3_assert_provenance_continuity(uuid) IS
    'Fail-closed recursive continuity assertion over declared internal Phase 3 boundaries.';

COMMENT ON FUNCTION public.p3_append_failure_record(
    public.p3_failure_category, public.p3_failure_severity, uuid, uuid, uuid, uuid, uuid, uuid, uuid, jsonb, text, uuid
) IS
    'Append-only failure tree writer that treats contradiction findings as read-only references and validates provenance continuity before composition.';

COMMENT ON VIEW public.p3_failure_composition_manifest IS
    'Unified manifest for failure records, provenance continuity, and compensating continuity lineage.';
