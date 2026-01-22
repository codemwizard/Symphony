-- Phase-7B Option 2A: Hot/Archive Outbox (Authoritative DB Invariants)
-- Replace-in-place. No legacy tables or compatibility paths.

BEGIN;

-- --------------------------------------------------------------------
-- 0) Remove legacy outbox artifacts and dependent views
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS supervisor_outbox_status CASCADE;
DROP TABLE IF EXISTS payment_outbox CASCADE;
DROP TYPE IF EXISTS outbox_status CASCADE;

-- --------------------------------------------------------------------
-- 1) Attempt state enum (archive)
-- --------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'outbox_attempt_state') THEN
    -- DISPATCHING is historical-only; inflight is lease state on pending.
    -- Inserts of DISPATCHING are forbidden by policy/guardrails.
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
-- 2) Per-participant monotonic sequence allocator (authoritative)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS participant_outbox_sequences (
  participant_id TEXT PRIMARY KEY,
  next_sequence_id BIGINT NOT NULL CHECK (next_sequence_id >= 1)
);

-- Allocates a strictly monotonic sequence_id per participant.
CREATE OR REPLACE FUNCTION bump_participant_outbox_seq(p_participant_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  allocated BIGINT;
BEGIN
  INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
  VALUES (p_participant_id, 2)
  ON CONFLICT (participant_id)
  DO UPDATE
    SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
  RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;

  RETURN allocated;
END;
$$;

COMMENT ON TABLE participant_outbox_sequences IS
  'Authoritative monotonic sequence allocator for outbox strict sequencing (Option 2A).';
COMMENT ON FUNCTION bump_participant_outbox_seq(TEXT) IS
  'Atomically allocates next monotonic sequence_id per participant.';

ALTER FUNCTION bump_participant_outbox_seq(TEXT) OWNER TO symphony_control;

-- --------------------------------------------------------------------
-- 3) Hot pending table (work queue)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_outbox_pending (
  outbox_id UUID PRIMARY KEY DEFAULT uuidv7(),

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

ALTER TABLE payment_outbox_pending
  ADD COLUMN IF NOT EXISTS claimed_by TEXT,
  ADD COLUMN IF NOT EXISTS lease_token UUID,
  ADD COLUMN IF NOT EXISTS lease_expires_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ck_pending_lease_consistency'
  ) THEN
    ALTER TABLE payment_outbox_pending
      ADD CONSTRAINT ck_pending_lease_consistency CHECK (
        (claimed_by IS NULL AND lease_token IS NULL AND lease_expires_at IS NULL)
        OR
        (claimed_by IS NOT NULL AND lease_token IS NOT NULL AND lease_expires_at IS NOT NULL)
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_pending_due
  ON payment_outbox_pending (next_attempt_at, created_at);

CREATE INDEX IF NOT EXISTS ix_pending_participant
  ON payment_outbox_pending (participant_id, next_attempt_at);

CREATE INDEX IF NOT EXISTS ix_pending_lease_expires
  ON payment_outbox_pending (lease_expires_at)
  WHERE lease_expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_pending_claimed_by
  ON payment_outbox_pending (claimed_by, lease_expires_at)
  WHERE claimed_by IS NOT NULL;

COMMENT ON TABLE payment_outbox_pending IS
  'Option 2A hot outbox queue. Rows are leased via pending lease columns and deleted on terminal completion.';
COMMENT ON COLUMN payment_outbox_pending.attempt_count IS
  'Non-authoritative cache of last_attempt_no; next attempt is derived from attempts history.';

-- --------------------------------------------------------------------
-- 4) Append-only attempts (archive + truth for status)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_outbox_attempts (
  attempt_id UUID PRIMARY KEY DEFAULT uuidv7(),

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

  CONSTRAINT ux_attempt_unique_per_outbox UNIQUE (outbox_id, attempt_no),
  CONSTRAINT ck_attempts_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_attempts_outbox_latest
  ON payment_outbox_attempts (outbox_id, claimed_at DESC);

DROP INDEX IF EXISTS public.ix_attempts_dispatching_age;

CREATE INDEX IF NOT EXISTS ix_attempts_instruction
  ON payment_outbox_attempts (instruction_id, claimed_at DESC);

CREATE INDEX IF NOT EXISTS ix_attempts_idempotency
  ON payment_outbox_attempts (instruction_id, idempotency_key, claimed_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS payment_outbox_attempts_one_terminal_per_outbox
  ON payment_outbox_attempts (outbox_id)
  WHERE state IN ('DISPATCHED', 'FAILED');

COMMENT ON INDEX payment_outbox_attempts_one_terminal_per_outbox IS
  'Enforces at most one terminal outcome (DISPATCHED or FAILED) per outbox_id.';

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

-- --------------------------------------------------------------------
-- 4b) Authoritative enqueue function (idempotency-safe, sequence-safe)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enqueue_payment_outbox(
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
  -- One 64-bit lock key derived from both fields to avoid int4 truncation.
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
  );

  SELECT p.outbox_id, p.sequence_id, p.created_at
  INTO existing_pending
  FROM payment_outbox_pending p
  WHERE p.instruction_id = p_instruction_id
    AND p.idempotency_key = p_idempotency_key
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN;
  END IF;

  SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
  INTO existing_attempt
  FROM payment_outbox_attempts a
  WHERE a.instruction_id = p_instruction_id
    AND a.idempotency_key = p_idempotency_key
  ORDER BY a.claimed_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
    RETURN;
  END IF;

  allocated_sequence := bump_participant_outbox_seq(p_participant_id);

  BEGIN
    INSERT INTO payment_outbox_pending (
      instruction_id,
      participant_id,
      sequence_id,
      idempotency_key,
      rail_type,
      payload
    )
    VALUES (
      p_instruction_id,
      p_participant_id,
      allocated_sequence,
      p_idempotency_key,
      p_rail_type,
      p_payload
    )
    RETURNING payment_outbox_pending.outbox_id, payment_outbox_pending.sequence_id, payment_outbox_pending.created_at
    INTO existing_pending;
  EXCEPTION
    WHEN unique_violation THEN
      SELECT p.outbox_id, p.sequence_id, p.created_at
      INTO existing_pending
      FROM payment_outbox_pending p
      WHERE p.instruction_id = p_instruction_id
        AND p.idempotency_key = p_idempotency_key
      LIMIT 1;
      IF NOT FOUND THEN
        RAISE;
      END IF;
  END;

  RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
END;
$$;

COMMENT ON FUNCTION enqueue_payment_outbox(TEXT, TEXT, TEXT, TEXT, JSONB) IS
  'Authoritative enqueue: idempotency-safe insert with monotonic sequence allocation.';

ALTER FUNCTION enqueue_payment_outbox(TEXT, TEXT, TEXT, TEXT, JSONB) OWNER TO symphony_control;

-- --------------------------------------------------------------------
-- 4c) Lease-based claim/complete/repair functions (authoritative)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION claim_outbox_batch(
  p_batch_size INT,
  p_worker_id TEXT,
  p_lease_seconds INT
)
RETURNS TABLE (
  outbox_id UUID,
  instruction_id TEXT,
  participant_id TEXT,
  sequence_id BIGINT,
  idempotency_key TEXT,
  rail_type TEXT,
  payload JSONB,
  attempt_count INT,
  lease_token UUID,
  lease_expires_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
WITH due AS (
  SELECT p.outbox_id
  FROM payment_outbox_pending p
  WHERE p.next_attempt_at <= NOW()
    AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
  ORDER BY p.next_attempt_at ASC, p.created_at ASC
  LIMIT p_batch_size
  FOR UPDATE SKIP LOCKED
),
leased AS (
  UPDATE payment_outbox_pending p
  SET
    claimed_by = p_worker_id,
    lease_token = uuidv7(),
    lease_expires_at = NOW() + make_interval(secs => p_lease_seconds)
  FROM due
  WHERE p.outbox_id = due.outbox_id
  RETURNING
    p.outbox_id,
    p.instruction_id,
    p.participant_id,
    p.sequence_id,
    p.idempotency_key,
    p.rail_type,
    p.payload,
    p.attempt_count,
    p.lease_token,
    p.lease_expires_at
)
SELECT * FROM leased;
$$;

COMMENT ON FUNCTION claim_outbox_batch(INT, TEXT, INT) IS
  'Claims due pending rows by leasing them and returning the leased batch.';

ALTER FUNCTION claim_outbox_batch(INT, TEXT, INT) OWNER TO symphony_control;

CREATE OR REPLACE FUNCTION complete_outbox_attempt(
  p_outbox_id UUID,
  p_lease_token UUID,
  p_worker_id TEXT,
  p_state outbox_attempt_state,
  p_rail_reference TEXT DEFAULT NULL,
  p_rail_code TEXT DEFAULT NULL,
  p_error_code TEXT DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL,
  p_latency_ms INT DEFAULT NULL,
  p_retry_delay_seconds INT DEFAULT 1
)
RETURNS TABLE (
  attempt_no INT,
  state outbox_attempt_state
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_instruction_id TEXT;
  v_participant_id TEXT;
  v_sequence_id BIGINT;
  v_idempotency_key TEXT;
  v_rail_type TEXT;
  v_payload JSONB;
  v_attempt_count INT;
  v_next_attempt_no INT;
  v_effective_state outbox_attempt_state;
BEGIN
  SELECT
    p.instruction_id,
    p.participant_id,
    p.sequence_id,
    p.idempotency_key,
    p.rail_type,
    p.payload,
    p.attempt_count
  INTO
    v_instruction_id,
    v_participant_id,
    v_sequence_id,
    v_idempotency_key,
    v_rail_type,
    v_payload,
    v_attempt_count
  FROM payment_outbox_pending p
  WHERE p.outbox_id = p_outbox_id
    AND p.claimed_by = p_worker_id
    AND p.lease_token = p_lease_token
    AND p.lease_expires_at > NOW()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEASE_LOST'
      USING ERRCODE = 'P7002',
            DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
  END IF;

  IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
    RAISE EXCEPTION 'Invalid completion state %', p_state
      USING ERRCODE = 'P7003';
  END IF;

  SELECT COALESCE(MAX(a.attempt_no), 0) + 1
  INTO v_next_attempt_no
  FROM payment_outbox_attempts a
  WHERE a.outbox_id = p_outbox_id;

  v_effective_state := p_state;
  IF p_state = 'RETRYABLE' AND (v_attempt_count >= 20 OR v_next_attempt_no >= 20) THEN
    v_effective_state := 'FAILED';
  END IF;

  INSERT INTO payment_outbox_attempts (
    outbox_id,
    instruction_id,
    participant_id,
    sequence_id,
    idempotency_key,
    rail_type,
    payload,
    attempt_no,
    state,
    claimed_at,
    completed_at,
    rail_reference,
    rail_code,
    error_code,
    error_message,
    latency_ms,
    worker_id
  )
  VALUES (
    p_outbox_id,
    v_instruction_id,
    v_participant_id,
    v_sequence_id,
    v_idempotency_key,
    v_rail_type,
    v_payload,
    v_next_attempt_no,
    v_effective_state,
    NOW(),
    CASE WHEN v_effective_state IN ('DISPATCHED', 'FAILED') THEN NOW() ELSE NULL END,
    p_rail_reference,
    p_rail_code,
    p_error_code,
    p_error_message,
    p_latency_ms,
    p_worker_id
  );

  IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
    DELETE FROM payment_outbox_pending
    WHERE outbox_id = p_outbox_id;
  ELSE
    UPDATE payment_outbox_pending
    SET
      attempt_count = GREATEST(payment_outbox_pending.attempt_count, v_next_attempt_no),
      next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
      claimed_by = NULL,
      lease_token = NULL,
      lease_expires_at = NULL
    WHERE outbox_id = p_outbox_id;
  END IF;

  RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
END;
$$;

COMMENT ON FUNCTION complete_outbox_attempt(UUID, UUID, TEXT, outbox_attempt_state, TEXT, TEXT, TEXT, TEXT, INT, INT) IS
  'Completes a leased outbox item by inserting an outcome attempt and updating pending state.';

ALTER FUNCTION complete_outbox_attempt(
  UUID, UUID, TEXT, outbox_attempt_state, TEXT, TEXT, TEXT, TEXT, INT, INT
) OWNER TO symphony_control;

CREATE OR REPLACE FUNCTION repair_expired_leases(
  p_batch_size INT,
  p_worker_id TEXT
)
RETURNS TABLE (
  outbox_id UUID,
  attempt_no INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_record RECORD;
  v_next_attempt_no INT;
BEGIN
  FOR v_record IN
    SELECT
      p.outbox_id,
      p.instruction_id,
      p.participant_id,
      p.sequence_id,
      p.idempotency_key,
      p.rail_type,
      p.payload
    FROM payment_outbox_pending p
    WHERE p.claimed_by IS NOT NULL
      AND p.lease_token IS NOT NULL
      AND p.lease_expires_at <= NOW()
    ORDER BY p.lease_expires_at ASC, p.created_at ASC
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  LOOP
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1
    INTO v_next_attempt_no
    FROM payment_outbox_attempts a
    WHERE a.outbox_id = v_record.outbox_id;

    INSERT INTO payment_outbox_attempts (
      outbox_id,
      instruction_id,
      participant_id,
      sequence_id,
      idempotency_key,
      rail_type,
      payload,
      attempt_no,
      state,
      claimed_at,
      completed_at,
      worker_id
    )
    VALUES (
      v_record.outbox_id,
      v_record.instruction_id,
      v_record.participant_id,
      v_record.sequence_id,
      v_record.idempotency_key,
      v_record.rail_type,
      v_record.payload,
      v_next_attempt_no,
      'ZOMBIE_REQUEUE',
      NOW(),
      NOW(),
      p_worker_id
    );

    UPDATE payment_outbox_pending
    SET
      attempt_count = GREATEST(payment_outbox_pending.attempt_count, v_next_attempt_no),
      next_attempt_at = NOW() + INTERVAL '1 second',
      claimed_by = NULL,
      lease_token = NULL,
      lease_expires_at = NULL
    WHERE outbox_id = v_record.outbox_id;

    outbox_id := v_record.outbox_id;
    attempt_no := v_next_attempt_no;
    RETURN NEXT;
  END LOOP;

  RETURN;
END;
$$;

COMMENT ON FUNCTION repair_expired_leases(INT, TEXT) IS
  'Repairs expired leases by clearing the lease and appending a ZOMBIE_REQUEUE attempt.';

ALTER FUNCTION repair_expired_leases(INT, TEXT) OWNER TO symphony_control;

-- --------------------------------------------------------------------
-- 5) NOTIFY wakeup trigger (best-effort)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_outbox_pending()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM pg_notify('outbox_pending', 'new_work');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_outbox_pending ON payment_outbox_pending;

CREATE TRIGGER trg_notify_outbox_pending
AFTER INSERT ON payment_outbox_pending
FOR EACH ROW
EXECUTE FUNCTION notify_outbox_pending();

-- --------------------------------------------------------------------
-- 6) Supervisor view (derived from pending + attempts)
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW supervisor_outbox_status AS
WITH latest_attempts AS (
  SELECT DISTINCT ON (outbox_id)
    outbox_id,
    state,
    attempt_no,
    claimed_at,
    completed_at,
    created_at
  FROM payment_outbox_attempts
  ORDER BY outbox_id, claimed_at DESC
)
SELECT
  '7B.2.1' AS view_version,
  NOW() AS generated_at,
  (SELECT COUNT(*) FROM payment_outbox_pending) AS pending_count,
  (SELECT COUNT(*) FROM payment_outbox_pending WHERE next_attempt_at <= NOW()) AS due_pending_count,
  (SELECT COUNT(*)
   FROM payment_outbox_pending
   WHERE claimed_by IS NOT NULL
     AND lease_expires_at > NOW()) AS leased_count,
  (SELECT COUNT(*)
   FROM payment_outbox_pending
   WHERE claimed_by IS NOT NULL
     AND lease_expires_at <= NOW()) AS expired_lease_count,
  (SELECT COUNT(*)
   FROM payment_outbox_pending
   WHERE next_attempt_at <= NOW()
     AND (lease_expires_at IS NULL OR lease_expires_at <= NOW())
     AND claimed_by IS NULL) AS due_unleased_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHED') AS dispatched_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED') AS failed_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'RETRYABLE') AS retryable_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED' AND attempt_no >= 5) AS dlq_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 1) AS attempt_1,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 2) AS attempt_2,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 3) AS attempt_3,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 4) AS attempt_4,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no >= 5) AS attempt_5_plus,
  (
    SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
    FROM payment_outbox_pending
  ) AS oldest_pending_age_seconds,
  (
    SELECT COUNT(*)
    FROM payment_outbox_attempts
    WHERE state = 'DISPATCHED'
      AND completed_at >= NOW() - INTERVAL '1 hour'
  ) AS dispatched_last_hour,
  (
    SELECT COUNT(*)
    FROM payment_outbox_attempts
    WHERE state = 'FAILED'
      AND completed_at >= NOW() - INTERVAL '1 hour'
  ) AS failed_last_hour;

COMMENT ON VIEW supervisor_outbox_status IS
  'Phase-7B Option 2A: Supervisor view for pending depth, attempt states, aging, and dispatch throughput.';

COMMIT;
