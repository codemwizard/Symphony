-- 0007_outbox_pending_indexes.sql
-- Add due-claim index for payment_outbox_pending

CREATE INDEX IF NOT EXISTS idx_payment_outbox_pending_due_claim
  ON public.payment_outbox_pending (next_attempt_at, lease_expires_at, created_at);
