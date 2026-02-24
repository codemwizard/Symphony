-- 0051_hier_006_supervisor_access_modes.sql
-- TSK-P1-HIER-006: append-only member_device_events anchored to ingress FK + supervisor access semantics.

CREATE TABLE IF NOT EXISTS public.supervisor_access_policies (
  scope TEXT PRIMARY KEY CHECK (scope IN ('READ_ONLY', 'AUDIT', 'APPROVAL_REQUIRED')),
  description TEXT NOT NULL,
  api_access BOOLEAN NOT NULL,
  db_access BOOLEAN NOT NULL,
  report_delivery BOOLEAN NOT NULL,
  read_window_minutes INTEGER NULL CHECK (read_window_minutes IS NULL OR read_window_minutes > 0),
  hold_timeout_minutes INTEGER NULL CHECK (hold_timeout_minutes IS NULL OR hold_timeout_minutes > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.supervisor_access_policies(scope, description, api_access, db_access, report_delivery, read_window_minutes, hold_timeout_minutes)
VALUES
  ('READ_ONLY', 'Periodic signed aggregate report delivery only; no API and no DB access.', FALSE, FALSE, TRUE, NULL, NULL),
  ('AUDIT', 'Time-bounded read-only token scoped to program_id with anonymized event records.', TRUE, FALSE, FALSE, 60, NULL),
  ('APPROVAL_REQUIRED', 'Instruction hold state requiring supervisor approve/reject before continuation.', TRUE, FALSE, FALSE, NULL, 30)
ON CONFLICT (scope) DO UPDATE
SET description = EXCLUDED.description,
    api_access = EXCLUDED.api_access,
    db_access = EXCLUDED.db_access,
    report_delivery = EXCLUDED.report_delivery,
    read_window_minutes = EXCLUDED.read_window_minutes,
    hold_timeout_minutes = EXCLUDED.hold_timeout_minutes;

CREATE TABLE IF NOT EXISTS public.supervisor_audit_tokens (
  token_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  scope TEXT NOT NULL DEFAULT 'AUDIT' CHECK (scope = 'AUDIT'),
  token_hash TEXT NOT NULL UNIQUE,
  issued_by TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_supervisor_audit_tokens_program_expires
  ON public.supervisor_audit_tokens(program_id, expires_at DESC);

CREATE OR REPLACE VIEW public.supervisor_audit_member_device_events AS
SELECT
  m.entity_id AS program_id,
  e.tenant_id,
  e.member_id,
  e.instruction_id,
  e.event_type,
  e.observed_at
FROM public.member_device_events e
JOIN public.members m ON m.member_id = e.member_id;

CREATE TABLE IF NOT EXISTS public.supervisor_approval_queue (
  instruction_id TEXT PRIMARY KEY,
  program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  status TEXT NOT NULL CHECK (status IN ('PENDING_SUPERVISOR_APPROVAL', 'APPROVED', 'REJECTED', 'TIMED_OUT')),
  held_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  timeout_at TIMESTAMPTZ NOT NULL,
  decided_at TIMESTAMPTZ NULL,
  decided_by TEXT NULL,
  decision_reason TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_supervisor_approval_queue_status_timeout
  ON public.supervisor_approval_queue(status, timeout_at);

CREATE OR REPLACE FUNCTION public.submit_for_supervisor_approval(
  p_instruction_id TEXT,
  p_program_id UUID,
  p_timeout_minutes INTEGER DEFAULT 30
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
BEGIN
  IF v_timeout <= 0 THEN
    RAISE EXCEPTION 'approval timeout must be positive';
  END IF;

  INSERT INTO public.supervisor_approval_queue(
    instruction_id, program_id, status, held_at, timeout_at, decided_at, decided_by, decision_reason
  ) VALUES (
    p_instruction_id, p_program_id, 'PENDING_SUPERVISOR_APPROVAL', NOW(), NOW() + make_interval(mins => v_timeout), NULL, NULL, NULL
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET program_id = EXCLUDED.program_id,
        status = 'PENDING_SUPERVISOR_APPROVAL',
        held_at = NOW(),
        timeout_at = NOW() + make_interval(mins => v_timeout),
        decided_at = NULL,
        decided_by = NULL,
        decision_reason = NULL;
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
BEGIN
  IF v_decision NOT IN ('APPROVED', 'REJECTED') THEN
    RAISE EXCEPTION 'invalid decision %', p_decision;
  END IF;

  UPDATE public.supervisor_approval_queue
  SET status = v_decision,
      decided_at = NOW(),
      decided_by = COALESCE(NULLIF(BTRIM(p_actor), ''), 'system'),
      decision_reason = p_reason
  WHERE instruction_id = p_instruction_id
    AND status = 'PENDING_SUPERVISOR_APPROVAL';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'instruction % is not pending supervisor approval', p_instruction_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.expire_supervisor_approvals(
  p_now TIMESTAMPTZ DEFAULT NOW()
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.supervisor_approval_queue
  SET status = 'TIMED_OUT',
      decided_at = p_now,
      decided_by = 'system_timeout',
      decision_reason = COALESCE(decision_reason, 'timeout')
  WHERE status = 'PENDING_SUPERVISOR_APPROVAL'
    AND timeout_at <= p_now;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON TABLE public.supervisor_access_policies FROM PUBLIC;
REVOKE ALL ON TABLE public.supervisor_audit_tokens FROM PUBLIC;
REVOKE ALL ON TABLE public.supervisor_approval_queue FROM PUBLIC;
REVOKE ALL ON TABLE public.supervisor_audit_member_device_events FROM PUBLIC;

