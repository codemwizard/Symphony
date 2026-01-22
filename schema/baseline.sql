-- ============================================================
-- SYMPHONY BASELINE SCHEMA
-- ============================================================
-- 
-- This file is a SNAPSHOT for fresh database creation.
-- It must match the schema produced by applying all migrations
-- in schema/migrations/ to an empty database.
--
-- Usage:
--   Fresh DB:    scripts/db/apply_baseline.sh
--   Dev reset:   scripts/db/reset_db.sh
--
-- For production evolution, use: scripts/db/migrate.sh
--
-- Prerequisites (managed by infrastructure, not migrations):
--   - symphony_control, symphony_ingest, symphony_executor,
--     symphony_readonly, symphony_auditor roles
-- ============================================================

-- ------------------------------------------------------------
-- 0) PostgreSQL 18+ Requirement + uuidv7() assertion
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

DO $$
BEGIN
  PERFORM uuidv7();
EXCEPTION
  WHEN undefined_function THEN
    RAISE EXCEPTION 'uuidv7() is required (PostgreSQL 18+).'
      USING ERRCODE = 'P7001';
END
$$;

-- ------------------------------------------------------------
-- 1) Extensions
-- ------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 1b) Roles (from 0003_roles.sql)
-- ------------------------------------------------------------
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_control') THEN CREATE ROLE symphony_control; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_ingest') THEN CREATE ROLE symphony_ingest; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_executor') THEN CREATE ROLE symphony_executor; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_readonly') THEN CREATE ROLE symphony_readonly; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_auditor') THEN CREATE ROLE symphony_auditor; END IF; END $$;

COMMENT ON ROLE symphony_control IS 'Control Plane administrator.';
COMMENT ON ROLE symphony_ingest IS 'Data Plane Ingest service.';
COMMENT ON ROLE symphony_executor IS 'Data Plane Executor worker.';
COMMENT ON ROLE symphony_readonly IS 'Read Plane for reporting.';
COMMENT ON ROLE symphony_auditor IS 'Read Plane for external auditors.';

-- Allow CI/Local/test users to SET ROLE into these if they exist
DO $$ BEGIN IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'symphony') THEN GRANT symphony_control, symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor TO symphony; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'symphony_admin') THEN GRANT symphony_control, symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor TO symphony_admin; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'test_user') THEN GRANT symphony_control, symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor TO test_user; END IF; END $$;

-- ------------------------------------------------------------
-- 2) Attempt State Enum
-- ------------------------------------------------------------
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
  outbox_id         UUID PRIMARY KEY DEFAULT uuidv7(),

  instruction_id    TEXT NOT NULL,
  participant_id    TEXT NOT NULL,
  sequence_id       BIGINT NOT NULL,

  idempotency_key   TEXT NOT NULL,
  rail_type         TEXT NOT NULL,
  payload           JSONB NOT NULL,

  attempt_count     INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

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
  attempt_id        UUID PRIMARY KEY DEFAULT uuidv7(),

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

CREATE INDEX ix_attempts_outbox_latest
  ON public.payment_outbox_attempts (outbox_id, claimed_at DESC);

CREATE INDEX ix_attempts_instruction
  ON public.payment_outbox_attempts (instruction_id, claimed_at DESC);

CREATE INDEX ix_attempts_idempotency
  ON public.payment_outbox_attempts (instruction_id, idempotency_key, claimed_at DESC);

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

-- ------------------------------------------------------------
-- 7) Schema Migrations Ledger
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version          TEXT PRIMARY KEY,
  description      TEXT NOT NULL,
  checksum_sha256  TEXT NOT NULL,
  applied_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.schema_migrations IS
  'Migration ledger: tracks applied migrations with checksums.';

-- ------------------------------------------------------------
-- 8) Outbox State Machine Functions (from 0002)
-- ------------------------------------------------------------

