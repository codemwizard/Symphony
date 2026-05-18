-- Migration: 0211_p3_recursive_legitimacy_engine.sql
-- Task: TSK-P3-WP-003
-- Description: Establish the replay-derived projection-universe and recursive
--              legitimacy evaluation substrate for Phase 3.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_projection_purpose'
    ) THEN
        CREATE TYPE public.p3_projection_purpose AS ENUM (
            'legitimacy_view',
            'admissibility_view'
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
          AND t.typname = 'p3_legitimacy_projection_state'
    ) THEN
        CREATE TYPE public.p3_legitimacy_projection_state AS ENUM (
            'legitimate',
            'illegitimate',
            'blocked',
            'requires_escalation'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_projection_universes (
    projection_universe_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_universe_key text NOT NULL UNIQUE,
    projection_purpose public.p3_projection_purpose NOT NULL,
    replay_algorithm_version text NOT NULL,
    temporal_evaluation_point timestamptz NOT NULL,
    source_record_set jsonb NOT NULL DEFAULT '{}'::jsonb,
    replay_reconstruction_inputs jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(projection_universe_key) <> ''),
    CHECK (btrim(replay_algorithm_version) <> ''),
    CHECK (jsonb_typeof(source_record_set) = 'object'),
    CHECK (jsonb_typeof(replay_reconstruction_inputs) = 'object')
);

