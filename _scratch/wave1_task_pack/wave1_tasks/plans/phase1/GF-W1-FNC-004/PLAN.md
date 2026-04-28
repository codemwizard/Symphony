# PLAN: GF-W1-FNC-004 — record_authority_decision + attempt_lifecycle_transition (migration 0083)

Status: planned
Phase: 1
Task: GF-W1-FNC-004
Author: <UNASSIGNED>

---

## Objective

Implement the two regulatory gate functions. Both require interpretation_pack_id.
attempt_lifecycle_transition reads lifecycle_checkpoint_rules as data — no
checkpoint logic is hardcoded. DSN-003 provisional pass semantics apply.

---

## Step 1 — Confirm prerequisites

- [ ] GF-W1-SCH-007 passed (regulatory plane tables exist)
- [ ] GF-W1-DSN-003 approved (INTERPRETATION_PACK_VALIDATION_SPEC.md exists)
- [ ] GF-W1-FNC-003 evidence passes

---

## Step 2 — Write migration SQL

File: `schema/migrations/0083_gf_fn_regulatory_transitions.sql`

```sql
-- symphony:migration id: 0083
-- phase: 1, volatility_class: CORE_SCHEMA

BEGIN;

-- Function 1: record_authority_decision
CREATE OR REPLACE FUNCTION public.record_authority_decision(
  p_regulatory_authority_id UUID,
  p_jurisdiction_code       TEXT,
  p_decision_type           TEXT,
  p_decision_outcome        TEXT,
  p_interpretation_pack_id  UUID,
  p_subject_type            TEXT,
  p_subject_id              UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_decision_id UUID;
BEGIN
  -- Enforce interpretation_pack_id non-null in function body (belt and suspenders)
  IF p_interpretation_pack_id IS NULL THEN
    RAISE EXCEPTION 'interpretation_pack_id is required for all authority decisions'
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify pack exists
  IF NOT EXISTS (
    SELECT 1 FROM public.interpretation_packs
    WHERE interpretation_pack_id = p_interpretation_pack_id
  ) THEN
    RAISE EXCEPTION 'interpretation_pack_id % does not exist', p_interpretation_pack_id
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.authority_decisions (
    regulatory_authority_id,
    jurisdiction_code,
    decision_type,
    decision_outcome,
    interpretation_pack_id,
    subject_type,
    subject_id
  )
  VALUES (
    p_regulatory_authority_id,
    p_jurisdiction_code,
    p_decision_type,
    p_decision_outcome,
    p_interpretation_pack_id,
    p_subject_type,
    p_subject_id
  )
  RETURNING decision_id INTO v_decision_id;

  RETURN v_decision_id;
END;
$$;

-- Function 2: attempt_lifecycle_transition
CREATE OR REPLACE FUNCTION public.attempt_lifecycle_transition(
  p_subject_id              UUID,
  p_subject_type            TEXT,
  p_from_status             TEXT,
  p_to_status               TEXT,
  p_interpretation_pack_id  UUID
)
RETURNS TEXT  -- returns final checkpoint_satisfaction_state
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_checkpoint        RECORD;
  v_pack_confidence   TEXT;
  v_satisfaction_state TEXT := 'SATISFIED';
BEGIN
  IF p_interpretation_pack_id IS NULL THEN
    RAISE EXCEPTION 'interpretation_pack_id required for lifecycle transitions'
      USING ERRCODE = 'P0001';
  END IF;

  -- Get confidence level of active pack
  SELECT confidence_level INTO v_pack_confidence
  FROM public.interpretation_packs
  WHERE interpretation_pack_id = p_interpretation_pack_id;

  -- Evaluate each checkpoint rule for this transition
  FOR v_checkpoint IN
    SELECT checkpoint_type, checkpoint_code
    FROM public.lifecycle_checkpoint_rules
    WHERE transition = p_from_status || '->' || p_to_status
      AND jurisdiction_code = (
        SELECT jurisdiction_code FROM public.interpretation_packs
        WHERE interpretation_pack_id = p_interpretation_pack_id
      )
  LOOP
    IF v_checkpoint.checkpoint_type = 'REQUIRED' THEN
      -- Hard block: unsatisfied required checkpoints raise immediately
      IF NOT EXISTS (
        SELECT 1 FROM public.checkpoint_satisfaction_records
        WHERE subject_id     = p_subject_id
          AND checkpoint_code = v_checkpoint.checkpoint_code
          AND satisfied       = true
      ) THEN
        RAISE EXCEPTION 'Required checkpoint % not satisfied', v_checkpoint.checkpoint_code
          USING ERRCODE = 'P0001';
      END IF;

    ELSIF v_checkpoint.checkpoint_type = 'CONDITIONALLY_REQUIRED' THEN
      -- Provisional pass per DSN-003 Section 5:
      -- If pack is PENDING_CLARIFICATION, allow through with CONDITIONALLY_SATISFIED
      IF v_pack_confidence = 'PENDING_CLARIFICATION' THEN
        v_satisfaction_state := 'CONDITIONALLY_SATISFIED';
      ELSE
        -- Treat as REQUIRED when pack is confirmed
        IF NOT EXISTS (
          SELECT 1 FROM public.checkpoint_satisfaction_records
          WHERE subject_id     = p_subject_id
            AND checkpoint_code = v_checkpoint.checkpoint_code
            AND satisfied       = true
        ) THEN
          RAISE EXCEPTION 'Conditionally required checkpoint % not satisfied', v_checkpoint.checkpoint_code
            USING ERRCODE = 'P0001';
        END IF;
      END IF;
    END IF;
  END LOOP;

  -- Record lifecycle event
  INSERT INTO public.asset_lifecycle_events (
    asset_batch_id,
    from_status,
    to_status,
    interpretation_pack_id,
    checkpoint_satisfaction_state,
    provisional_reason
  )
  VALUES (
    p_subject_id,
    p_from_status,
    p_to_status,
    p_interpretation_pack_id,
    v_satisfaction_state,
    CASE WHEN v_satisfaction_state = 'CONDITIONALLY_SATISFIED'
         THEN 'PENDING_CLARIFICATION' ELSE NULL END
  );

  RETURN v_satisfaction_state;
END;
$$;

COMMIT;
```

