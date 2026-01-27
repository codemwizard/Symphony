-- ============================================================
-- 0006_repair_expired_leases_retry_ceiling.sql
-- Enforce retry ceiling in repair_expired_leases
-- ============================================================

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
    v_record RECORD;
    v_next_attempt_no INT;
    v_retry_ceiling INT;
  BEGIN
    v_retry_ceiling := public.outbox_retry_ceiling();

    FOR v_record IN
      SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
             p.idempotency_key, p.rail_type, p.payload
      FROM payment_outbox_pending p
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
      ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
    LOOP
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;

      IF v_next_attempt_no >= v_retry_ceiling THEN
        INSERT INTO payment_outbox_attempts (
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          attempt_no, state, claimed_at, completed_at, error_code, error_message, worker_id
        ) VALUES (
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_next_attempt_no, 'FAILED', NOW(), NOW(),
          'RETRY_CEILING_EXCEEDED', 'expired lease repair hit retry ceiling', p_worker_id
        );

        DELETE FROM payment_outbox_pending WHERE outbox_id = v_record.outbox_id;
      ELSE
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
      END IF;

      outbox_id := v_record.outbox_id;
      attempt_no := v_next_attempt_no;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END;
$$;
