# PLAN: GF-W1-FNC-007 — interpretation confidence enforcement (migration 0087)

Status: planned
Phase: 1
Task: GF-W1-FNC-007
Author: <UNASSIGNED>

---

## Objective

Two distinct structural enforcements not covered by FNC-004:

1. `authority_decisions.interpretation_confidence_level` NOT NULL — permanently
   captures epistemic status at decision time, surviving pack supersession.

2. ISSUANCE_CONFIDENCE_GATE seeded in `lifecycle_checkpoint_rules` as a data row
   — makes the issuance block under PENDING_CLARIFICATION data-driven, not hardcoded.

## ORDERING NOTE

This task (migration 0087) must be applied BEFORE FNC-005 (migration 0084)
is built, because FNC-005's issue_asset_batch calls attempt_lifecycle_transition
which reads lifecycle_checkpoint_rules for the ISSUANCE_CONFIDENCE_GATE row.
Migration numbers reflect file creation order. DAG dependency order is authoritative.
Build order: FNC-004 → FNC-007 → FNC-005.

---

## Step 1 — Confirm prerequisites

- [ ] GF-W1-FNC-004 evidence passes (authority_decisions table exists)
- [ ] GF-W1-SCH-002 evidence passes (interpretation_packs exists)
- [ ] MIGRATION_HEAD = 0086

---

## Step 2 — Write migration SQL

File: `schema/migrations/0087_gf_fn_confidence_enforcement.sql`

```sql
-- symphony:migration id: 0087
-- phase: 1, volatility_class: CORE_SCHEMA
-- DEPENDENCY NOTE: Applied before FNC-005 (0084) per DAG order despite higher number

BEGIN;

-- Add interpretation_confidence_level column to authority_decisions
ALTER TABLE public.authority_decisions
  ADD COLUMN interpretation_confidence_level TEXT NOT NULL
  CHECK (interpretation_confidence_level IN
    ('CONFIRMED', 'PRACTICE_ASSUMED', 'PENDING_CLARIFICATION'));

-- Update record_authority_decision to populate the new column.
-- This is an ALTER of the function from FNC-004.
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
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_decision_id    UUID;
  v_confidence_lvl TEXT;
BEGIN
  IF p_interpretation_pack_id IS NULL THEN
    RAISE EXCEPTION 'interpretation_pack_id required'
      USING ERRCODE = 'P0001';
  END IF;

  -- Resolve confidence level at decision time — captured permanently
  SELECT confidence_level INTO v_confidence_lvl
  FROM public.interpretation_packs
  WHERE interpretation_pack_id = p_interpretation_pack_id;

  IF v_confidence_lvl IS NULL THEN
    RAISE EXCEPTION 'interpretation_pack_id % not found', p_interpretation_pack_id
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.authority_decisions (
    regulatory_authority_id, jurisdiction_code,
    decision_type, decision_outcome,
    interpretation_pack_id, interpretation_confidence_level,
    subject_type, subject_id
  )
  VALUES (
    p_regulatory_authority_id, p_jurisdiction_code,
    p_decision_type, p_decision_outcome,
    p_interpretation_pack_id, v_confidence_lvl,
    p_subject_type, p_subject_id
  )
  RETURNING decision_id INTO v_decision_id;

  RETURN v_decision_id;
END;
$$;

-- Seed the data-driven issuance confidence gate rule.
-- This row is what FNC-005 (issue_asset_batch) reads via
-- attempt_lifecycle_transition. The policy lives here, not in function code.
INSERT INTO public.lifecycle_checkpoint_rules (
  checkpoint_type,
  transition,
  checkpoint_code,
  jurisdiction_code,
  rule_expression,
  blocking_behavior,
  notes
)
SELECT
  'CONDITIONALLY_REQUIRED',
  'ACTIVE->ISSUED',
  'ISSUANCE_CONFIDENCE_GATE',
  'ALL',  -- applies across all jurisdictions
  'interpretation_confidence_level != PENDING_CLARIFICATION',
  'SOFT_BLOCK',
  'Data-driven: update row when MGEE confirms practice. ' ||
  'PENDING_CLARIFICATION produces CONDITIONALLY_SATISFIED per DSN-003 Section 5.'
WHERE NOT EXISTS (
  SELECT 1 FROM public.lifecycle_checkpoint_rules
  WHERE checkpoint_code = 'ISSUANCE_CONFIDENCE_GATE'
);

COMMIT;
```

---

## Step 3 — Rollback procedure

```sql
BEGIN;
-- Remove the seeded row
DELETE FROM public.lifecycle_checkpoint_rules
WHERE checkpoint_code = 'ISSUANCE_CONFIDENCE_GATE';

-- Revert record_authority_decision to FNC-004 version
-- (restore from FNC-004 migration source)

-- Remove column — only safe before any rows exist
ALTER TABLE public.authority_decisions
  DROP COLUMN IF EXISTS interpretation_confidence_level;

COMMIT;
```

Note: column rollback is only safe before any authority_decisions rows exist.
After FNC-004 has been used to create real decision records, dropping the column
would destroy data. If rollback is needed after decisions exist, the correct
procedure is forward-migration to nullable with a default, not DROP COLUMN.

---

## Step 4 — Critical negative tests

```sql
-- N1: NOT NULL enforced independently of function
INSERT INTO authority_decisions (
  regulatory_authority_id, ..., interpretation_pack_id
  -- interpretation_confidence_level deliberately omitted
)
VALUES (...);
-- Must fail with NOT NULL constraint

-- N2: Dangling pack reference
SELECT record_authority_decision(
  ..., '<nonexistent_pack_id>', ...
);
-- Must raise P0001 before INSERT

-- N3: Historical epistemic state preserved
-- Step a: Record decision under PENDING_CLARIFICATION pack
SELECT record_authority_decision(..., '<pending_pack_id>', ...);

-- Step b: Supersede the pack
UPDATE interpretation_packs SET effective_to = now()
  WHERE interpretation_pack_id = '<pending_pack_id>';
INSERT INTO interpretation_packs (..., confidence_level = 'CONFIRMED', ...)
  VALUES (...);

-- Step c: Check original decision record
SELECT interpretation_confidence_level FROM authority_decisions
WHERE interpretation_pack_id = '<pending_pack_id>';
-- Must still be 'PENDING_CLARIFICATION' — not updated by supersession

-- N4: Data-driven gate row exists
SELECT * FROM lifecycle_checkpoint_rules
WHERE checkpoint_code = 'ISSUANCE_CONFIDENCE_GATE';
-- Must return one row
```
