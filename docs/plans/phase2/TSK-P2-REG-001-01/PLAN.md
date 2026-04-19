# TSK-P2-REG-001-01: Create statutory_levy_registry table

Task: TSK-P2-REG-001-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-001-00
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-001-01.TABLE_OR_CONSTRAINT_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the statutory_levy_registry table with temporal uniqueness constraints to track statutory levy rates over time.

## Architectural Context

The statutory_levy_registry table stores levy rates with temporal versioning via effective_from/effective_to columns and a UNIQUE constraint on (levy_code, jurisdiction_code, effective_from) to prevent overlapping rate periods.

## Pre-conditions

- TSK-P2-REG-001-00 PLAN.md exists and passes verification
- MIGRATION_HEAD is at previous migration

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0123_create_statutory_levy_registry.sql | CREATE | Migration creating statutory_levy_registry table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0123 |
| scripts/db/verify_tsk_p2_reg_001_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If statutory_levy_registry table does not exist
- If UNIQUE constraint on (levy_code, jurisdiction_code, effective_from) is missing
- If MIGRATION_HEAD is not updated to 0123

## Implementation Steps

### [ID tsk_p2_reg_001_01_work_item_01] Write migration 0123
Write migration 0123 at schema/migrations/0123_create_statutory_levy_registry.sql creating statutory_levy_registry table with columns: levy_id UUID PRIMARY KEY, levy_code VARCHAR NOT NULL, jurisdiction_code VARCHAR NOT NULL, effective_from TIMESTAMPTZ NOT NULL, effective_to TIMESTAMPTZ, rate_value NUMERIC NOT NULL, and UNIQUE constraint on (levy_code, jurisdiction_code, effective_from).

### [ID tsk_p2_reg_001_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0123: echo 0123 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_reg_001_01_work_item_03] Write verification script
Write verify_tsk_p2_reg_001_01.sh that runs psql to verify table exists and UNIQUE constraint is present.

### [ID tsk_p2_reg_001_01_work_item_04] Run verification script
Run verify_tsk_p2_reg_001_01.sh to confirm migration is successful.

### [ID tsk_p2_reg_001_01_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_001_01_work_item_01] [ID tsk_p2_reg_001_01_work_item_02]
# [ID tsk_p2_reg_001_01_work_item_03] [ID tsk_p2_reg_001_01_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_001_01.sh && bash scripts/db/verify_tsk_p2_reg_001_01.sh > evidence/phase2/tsk_p2_reg_001_01.json || exit 1

# [ID tsk_p2_reg_001_01_work_item_01]
test -f schema/migrations/0123_create_statutory_levy_registry.sql || exit 1

# [ID tsk_p2_reg_001_01_work_item_02]
test "$(cat schema/migrations/MIGRATION_HEAD)" = "0123" || exit 1

# [ID tsk_p2_reg_001_01_work_item_04]
test -f evidence/phase2/tsk_p2_reg_001_01.json || exit 1

# [ID tsk_p2_reg_001_01_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_001_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- unique_constraint_present
- migration_head
- observed_paths

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0123_create_statutory_levy_registry.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Critical | Test migration on dev database first |
| UNIQUE constraint incorrect | Low | High | Review constraint definition carefully |

## Approval

This task modifies schema. Requires human review before merge.
