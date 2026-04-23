-- Migration 0134: Create policy_decisions table
-- Task: TSK-P2-PREAUTH-004-01
-- Wave: 4 — Authority Binding
-- Contract: docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md
--
-- This table records policy decisions that bind execution events to
-- authoritative decisions. Each row is cryptographically anchored:
--   decision_hash = sha256(canonical_json(decision_payload))  [RFC 8785 JCS]
--   signature     = ed25519_sign(decision_hash)
--
-- Encoding contract:
--   decision_hash: lowercase hex, 64 chars (sha256, no 0x prefix)
--   signature:     lowercase hex, 128 chars (ed25519, no 0x prefix)

-- ============================================================
-- TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.policy_decisions (
    policy_decision_id  UUID PRIMARY KEY,
    execution_id        UUID NOT NULL
                        REFERENCES public.execution_records(execution_id),
    entity_type         TEXT NOT NULL,
    entity_id           UUID NOT NULL,
    decision_type       TEXT NOT NULL,
    authority_scope     TEXT NOT NULL,
    declared_by         UUID NOT NULL,
    decision_hash       TEXT NOT NULL
                        CHECK (decision_hash ~ '^[0-9a-f]{64}$'),
    signature           TEXT NOT NULL
                        CHECK (signature ~ '^[0-9a-f]{128}$'),
    signed_at           TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (execution_id, decision_type)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_policy_decisions_entity
    ON public.policy_decisions(entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_policy_decisions_declared_by
    ON public.policy_decisions(declared_by);

-- ============================================================
-- APPEND-ONLY TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_append_only()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RAISE EXCEPTION 'policy_decisions is append-only: UPDATE and DELETE are prohibited'
        USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER trg_policy_decisions_append_only
    BEFORE UPDATE OR DELETE ON public.policy_decisions
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_policy_decisions_append_only();

-- ============================================================
-- PRIVILEGE HYGIENE
-- ============================================================
REVOKE ALL ON public.policy_decisions FROM PUBLIC;
