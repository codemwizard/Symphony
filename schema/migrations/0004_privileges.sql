-- ============================================================
-- 0004_privileges.sql
-- Least-privilege grants for core tables + DB APIs
-- ============================================================

-- This migration is intentionally explicit and defensive:
--  - REVOKE everything first (idempotent)
--  - Grant ONLY what runtime roles need
--  - Prefer SECURITY DEFINER functions over direct table DML
--  - Enforce "no runtime DDL" posture (no CREATE on schema public)

-- ------------------------------------------------------------
-- 0) Schema hardening: no runtime DDL
-- ------------------------------------------------------------
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- ------------------------------------------------------------
-- 1) Schema usage
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO
  symphony_ingest,
  symphony_executor,
  symphony_control,
  symphony_readonly,
  symphony_auditor,
  test_user;

-- ------------------------------------------------------------
-- 2) Start from deny-by-default (idempotent)
-- ------------------------------------------------------------
REVOKE ALL ON TABLE public.payment_outbox_pending FROM PUBLIC;
REVOKE ALL ON TABLE public.payment_outbox_attempts FROM PUBLIC;
REVOKE ALL ON TABLE public.participant_outbox_sequences FROM PUBLIC;

REVOKE ALL ON TABLE public.payment_outbox_pending FROM
  symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor, symphony_control, test_user;
REVOKE ALL ON TABLE public.payment_outbox_attempts FROM
  symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor, symphony_control, test_user;
REVOKE ALL ON TABLE public.participant_outbox_sequences FROM
  symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor, symphony_control, test_user;

-- Boot-critical (policy_versions) is added in 0005. Keep this migration idempotent.
DO $$
  BEGIN
    IF to_regclass('public.policy_versions') IS NOT NULL THEN
      EXECUTE 'REVOKE ALL ON TABLE public.policy_versions FROM PUBLIC';
      EXECUTE 'REVOKE ALL ON TABLE public.policy_versions FROM symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor, symphony_control, test_user';
    END IF;
  END $$;

-- Optional hardening: migration ledger should not be readable by PUBLIC.
DO $$
  BEGIN
    IF to_regclass('public.schema_migrations') IS NOT NULL THEN
      EXECUTE 'REVOKE ALL ON TABLE public.schema_migrations FROM PUBLIC';
    END IF;
  END $$;

-- ------------------------------------------------------------
-- 3) Control plane (symphony_control)
-- ------------------------------------------------------------
-- Control can administer the hot queue + sequences (ops/admin)
GRANT ALL PRIVILEGES ON TABLE public.payment_outbox_pending TO symphony_control;
GRANT ALL PRIVILEGES ON TABLE public.participant_outbox_sequences TO symphony_control;

-- Option A: payment_outbox_attempts is append-only with NO overrides, period.
-- Control may SELECT history (and INSERT via explicit admin tooling), but MUST NOT mutate.
GRANT SELECT, INSERT ON TABLE public.payment_outbox_attempts TO symphony_control;
REVOKE UPDATE, DELETE, TRUNCATE ON TABLE public.payment_outbox_attempts FROM symphony_control;

-- ------------------------------------------------------------
-- 4) Runtime services: function-only access
-- ------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.uuid_v7_or_random() TO
  symphony_ingest, symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user;

GRANT EXECUTE ON FUNCTION public.enqueue_payment_outbox(text, text, text, text, jsonb) TO
  symphony_ingest, symphony_control, test_user;

GRANT EXECUTE ON FUNCTION public.claim_outbox_batch(int, text, int) TO
  symphony_executor, symphony_control, test_user;
GRANT EXECUTE ON FUNCTION public.complete_outbox_attempt(uuid, uuid, text, public.outbox_attempt_state, text, text, text, text, int, int) TO
  symphony_executor, symphony_control, test_user;
GRANT EXECUTE ON FUNCTION public.repair_expired_leases(int, text) TO
  symphony_executor, symphony_control, test_user;

-- ------------------------------------------------------------
-- 5) Read-only / Auditor
-- ------------------------------------------------------------
GRANT SELECT ON public.payment_outbox_pending TO symphony_readonly;
GRANT SELECT ON public.payment_outbox_attempts TO symphony_readonly;

GRANT SELECT ON public.payment_outbox_pending TO symphony_auditor;
GRANT SELECT ON public.payment_outbox_attempts TO symphony_auditor;

-- Defense-in-depth: no sequence visibility for readonly/auditor/test_user
REVOKE ALL ON TABLE public.participant_outbox_sequences FROM symphony_readonly, symphony_auditor, test_user;

-- ------------------------------------------------------------
-- 6) Policy versions: boot needs read access (table created in 0005)
-- ------------------------------------------------------------
DO $$
  BEGIN
    IF to_regclass('public.policy_versions') IS NOT NULL THEN
      EXECUTE 'GRANT SELECT ON TABLE public.policy_versions TO symphony_executor, symphony_control, symphony_readonly, symphony_auditor, test_user';
    END IF;
  END $$;