CREATE TABLE IF NOT EXISTS public.p3_legitimacy_projection_records (
    legitimacy_projection_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_universe_id uuid NOT NULL
        REFERENCES public.p3_projection_universes(projection_universe_id) ON DELETE RESTRICT,
    subject_node_id uuid NOT NULL
        REFERENCES public.p3_dependency_nodes(node_id) ON DELETE RESTRICT,
    source_policy_artifact_id uuid NULL
        REFERENCES public.p3_policy_artifacts(policy_artifact_id) ON DELETE RESTRICT,
    source_authority_lineage_id uuid NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    derived_state public.p3_legitimacy_projection_state NOT NULL,
    blocking_ancestor_node_id uuid NULL
        REFERENCES public.p3_dependency_nodes(node_id) ON DELETE RESTRICT,
    projection_context_hash text NOT NULL,
    mutability_class text NOT NULL DEFAULT 'supersedable_projection',
    replay_reconstruction_inputs jsonb NOT NULL DEFAULT '{}'::jsonb,
    projection_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    evaluated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(projection_context_hash) <> ''),
    CHECK (mutability_class = 'supersedable_projection'),
    CHECK (
        blocking_ancestor_node_id IS NULL
        OR blocking_ancestor_node_id <> subject_node_id
        OR derived_state = 'illegitimate'
    ),
    CHECK (jsonb_typeof(replay_reconstruction_inputs) = 'object'),
    CHECK (jsonb_typeof(projection_metadata) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_projection_universes_key
    ON public.p3_projection_universes (projection_universe_key, temporal_evaluation_point, projection_universe_id);

CREATE INDEX IF NOT EXISTS idx_p3_legitimacy_projection_subject
    ON public.p3_legitimacy_projection_records (projection_universe_id, subject_node_id, evaluated_at DESC, lineage_provenance_id);

CREATE INDEX IF NOT EXISTS idx_p3_legitimacy_projection_blocking
    ON public.p3_legitimacy_projection_records (blocking_ancestor_node_id)
    WHERE blocking_ancestor_node_id IS NOT NULL;

CREATE OR REPLACE VIEW public.p3_legitimacy_projection_manifest AS
SELECT
    u.projection_universe_id,
    u.projection_universe_key,
    u.projection_purpose,
    u.replay_algorithm_version,
    u.temporal_evaluation_point,
    u.lineage_provenance_id AS projection_universe_provenance_id,
    r.legitimacy_projection_record_id,
    r.subject_node_id,
    n.node_key AS subject_node_key,
    n.node_kind AS subject_node_kind,
    r.source_policy_artifact_id,
    p.artifact_key AS source_policy_artifact_key,
    r.source_authority_lineage_id,
    a.authority_key AS source_authority_key,
    r.derived_state,
    r.blocking_ancestor_node_id,
    b.node_key AS blocking_ancestor_node_key,
    r.projection_context_hash,
    r.mutability_class,
    r.lineage_provenance_id AS projection_record_provenance_id,
    r.evaluated_at
FROM public.p3_legitimacy_projection_records r
JOIN public.p3_projection_universes u
  ON u.projection_universe_id = r.projection_universe_id
JOIN public.p3_dependency_nodes n
  ON n.node_id = r.subject_node_id
LEFT JOIN public.p3_policy_artifacts p
  ON p.policy_artifact_id = r.source_policy_artifact_id
LEFT JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = r.source_authority_lineage_id
LEFT JOIN public.p3_dependency_nodes b
  ON b.node_id = r.blocking_ancestor_node_id;

CREATE OR REPLACE FUNCTION public.p3_evaluate_legitimacy_projection(
    p_projection_universe_key text,
    p_subject_node_id uuid
)
RETURNS TABLE (
    projection_universe_id uuid,
    projection_universe_key text,
    subject_node_id uuid,
    subject_node_key text,
    derived_state public.p3_legitimacy_projection_state,
    blocking_ancestor_node_id uuid,
    blocking_ancestor_node_key text,
    traversed_node_count integer,
    projection_universe_provenance_id uuid,
    subject_node_provenance_id uuid,
    traversal_path uuid[]
)
LANGUAGE sql
STABLE
AS $$
WITH RECURSIVE universe AS (
    SELECT
        u.projection_universe_id,
        u.projection_universe_key,
        u.lineage_provenance_id AS projection_universe_provenance_id
    FROM public.p3_projection_universes u
    WHERE u.projection_universe_key = p_projection_universe_key
),
subject_node AS (
    SELECT
        n.node_id AS subject_node_id,
        n.node_key AS subject_node_key,
        n.lineage_provenance_id AS subject_node_provenance_id
    FROM public.p3_dependency_nodes n
    WHERE n.node_id = p_subject_node_id
),
closure AS (
    SELECT
        0 AS depth,
        s.subject_node_id AS node_id,
        ARRAY[s.subject_node_id]::uuid[] AS traversal_path
    FROM subject_node s

    UNION ALL

    SELECT
        c.depth + 1,
        e.upstream_node_id AS node_id,
        c.traversal_path || e.upstream_node_id
    FROM closure c
    JOIN public.p3_dependency_edges e
      ON e.downstream_node_id = c.node_id
    WHERE NOT e.upstream_node_id = ANY (c.traversal_path)
),
ranked_projection_state AS (
    SELECT
        c.depth,
        c.node_id,
        c.traversal_path,
        n.node_key,
        r.derived_state,
        row_number() OVER (
            PARTITION BY c.node_id
            ORDER BY r.evaluated_at DESC, r.lineage_provenance_id
        ) AS projection_rank
    FROM closure c
    JOIN public.p3_dependency_nodes n
      ON n.node_id = c.node_id
    JOIN universe u
      ON TRUE
    LEFT JOIN public.p3_legitimacy_projection_records r
      ON r.projection_universe_id = u.projection_universe_id
     AND r.subject_node_id = c.node_id
),
latest_projection_state AS (
    SELECT
        depth,
        node_id,
        traversal_path,
        node_key,
        derived_state
    FROM ranked_projection_state
    WHERE projection_rank = 1
       OR projection_rank IS NULL
),
blocking AS (
    SELECT
        l.node_id AS blocking_ancestor_node_id,
        l.node_key AS blocking_ancestor_node_key,
        l.depth,
        l.traversal_path
    FROM latest_projection_state l
    WHERE l.derived_state = 'illegitimate'
    ORDER BY l.depth, l.node_key, l.node_id
    LIMIT 1
)
SELECT
    u.projection_universe_id,
    u.projection_universe_key,
    s.subject_node_id,
    s.subject_node_key,
    CASE
        WHEN b.blocking_ancestor_node_id IS NULL THEN 'legitimate'::public.p3_legitimacy_projection_state
        WHEN b.blocking_ancestor_node_id = s.subject_node_id THEN 'illegitimate'::public.p3_legitimacy_projection_state
        ELSE 'blocked'::public.p3_legitimacy_projection_state
    END AS derived_state,
    b.blocking_ancestor_node_id,
    b.blocking_ancestor_node_key,
    (SELECT COUNT(*) FROM closure)::integer AS traversed_node_count,
    u.projection_universe_provenance_id,
    s.subject_node_provenance_id,
    COALESCE(b.traversal_path, ARRAY[s.subject_node_id]::uuid[]) AS traversal_path
FROM universe u
JOIN subject_node s
  ON TRUE
LEFT JOIN blocking b
  ON TRUE;
$$;

CREATE OR REPLACE FUNCTION public.p3_assert_legitimacy_projection(
    p_projection_universe_key text,
    p_subject_node_id uuid
)
RETURNS void
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_evaluation record;
BEGIN
    SELECT *
    INTO v_evaluation
    FROM public.p3_evaluate_legitimacy_projection(
        p_projection_universe_key,
        p_subject_node_id
    );

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Projection universe % or subject node % not found',
            p_projection_universe_key,
            p_subject_node_id
            USING ERRCODE = 'P3002';
    END IF;

    IF v_evaluation.derived_state <> 'legitimate' THEN
        RAISE EXCEPTION
            'Recursive legitimacy blocked for node % in projection universe % by ancestor %',
            p_subject_node_id,
            p_projection_universe_key,
            v_evaluation.blocking_ancestor_node_id
            USING ERRCODE = 'P3002';
    END IF;
END;
$$;

COMMENT ON TABLE public.p3_projection_universes IS
    'Phase 3 projection-universe registry. Declares deterministic replay contexts for derived legitimacy and admissibility evaluation.';

COMMENT ON TABLE public.p3_legitimacy_projection_records IS
    'Phase 3 supersedable derived legitimacy records. Stores replay-derived legitimacy findings without mutating source lineage truth.';

COMMENT ON VIEW public.p3_legitimacy_projection_manifest IS
    'Deterministic manifest over Phase 3 projection universes and derived legitimacy records.';

COMMENT ON FUNCTION public.p3_evaluate_legitimacy_projection(text, uuid) IS
    'Deterministic recursive legitimacy evaluation for a subject dependency node within a declared projection universe.';

COMMENT ON FUNCTION public.p3_assert_legitimacy_projection(text, uuid) IS
    'Fail-closed legitimacy assertion wrapper. Raises SQLSTATE P3002 when the subject node or one of its ancestors is illegitimate within the declared projection universe.';
