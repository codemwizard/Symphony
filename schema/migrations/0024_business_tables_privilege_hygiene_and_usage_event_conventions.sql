-- 0024_business_tables_privilege_hygiene_and_usage_event_conventions.sql
-- Phase-0: tighten privilege posture for business tables and add missing convention hooks.

ALTER TABLE public.billing_usage_events
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_billing_usage_events_idempotency
  ON public.billing_usage_events(billable_client_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Revoke-first posture: ensure PUBLIC does not retain accidental privileges on new business tables.
REVOKE ALL ON TABLE public.participants FROM PUBLIC;
REVOKE ALL ON TABLE public.billable_clients FROM PUBLIC;
REVOKE ALL ON TABLE public.billing_usage_events FROM PUBLIC;
REVOKE ALL ON TABLE public.external_proofs FROM PUBLIC;
REVOKE ALL ON TABLE public.evidence_packs FROM PUBLIC;
REVOKE ALL ON TABLE public.evidence_pack_items FROM PUBLIC;

