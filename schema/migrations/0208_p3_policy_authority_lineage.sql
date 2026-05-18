-- Migration: 0208_p3_policy_authority_lineage.sql
-- Task: TSK-P3-WP-002
-- Description: Establish the replay-authoritative policy artifact and authority
--              lineage substrate for Phase 3 policy and authority reconstruction.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_policy_artifact_class'
    ) THEN
        CREATE TYPE public.p3_policy_artifact_class AS ENUM (
            'constraint_policy',
            'authority_policy',
            'precedence_policy',
            'contradiction_policy',
            'replay_policy',
            'projection_policy',
            'spatial_policy',
            'failure_policy'
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
          AND t.typname = 'p3_authority_source_kind'
    ) THEN
        CREATE TYPE public.p3_authority_source_kind AS ENUM (
            'constitutional_document',
            'regulator_instrument',
            'delegated_authority',
            'policy_bound_authority'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_authority_lineage (
    authority_lineage_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_key text NOT NULL UNIQUE,
    authority_source_kind public.p3_authority_source_kind NOT NULL,
    source_reference text NOT NULL,
    delegated_from_authority_lineage_id uuid NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    revoked_by_authority_lineage_id uuid NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    revocation_lineage_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    resource_scope text NOT NULL,
    act_scope text NOT NULL,
    jurisdiction_scope text NULL,
    effective_from timestamptz NOT NULL,
    effective_to timestamptz NULL,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(authority_key) <> ''),
    CHECK (btrim(source_reference) <> ''),
    CHECK (btrim(resource_scope) <> ''),
    CHECK (btrim(act_scope) <> ''),
    CHECK (effective_to IS NULL OR effective_to > effective_from),
    CHECK (
        delegated_from_authority_lineage_id IS NULL
        OR delegated_from_authority_lineage_id <> authority_lineage_id
    ),
    CHECK (
        revoked_by_authority_lineage_id IS NULL
        OR revoked_by_authority_lineage_id <> authority_lineage_id
    ),
    CHECK (jsonb_typeof(revocation_lineage_metadata) = 'object')
);

