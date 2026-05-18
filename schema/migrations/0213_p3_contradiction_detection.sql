-- Migration: 0213_p3_contradiction_detection.sql
-- Task: TSK-P3-WP-004
-- Description: Establish the replay-aware contradiction detection substrate for
--              direct, temporal, and authority-scope contradiction classes.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
          AND t.typname = 'p3_contradiction_class'
    ) THEN
        CREATE TYPE public.p3_contradiction_class AS ENUM (
            'direct',
            'temporal',
            'authority_scope'
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
          AND t.typname = 'p3_contradiction_resolution_state'
    ) THEN
        CREATE TYPE public.p3_contradiction_resolution_state AS ENUM (
            'contradiction_detected',
            'quarantined',
            'superseded',
            'escalation_required'
        );
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.p3_contradiction_claims (
    contradiction_claim_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_dependency_node_id uuid NOT NULL REFERENCES public.p3_dependency_nodes (node_id),
    source_authority_lineage_id uuid REFERENCES public.p3_authority_lineage (authority_lineage_id),
    source_policy_artifact_id uuid REFERENCES public.p3_policy_artifacts (policy_artifact_id),
    projection_universe_id uuid REFERENCES public.p3_projection_universes (projection_universe_id),
    resource_key text NOT NULL,
    fact_key text NOT NULL,
    asserted_value text NOT NULL,
    effective_from timestamptz NOT NULL,
    effective_to timestamptz,
    claimed_resource_scope text,
    claimed_act_scope text,
    declared_order_at timestamptz NOT NULL DEFAULT now(),
    declared_tie_break_key text NOT NULL,
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (btrim(resource_key) <> ''),
    CHECK (btrim(fact_key) <> ''),
    CHECK (btrim(asserted_value) <> ''),
    CHECK (btrim(declared_tie_break_key) <> ''),
    CHECK (effective_to IS NULL OR effective_to > effective_from)
);

CREATE INDEX IF NOT EXISTS idx_p3_contradiction_claims_resource_fact
    ON public.p3_contradiction_claims (resource_key, fact_key, effective_from, declared_order_at);

CREATE TABLE IF NOT EXISTS public.p3_contradiction_records (
    contradiction_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    contradiction_class public.p3_contradiction_class NOT NULL,
    primary_claim_id uuid NOT NULL REFERENCES public.p3_contradiction_claims (contradiction_claim_id),
    conflicting_claim_id uuid REFERENCES public.p3_contradiction_claims (contradiction_claim_id),
    resolution_state public.p3_contradiction_resolution_state NOT NULL,
    mutability_class text NOT NULL DEFAULT 'immutable_lineage',
    authority_transfer_mode text NOT NULL DEFAULT 'AT-SHARED',
    authority_transfer_purpose text NOT NULL DEFAULT 'contradiction_adjudication',
    canonical_order_at timestamptz NOT NULL,
    tie_break_key text NOT NULL,
    contradiction_reason text NOT NULL,
    replay_context_hash text NOT NULL,
    quarantine_required boolean NOT NULL DEFAULT false,
    lineage_provenance_id uuid NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mutability_class IN ('immutable_lineage', 'compensating_lineage')),
    CHECK (authority_transfer_mode IN ('AT-EXCLUSIVE', 'AT-SHARED', 'AT-DELEGATED', 'AT-ADVISORY')),
    CHECK (btrim(authority_transfer_purpose) <> ''),
    CHECK (btrim(tie_break_key) <> ''),
    CHECK (btrim(contradiction_reason) <> ''),
    CHECK (btrim(replay_context_hash) <> ''),
    CHECK (conflicting_claim_id IS NULL OR primary_claim_id <> conflicting_claim_id)
);

CREATE INDEX IF NOT EXISTS idx_p3_contradiction_records_class_state
    ON public.p3_contradiction_records (contradiction_class, resolution_state, canonical_order_at);

CREATE TABLE IF NOT EXISTS public.p3_quarantine_records (
    quarantine_record_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    contradiction_record_id uuid NOT NULL UNIQUE REFERENCES public.p3_contradiction_records (contradiction_record_id),
    subject_claim_id uuid NOT NULL REFERENCES public.p3_contradiction_claims (contradiction_claim_id),
    mutability_class text NOT NULL DEFAULT 'quarantined_state',
    quarantine_reason text NOT NULL,
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mutability_class = 'quarantined_state'),
    CHECK (btrim(quarantine_reason) <> '')
);

CREATE TABLE IF NOT EXISTS public.p3_contradiction_supersessions (
    contradiction_supersession_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    prior_contradiction_record_id uuid NOT NULL REFERENCES public.p3_contradiction_records (contradiction_record_id),
    superseding_contradiction_record_id uuid NOT NULL REFERENCES public.p3_contradiction_records (contradiction_record_id),
    mutability_class text NOT NULL DEFAULT 'compensating_lineage',
    supersession_reason text NOT NULL,
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mutability_class = 'compensating_lineage'),
    CHECK (prior_contradiction_record_id <> superseding_contradiction_record_id),
    CHECK (btrim(supersession_reason) <> '')
);

