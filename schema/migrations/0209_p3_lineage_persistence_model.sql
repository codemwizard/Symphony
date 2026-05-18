-- Migration: 0209_p3_lineage_persistence_model.sql
-- Task: TSK-P3-SUPPORT-DB-001
-- Description: Establish the shared persistence model for Phase 3 dependency,
--              policy, and authority lineage surfaces.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_lineage_surface_id'
    ) THEN
        CREATE TYPE public.p3_lineage_surface_id AS ENUM (
            'P3-SURF-001',
            'P3-SURF-002'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_lineage_continuity_anchors (
    continuity_anchor_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    surface_id public.p3_lineage_surface_id NOT NULL,
    artifact_kind text NOT NULL,
    artifact_locator text NOT NULL,
    lineage_provenance_id uuid NOT NULL,
    continuity_scope text NOT NULL,
    replay_reconstruction_inputs jsonb NOT NULL DEFAULT '{}'::jsonb,
    phase2_compatibility_intent text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (surface_id, lineage_provenance_id, artifact_kind),
    CHECK (btrim(artifact_kind) <> ''),
    CHECK (btrim(artifact_locator) <> ''),
    CHECK (btrim(continuity_scope) <> ''),
    CHECK (btrim(phase2_compatibility_intent) <> ''),
    CHECK (jsonb_typeof(replay_reconstruction_inputs) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_lineage_continuity_surface
    ON public.p3_lineage_continuity_anchors (surface_id, artifact_kind, created_at);

CREATE OR REPLACE FUNCTION public.p3_deny_lineage_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 lineage persistence is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3901';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_dependency_nodes_mutation ON public.p3_dependency_nodes;
CREATE TRIGGER trg_deny_p3_dependency_nodes_mutation
BEFORE UPDATE OR DELETE ON public.p3_dependency_nodes
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_lineage_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_dependency_edges_mutation ON public.p3_dependency_edges;
CREATE TRIGGER trg_deny_p3_dependency_edges_mutation
BEFORE UPDATE OR DELETE ON public.p3_dependency_edges
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_lineage_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_authority_lineage_mutation ON public.p3_authority_lineage;
CREATE TRIGGER trg_deny_p3_authority_lineage_mutation
BEFORE UPDATE OR DELETE ON public.p3_authority_lineage
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_lineage_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_policy_artifacts_mutation ON public.p3_policy_artifacts;
CREATE TRIGGER trg_deny_p3_policy_artifacts_mutation
BEFORE UPDATE OR DELETE ON public.p3_policy_artifacts
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_lineage_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_lineage_continuity_anchors_mutation ON public.p3_lineage_continuity_anchors;
CREATE TRIGGER trg_deny_p3_lineage_continuity_anchors_mutation
BEFORE UPDATE OR DELETE ON public.p3_lineage_continuity_anchors
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_lineage_mutation();

CREATE OR REPLACE VIEW public.p3_lineage_persistence_manifest AS
SELECT
    'P3-SURF-001'::public.p3_lineage_surface_id AS surface_id,
    'dependency_node'::text AS artifact_kind,
    n.node_id AS primary_record_id,
    n.lineage_provenance_id,
    n.declared_at AS effective_from,
    NULL::timestamptz AS effective_to,
    NULL::text AS resource_scope,
    NULL::text AS act_scope
FROM public.p3_dependency_nodes n

UNION ALL

SELECT
    'P3-SURF-001'::public.p3_lineage_surface_id AS surface_id,
    'dependency_edge'::text AS artifact_kind,
    e.edge_id AS primary_record_id,
    e.lineage_provenance_id,
    e.declared_at AS effective_from,
    NULL::timestamptz AS effective_to,
    NULL::text AS resource_scope,
    NULL::text AS act_scope
FROM public.p3_dependency_edges e

UNION ALL

SELECT
    'P3-SURF-002'::public.p3_lineage_surface_id AS surface_id,
    'authority_lineage'::text AS artifact_kind,
    a.authority_lineage_id AS primary_record_id,
    a.lineage_provenance_id,
    a.effective_from,
    a.effective_to,
    a.resource_scope,
    a.act_scope
FROM public.p3_authority_lineage a

UNION ALL

SELECT
    'P3-SURF-002'::public.p3_lineage_surface_id AS surface_id,
    'policy_artifact'::text AS artifact_kind,
    p.policy_artifact_id AS primary_record_id,
    p.lineage_provenance_id,
    p.effective_from,
    p.effective_to,
    p.resource_scope,
    p.act_scope
FROM public.p3_policy_artifacts p

UNION ALL

SELECT
    c.surface_id,
    'continuity_anchor'::text AS artifact_kind,
    c.continuity_anchor_id AS primary_record_id,
    c.lineage_provenance_id,
    c.created_at AS effective_from,
    NULL::timestamptz AS effective_to,
    c.continuity_scope AS resource_scope,
    NULL::text AS act_scope
FROM public.p3_lineage_continuity_anchors c;

COMMENT ON TABLE public.p3_lineage_continuity_anchors IS
    'Phase 3 continuity anchors for replay-survivable exchange of dependency, policy, and authority lineage artifacts across internal boundaries.';

COMMENT ON FUNCTION public.p3_deny_lineage_mutation() IS
    'Shared append-only enforcement for Phase 3 lineage persistence tables.';

COMMENT ON VIEW public.p3_lineage_persistence_manifest IS
    'Unified persistence manifest over Phase 3 dependency, policy, authority, and continuity-anchor lineage artifacts.';
