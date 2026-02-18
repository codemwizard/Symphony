-- 0027_billable_clients_client_key_index_concurrently.sql
-- symphony:no_tx
--
-- Phase-0: stable payer key uniqueness. Concurrent index avoids long locks.

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS ux_billable_clients_client_key
  ON public.billable_clients(client_key)
  WHERE client_key IS NOT NULL;

