-- Migration 0134: policy_decisions (Wave 4 cryptographic truth-anchor row type)
-- Task: TSK-P2-PREAUTH-004-01
-- Wave:  Wave 4 — Authority Binding
-- Contract: docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md (Cryptographic Contract + policy_decisions Schema)
-- PLAN:     docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md
--
-- Expands the schema by exactly one table: public.policy_decisions. The table
-- is the Wave 4 analogue of public.execution_records (Wave 3): append-only,
-- FK-bound to execution_records, entity-bound via (entity_type, entity_id),
-- and committed by decision_hash = sha256(canonical_json(decision_payload))
-- plus signature = ed25519_sign(decision_hash, private_key). Both are
-- length-pinned by CHECK regexes.
--
-- Append-only enforcement (UPDATE + DELETE) ships in the same migration via
-- enforce_policy_decisions_append_only, raising SQLSTATE GF061 (next free code
-- in the Wave 3/4 GF-prefix sequence; kept distinct from 23514 so negative
-- tests can differentiate CHECK violations on decision_hash/signature from
-- append-only rejections). The function is SECURITY DEFINER with hardened
-- search_path and revoke-first posture, mirroring the 0133 pattern per
-- AGENTS.md.
--
-- NOTE: do NOT add top-level BEGIN/COMMIT. scripts/db/migrate.sh wraps every
-- migration in its own transaction (migrate.sh:158-166).

-- ─── Truth-anchor row type ──────────────────────────────────────────
CREATE TABLE public.policy_decisions (
    policy_decision_id  UUID        NOT NULL PRIMARY KEY,
    execution_id        UUID        NOT NULL REFERENCES public.execution_records(execution_id),
    decision_type       TEXT        NOT NULL,
    authority_scope     TEXT        NOT NULL,
    declared_by         UUID        NOT NULL,
    entity_type         TEXT        NOT NULL,
    entity_id           UUID        NOT NULL,
    decision_hash       TEXT        NOT NULL CHECK (decision_hash ~ '^[0-9a-f]{64}$'),
    signature           TEXT        NOT NULL CHECK (signature ~ '^[0-9a-f]{128}$'),
    signed_at           TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (execution_id, decision_type)
);

CREATE INDEX idx_policy_decisions_entity      ON public.policy_decisions (entity_type, entity_id);
CREATE INDEX idx_policy_decisions_declared_by ON public.policy_decisions (declared_by);

COMMENT ON TABLE public.policy_decisions IS
    'Wave 4 cryptographic truth-anchor row type. Append-only. Each row binds a '
    'signed policy decision to an execution via execution_id + '
    '(entity_type, entity_id). decision_hash = sha256(canonical_json(decision_payload)); '
    'signature = ed25519_sign(decision_hash, private_key). See '
    'docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md §Payload → Column Mapping '
    'for the payload ↔ column contract consumed by TSK-P2-PREAUTH-004-03 V3 '
    'recompute.';

-- ─── Append-only enforcement (GF061) ────────────────────────────────
-- Raises GF061 on UPDATE or DELETE of any existing row. SECURITY DEFINER with
-- SET search_path = pg_catalog, public per AGENTS.md (mirrors 0133). Function
-- EXECUTE is revoked from PUBLIC immediately after creation.
CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF061: policy_decisions is append-only, UPDATE/DELETE not allowed'
        USING ERRCODE = 'GF061';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER enforce_policy_decisions_append_only
BEFORE UPDATE OR DELETE ON public.policy_decisions
FOR EACH ROW EXECUTE FUNCTION public.enforce_policy_decisions_append_only();

REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only() FROM PUBLIC;

COMMENT ON FUNCTION public.enforce_policy_decisions_append_only() IS
    'TSK-P2-PREAUTH-004-01: policy_decisions is append-only. Raises SQLSTATE '
    'GF061 on UPDATE or DELETE. SECURITY DEFINER SET search_path = pg_catalog, '
    'public (AGENTS.md hardening requirement, mirrors 0133 GF056).';
