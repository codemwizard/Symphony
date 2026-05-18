-- Migration: 0207_p3_typed_dependency_graph.sql
-- Task: TSK-P3-WP-001
-- Description: Establish the replay-authoritative typed dependency graph
--              substrate for Phase 3 dependency lineage traversal.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_dependency_node_kind'
    ) THEN
        CREATE TYPE public.p3_dependency_node_kind AS ENUM (
            'decision_record',
            'fact_record'
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
          AND t.typname = 'p3_dependency_edge_kind'
    ) THEN
        CREATE TYPE public.p3_dependency_edge_kind AS ENUM (
            'decision_input',
            'fact_input',
            'supporting_evidence',
            'calculation_basis',
            'temporal_predecessor'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_dependency_nodes (
    node_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    node_key text NOT NULL UNIQUE,
    node_kind public.p3_dependency_node_kind NOT NULL,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(node_key) <> '')
);

CREATE TABLE IF NOT EXISTS public.p3_dependency_edges (
    edge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    downstream_node_id uuid NOT NULL REFERENCES public.p3_dependency_nodes(node_id) ON DELETE RESTRICT,
    upstream_node_id uuid NOT NULL REFERENCES public.p3_dependency_nodes(node_id) ON DELETE RESTRICT,
    dependency_kind public.p3_dependency_edge_kind NOT NULL,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (downstream_node_id <> upstream_node_id),
    UNIQUE (downstream_node_id, upstream_node_id, dependency_kind)
);

CREATE INDEX IF NOT EXISTS idx_p3_dependency_edges_downstream
    ON public.p3_dependency_edges (downstream_node_id, dependency_kind, upstream_node_id);

CREATE INDEX IF NOT EXISTS idx_p3_dependency_edges_upstream
    ON public.p3_dependency_edges (upstream_node_id);

CREATE OR REPLACE VIEW public.p3_typed_dependency_adjacency AS
SELECT
    e.edge_id,
    e.downstream_node_id,
    d.node_key AS downstream_node_key,
    d.node_kind AS downstream_node_kind,
    e.upstream_node_id,
    u.node_key AS upstream_node_key,
    u.node_kind AS upstream_node_kind,
    e.dependency_kind,
    e.lineage_provenance_id AS edge_provenance_id,
    u.lineage_provenance_id AS upstream_node_provenance_id,
    e.declared_at
FROM public.p3_dependency_edges e
JOIN public.p3_dependency_nodes d
  ON d.node_id = e.downstream_node_id
JOIN public.p3_dependency_nodes u
  ON u.node_id = e.upstream_node_id;

CREATE OR REPLACE FUNCTION public.p3_collect_upstream_dependencies(p_root_node_id uuid)
RETURNS TABLE (
    root_node_id uuid,
    depth integer,
    downstream_node_id uuid,
    upstream_node_id uuid,
    dependency_kind public.p3_dependency_edge_kind,
    upstream_node_key text,
    upstream_node_kind public.p3_dependency_node_kind,
    edge_provenance_id uuid,
    upstream_node_provenance_id uuid,
    traversal_path uuid[]
)
LANGUAGE sql
STABLE
AS $$
WITH RECURSIVE closure AS (
    SELECT
        p_root_node_id AS root_node_id,
        1 AS depth,
        e.downstream_node_id,
        e.upstream_node_id,
        e.dependency_kind,
        e.lineage_provenance_id AS edge_provenance_id,
        ARRAY[e.downstream_node_id, e.upstream_node_id]::uuid[] AS traversal_path
    FROM public.p3_dependency_edges e
    WHERE e.downstream_node_id = p_root_node_id

    UNION ALL

    SELECT
        c.root_node_id,
        c.depth + 1,
        e.downstream_node_id,
        e.upstream_node_id,
        e.dependency_kind,
        e.lineage_provenance_id AS edge_provenance_id,
        c.traversal_path || e.upstream_node_id
    FROM closure c
    JOIN public.p3_dependency_edges e
      ON e.downstream_node_id = c.upstream_node_id
    WHERE NOT e.upstream_node_id = ANY (c.traversal_path)
)
SELECT
    c.root_node_id,
    c.depth,
    c.downstream_node_id,
    c.upstream_node_id,
    c.dependency_kind,
    n.node_key AS upstream_node_key,
    n.node_kind AS upstream_node_kind,
    c.edge_provenance_id,
    n.lineage_provenance_id AS upstream_node_provenance_id,
    c.traversal_path
FROM closure c
JOIN public.p3_dependency_nodes n
  ON n.node_id = c.upstream_node_id
ORDER BY
    c.depth,
    c.dependency_kind::text,
    n.node_key,
    c.upstream_node_id;
$$;

COMMENT ON TABLE public.p3_dependency_nodes IS
    'Phase 3 typed dependency graph node registry. Stores immutable lineage-safe identifiers for decision and fact records only.';

COMMENT ON TABLE public.p3_dependency_edges IS
    'Phase 3 typed dependency graph edge registry. Stores typed upstream dependencies with immutable provenance identifiers.';

COMMENT ON VIEW public.p3_typed_dependency_adjacency IS
    'Deterministic adjacency projection for Phase 3 typed dependency lineage traversal.';

COMMENT ON FUNCTION public.p3_collect_upstream_dependencies(uuid) IS
    'Deterministic recursive traversal primitive for replay-authoritative Phase 3 typed upstream dependency closure.';
