-- 0018_outbox_tenant_attribution.sql
-- Tenant/member attribution (expand-first) for outbox tables

ALTER TABLE public.payment_outbox_pending
  ADD COLUMN IF NOT EXISTS tenant_id UUID NULL REFERENCES public.tenants(tenant_id);

ALTER TABLE public.payment_outbox_attempts
  ADD COLUMN IF NOT EXISTS tenant_id UUID NULL REFERENCES public.tenants(tenant_id),
  ADD COLUMN IF NOT EXISTS member_id UUID NULL REFERENCES public.tenant_members(member_id);

-- Optional index for Phase-1 query shapes; use concurrently for hot tables
-- symphony:no_tx
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_pending_tenant_due
  ON public.payment_outbox_pending(tenant_id, next_attempt_at)
  WHERE tenant_id IS NOT NULL;
