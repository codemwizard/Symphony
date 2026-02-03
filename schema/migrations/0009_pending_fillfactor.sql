-- 0009_pending_fillfactor.sql
-- Enforce MVCC posture for payment_outbox_pending

ALTER TABLE public.payment_outbox_pending
  SET (fillfactor = 80);
