# TSK-P2-REG-003-04: Add taxonomy_aligned column to projects

Task: TSK-P2-REG-003-04
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-003-03
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-003-04.COLUMN_OR_TYPE_INCORRECT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Add taxonomy_aligned column to projects table. This MUST be completed BEFORE the K13 trigger implementation to ensure column exists for trigger logic.

## Architectural Context

The taxonomy_aligned column is a BOOLEAN flag indicating EU Taxonomy K13 alignment. It must exist BEFORE the enforce_k13_taxonomy_alignment() trigger is attached to projects table.

## Pre-conditions

- TSK-P2-REG-003-03 (project_boundaries) is complete
- projects table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_taxonomy_aligned.sql | CREATE | Migration adding taxonomy_aligned column |
| scripts/db/verify_tsk_p2_reg_003_04.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If taxonomy_aligned column does not exist in projects table
- If taxonomy_aligned is not BOOLEAN NOT NULL DEFAULT false

## Implementation Steps

### [ID tsk_p2_reg_003_04_work_item_01] Write migration 0125 for taxonomy_aligned column
Write migration 0125 at schema/migrations/0125_taxonomy_aligned.sql with ALTER TABLE IF NOT EXISTS public.projects ADD COLUMN IF NOT EXISTS taxonomy_aligned BOOLEAN NOT NULL DEFAULT false.

### [ID tsk_p2_reg_003_04_work_item_02] Write verification script
Write verify_tsk_p2_reg_003_04.sh that runs psql to verify taxonomy_aligned column exists in projects table.

### [ID tsk_p2_reg_003_04_work_item_03] Run verification script
Run verify_tsk_p2_reg_003_04.sh to confirm column addition is successful.

### [ID tsk_p2_reg_003_04_work_item_04] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_04_work_item_01] [ID tsk_p2_reg_003_04_work_item_02]
# [ID tsk_p2_reg_003_04_work_item_03]
test -x scripts/db/verify_tsk_p2_reg_003_04.sh && bash scripts/db/verify_tsk_p2_reg_003_04.sh > evidence/phase2/tsk_p2_reg_003_04.json || exit 1

# [ID tsk_p2_reg_003_04_work_item_01]
test -f schema/migrations/0125_taxonomy_aligned.sql || exit 1

# [ID tsk_p2_reg_003_04_work_item_03]
test -f evidence/phase2/tsk_p2_reg_003_04.json || exit 1

# [ID tsk_p2_reg_003_04_work_item_04]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_04.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- column_exists
- column_type_correct
- observed_paths

## Rollback

Revert column addition:
```bash
psql -c "ALTER TABLE projects DROP COLUMN IF EXISTS taxonomy_aligned"
git checkout schema/migrations/0125_taxonomy_aligned.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Column addition fails | Low | Medium | Check projects table exists and has no conflicts |
| Migration order incorrect | Low | Critical | Ensure this completes BEFORE TSK-P2-REG-003-05 |

## Approval

This task modifies schema. Requires human review before merge.
