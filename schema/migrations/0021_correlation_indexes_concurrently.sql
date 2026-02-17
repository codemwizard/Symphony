-- 0021_correlation_indexes_concurrently.sql
-- Correlation stitchability indexes for ingress/outbox hooks
-- symphony:no_tx

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ingress_attestations_tenant_correlation
  ON public.ingress_attestations(tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ingress_attestations_correlation_id
  ON public.ingress_attestations(correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_pending_tenant_correlation
  ON public.payment_outbox_pending(tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_pending_correlation_id
  ON public.payment_outbox_pending(correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_attempts_tenant_correlation
  ON public.payment_outbox_attempts(tenant_id, correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_attempts_correlation_id
  ON public.payment_outbox_attempts(correlation_id)
  WHERE correlation_id IS NOT NULL;
