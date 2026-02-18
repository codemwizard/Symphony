-- ============================================================
-- 0001_init.sql
-- Minimal schema bootstrap: roles, extensions, core outbox tables
-- ============================================================

-- Fail fast if PostgreSQL major version < 18
DO $$
  DECLARE
    v_major int;
  BEGIN
    v_major := current_setting('server_version_num')::int / 10000;
    IF v_major < 18 THEN
      RAISE EXCEPTION 'Symphony requires PostgreSQL 18+';
    END IF;
  END $$;

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- --------------------------------------------------------------------
-- UUID strategy wrapper:
-- - If platform provides public.uuidv7(), use it.
-- - Otherwise fall back to pgcrypto gen_random_uuid().
--
-- IMPORTANT:
-- We choose the implementation at migration time to avoid runtime overhead
-- and to avoid referencing uuidv7() on systems where it does not exist.
-- --------------------------------------------------------------------
DO $setup$
  BEGIN
    IF to_regprocedure('public.uuidv7()') IS NOT NULL THEN
      EXECUTE $fn$
        CREATE OR REPLACE FUNCTION public.uuid_v7_or_random()
        RETURNS uuid
        LANGUAGE sql
        VOLATILE
        AS $body$
          SELECT public.uuidv7();
        $body$;
      $fn$;
    ELSE
      EXECUTE $fn$
        CREATE OR REPLACE FUNCTION public.uuid_v7_or_random()
        RETURNS uuid
        LANGUAGE sql
        VOLATILE
        AS $body$
          SELECT gen_random_uuid();
        $body$;
      $fn$;
    END IF;
  END
  $setup$;

COMMENT ON FUNCTION public.uuid_v7_or_random() IS
  'UUID generator chosen at migration-time: uuidv7() if available, else pgcrypto gen_random_uuid().';

-- Optional: lightweight observability for health checks / evidence bundles.
CREATE OR REPLACE FUNCTION public.uuid_strategy()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN to_regprocedure('public.uuidv7()') IS NOT NULL THEN 'uuidv7'
    ELSE 'gen_random_uuid'
  END;
$$;

COMMENT ON FUNCTION public.uuid_strategy() IS
  'Reports which UUID strategy is active (uuidv7 vs gen_random_uuid).';

-- --------------------------------------------------------------------
-- Attempt state enum (archive)
-- --------------------------------------------------------------------
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'outbox_attempt_state') THEN
      CREATE TYPE outbox_attempt_state AS ENUM (
        'DISPATCHING',
        'DISPATCHED',
        'RETRYABLE',
        'FAILED',
        'ZOMBIE_REQUEUE'
      );
    END IF;
  END $$;

-- --------------------------------------------------------------------
-- Per-participant monotonic sequence allocator table
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS participant_outbox_sequences (
  participant_id TEXT PRIMARY KEY,
  next_sequence_id BIGINT NOT NULL CHECK (next_sequence_id >= 1)
);

-- --------------------------------------------------------------------
-- Hot pending outbox table (work queue)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_outbox_pending (
  outbox_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),

  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  sequence_id BIGINT NOT NULL,

  idempotency_key TEXT NOT NULL,
  rail_type TEXT NOT NULL,
  payload JSONB NOT NULL,

  attempt_count INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  claimed_by TEXT,
  lease_token UUID,
  lease_expires_at TIMESTAMPTZ,

  CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id),
  CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key),
  CONSTRAINT ck_pending_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

COMMENT ON TABLE payment_outbox_pending IS
  'Active hot queue for payment instructions waiting for dispatch or retry.';

COMMENT ON COLUMN payment_outbox_pending.lease_token IS
  'Random UUID token proving ownership of the claim (fencing token).';

COMMENT ON COLUMN payment_outbox_pending.attempt_count IS
  'Total number of attempts made so far (used for backoff).';

-- --------------------------------------------------------------------
-- Append-only attempts (archive + truth for status)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_outbox_attempts (
  attempt_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),

  outbox_id UUID NOT NULL,
  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  sequence_id BIGINT NOT NULL,
  idempotency_key TEXT NOT NULL,
  rail_type TEXT NOT NULL,
  payload JSONB NOT NULL,

  attempt_no INT NOT NULL CHECK (attempt_no >= 1),
  state outbox_attempt_state NOT NULL,

  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  rail_reference TEXT,
  rail_code TEXT,
  error_code TEXT,
  error_message TEXT,
  latency_ms INT CHECK (latency_ms IS NULL OR latency_ms >= 0),

  worker_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT ux_attempts_outbox_attempt_no UNIQUE (outbox_id, attempt_no),
  CONSTRAINT ck_attempts_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX idx_attempts_instruction_idempotency
  ON payment_outbox_attempts(instruction_id, idempotency_key);

CREATE INDEX idx_attempts_outbox_id
  ON payment_outbox_attempts(outbox_id);

COMMENT ON TABLE payment_outbox_attempts IS
  'Append-only outbox attempt ledger (authoritative status history). No UPDATE/DELETE.';

CREATE OR REPLACE FUNCTION deny_outbox_attempts_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    RAISE EXCEPTION 'payment_outbox_attempts is append-only'
      USING ERRCODE = 'P0001';
  END;
$$;

DROP TRIGGER IF EXISTS trg_deny_outbox_attempts_mutation ON payment_outbox_attempts;

CREATE TRIGGER trg_deny_outbox_attempts_mutation
BEFORE UPDATE OR DELETE ON payment_outbox_attempts
FOR EACH ROW
EXECUTE FUNCTION deny_outbox_attempts_mutation();