---

## Step 3 — Rollback procedure

```sql
BEGIN;
DROP FUNCTION IF EXISTS public.attempt_lifecycle_transition(UUID, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS public.record_authority_decision(UUID, TEXT, TEXT, TEXT, UUID, TEXT, UUID);
COMMIT;
```

Functions are stateless — rollback is clean. No data to reverse.

---

## Step 4 — Run verifiers

```bash
bash scripts/db/verify_gf_fnc_004.sh
python3 scripts/audit/verify_neutral_schema_ast.py \
  schema/migrations/0083_gf_fn_regulatory_transitions.sql
bash scripts/dev/pre_ci.sh
```

---

## Critical negative test — provisional pass

```sql
-- Insert CONDITIONALLY_REQUIRED checkpoint rule
INSERT INTO lifecycle_checkpoint_rules (
  checkpoint_type, transition, checkpoint_code,
  jurisdiction_code, interpretation_pack_id
) VALUES (
  'CONDITIONALLY_REQUIRED', 'ACTIVE->ISSUED', 'TEST_CONDITIONAL_GATE',
  'ZM', '<pending_clarification_pack_id>'
);

-- Call transition without satisfying the checkpoint
-- Must SUCCEED and return 'CONDITIONALLY_SATISFIED' (not raise)
SELECT attempt_lifecycle_transition(
  '<project_id>', 'asset_batch', 'ACTIVE', 'ISSUED',
  '<pending_clarification_pack_id>'
);
-- Must return 'CONDITIONALLY_SATISFIED'

-- Verify lifecycle event captured provisional_reason
SELECT provisional_reason FROM asset_lifecycle_events
WHERE asset_batch_id = '<project_id>'
ORDER BY created_at DESC LIMIT 1;
-- Must be 'PENDING_CLARIFICATION'
```
