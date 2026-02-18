-- 0025_boz_observability_role.sql
-- Phase-0: BoZ regulator observability seat (read-only, NOLOGIN, revoke-first)

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'boz_auditor') THEN
    CREATE ROLE boz_auditor NOLOGIN;
  END IF;
  ALTER ROLE boz_auditor NOLOGIN;
END $$;

-- Schema posture: allow read access but never DDL.
GRANT USAGE ON SCHEMA public TO boz_auditor;
REVOKE CREATE ON SCHEMA public FROM boz_auditor;

-- Table allowlist (Phase-0 structural observability only)
GRANT SELECT ON TABLE public.payment_outbox_pending TO boz_auditor;
GRANT SELECT ON TABLE public.payment_outbox_attempts TO boz_auditor;
GRANT SELECT ON TABLE public.participants TO boz_auditor;
GRANT SELECT ON TABLE public.billable_clients TO boz_auditor;
GRANT SELECT ON TABLE public.billing_usage_events TO boz_auditor;
GRANT SELECT ON TABLE public.external_proofs TO boz_auditor;
GRANT SELECT ON TABLE public.evidence_packs TO boz_auditor;
GRANT SELECT ON TABLE public.evidence_pack_items TO boz_auditor;

-- Defense-in-depth: explicitly revoke DML surfaces even if upstream grants drift later.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.payment_outbox_pending FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.payment_outbox_attempts FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.participants FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.billable_clients FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.billing_usage_events FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.external_proofs FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.evidence_packs FROM boz_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.evidence_pack_items FROM boz_auditor;

