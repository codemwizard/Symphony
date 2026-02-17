-- 0013_outbox_pending_indexes_concurrently.sql
-- symphony:no_tx
-- Ensure due-claim index is created concurrently (no blocking)

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_outbox_pending_due_claim
  ON public.payment_outbox_pending (next_attempt_at, lease_expires_at, created_at);
