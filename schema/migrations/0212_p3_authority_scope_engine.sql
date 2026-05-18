-- Migration: 0212_p3_authority_scope_engine.sql
-- Task: TSK-P3-WP-006
-- Description: Establish the replay-authoritative authority-scope and
--              delegation enforcement substrate for Phase 3.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_authority_enforcement_state'
    ) THEN
        CREATE TYPE public.p3_authority_enforcement_state AS ENUM (
            'authorized',
            'out_of_scope',
            'revoked',
            'delegation_overflow'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_authority_scope_records (
    authority_scope_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_lineage_id uuid NOT NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    supporting_policy_artifact_id uuid NULL
        REFERENCES public.p3_policy_artifacts(policy_artifact_id) ON DELETE RESTRICT,
    supporting_dependency_node_id uuid NULL
        REFERENCES public.p3_dependency_nodes(node_id) ON DELETE RESTRICT,
    claimed_resource_scope text NOT NULL,
    claimed_act_scope text NOT NULL,
    evaluated_effective_at timestamptz NOT NULL,
    enforcement_state public.p3_authority_enforcement_state NOT NULL,
    resolved_root_authority_lineage_id uuid NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    blocking_authority_lineage_id uuid NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    delegation_depth integer NOT NULL DEFAULT 0,
    revocation_lineage_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(claimed_resource_scope) <> ''),
    CHECK (btrim(claimed_act_scope) <> ''),
    CHECK (delegation_depth >= 0),
    CHECK (jsonb_typeof(revocation_lineage_snapshot) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_authority_scope_records_authority
    ON public.p3_authority_scope_records (authority_lineage_id, evaluated_effective_at DESC, lineage_provenance_id);

CREATE INDEX IF NOT EXISTS idx_p3_authority_scope_records_dependency
    ON public.p3_authority_scope_records (supporting_dependency_node_id)
    WHERE supporting_dependency_node_id IS NOT NULL;

CREATE OR REPLACE VIEW public.p3_authority_scope_manifest AS
SELECT
    r.authority_scope_record_id,
    r.authority_lineage_id,
    a.authority_key,
    a.authority_source_kind,
    a.resource_scope AS declared_resource_scope,
    a.act_scope AS declared_act_scope,
    a.delegated_from_authority_lineage_id,
    a.revoked_by_authority_lineage_id,
    r.supporting_policy_artifact_id,
    p.artifact_key AS supporting_policy_artifact_key,
    r.supporting_dependency_node_id,
    n.node_key AS supporting_dependency_node_key,
    r.claimed_resource_scope,
    r.claimed_act_scope,
    r.evaluated_effective_at,
    r.enforcement_state,
    r.resolved_root_authority_lineage_id,
    root_authority.authority_key AS resolved_root_authority_key,
    r.blocking_authority_lineage_id,
    blocking_authority.authority_key AS blocking_authority_key,
    r.delegation_depth,
    r.revocation_lineage_snapshot,
    r.lineage_provenance_id,
    r.created_at
FROM public.p3_authority_scope_records r
JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = r.authority_lineage_id
LEFT JOIN public.p3_policy_artifacts p
  ON p.policy_artifact_id = r.supporting_policy_artifact_id
LEFT JOIN public.p3_dependency_nodes n
  ON n.node_id = r.supporting_dependency_node_id
LEFT JOIN public.p3_authority_lineage root_authority
  ON root_authority.authority_lineage_id = r.resolved_root_authority_lineage_id
LEFT JOIN public.p3_authority_lineage blocking_authority
  ON blocking_authority.authority_lineage_id = r.blocking_authority_lineage_id;

CREATE OR REPLACE FUNCTION public.p3_evaluate_authority_scope(
    p_authority_lineage_id uuid,
    p_claimed_resource_scope text,
    p_claimed_act_scope text,
    p_evaluated_effective_at timestamptz
)
RETURNS TABLE (
    authority_lineage_id uuid,
    enforcement_state public.p3_authority_enforcement_state,
    resolved_root_authority_lineage_id uuid,
    blocking_authority_lineage_id uuid,
    delegation_depth integer,
    authority_lineage_provenance_id uuid,
    revocation_lineage_snapshot jsonb,
    traversal_path uuid[]
)
LANGUAGE sql
STABLE
AS $$
WITH RECURSIVE authority_chain AS (
    SELECT
        1 AS depth,
        a.authority_lineage_id,
        a.delegated_from_authority_lineage_id,
        a.revoked_by_authority_lineage_id,
        a.resource_scope,
        a.act_scope,
        a.effective_from,
        a.effective_to,
        a.lineage_provenance_id,
        ARRAY[a.authority_lineage_id]::uuid[] AS traversal_path
    FROM public.p3_authority_lineage a
    WHERE a.authority_lineage_id = p_authority_lineage_id

    UNION ALL

    SELECT
        c.depth + 1,
        a.authority_lineage_id,
        a.delegated_from_authority_lineage_id,
        a.revoked_by_authority_lineage_id,
        a.resource_scope,
        a.act_scope,
        a.effective_from,
        a.effective_to,
        a.lineage_provenance_id,
        c.traversal_path || a.authority_lineage_id
    FROM authority_chain c
    JOIN public.p3_authority_lineage a
      ON a.authority_lineage_id = c.delegated_from_authority_lineage_id
    WHERE NOT a.authority_lineage_id = ANY (c.traversal_path)
),
summary AS (
    SELECT
        c.authority_lineage_id AS root_authority_lineage_id,
        c.lineage_provenance_id AS root_authority_lineage_provenance_id,
        c.traversal_path AS root_traversal_path
    FROM authority_chain c
    WHERE c.delegated_from_authority_lineage_id IS NULL
    ORDER BY c.depth DESC, c.authority_lineage_id
    LIMIT 1
),
violations AS (
    SELECT
        CASE
            WHEN c.revoked_by_authority_lineage_id IS NOT NULL THEN 'revoked'::public.p3_authority_enforcement_state
            WHEN c.resource_scope <> p_claimed_resource_scope
              OR c.act_scope <> p_claimed_act_scope THEN
                CASE
                    WHEN c.depth = 1 THEN 'out_of_scope'::public.p3_authority_enforcement_state
                    ELSE 'delegation_overflow'::public.p3_authority_enforcement_state
                END
            WHEN p_evaluated_effective_at < c.effective_from
              OR (c.effective_to IS NOT NULL AND p_evaluated_effective_at >= c.effective_to) THEN 'out_of_scope'::public.p3_authority_enforcement_state
            ELSE NULL::public.p3_authority_enforcement_state
        END AS violation_state,
        c.authority_lineage_id AS blocking_authority_lineage_id,
        c.depth,
        c.traversal_path,
        c.revoked_by_authority_lineage_id
    FROM authority_chain c
),
first_violation AS (
    SELECT
        v.violation_state,
        v.blocking_authority_lineage_id,
        v.depth,
        v.traversal_path,
        v.revoked_by_authority_lineage_id
    FROM violations v
    WHERE v.violation_state IS NOT NULL
    ORDER BY
        CASE v.violation_state
            WHEN 'revoked' THEN 1
            WHEN 'delegation_overflow' THEN 2
            WHEN 'out_of_scope' THEN 3
            ELSE 4
        END,
        v.depth,
        v.blocking_authority_lineage_id
    LIMIT 1
)
SELECT
    p_authority_lineage_id AS authority_lineage_id,
    COALESCE(v.violation_state, 'authorized'::public.p3_authority_enforcement_state) AS enforcement_state,
    s.root_authority_lineage_id AS resolved_root_authority_lineage_id,
    v.blocking_authority_lineage_id,
    COALESCE((SELECT max(depth) FROM authority_chain), 0)::integer AS delegation_depth,
    COALESCE(s.root_authority_lineage_provenance_id, a.lineage_provenance_id) AS authority_lineage_provenance_id,
    CASE
        WHEN v.violation_state = 'revoked' THEN jsonb_build_object(
            'revoked_by_authority_lineage_id',
            v.revoked_by_authority_lineage_id
        )
        ELSE '{}'::jsonb
    END AS revocation_lineage_snapshot,
    COALESCE(v.traversal_path, s.root_traversal_path, ARRAY[p_authority_lineage_id]::uuid[]) AS traversal_path
FROM public.p3_authority_lineage a
LEFT JOIN summary s
  ON TRUE
LEFT JOIN first_violation v
  ON TRUE
WHERE a.authority_lineage_id = p_authority_lineage_id;
$$;

CREATE OR REPLACE FUNCTION public.p3_assert_authority_scope(
    p_authority_lineage_id uuid,
    p_claimed_resource_scope text,
    p_claimed_act_scope text,
    p_evaluated_effective_at timestamptz
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
    FROM public.p3_evaluate_authority_scope(
        p_authority_lineage_id,
        p_claimed_resource_scope,
        p_claimed_act_scope,
        p_evaluated_effective_at
    );

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Authority lineage % not found',
            p_authority_lineage_id
            USING ERRCODE = 'P3006';
    END IF;

    IF v_evaluation.enforcement_state <> 'authorized' THEN
        RAISE EXCEPTION
            'Authority scope blocked for lineage % at resource % / act % with state %',
            p_authority_lineage_id,
            p_claimed_resource_scope,
            p_claimed_act_scope,
            v_evaluation.enforcement_state
            USING ERRCODE = 'P3006';
    END IF;
END;
$$;

COMMENT ON TABLE public.p3_authority_scope_records IS
    'Phase 3 authority-scope enforcement records. Stores replay-authoritative, revocable authority-evaluation outcomes anchored to canonical policy, authority, and dependency lineage.';

COMMENT ON VIEW public.p3_authority_scope_manifest IS
    'Deterministic manifest over Phase 3 authority-scope enforcement records and their canonical lineage anchors.';

COMMENT ON FUNCTION public.p3_evaluate_authority_scope(uuid, text, text, timestamptz) IS
    'Deterministic evaluation of an authority claim against declared scope, effective-time windows, revocation lineage, and delegation overflow boundaries.';

COMMENT ON FUNCTION public.p3_assert_authority_scope(uuid, text, text, timestamptz) IS
    'Fail-closed authority scope assertion wrapper. Raises SQLSTATE P3006 when the authority claim is out of scope, revoked, or exceeds the delegator''s declared authority.';
