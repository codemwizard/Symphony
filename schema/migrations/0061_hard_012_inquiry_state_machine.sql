DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'inquiry_state_enum' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.inquiry_state_enum AS ENUM ('SCHEDULED', 'SENT', 'ACKNOWLEDGED', 'EXHAUSTED');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS public.inquiry_state_machine (
  instruction_id TEXT PRIMARY KEY,
  inquiry_state public.inquiry_state_enum NOT NULL DEFAULT 'SCHEDULED',
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL CHECK (max_attempts > 0),
  policy_version_id TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.touch_inquiry_state_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_inquiry_state_machine_updated_at ON public.inquiry_state_machine;
CREATE TRIGGER trg_touch_inquiry_state_machine_updated_at
BEFORE UPDATE ON public.inquiry_state_machine
FOR EACH ROW
EXECUTE FUNCTION public.touch_inquiry_state_updated_at();

CREATE OR REPLACE FUNCTION public.apply_inquiry_attempt(
  p_instruction_id TEXT,
  p_policy_version_id TEXT,
  p_max_attempts INTEGER
)
RETURNS public.inquiry_state_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state public.inquiry_state_enum;
  v_attempts INTEGER;
  v_max INTEGER;
BEGIN
  IF p_max_attempts IS NULL OR p_max_attempts <= 0 THEN
    RAISE EXCEPTION 'invalid_max_attempts' USING ERRCODE = 'P7302';
  END IF;

  INSERT INTO public.inquiry_state_machine(instruction_id, inquiry_state, attempts, max_attempts, policy_version_id)
  VALUES (p_instruction_id, 'SCHEDULED', 0, p_max_attempts, p_policy_version_id)
  ON CONFLICT (instruction_id) DO NOTHING;

  SELECT inquiry_state, attempts, max_attempts INTO v_state, v_attempts, v_max
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IN ('ACKNOWLEDGED', 'EXHAUSTED') THEN
    RAISE EXCEPTION 'illegal_transition_from_terminal_inquiry_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  v_attempts := v_attempts + 1;

  IF v_attempts >= v_max THEN
    UPDATE public.inquiry_state_machine
    SET attempts = v_attempts,
        inquiry_state = 'EXHAUSTED',
        policy_version_id = p_policy_version_id,
        max_attempts = p_max_attempts
    WHERE instruction_id = p_instruction_id;
    RETURN 'EXHAUSTED';
  END IF;

  UPDATE public.inquiry_state_machine
  SET attempts = v_attempts,
      inquiry_state = 'SENT',
      policy_version_id = p_policy_version_id,
      max_attempts = p_max_attempts
  WHERE instruction_id = p_instruction_id;
  RETURN 'SENT';
END;
$$;

CREATE OR REPLACE FUNCTION public.acknowledge_inquiry_response(
  p_instruction_id TEXT,
  p_policy_version_id TEXT
)
RETURNS public.inquiry_state_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state public.inquiry_state_enum;
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL THEN
    RAISE EXCEPTION 'inquiry_not_found' USING ERRCODE = 'P7300';
  END IF;

  IF v_state <> 'SENT' THEN
    RAISE EXCEPTION 'illegal_transition_to_acknowledged_from:%', v_state USING ERRCODE = 'P7300';
  END IF;

  UPDATE public.inquiry_state_machine
  SET inquiry_state = 'ACKNOWLEDGED',
      policy_version_id = p_policy_version_id
  WHERE instruction_id = p_instruction_id;

  RETURN 'ACKNOWLEDGED';
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(
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

  IF v_state = 'EXHAUSTED' THEN
    RAISE EXCEPTION 'INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED' USING ERRCODE = 'P7301';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.apply_inquiry_attempt(TEXT, TEXT, INTEGER)
  IS 'TSK-HARD-012: applies one inquiry attempt using policy-resolved max_attempts; transitions SENT/EXHAUSTED.';
COMMENT ON FUNCTION public.acknowledge_inquiry_response(TEXT, TEXT)
  IS 'TSK-HARD-012: allows only SENT -> ACKNOWLEDGED transition.';
COMMENT ON FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(TEXT)
  IS 'TSK-HARD-012: fail-closed guard for auto-finalization while inquiry is EXHAUSTED (P7301).';

REVOKE ALL ON FUNCTION public.apply_inquiry_attempt(TEXT, TEXT, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.acknowledge_inquiry_response(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(TEXT) FROM PUBLIC;
