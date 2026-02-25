-- 0058_hier_011_supervisor_access_mechanisms.sql
-- TSK-P1-HIER-011: concrete supervisor access mechanisms (READ_ONLY report signing, AUDIT token API posture, APPROVAL_REQUIRED self-approval guard).

ALTER TABLE public.supervisor_approval_queue
  ADD COLUMN IF NOT EXISTS held_reason TEXT,
  ADD COLUMN IF NOT EXISTS submitted_by TEXT,
  ADD COLUMN IF NOT EXISTS approved_by TEXT,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

UPDATE public.supervisor_approval_queue
SET submitted_by = COALESCE(submitted_by, decided_by, 'system')
WHERE submitted_by IS NULL;

CREATE OR REPLACE FUNCTION public.submit_for_supervisor_approval(
  p_instruction_id TEXT,
  p_program_id UUID,
  p_timeout_minutes INTEGER DEFAULT 30,
  p_held_reason TEXT DEFAULT NULL,
  p_submitted_by TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
  v_submitted_by TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_submitted_by, '')), ''), 'system');
BEGIN
  IF v_timeout <= 0 THEN
    RAISE EXCEPTION 'approval timeout must be positive';
  END IF;

  INSERT INTO public.supervisor_approval_queue(
    instruction_id, program_id, status, held_at, held_reason, timeout_at, submitted_by,
    decided_at, decided_by, decision_reason, approved_by, approved_at
  ) VALUES (
    p_instruction_id,
    p_program_id,
    'PENDING_SUPERVISOR_APPROVAL',
    NOW(),
    p_held_reason,
    NOW() + make_interval(mins => v_timeout),
    v_submitted_by,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET program_id = EXCLUDED.program_id,
        status = 'PENDING_SUPERVISOR_APPROVAL',
        held_at = NOW(),
        held_reason = EXCLUDED.held_reason,
        timeout_at = EXCLUDED.timeout_at,
        submitted_by = EXCLUDED.submitted_by,
        decided_at = NULL,
        decided_by = NULL,
        decision_reason = NULL,
        approved_by = NULL,
        approved_at = NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_for_supervisor_approval(
  p_instruction_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_program_id UUID;
BEGIN
  SELECT program_id
  INTO v_program_id
  FROM public.programs
  ORDER BY created_at ASC
  LIMIT 1;

  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'no program available for supervisor approval submission';
  END IF;

  PERFORM public.submit_for_supervisor_approval(p_instruction_id, v_program_id, 30, NULL, 'system');
END;
$$;

CREATE OR REPLACE FUNCTION public.decide_supervisor_approval(
  p_instruction_id TEXT,
  p_decision TEXT,
  p_actor TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_decision TEXT := UPPER(BTRIM(COALESCE(p_decision, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
BEGIN
  IF v_decision NOT IN ('APPROVED', 'REJECTED') THEN
    RAISE EXCEPTION 'invalid decision %', p_decision;
  END IF;

  UPDATE public.supervisor_approval_queue
  SET status = v_decision,
      approved_at = CASE WHEN v_decision = 'APPROVED' THEN NOW() ELSE approved_at END,
      approved_by = CASE WHEN v_decision = 'APPROVED' THEN v_actor ELSE approved_by END,
      decided_at = NOW(),
      decided_by = v_actor,
      decision_reason = p_reason
  WHERE instruction_id = p_instruction_id
    AND status = 'PENDING_SUPERVISOR_APPROVAL'
    AND COALESCE(submitted_by, '') <> v_actor;

  IF NOT FOUND THEN
    IF EXISTS (
      SELECT 1
      FROM public.supervisor_approval_queue
      WHERE instruction_id = p_instruction_id
        AND status = 'PENDING_SUPERVISOR_APPROVAL'
        AND COALESCE(submitted_by, '') = v_actor
    ) THEN
      RAISE EXCEPTION 'self approval is not permitted for instruction %', p_instruction_id
        USING ERRCODE = '42501';
    END IF;

    RAISE EXCEPTION 'instruction % is not pending supervisor approval', p_instruction_id;
  END IF;
END;
$$;