-- bump_participant_outbox_seq
CREATE FUNCTION public.bump_participant_outbox_seq(p_participant_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  allocated BIGINT;
BEGIN
  INSERT INTO public.participant_outbox_sequences(participant_id, next_sequence_id)
  VALUES (p_participant_id, 2)
  ON CONFLICT (participant_id)
  DO UPDATE
    SET next_sequence_id = public.participant_outbox_sequences.next_sequence_id + 1
  RETURNING (public.participant_outbox_sequences.next_sequence_id - 1) INTO allocated;

  RETURN allocated;
END;
$$;

-- enqueue_payment_outbox
CREATE FUNCTION public.enqueue_payment_outbox(
  p_instruction_id TEXT,
  p_participant_id TEXT,
  p_idempotency_key TEXT,
  p_rail_type TEXT,
  p_payload JSONB
)
RETURNS TABLE (
  outbox_id UUID,
  sequence_id BIGINT,
  created_at TIMESTAMPTZ,
  state TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  existing_pending RECORD;
  existing_attempt RECORD;
  allocated_sequence BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
  );

  SELECT p.outbox_id, p.sequence_id, p.created_at
    INTO existing_pending
  FROM public.payment_outbox_pending p
  WHERE p.instruction_id = p_instruction_id
    AND p.idempotency_key = p_idempotency_key
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN;
  END IF;

  SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
    INTO existing_attempt
  FROM public.payment_outbox_attempts a
  WHERE a.instruction_id = p_instruction_id
    AND a.idempotency_key = p_idempotency_key
  ORDER BY a.claimed_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
    RETURN;
  END IF;

  allocated_sequence := public.bump_participant_outbox_seq(p_participant_id);

  BEGIN
    INSERT INTO public.payment_outbox_pending (
      instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload
    )
    VALUES (
      p_instruction_id, p_participant_id, allocated_sequence, p_idempotency_key, p_rail_type, p_payload
    )
    RETURNING public.payment_outbox_pending.outbox_id, public.payment_outbox_pending.sequence_id, public.payment_outbox_pending.created_at
      INTO existing_pending;
  EXCEPTION
    WHEN unique_violation THEN
      SELECT p.outbox_id, p.sequence_id, p.created_at INTO existing_pending
      FROM public.payment_outbox_pending p
      WHERE p.instruction_id = p_instruction_id AND p.idempotency_key = p_idempotency_key
      LIMIT 1;
      IF NOT FOUND THEN RAISE; END IF;
  END;

  RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
END;
$$;

-- claim_outbox_batch
CREATE FUNCTION public.claim_outbox_batch(
  p_batch_size INT,
  p_worker_id TEXT,
  p_lease_seconds INT
)
RETURNS TABLE (
  outbox_id UUID, instruction_id TEXT, participant_id TEXT, sequence_id BIGINT,
  idempotency_key TEXT, rail_type TEXT, payload JSONB, attempt_count INT,
  lease_token UUID, lease_expires_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
WITH due AS (
  SELECT p.outbox_id FROM public.payment_outbox_pending p
  WHERE p.next_attempt_at <= NOW() AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
  ORDER BY p.next_attempt_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
),
leased AS (
  UPDATE public.payment_outbox_pending p SET
    claimed_by = p_worker_id, lease_token = uuidv7(),
    lease_expires_at = NOW() + make_interval(secs => p_lease_seconds)
  FROM due WHERE p.outbox_id = due.outbox_id
  RETURNING p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
    p.idempotency_key, p.rail_type, p.payload, p.attempt_count, p.lease_token, p.lease_expires_at
)
SELECT * FROM leased;
$$;

-- complete_outbox_attempt
CREATE FUNCTION public.complete_outbox_attempt(
  p_outbox_id UUID, p_lease_token UUID, p_worker_id TEXT, p_state public.outbox_attempt_state,
  p_rail_reference TEXT DEFAULT NULL, p_rail_code TEXT DEFAULT NULL,
  p_error_code TEXT DEFAULT NULL, p_error_message TEXT DEFAULT NULL,
  p_latency_ms INT DEFAULT NULL, p_retry_delay_seconds INT DEFAULT 1
)
RETURNS TABLE (attempt_no INT, state public.outbox_attempt_state)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
  v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
  v_next_attempt_no INT; v_effective_state public.outbox_attempt_state;
BEGIN
  SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
  INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
  FROM public.payment_outbox_pending p
  WHERE p.outbox_id = p_outbox_id AND p.claimed_by = p_worker_id
    AND p.lease_token = p_lease_token AND p.lease_expires_at > NOW()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002',
      DETAIL = 'Lease missing/expired or token mismatch';
  END IF;

  IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
    RAISE EXCEPTION 'Invalid completion state %', p_state USING ERRCODE = 'P7003';
  END IF;

  SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
  FROM public.payment_outbox_attempts a WHERE a.outbox_id = p_outbox_id;

  v_effective_state := p_state;
  IF p_state = 'RETRYABLE' AND v_next_attempt_no >= 20 THEN v_effective_state := 'FAILED'; END IF;

  INSERT INTO public.payment_outbox_attempts (
    outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
    attempt_no, state, claimed_at, completed_at, rail_reference, rail_code,
    error_code, error_message, latency_ms, worker_id
  ) VALUES (
    p_outbox_id, v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload,
    v_next_attempt_no, v_effective_state, NOW(),
    CASE WHEN v_effective_state IN ('DISPATCHED', 'FAILED') THEN NOW() ELSE NULL END,
    p_rail_reference, p_rail_code, p_error_code, p_error_message, p_latency_ms, p_worker_id
  );

  IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
    DELETE FROM public.payment_outbox_pending WHERE outbox_id = p_outbox_id;
  ELSE
    UPDATE public.payment_outbox_pending SET
      attempt_count = GREATEST(attempt_count, v_next_attempt_no),
      next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
      claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
    WHERE outbox_id = p_outbox_id;
  END IF;

  RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
END;
$$;

-- repair_expired_leases
CREATE FUNCTION public.repair_expired_leases(p_batch_size INT, p_worker_id TEXT)
RETURNS TABLE (outbox_id UUID, attempt_no INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_record RECORD; v_next_attempt_no INT;
BEGIN
  FOR v_record IN
    SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
           p.idempotency_key, p.rail_type, p.payload
    FROM public.payment_outbox_pending p
    WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
    ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
  LOOP
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    FROM public.payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;

    INSERT INTO public.payment_outbox_attempts (
      outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
      attempt_no, state, claimed_at, completed_at, worker_id
    ) VALUES (
      v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
      v_record.idempotency_key, v_record.rail_type, v_record.payload,
      v_next_attempt_no, 'ZOMBIE_REQUEUE', NOW(), NOW(), p_worker_id
    );

    UPDATE public.payment_outbox_pending SET
      attempt_count = GREATEST(attempt_count, v_next_attempt_no),
      next_attempt_at = NOW() + INTERVAL '1 second',
      claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
    WHERE outbox_id = v_record.outbox_id;

    outbox_id := v_record.outbox_id;
    attempt_no := v_next_attempt_no;
    RETURN NEXT;
  END LOOP;
  RETURN;
END;
$$;
