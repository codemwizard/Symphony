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

  attempt_count INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0 AND attempt_count <= 20),
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id),
  CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key),
  CONSTRAINT ck_pending_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_pending_due
  ON payment_outbox_pending (next_attempt_at, created_at);

CREATE INDEX IF NOT EXISTS ix_pending_participant
  ON payment_outbox_pending (participant_id, next_attempt_at);

COMMENT ON TABLE payment_outbox_pending IS
  'Option 2A hot outbox queue. Rows are deleted when claimed (DELETE...RETURNING).';
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

CREATE INDEX IF NOT EXISTS ix_attempts_dispatching_age
  ON payment_outbox_attempts (claimed_at)
  WHERE state = 'DISPATCHING';

CREATE INDEX IF NOT EXISTS ix_attempts_instruction
  ON payment_outbox_attempts (instruction_id, claimed_at DESC);

CREATE INDEX IF NOT EXISTS ix_attempts_idempotency
  ON payment_outbox_attempts (instruction_id, idempotency_key, claimed_at DESC);

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
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_instruction_id, 1),
    hashtextextended(p_idempotency_key, 2)
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
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHING') AS dispatching_count,
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
    FROM latest_attempts
    WHERE state = 'DISPATCHING'
      AND claimed_at < NOW() - INTERVAL '120 seconds'
  ) AS stuck_dispatching_count,
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
