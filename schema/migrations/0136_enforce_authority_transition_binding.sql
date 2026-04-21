-- Migration 0136: Install INV-AUTH-TRANSITION-BINDING-01 enforcement function
-- Task: TSK-P2-PREAUTH-004-03
-- This migration installs the enforce_authority_transition_binding function
-- with SECURITY DEFINER hardening as per AGENTS.md hard constraints

CREATE OR REPLACE FUNCTION public.enforce_authority_transition_binding(
  p_execution_id         uuid,
  p_policy_decision_id   uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_pd_execution_id      uuid;
  v_er_exists            boolean;
BEGIN
  -- Step 1: resolve the policy_decisions row. If absent, reject.
  SELECT execution_id
    INTO v_pd_execution_id
    FROM public.policy_decisions
    WHERE policy_decision_id = p_policy_decision_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'authority_transition_binding: no policy_decision row for policy_decision_id';
  END IF;

  -- Step 2: confirm the execution_records row exists. execution_records does NOT
  -- carry entity_type/entity_id on Wave 4 (see "Execution-side entity binding gap"
  -- in the PLAN); existence-only is the strongest check implementable here.
  SELECT EXISTS (
    SELECT 1 FROM public.execution_records WHERE execution_id = p_execution_id
  ) INTO v_er_exists;

  IF NOT v_er_exists THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'authority_transition_binding: no execution_records row for execution_id';
  END IF;

  -- Step 3: the decision's execution_id must equal the transition's execution_id.
  -- FK on policy_decisions.execution_id already binds the decision to AN execution;
  -- this equality ensures it is binding to THIS execution.
  IF v_pd_execution_id IS DISTINCT FROM p_execution_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'authority_transition_binding: execution_id mismatch';
  END IF;
END;
$$;
