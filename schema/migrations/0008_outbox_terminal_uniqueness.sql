-- Enforce one terminal attempt per outbox_id (terminal set: DISPATCHED, FAILED)
CREATE UNIQUE INDEX IF NOT EXISTS ux_outbox_attempts_one_terminal_per_outbox
  ON public.payment_outbox_attempts(outbox_id)
  WHERE state IN ('DISPATCHED', 'FAILED');
