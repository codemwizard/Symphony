-- Migration 0134: Create policy_decisions table
-- Task: TSK-P2-PREAUTH-004-01
-- Wave: 4 — Authority Binding
-- Contract: docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md (policy_decisions Schema)
--
-- Append-only table recording policy decisions with cryptographic binding.
-- decision_hash = sha256(canonical_json(decision_payload)) per 004-00 contract.
-- signature = ed25519_sign(decision_hash, declared_by_private_key).
--
-- NOTE: do NOT add top-level BEGIN/COMMIT. scripts/db/migrate.sh wraps every
-- migration in its own transaction.

-- ─── Table creation ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.policy_decisions (
    policy_decision_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    execution_id        UUID        NOT NULL,
    decision_type       TEXT        NOT NULL,
    authority_scope     TEXT        NOT NULL,
    declared_by         UUID        NOT NULL,
    entity_type         TEXT        NOT NULL,
    entity_id           UUID        NOT NULL,
    decision_hash       TEXT        NOT NULL,
    signature           TEXT        NOT NULL,
    signed_at           TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT policy_decisions_pk
        PRIMARY KEY (policy_decision_id),

    CONSTRAINT policy_decisions_fk_execution
        FOREIGN KEY (execution_id)
        REFERENCES public.execution_records(execution_id)
        ON DELETE RESTRICT,

    CONSTRAINT policy_decisions_unique_exec_type
        UNIQUE (execution_id, decision_type),

    CONSTRAINT policy_decisions_hash_hex_64
        CHECK (decision_hash ~ '^[0-9a-f]{64}$'),

    CONSTRAINT policy_decisions_sig_hex_128
        CHECK (signature ~ '^[0-9a-f]{128}$')
);

-- ─── Indexes ─────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_policy_decisions_entity
    ON public.policy_decisions (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_policy_decisions_declared_by
    ON public.policy_decisions (declared_by);

-- ─── Append-only trigger ─────────────────────────────────────────────
-- policy_decisions is immutable after insert. UPDATE and DELETE are blocked.
CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF060: policy_decisions is append-only, UPDATE/DELETE not allowed'
        USING ERRCODE = 'GF060';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER policy_decisions_append_only_trigger
BEFORE UPDATE OR DELETE ON public.policy_decisions
FOR EACH ROW EXECUTE FUNCTION public.enforce_policy_decisions_append_only();

REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only() FROM PUBLIC;

-- ─── Privilege posture ───────────────────────────────────────────────
REVOKE ALL ON TABLE public.policy_decisions FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE public.policy_decisions TO symphony_command;
GRANT ALL ON TABLE public.policy_decisions TO symphony_control;

-- ─── Comments ────────────────────────────────────────────────────────
COMMENT ON TABLE public.policy_decisions IS
    'Wave 4 authority-binding: append-only policy decision records with cryptographic hash and signature. Contract: docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md';

COMMENT ON COLUMN public.policy_decisions.decision_hash IS
    'sha256(canonical_json(decision_payload)) — 64-char lowercase hex. Recomputed by verifier at V3.';

COMMENT ON COLUMN public.policy_decisions.signature IS
    'Ed25519 signature over hex_decode(decision_hash) — 128-char lowercase hex. Key resolution deferred to later wave.';

COMMENT ON FUNCTION public.enforce_policy_decisions_append_only() IS
    'Append-only guard for policy_decisions. Raises GF060 on UPDATE/DELETE.';
