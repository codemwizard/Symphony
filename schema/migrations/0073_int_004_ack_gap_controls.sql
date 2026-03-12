-- 0073_int_004_ack_gap_controls.sql
-- TSK-P1-INT-004: AWAITING_EXECUTION lifecycle, missing-ack escalation, supervisor recovery, and append-only interrupt audit trail.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'inquiry_state_enum'
      AND e.enumlabel = 'AWAITING_EXECUTION'
  ) THEN
    ALTER TYPE public.inquiry_state_enum ADD VALUE 'AWAITING_EXECUTION' AFTER 'SENT';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'inquiry_state_enum'
      AND e.enumlabel = 'ESCALATED'
  ) THEN
    ALTER TYPE public.inquiry_state_enum ADD VALUE 'ESCALATED' AFTER 'AWAITING_EXECUTION';
  END IF;
END$$;

ALTER TABLE public.supervisor_approval_queue
  ADD COLUMN IF NOT EXISTS escalated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reset_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resumed_at TIMESTAMPTZ;

ALTER TABLE public.supervisor_approval_queue
  DROP CONSTRAINT IF EXISTS supervisor_approval_queue_status_check;

ALTER TABLE public.supervisor_approval_queue
  ADD CONSTRAINT supervisor_approval_queue_status_check
  CHECK (status IN (
    'PENDING_SUPERVISOR_APPROVAL',
    'APPROVED',
    'REJECTED',
    'TIMED_OUT',
    'ESCALATED',
    'RESET'
  ));