CREATE TABLE IF NOT EXISTS public.p3_contradiction_escalations (
    contradiction_escalation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    contradiction_record_id uuid NOT NULL REFERENCES public.p3_contradiction_records (contradiction_record_id),
    receiving_surface_id text NOT NULL,
    authority_transfer_mode text NOT NULL,
    authority_transfer_purpose text NOT NULL,
    mutability_class text NOT NULL DEFAULT 'supersedable_projection',
    lineage_provenance_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mutability_class = 'supersedable_projection'),
    CHECK (authority_transfer_mode IN ('AT-EXCLUSIVE', 'AT-SHARED', 'AT-DELEGATED', 'AT-ADVISORY')),
    CHECK (btrim(receiving_surface_id) <> ''),
    CHECK (btrim(authority_transfer_purpose) <> '')
);

CREATE OR REPLACE FUNCTION public.p3_deny_contradiction_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Phase 3 contradiction substrate is append-only for %', TG_TABLE_NAME
        USING ERRCODE = 'P3009';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_p3_contradiction_claims_mutation ON public.p3_contradiction_claims;
CREATE TRIGGER trg_deny_p3_contradiction_claims_mutation
BEFORE UPDATE OR DELETE ON public.p3_contradiction_claims
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_contradiction_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_contradiction_records_mutation ON public.p3_contradiction_records;
CREATE TRIGGER trg_deny_p3_contradiction_records_mutation
BEFORE UPDATE OR DELETE ON public.p3_contradiction_records
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_contradiction_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_quarantine_records_mutation ON public.p3_quarantine_records;
CREATE TRIGGER trg_deny_p3_quarantine_records_mutation
BEFORE UPDATE OR DELETE ON public.p3_quarantine_records
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_contradiction_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_contradiction_supersessions_mutation ON public.p3_contradiction_supersessions;
CREATE TRIGGER trg_deny_p3_contradiction_supersessions_mutation
BEFORE UPDATE OR DELETE ON public.p3_contradiction_supersessions
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_contradiction_mutation();

DROP TRIGGER IF EXISTS trg_deny_p3_contradiction_escalations_mutation ON public.p3_contradiction_escalations;
CREATE TRIGGER trg_deny_p3_contradiction_escalations_mutation
BEFORE UPDATE OR DELETE ON public.p3_contradiction_escalations
FOR EACH ROW
EXECUTE FUNCTION public.p3_deny_contradiction_mutation();

