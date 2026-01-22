-- ============================================================
-- 0001_init.sql — Minimal Foundational Schema
-- ============================================================
-- This migration establishes the baseline database structure.
-- 
-- Includes:
--   - PostgreSQL 18+ requirement
--   - Extensions (pgcrypto for UUID generation)
--   - Core types (enums)
--   - Payment outbox tables (pending + attempts)
--   - Append-only enforcement trigger
--
-- Explicitly NOT included (belongs in subsequent migrations):
--   - Roles (managed by infra or 0005_roles.sql)
--   - Large business logic functions
--   - Privilege matrices and role grants
--   - Operational views
--   - Non-essential seed data
--
-- Prerequisites (managed by infrastructure, not migrations):
--   - symphony_control, symphony_ingest, symphony_executor,
--     symphony_readonly, symphony_auditor roles
-- ============================================================

-- ------------------------------------------------------------
-- 0) PostgreSQL 18+ Requirement
-- ------------------------------------------------------------
DO $$
DECLARE
  v_major int;
BEGIN
  v_major := current_setting('server_version_num')::int / 10000;
  IF v_major < 18 THEN
    RAISE EXCEPTION 'Symphony requires PostgreSQL 18+, got server_version=%', 
      current_setting('server_version');
  END IF;
END
$$;

-- ------------------------------------------------------------
-- 1) Extensions
-- ------------------------------------------------------------
-- pgcrypto provides gen_random_uuid() for UUID generation
-- Note: uuidv7() native support pending PG18 confirmation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 2) Attempt State Enum
-- ------------------------------------------------------------
-- DISPATCHING is historical-only; never inserted by application code.
CREATE TYPE outbox_attempt_state AS ENUM (
  'DISPATCHING',
  'DISPATCHED',
  'RETRYABLE',
  'FAILED',
  'ZOMBIE_REQUEUE'
);

COMMENT ON TYPE outbox_attempt_state IS
  'Outbox attempt lifecycle states. DISPATCHING is historical-only.';

-- ------------------------------------------------------------
-- 3) Participant Sequence Allocator
-- ------------------------------------------------------------
CREATE TABLE public.participant_outbox_sequences (
  participant_id    TEXT PRIMARY KEY,
  next_sequence_id  BIGINT NOT NULL CHECK (next_sequence_id >= 1)
);

COMMENT ON TABLE public.participant_outbox_sequences IS
  'Monotonic sequence allocator per participant for outbox ordering.';

-- ------------------------------------------------------------
-- 4) Payment Outbox Pending (work queue)
-- ------------------------------------------------------------
CREATE TABLE public.payment_outbox_pending (
  outbox_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  instruction_id    TEXT NOT NULL,
  participant_id    TEXT NOT NULL,
  sequence_id       BIGINT NOT NULL,

  idempotency_key   TEXT NOT NULL,
  rail_type         TEXT NOT NULL,
  payload           JSONB NOT NULL,

  attempt_count     INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Lease fields
  claimed_by        TEXT,
  lease_token       UUID,
  lease_expires_at  TIMESTAMPTZ,

  CONSTRAINT ux_pending_participant_sequence 
    UNIQUE (participant_id, sequence_id),
  CONSTRAINT ux_pending_idempotency 
    UNIQUE (instruction_id, idempotency_key),
  CONSTRAINT ck_pending_payload_is_object 
    CHECK (jsonb_typeof(payload) = 'object'),
  CONSTRAINT ck_pending_lease_consistency CHECK (
    (claimed_by IS NULL AND lease_token IS NULL AND lease_expires_at IS NULL)
    OR
    (claimed_by IS NOT NULL AND lease_token IS NOT NULL AND lease_expires_at IS NOT NULL)
  )
);

-- Indexes for claim operations
CREATE INDEX ix_pending_due
  ON public.payment_outbox_pending (next_attempt_at, created_at);

CREATE INDEX ix_pending_participant
  ON public.payment_outbox_pending (participant_id, next_attempt_at);

CREATE INDEX ix_pending_lease_expires
  ON public.payment_outbox_pending (lease_expires_at)
  WHERE lease_expires_at IS NOT NULL;

CREATE INDEX ix_pending_claimed_by
  ON public.payment_outbox_pending (claimed_by, lease_expires_at)
  WHERE claimed_by IS NOT NULL;

COMMENT ON TABLE public.payment_outbox_pending IS
  'Hot outbox queue. Rows leased via pending columns, deleted on terminal completion.';

-- ------------------------------------------------------------
-- 5) Payment Outbox Attempts (append-only archive)
-- ------------------------------------------------------------
CREATE TABLE public.payment_outbox_attempts (
  attempt_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  outbox_id         UUID NOT NULL,
  instruction_id    TEXT NOT NULL,
  participant_id    TEXT NOT NULL,
  sequence_id       BIGINT NOT NULL,
  idempotency_key   TEXT NOT NULL,
  rail_type         TEXT NOT NULL,
  payload           JSONB NOT NULL,

  attempt_no        INT NOT NULL CHECK (attempt_no >= 1),
  state             outbox_attempt_state NOT NULL,

  claimed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at      TIMESTAMPTZ,

  rail_reference    TEXT,
  rail_code         TEXT,
  error_code        TEXT,
  error_message     TEXT,
  latency_ms        INT CHECK (latency_ms IS NULL OR latency_ms >= 0),

  worker_id         TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT ux_attempt_unique_per_outbox 
    UNIQUE (outbox_id, attempt_no),
  CONSTRAINT ck_attempts_payload_is_object 
    CHECK (jsonb_typeof(payload) = 'object')
);

-- Indexes
CREATE INDEX ix_attempts_outbox_latest
  ON public.payment_outbox_attempts (outbox_id, claimed_at DESC);

CREATE INDEX ix_attempts_instruction
  ON public.payment_outbox_attempts (instruction_id, claimed_at DESC);

CREATE INDEX ix_attempts_idempotency
  ON public.payment_outbox_attempts (instruction_id, idempotency_key, claimed_at DESC);

-- One terminal outcome per outbox_id
CREATE UNIQUE INDEX payment_outbox_attempts_one_terminal_per_outbox
  ON public.payment_outbox_attempts (outbox_id)
  WHERE state IN ('DISPATCHED', 'FAILED');

COMMENT ON TABLE public.payment_outbox_attempts IS
  'Append-only outbox attempt ledger. No UPDATE/DELETE allowed.';

COMMENT ON INDEX payment_outbox_attempts_one_terminal_per_outbox IS
  'Enforces at most one terminal outcome (DISPATCHED or FAILED) per outbox_id.';

-- ------------------------------------------------------------
-- 6) Append-Only Enforcement Trigger
-- ------------------------------------------------------------
CREATE FUNCTION public.deny_outbox_attempts_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'payment_outbox_attempts is append-only (INSERT only)'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER trg_deny_outbox_attempts_update
BEFORE UPDATE ON public.payment_outbox_attempts
FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();

CREATE TRIGGER trg_deny_outbox_attempts_delete
BEFORE DELETE ON public.payment_outbox_attempts
FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();
