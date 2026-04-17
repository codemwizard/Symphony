# TSK-P2-PREAUTH-003-02: Add interpretation_version_id FK to execution_records

**Task:** TSK-P2-PREAUTH-003-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-003-01
**Blocks:** TSK-P2-PREAUTH-004-00
**Failure Signature**: FK not added or missing => CRITICAL_FAIL

## Objective

Add interpretation_version_id foreign key to execution_records table to bind executions to interpretation packs. This task enables the system to link executions to interpretation versions, ensuring reproducible calculations.

## Architectural Context

The interpretation_version_id foreign key binds execution records to interpretation packs, ensuring that each execution is associated with the specific interpretation pack version used for that calculation.

## Pre-conditions

- TSK-P2-PREAUTH-003-01 is complete
- execution_records table exists
- interpretation_packs table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0118_create_execution_records.sql | MODIFY | Add interpretation_version_id column and FK |
| scripts/db/verify_tsk_p2_preauth_003_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not add interpretation_version_id column
- If FK constraint to interpretation_packs is missing

## Implementation Steps

### [ID tsk_p2_preauth_003_02_work_item_01] Add interpretation_version_id column to migration 0118
Add interpretation_version_id column to migration 0118: ALTER TABLE execution_records ADD COLUMN interpretation_version_id UUID REFERENCES interpretation_packs(interpretation_pack_id).

### [ID tsk_p2_preauth_003_02_work_item_02] Write verification script
Write verify_tsk_p2_preauth_003_02.sh that runs psql to verify column exists and FK constraint is present.

### [ID tsk_p2_preauth_003_02_work_item_03] Run verification script
Run verify_tsk_p2_preauth_003_02.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_003_02_work_item_01] [ID tsk_p2_preauth_003_02_work_item_02]
# [ID tsk_p2_preauth_003_02_work_item_03]
test -x scripts/db/verify_tsk_p2_preauth_003_02.sh && bash scripts/db/verify_tsk_p2_preauth_003_02.sh > evidence/phase2/tsk_p2_preauth_003_02.json || exit 1

# [ID tsk_p2_preauth_003_02_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_003_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_003_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- column_exists
- fk_constraint_present

## Rollback

Revert column addition from migration 0118:
```bash
git checkout schema/migrations/0118_create_execution_records.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| FK constraint incorrect | Low | Critical | Review FK target and cascade behavior |
| Existing data incompatible | Low | High | Ensure existing rows can be NULL or have valid references |

## Approval

This task modifies database schema with foreign key. Requires human review before merge.
