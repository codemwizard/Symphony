-- 0063_hard_wave2_adjustment_governance.sql

CREATE TYPE public.adjustment_state_enum AS ENUM (
  'requested',
  'pending_approval',
  'cooling_off',
  'eligible_execute',
  'executed',
  'denied',
  'blocked_legal_hold'
);

CREATE TABLE public.adjustment_instructions (
  adjustment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_instruction_id text NOT NULL,
  adjustment_state public.adjustment_state_enum NOT NULL DEFAULT 'requested',
  adjustment_type text NOT NULL,
  adjustment_value numeric(18,2) NOT NULL,
  recipient_ref text NOT NULL,
  justification text,
  policy_version_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT adjustment_parent_fk FOREIGN KEY (parent_instruction_id)
    REFERENCES public.inquiry_state_machine(instruction_id)
);

CREATE TABLE public.adjustment_approval_stages (
  stage_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.adjustment_instructions(adjustment_id),
  required_approver_count integer NOT NULL,
  quorum_threshold integer NOT NULL,
  stage_status text NOT NULL,
  quorum_policy_version_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.adjustment_approvals (
  approval_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_id uuid NOT NULL REFERENCES public.adjustment_approval_stages(stage_id),
  approver_id text NOT NULL,
  role_at_time_of_signing text NOT NULL,
  department_at_time_of_signing text NOT NULL,
  attestation_timestamp timestamptz NOT NULL DEFAULT now(),
  signature_ref text NOT NULL,
  unsigned_reason text,
  UNIQUE(stage_id, approver_id)
);

CREATE TABLE public.adjustment_execution_attempts (
  attempt_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.adjustment_instructions(adjustment_id),
  idempotency_key text NOT NULL,
  adjustment_value numeric(18,2) NOT NULL,
  attempt_timestamp timestamptz NOT NULL DEFAULT now(),
  dispatch_reference text,
  outcome text NOT NULL,
  UNIQUE(adjustment_id, idempotency_key)
);

CREATE TABLE public.adjustment_freeze_flags (
  flag_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.adjustment_instructions(adjustment_id),
  flag_type text NOT NULL,
  authority_reference text NOT NULL,
  operator_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  active boolean NOT NULL DEFAULT true
);

CREATE OR REPLACE FUNCTION public.issue_adjustment(
  p_parent_instruction_id text,
  p_adjustment_type text,
  p_adjustment_value numeric,
  p_policy_version_id text,
  p_justification text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_id uuid;
  v_recipient text;
BEGIN
  SELECT 'parent:' || p_parent_instruction_id INTO v_recipient;
  INSERT INTO public.adjustment_instructions(
    parent_instruction_id, adjustment_type, adjustment_value,
    recipient_ref, policy_version_id, justification
  ) VALUES (
    p_parent_instruction_id, p_adjustment_type, p_adjustment_value,
    v_recipient, p_policy_version_id, p_justification
  ) RETURNING adjustment_id INTO v_id;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.issue_adjustment_with_recipient(
  p_parent_instruction_id text,
  p_recipient text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  RAISE EXCEPTION 'ADJUSTMENT_RECIPIENT_NOT_PERMITTED' USING ERRCODE = 'P7601';
END;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_adjustment_ceiling(
  p_adjustment_id uuid,
  p_parent_instruction_value numeric
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_parent text;
  v_total numeric;
BEGIN
  SELECT parent_instruction_id INTO v_parent FROM public.adjustment_instructions WHERE adjustment_id = p_adjustment_id;
  SELECT coalesce(sum(a.adjustment_value),0)
  INTO v_total
  FROM public.adjustment_execution_attempts e
  JOIN public.adjustment_instructions a ON a.adjustment_id=e.adjustment_id
  WHERE a.parent_instruction_id=v_parent AND e.outcome='executed';

  IF v_total > p_parent_instruction_value THEN
    RAISE EXCEPTION 'ADJUSTMENT_CEILING_BREACH' USING ERRCODE = 'P7201';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_adjustment_execution_allowed(
  p_adjustment_id uuid,
  p_current_state public.adjustment_state_enum,
  p_freeze_flag_type text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_current_state = 'cooling_off' THEN
    RAISE EXCEPTION 'ADJUSTMENT_COOLING_OFF_ACTIVE' USING ERRCODE = 'P7701';
  END IF;
  IF p_freeze_flag_type IS NOT NULL THEN
    RAISE EXCEPTION 'ADJUSTMENT_FREEZE_BLOCK' USING ERRCODE = 'P7702';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_adjustment_terminal_immutability()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP='UPDATE' AND OLD.adjustment_state IN ('executed','denied','blocked_legal_hold') THEN
    RAISE EXCEPTION 'ADJUSTMENT_TERMINAL_IMMUTABLE' USING ERRCODE = 'P7101';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_adjustment_terminal_immutability ON public.adjustment_instructions;
CREATE TRIGGER trg_adjustment_terminal_immutability
BEFORE UPDATE ON public.adjustment_instructions
FOR EACH ROW EXECUTE FUNCTION public.enforce_adjustment_terminal_immutability();

REVOKE ALL ON TABLE public.adjustment_instructions FROM PUBLIC;
REVOKE ALL ON TABLE public.adjustment_approval_stages FROM PUBLIC;
REVOKE ALL ON TABLE public.adjustment_approvals FROM PUBLIC;
REVOKE ALL ON TABLE public.adjustment_execution_attempts FROM PUBLIC;
REVOKE ALL ON TABLE public.adjustment_freeze_flags FROM PUBLIC;