CREATE TABLE IF NOT EXISTS public.p3_policy_artifacts (
    policy_artifact_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    artifact_key text NOT NULL UNIQUE,
    artifact_class public.p3_policy_artifact_class NOT NULL,
    source_authority_lineage_id uuid NOT NULL
        REFERENCES public.p3_authority_lineage(authority_lineage_id) ON DELETE RESTRICT,
    artifact_version text NOT NULL,
    effective_from timestamptz NOT NULL,
    effective_to timestamptz NULL,
    supersedes_policy_artifact_id uuid NULL
        REFERENCES public.p3_policy_artifacts(policy_artifact_id) ON DELETE RESTRICT,
    revoked_by_policy_artifact_id uuid NULL
        REFERENCES public.p3_policy_artifacts(policy_artifact_id) ON DELETE RESTRICT,
    jurisdiction_scope text NULL,
    resource_scope text NOT NULL,
    act_scope text NOT NULL,
    replay_reconstruction_hints jsonb NOT NULL DEFAULT '{}'::jsonb,
    lineage_provenance_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    declared_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(artifact_key) <> ''),
    CHECK (btrim(artifact_version) <> ''),
    CHECK (btrim(resource_scope) <> ''),
    CHECK (btrim(act_scope) <> ''),
    CHECK (effective_to IS NULL OR effective_to > effective_from),
    CHECK (
        supersedes_policy_artifact_id IS NULL
        OR supersedes_policy_artifact_id <> policy_artifact_id
    ),
    CHECK (
        revoked_by_policy_artifact_id IS NULL
        OR revoked_by_policy_artifact_id <> policy_artifact_id
    ),
    CHECK (jsonb_typeof(replay_reconstruction_hints) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_p3_authority_lineage_delegated_from
    ON public.p3_authority_lineage (delegated_from_authority_lineage_id);

CREATE INDEX IF NOT EXISTS idx_p3_authority_lineage_scope_time
    ON public.p3_authority_lineage (resource_scope, act_scope, effective_from, authority_key);

CREATE INDEX IF NOT EXISTS idx_p3_policy_artifacts_source_authority
    ON public.p3_policy_artifacts (source_authority_lineage_id, effective_from, artifact_key);

CREATE INDEX IF NOT EXISTS idx_p3_policy_artifacts_scope_time
    ON public.p3_policy_artifacts (resource_scope, act_scope, effective_from, artifact_key);

CREATE OR REPLACE VIEW public.p3_policy_authority_lineage_projection AS
SELECT
    p.policy_artifact_id,
    p.artifact_key,
    p.artifact_class,
    p.artifact_version,
    p.effective_from AS policy_effective_from,
    p.effective_to AS policy_effective_to,
    p.resource_scope AS policy_resource_scope,
    p.act_scope AS policy_act_scope,
    p.jurisdiction_scope AS policy_jurisdiction_scope,
    p.lineage_provenance_id AS policy_provenance_id,
    a.authority_lineage_id,
    a.authority_key,
    a.authority_source_kind,
    a.source_reference,
    a.delegated_from_authority_lineage_id,
    a.revoked_by_authority_lineage_id,
    a.revocation_lineage_metadata,
    a.resource_scope AS authority_resource_scope,
    a.act_scope AS authority_act_scope,
    a.jurisdiction_scope AS authority_jurisdiction_scope,
    a.effective_from AS authority_effective_from,
    a.effective_to AS authority_effective_to,
    a.lineage_provenance_id AS authority_provenance_id
FROM public.p3_policy_artifacts p
JOIN public.p3_authority_lineage a
  ON a.authority_lineage_id = p.source_authority_lineage_id;

CREATE OR REPLACE FUNCTION public.p3_collect_policy_authority_lineage(p_policy_artifact_id uuid)
RETURNS TABLE (
    policy_artifact_id uuid,
    artifact_key text,
    artifact_class public.p3_policy_artifact_class,
    artifact_version text,
    depth integer,
    authority_lineage_id uuid,
    authority_key text,
    authority_source_kind public.p3_authority_source_kind,
    delegated_from_authority_lineage_id uuid,
    authority_resource_scope text,
    authority_act_scope text,
    authority_effective_from timestamptz,
    authority_effective_to timestamptz,
    authority_provenance_id uuid,
    policy_provenance_id uuid,
    traversal_path uuid[]
)
LANGUAGE sql
STABLE
AS $$
WITH RECURSIVE authority_chain AS (
    SELECT
        p.policy_artifact_id,
        p.artifact_key,
        p.artifact_class,
        p.artifact_version,
        1 AS depth,
        a.authority_lineage_id,
        a.authority_key,
        a.authority_source_kind,
        a.delegated_from_authority_lineage_id,
        a.resource_scope AS authority_resource_scope,
        a.act_scope AS authority_act_scope,
        a.effective_from AS authority_effective_from,
        a.effective_to AS authority_effective_to,
        a.lineage_provenance_id AS authority_provenance_id,
        p.lineage_provenance_id AS policy_provenance_id,
        ARRAY[a.authority_lineage_id]::uuid[] AS traversal_path
    FROM public.p3_policy_artifacts p
    JOIN public.p3_authority_lineage a
      ON a.authority_lineage_id = p.source_authority_lineage_id
    WHERE p.policy_artifact_id = p_policy_artifact_id

    UNION ALL

    SELECT
        c.policy_artifact_id,
        c.artifact_key,
        c.artifact_class,
        c.artifact_version,
        c.depth + 1,
        a.authority_lineage_id,
        a.authority_key,
        a.authority_source_kind,
        a.delegated_from_authority_lineage_id,
        a.resource_scope AS authority_resource_scope,
        a.act_scope AS authority_act_scope,
        a.effective_from AS authority_effective_from,
        a.effective_to AS authority_effective_to,
        a.lineage_provenance_id AS authority_provenance_id,
        c.policy_provenance_id,
        c.traversal_path || a.authority_lineage_id
    FROM authority_chain c
    JOIN public.p3_authority_lineage a
      ON a.authority_lineage_id = c.delegated_from_authority_lineage_id
    WHERE NOT a.authority_lineage_id = ANY (c.traversal_path)
)
SELECT
    c.policy_artifact_id,
    c.artifact_key,
    c.artifact_class,
    c.artifact_version,
    c.depth,
    c.authority_lineage_id,
    c.authority_key,
    c.authority_source_kind,
    c.delegated_from_authority_lineage_id,
    c.authority_resource_scope,
    c.authority_act_scope,
    c.authority_effective_from,
    c.authority_effective_to,
    c.authority_provenance_id,
    c.policy_provenance_id,
    c.traversal_path
FROM authority_chain c
ORDER BY
    c.depth,
    c.authority_key,
    c.authority_lineage_id;
$$;

COMMENT ON TABLE public.p3_authority_lineage IS
    'Phase 3 authority-lineage substrate. Stores replay-addressable authority scope, delegation ancestry, revocation metadata, and immutable provenance identifiers.';

COMMENT ON TABLE public.p3_policy_artifacts IS
    'Phase 3 policy-artifact lineage substrate. Stores versioned replay-authoritative policy artifacts linked to declared authority lineage.';

COMMENT ON VIEW public.p3_policy_authority_lineage_projection IS
    'Deterministic join projection between policy artifacts and their source authority lineage records.';

COMMENT ON FUNCTION public.p3_collect_policy_authority_lineage(uuid) IS
    'Deterministic authority-lineage traversal for a single Phase 3 policy artifact.';
