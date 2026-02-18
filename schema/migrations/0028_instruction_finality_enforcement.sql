-- 0028_instruction_finality_enforcement.sql
-- INV-114: instruction finality / reversal-only enforcement (Phase-1)

CREATE TABLE IF NOT EXISTS public.instruction_settlement_finality (
  finality_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  is_final BOOLEAN NOT NULL DEFAULT TRUE,
  final_state TEXT NOT NULL CHECK (final_state IN ('SETTLED', 'REVERSED')),
  rail_message_type TEXT NOT NULL CHECK (rail_message_type IN ('pacs.008', 'camt.056')),
  reversal_of_instruction_id TEXT NULL,
  finalized_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NULL,
  CONSTRAINT ux_instruction_settlement_finality_instruction UNIQUE (instruction_id),
  CONSTRAINT instruction_settlement_finality_is_final_true_chk CHECK (is_final = TRUE),
  CONSTRAINT instruction_settlement_finality_self_reversal_chk CHECK (
    reversal_of_instruction_id IS NULL OR reversal_of_instruction_id <> instruction_id
  ),
  CONSTRAINT instruction_settlement_finality_shape_chk CHECK (
    (
      final_state = 'SETTLED'
      AND reversal_of_instruction_id IS NULL
      AND rail_message_type = 'pacs.008'
    )
    OR
    (
      final_state = 'REVERSED'
      AND reversal_of_instruction_id IS NOT NULL
      AND rail_message_type = 'camt.056'
    )
  )
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'instruction_settlement_finality_reversal_fk'
      AND conrelid = 'public.instruction_settlement_finality'::regclass
  ) THEN
    ALTER TABLE public.instruction_settlement_finality
      ADD CONSTRAINT instruction_settlement_finality_reversal_fk
      FOREIGN KEY (reversal_of_instruction_id)
      REFERENCES public.instruction_settlement_finality(instruction_id)
      DEFERRABLE INITIALLY IMMEDIATE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_instruction_settlement_finality_one_reversal_per_original
  ON public.instruction_settlement_finality(reversal_of_instruction_id)
  WHERE reversal_of_instruction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_instruction_settlement_finality_participant_finalized
  ON public.instruction_settlement_finality(participant_id, finalized_at DESC);

CREATE OR REPLACE FUNCTION public.enforce_instruction_reversal_source()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_source_state TEXT;
  v_source_final BOOLEAN;
BEGIN
  IF NEW.is_final IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'instruction settlement rows must be final'
      USING ERRCODE = 'P7003';
  END IF;

  IF NEW.reversal_of_instruction_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT final_state, is_final
  INTO v_source_state, v_source_final
  FROM public.instruction_settlement_finality
  WHERE instruction_id = NEW.reversal_of_instruction_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'reversal requires existing instruction %', NEW.reversal_of_instruction_id
      USING ERRCODE = 'P7003';
  END IF;

  IF v_source_state <> 'SETTLED' OR v_source_final IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'reversal source instruction must be final and SETTLED: %', NEW.reversal_of_instruction_id
      USING ERRCODE = 'P7003';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_instruction_reversal_source ON public.instruction_settlement_finality;

CREATE TRIGGER trg_enforce_instruction_reversal_source
BEFORE INSERT ON public.instruction_settlement_finality
FOR EACH ROW
EXECUTE FUNCTION public.enforce_instruction_reversal_source();

CREATE OR REPLACE FUNCTION public.deny_final_instruction_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.is_final IS TRUE THEN
    RAISE EXCEPTION 'final instruction cannot be mutated'
      USING ERRCODE = 'P7003';
  END IF;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_final_instruction_mutation ON public.instruction_settlement_finality;

CREATE TRIGGER trg_deny_final_instruction_mutation
BEFORE UPDATE OR DELETE ON public.instruction_settlement_finality
FOR EACH ROW
EXECUTE FUNCTION public.deny_final_instruction_mutation();

REVOKE ALL ON TABLE public.instruction_settlement_finality FROM PUBLIC;
REVOKE ALL ON TABLE public.instruction_settlement_finality FROM symphony_executor;
GRANT SELECT ON TABLE public.instruction_settlement_finality TO symphony_readonly;