CREATE OR REPLACE FUNCTION public.p3_assert_contradiction_claim(
    p_source_dependency_node_id uuid,
    p_source_authority_lineage_id uuid,
    p_source_policy_artifact_id uuid,
    p_projection_universe_id uuid,
    p_resource_key text,
    p_fact_key text,
    p_asserted_value text,
    p_effective_from timestamptz,
    p_effective_to timestamptz,
    p_claimed_resource_scope text,
    p_claimed_act_scope text,
    p_declared_order_at timestamptz,
    p_declared_tie_break_key text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_claim_id uuid;
    v_authority_state public.p3_authority_enforcement_state;
BEGIN
    IF p_source_authority_lineage_id IS NOT NULL
       AND p_claimed_resource_scope IS NOT NULL
       AND p_claimed_act_scope IS NOT NULL THEN
        SELECT enforcement_state
        INTO v_authority_state
        FROM public.p3_evaluate_authority_scope(
            p_source_authority_lineage_id,
            p_claimed_resource_scope,
            p_claimed_act_scope,
            p_effective_from
        );

        IF v_authority_state <> 'authorized' THEN
            RAISE EXCEPTION 'authority-scope contradiction for %, %', p_resource_key, p_fact_key
                USING ERRCODE = 'P3005';
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.p3_contradiction_claims c
        WHERE c.resource_key = p_resource_key
          AND c.fact_key = p_fact_key
          AND c.effective_from = p_effective_from
          AND COALESCE(c.effective_to, 'infinity'::timestamptz) = COALESCE(p_effective_to, 'infinity'::timestamptz)
          AND c.asserted_value <> p_asserted_value
    ) THEN
        RAISE EXCEPTION 'direct contradiction for %, %', p_resource_key, p_fact_key
            USING ERRCODE = 'P3003';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.p3_contradiction_claims c
        WHERE c.resource_key = p_resource_key
          AND c.fact_key = p_fact_key
          AND c.asserted_value <> p_asserted_value
          AND tstzrange(c.effective_from, COALESCE(c.effective_to, 'infinity'::timestamptz), '[)')
              && tstzrange(p_effective_from, COALESCE(p_effective_to, 'infinity'::timestamptz), '[)')
    ) THEN
        RAISE EXCEPTION 'temporal contradiction for %, %', p_resource_key, p_fact_key
            USING ERRCODE = 'P3004';
    END IF;

    INSERT INTO public.p3_contradiction_claims (
        source_dependency_node_id,
        source_authority_lineage_id,
        source_policy_artifact_id,
        projection_universe_id,
        resource_key,
        fact_key,
        asserted_value,
        effective_from,
        effective_to,
        claimed_resource_scope,
        claimed_act_scope,
        declared_order_at,
        declared_tie_break_key,
        lineage_provenance_id
    ) VALUES (
        p_source_dependency_node_id,
        p_source_authority_lineage_id,
        p_source_policy_artifact_id,
        p_projection_universe_id,
        p_resource_key,
        p_fact_key,
        p_asserted_value,
        p_effective_from,
        p_effective_to,
        p_claimed_resource_scope,
        p_claimed_act_scope,
        p_declared_order_at,
        p_declared_tie_break_key,
        p_lineage_provenance_id
    )
    RETURNING contradiction_claim_id INTO v_claim_id;

    RETURN v_claim_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_contradiction_finding(
    p_contradiction_class public.p3_contradiction_class,
    p_primary_claim_id uuid,
    p_conflicting_claim_id uuid,
    p_resolution_state public.p3_contradiction_resolution_state,
    p_contradiction_reason text,
    p_replay_context_hash text,
    p_lineage_provenance_id uuid,
    p_authority_transfer_mode text DEFAULT 'AT-SHARED',
    p_authority_transfer_purpose text DEFAULT 'contradiction_adjudication',
    p_receiving_surface_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_primary public.p3_contradiction_claims%ROWTYPE;
    v_conflicting public.p3_contradiction_claims%ROWTYPE;
    v_contradiction_record_id uuid;
    v_canonical_order_at timestamptz;
    v_tie_break_key text;
BEGIN
    SELECT * INTO v_primary
    FROM public.p3_contradiction_claims
    WHERE contradiction_claim_id = p_primary_claim_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'primary contradiction claim not found: %', p_primary_claim_id
            USING ERRCODE = 'P3003';
    END IF;

    IF p_conflicting_claim_id IS NOT NULL THEN
        SELECT * INTO v_conflicting
        FROM public.p3_contradiction_claims
        WHERE contradiction_claim_id = p_conflicting_claim_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'conflicting contradiction claim not found: %', p_conflicting_claim_id
                USING ERRCODE = 'P3003';
        END IF;
        v_canonical_order_at := LEAST(v_primary.declared_order_at, v_conflicting.declared_order_at);
        v_tie_break_key := LEAST(v_primary.declared_tie_break_key, v_conflicting.declared_tie_break_key)
            || '::'
            || GREATEST(v_primary.declared_tie_break_key, v_conflicting.declared_tie_break_key);
    ELSE
        v_canonical_order_at := v_primary.declared_order_at;
        v_tie_break_key := v_primary.declared_tie_break_key;
    END IF;

    INSERT INTO public.p3_contradiction_records (
        contradiction_class,
        primary_claim_id,
        conflicting_claim_id,
        resolution_state,
        authority_transfer_mode,
        authority_transfer_purpose,
        canonical_order_at,
        tie_break_key,
        contradiction_reason,
        replay_context_hash,
        quarantine_required,
        lineage_provenance_id
    ) VALUES (
        p_contradiction_class,
        p_primary_claim_id,
        p_conflicting_claim_id,
        p_resolution_state,
        p_authority_transfer_mode,
        p_authority_transfer_purpose,
        v_canonical_order_at,
        v_tie_break_key,
        p_contradiction_reason,
        p_replay_context_hash,
        p_resolution_state = 'quarantined',
        p_lineage_provenance_id
    )
    RETURNING contradiction_record_id INTO v_contradiction_record_id;

    IF p_resolution_state = 'quarantined' THEN
        INSERT INTO public.p3_quarantine_records (
            contradiction_record_id,
            subject_claim_id,
            quarantine_reason,
            lineage_provenance_id
        ) VALUES (
            v_contradiction_record_id,
            p_primary_claim_id,
            p_contradiction_reason,
            p_lineage_provenance_id
        );
    END IF;

    IF p_resolution_state = 'escalation_required' THEN
        INSERT INTO public.p3_contradiction_escalations (
            contradiction_record_id,
            receiving_surface_id,
            authority_transfer_mode,
            authority_transfer_purpose,
            lineage_provenance_id
        ) VALUES (
            v_contradiction_record_id,
            COALESCE(p_receiving_surface_id, 'P3-SURF-005'),
            p_authority_transfer_mode,
            p_authority_transfer_purpose,
            p_lineage_provenance_id
        );
    END IF;

    RETURN v_contradiction_record_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.p3_append_contradiction_supersession(
    p_prior_contradiction_record_id uuid,
    p_superseding_contradiction_record_id uuid,
    p_supersession_reason text,
    p_lineage_provenance_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_supersession_id uuid;
BEGIN
    INSERT INTO public.p3_contradiction_supersessions (
        prior_contradiction_record_id,
        superseding_contradiction_record_id,
        supersession_reason,
        lineage_provenance_id
    ) VALUES (
        p_prior_contradiction_record_id,
        p_superseding_contradiction_record_id,
        p_supersession_reason,
        p_lineage_provenance_id
    )
    RETURNING contradiction_supersession_id INTO v_supersession_id;

    RETURN v_supersession_id;
END;
$$;

CREATE OR REPLACE VIEW public.p3_contradiction_manifest AS
SELECT
    'contradiction_record'::text AS artifact_kind,
    c.contradiction_record_id AS artifact_id,
    c.contradiction_class::text AS classification,
    c.resolution_state::text AS state,
    c.mutability_class,
    c.authority_transfer_mode,
    c.authority_transfer_purpose,
    c.canonical_order_at,
    c.tie_break_key,
    c.lineage_provenance_id,
    c.recorded_at AS created_at
FROM public.p3_contradiction_records c

UNION ALL

SELECT
    'quarantine_record'::text AS artifact_kind,
    q.quarantine_record_id AS artifact_id,
    'quarantine'::text AS classification,
    'quarantined'::text AS state,
    q.mutability_class,
    'AT-SHARED'::text AS authority_transfer_mode,
    'contradiction_quarantine'::text AS authority_transfer_purpose,
    c.canonical_order_at,
    c.tie_break_key,
    q.lineage_provenance_id,
    q.created_at
FROM public.p3_quarantine_records q
JOIN public.p3_contradiction_records c
  ON c.contradiction_record_id = q.contradiction_record_id

UNION ALL

SELECT
    'supersession_record'::text AS artifact_kind,
    s.contradiction_supersession_id AS artifact_id,
    'supersession'::text AS classification,
    'superseded'::text AS state,
    s.mutability_class,
    'AT-DELEGATED'::text AS authority_transfer_mode,
    'contradiction_supersession'::text AS authority_transfer_purpose,
    c.canonical_order_at,
    c.tie_break_key,
    s.lineage_provenance_id,
    s.created_at
FROM public.p3_contradiction_supersessions s
JOIN public.p3_contradiction_records c
  ON c.contradiction_record_id = s.superseding_contradiction_record_id

UNION ALL

SELECT
    'escalation_record'::text AS artifact_kind,
    e.contradiction_escalation_id AS artifact_id,
    'escalation'::text AS classification,
    'escalation_required'::text AS state,
    e.mutability_class,
    e.authority_transfer_mode,
    e.authority_transfer_purpose,
    c.canonical_order_at,
    c.tie_break_key,
    e.lineage_provenance_id,
    e.created_at
FROM public.p3_contradiction_escalations e
JOIN public.p3_contradiction_records c
  ON c.contradiction_record_id = e.contradiction_record_id;

COMMENT ON TABLE public.p3_contradiction_claims IS
    'Replay-addressable contradiction claims evaluated for direct, temporal, and authority-scope contradiction classes only.';

COMMENT ON TABLE public.p3_contradiction_records IS
    'Append-only contradiction findings carrying canonical ordering and explicit authority-transfer metadata.';

COMMENT ON TABLE public.p3_quarantine_records IS
    'Replay-visible quarantine records derived from contradiction findings without mutating source claims.';

COMMENT ON TABLE public.p3_contradiction_supersessions IS
    'Append-only supersession chain over contradiction findings.';

COMMENT ON TABLE public.p3_contradiction_escalations IS
    'Replay-visible escalation routing records for contradiction findings requiring external adjudication.';

COMMENT ON FUNCTION public.p3_assert_contradiction_claim(
    uuid, uuid, uuid, uuid, text, text, text, timestamptz, timestamptz, text, text, timestamptz, text, uuid
) IS
    'Fail-closed contradiction gate for direct, temporal, and authority-scope contradiction classes.';

COMMENT ON FUNCTION public.p3_append_contradiction_finding(
    public.p3_contradiction_class, uuid, uuid, public.p3_contradiction_resolution_state, text, text, uuid, text, text, text
) IS
    'Append-only contradiction finding writer for quarantine and escalation records under declared canonical ordering.';

COMMENT ON VIEW public.p3_contradiction_manifest IS
    'Unified replay-visible contradiction, quarantine, supersession, and escalation manifest for Phase 3 Wave 3.';
