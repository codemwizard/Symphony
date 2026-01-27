-- ============================================================
-- 0002_outbox_functions.sql
-- Outbox functions: enqueue, claim, complete, repair
-- ============================================================

-- --------------------------------------------------------------------
-- Helper: Retry ceiling configuration (GUC)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.outbox_retry_ceiling()
RETURNS int
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('symphony.outbox_retry_ceiling', true), '')::int,
    20
  );
$$;

COMMENT ON FUNCTION public.outbox_retry_ceiling() IS
  'Returns the configured retry ceiling (symphony.outbox_retry_ceiling) or default 20.';

-- --------------------------------------------------------------------
-- Monotonic sequence allocator (authoritative)
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- Authoritative enqueue (idempotency-safe)
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

-- --------------------------------------------------------------------
-- Claim batch (lease-based)
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
     lease_token = public.uuid_v7_or_random(),
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

-- --------------------------------------------------------------------
-- Complete attempt
-- --------------------------------------------------------------------
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
    v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
    v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
    v_next_attempt_no INT; v_effective_state outbox_attempt_state;
  BEGIN
    SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
    INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
    FROM payment_outbox_pending p
    WHERE p.outbox_id = p_outbox_id AND p.claimed_by = p_worker_id
      AND p.lease_token = p_lease_token AND p.lease_expires_at > NOW()
    FOR UPDATE;
  
    IF NOT FOUND THEN
      RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002',
        DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
    END IF;
  
    IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
      RAISE EXCEPTION 'Invalid completion state %', p_state USING ERRCODE = 'P7003';
    END IF;
  
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    FROM payment_outbox_attempts a WHERE a.outbox_id = p_outbox_id;
  
    v_effective_state := p_state;
    -- Retry ceiling is a safety fuse to prevent infinite retry loops.
    -- Configurable via GUC; default 20.
    IF p_state = 'RETRYABLE' AND v_next_attempt_no >= public.outbox_retry_ceiling() THEN
      v_effective_state := 'FAILED';
    END IF;
  
    INSERT INTO payment_outbox_attempts (
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
      DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
    ELSE
      UPDATE payment_outbox_pending SET
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
      WHERE outbox_id = p_outbox_id;
    END IF;
  
    RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
  END;
$$;

-- --------------------------------------------------------------------
-- Repair expired leases
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION repair_expired_leases(
  p_batch_size INT,
  p_worker_id TEXT
)
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
      FROM payment_outbox_pending p
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
      ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
    LOOP
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;
  
      INSERT INTO payment_outbox_attempts (
        outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
        attempt_no, state, claimed_at, completed_at, worker_id
      ) VALUES (
        v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
        v_record.idempotency_key, v_record.rail_type, v_record.payload,
        v_next_attempt_no, 'ZOMBIE_REQUEUE', NOW(), NOW(), p_worker_id
      );
  
      UPDATE payment_outbox_pending SET
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        next_attempt_at = NOW() + INTERVAL '1 second',
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
      WHERE payment_outbox_pending.outbox_id = v_record.outbox_id;
  
      outbox_id := v_record.outbox_id;
      attempt_no := v_next_attempt_no;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END;
$$;
