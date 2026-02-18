-- 0031_rail_sequence_truth_anchor_continuity.sql
-- INV-116: rail truth-anchor sequence continuity (Phase-1)

CREATE TABLE IF NOT EXISTS public.rail_dispatch_truth_anchor (
  anchor_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  attempt_id UUID NOT NULL,
  outbox_id UUID NOT NULL,
  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  rail_participant_id TEXT NOT NULL,
  rail_profile TEXT NOT NULL,
  rail_sequence_ref TEXT NOT NULL,
  state outbox_attempt_state NOT NULL,
  anchored_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ux_rail_truth_anchor_attempt_id UNIQUE (attempt_id),
  CONSTRAINT ux_rail_truth_anchor_sequence_scope UNIQUE (rail_sequence_ref, rail_participant_id, rail_profile),
  CONSTRAINT rail_truth_anchor_state_chk CHECK (state = 'DISPATCHED')
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rail_truth_anchor_attempt_fk'
      AND conrelid = 'public.rail_dispatch_truth_anchor'::regclass
  ) THEN
    ALTER TABLE public.rail_dispatch_truth_anchor
      ADD CONSTRAINT rail_truth_anchor_attempt_fk
      FOREIGN KEY (attempt_id)
      REFERENCES public.payment_outbox_attempts(attempt_id)
      DEFERRABLE INITIALLY IMMEDIATE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rail_truth_anchor_participant_anchored
  ON public.rail_dispatch_truth_anchor(rail_participant_id, anchored_at DESC);

CREATE OR REPLACE FUNCTION public.anchor_dispatched_outbox_attempt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_sequence_ref TEXT;
  v_profile TEXT;
BEGIN
  IF NEW.state <> 'DISPATCHED' THEN
    RETURN NEW;
  END IF;

  v_sequence_ref := NULLIF(BTRIM(NEW.rail_reference), '');
  IF v_sequence_ref IS NULL THEN
    RAISE EXCEPTION 'dispatch requires rail sequence reference'
      USING ERRCODE = 'P7005';
  END IF;

  v_profile := COALESCE(NULLIF(BTRIM(NEW.rail_type), ''), 'GENERIC');

  INSERT INTO public.rail_dispatch_truth_anchor(
    attempt_id,
    outbox_id,
    instruction_id,
    participant_id,
    rail_participant_id,
    rail_profile,
    rail_sequence_ref,
    state
  ) VALUES (
    NEW.attempt_id,
    NEW.outbox_id,
    NEW.instruction_id,
    NEW.participant_id,
    NEW.participant_id,
    v_profile,
    v_sequence_ref,
    NEW.state
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_anchor_dispatched_outbox_attempt ON public.payment_outbox_attempts;

CREATE TRIGGER trg_anchor_dispatched_outbox_attempt
AFTER INSERT ON public.payment_outbox_attempts
FOR EACH ROW
EXECUTE FUNCTION public.anchor_dispatched_outbox_attempt();

DROP TRIGGER IF EXISTS trg_deny_rail_dispatch_truth_anchor_mutation ON public.rail_dispatch_truth_anchor;

CREATE TRIGGER trg_deny_rail_dispatch_truth_anchor_mutation
BEFORE UPDATE OR DELETE ON public.rail_dispatch_truth_anchor
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

REVOKE ALL ON TABLE public.rail_dispatch_truth_anchor FROM PUBLIC;
REVOKE ALL ON TABLE public.rail_dispatch_truth_anchor FROM symphony_executor;
GRANT SELECT ON TABLE public.rail_dispatch_truth_anchor TO symphony_readonly;