CREATE TABLE IF NOT EXISTS public.supervisor_interrupt_audit_events (
  event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  instruction_id TEXT NOT NULL,
  program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  action TEXT NOT NULL CHECK (action IN ('ESCALATED', 'ACKNOWLEDGED', 'RESUMED', 'RESET')),
  queue_status TEXT NOT NULL CHECK (queue_status IN (
    'PENDING_SUPERVISOR_APPROVAL',
    'APPROVED',
    'REJECTED',
    'TIMED_OUT',
    'ESCALATED',
    'RESET'
  )),
  actor TEXT NOT NULL,
  reason TEXT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_supervisor_interrupt_audit_events_instruction_recorded
  ON public.supervisor_interrupt_audit_events(instruction_id, recorded_at DESC);

CREATE OR REPLACE FUNCTION public.mark_instruction_awaiting_execution(
  p_instruction_id TEXT,
  p_program_id UUID,
  p_policy_version_id TEXT,
  p_actor TEXT DEFAULT 'system'
)
RETURNS public.inquiry_state_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  INSERT INTO public.inquiry_state_machine(
    instruction_id, inquiry_state, attempts, max_attempts, policy_version_id
  ) VALUES (
    p_instruction_id, 'AWAITING_EXECUTION', 0, 1, p_policy_version_id
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET inquiry_state = 'AWAITING_EXECUTION',
        policy_version_id = EXCLUDED.policy_version_id;

  RETURN 'AWAITING_EXECUTION';
END;
$$;

CREATE OR REPLACE FUNCTION public.escalate_missing_acknowledgement(
  p_instruction_id TEXT,
  p_program_id UUID,
  p_policy_version_id TEXT,
  p_actor TEXT DEFAULT 'system',
  p_reason TEXT DEFAULT 'missing_acknowledgement',
  p_timeout_minutes INTEGER DEFAULT 30
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state public.inquiry_state_enum;
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL THEN
    RAISE EXCEPTION 'acknowledgement_state_not_found' USING ERRCODE = 'P7300';
  END IF;

  IF v_state <> 'AWAITING_EXECUTION' THEN
    RAISE EXCEPTION 'illegal_escalation_from_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  PERFORM public.submit_for_supervisor_approval(
    p_instruction_id,
    p_program_id,
    p_timeout_minutes,
    p_reason,
    v_actor
  );

  UPDATE public.supervisor_approval_queue
  SET status = 'ESCALATED',
      held_reason = COALESCE(p_reason, held_reason, 'missing_acknowledgement'),
      escalated_at = NOW(),
      decided_at = NULL,
      decided_by = NULL,
      decision_reason = NULL
  WHERE instruction_id = p_instruction_id;

  UPDATE public.inquiry_state_machine
  SET inquiry_state = 'ESCALATED',
      policy_version_id = p_policy_version_id
  WHERE instruction_id = p_instruction_id;

  INSERT INTO public.supervisor_interrupt_audit_events(
    instruction_id, program_id, action, queue_status, actor, reason
  ) VALUES (
    p_instruction_id, p_program_id, 'ESCALATED', 'ESCALATED', v_actor, p_reason
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_missing_acknowledgement_interrupt(
  p_instruction_id TEXT,
  p_action TEXT,
  p_actor TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS public.inquiry_state_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_action TEXT := UPPER(BTRIM(COALESCE(p_action, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
  v_program_id UUID;
  v_state public.inquiry_state_enum;
  v_queue_status TEXT;
BEGIN
  IF v_action NOT IN ('ACKNOWLEDGE', 'RESUME', 'RESET') THEN
    RAISE EXCEPTION 'invalid_interrupt_action:%', p_action USING ERRCODE = 'P7300';
  END IF;

  SELECT program_id INTO v_program_id
  FROM public.supervisor_approval_queue
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'supervisor_interrupt_not_found' USING ERRCODE = 'P7300';
  END IF;

  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL OR v_state NOT IN ('ESCALATED', 'AWAITING_EXECUTION') THEN
    RAISE EXCEPTION 'illegal_interrupt_resolution_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  IF v_action = 'ACKNOWLEDGE' THEN
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'ACKNOWLEDGED'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'APPROVED',
        approved_at = NOW(),
        approved_by = v_actor,
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'acknowledged')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'APPROVED';
    v_state := 'ACKNOWLEDGED';
  ELSIF v_action = 'RESUME' THEN
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'AWAITING_EXECUTION'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'APPROVED',
        resumed_at = NOW(),
        approved_at = NOW(),
        approved_by = v_actor,
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'resume_ack_wait')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'APPROVED';
    v_state := 'AWAITING_EXECUTION';
  ELSE
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'AWAITING_EXECUTION'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'RESET',
        reset_at = NOW(),
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'reset_to_ack_wait')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'RESET';
    v_state := 'AWAITING_EXECUTION';
  END IF;

  INSERT INTO public.supervisor_interrupt_audit_events(
    instruction_id, program_id, action, queue_status, actor, reason
  ) VALUES (
    p_instruction_id, v_program_id,
    CASE v_action
      WHEN 'ACKNOWLEDGE' THEN 'ACKNOWLEDGED'
      WHEN 'RESUME' THEN 'RESUMED'
      ELSE 'RESET'
    END,
    v_queue_status,
    v_actor,
    p_reason
  );

  RETURN v_state;
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_settlement_requires_acknowledgement(
  p_instruction_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state public.inquiry_state_enum;
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id;

  IF v_state IS DISTINCT FROM 'ACKNOWLEDGED' THEN
    RAISE EXCEPTION 'ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT' USING ERRCODE = 'P7301';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_settlement_acknowledgement()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.final_state = 'SETTLED' THEN
    PERFORM public.guard_settlement_requires_acknowledgement(NEW.instruction_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_settlement_acknowledgement
  ON public.instruction_settlement_finality;

CREATE TRIGGER trg_enforce_settlement_acknowledgement
BEFORE INSERT ON public.instruction_settlement_finality
FOR EACH ROW
EXECUTE FUNCTION public.enforce_settlement_acknowledgement();

COMMENT ON FUNCTION public.mark_instruction_awaiting_execution(TEXT, UUID, TEXT, TEXT)
  IS 'TSK-P1-INT-004: records post-egress pre-ack lifecycle as AWAITING_EXECUTION.';
COMMENT ON FUNCTION public.escalate_missing_acknowledgement(TEXT, UUID, TEXT, TEXT, TEXT, INTEGER)
  IS 'TSK-P1-INT-004: reuses supervisor_approval_queue for missing-ack Tier-3 interrupt escalation and writes append-only audit events.';
COMMENT ON FUNCTION public.resolve_missing_acknowledgement_interrupt(TEXT, TEXT, TEXT, TEXT)
  IS 'TSK-P1-INT-004: supports ACKNOWLEDGE, RESUME, and RESET interrupt actions with append-only audit evidence; RESET returns to AWAITING_EXECUTION only.';
COMMENT ON FUNCTION public.guard_settlement_requires_acknowledgement(TEXT)
  IS 'TSK-P1-INT-004: fail-closed settlement guard requiring explicit acknowledgement state.';
COMMENT ON FUNCTION public.enforce_settlement_acknowledgement()
  IS 'TSK-P1-INT-004: wires acknowledgement guard into settlement writes so SETTLED records fail closed until ACKNOWLEDGED.';

REVOKE ALL ON TABLE public.supervisor_interrupt_audit_events FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_instruction_awaiting_execution(TEXT, UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.escalate_missing_acknowledgement(TEXT, UUID, TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_missing_acknowledgement_interrupt(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.guard_settlement_requires_acknowledgement(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enforce_settlement_acknowledgement() FROM PUBLIC;
