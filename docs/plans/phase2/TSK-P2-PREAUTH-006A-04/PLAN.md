# TSK-P2-PREAUTH-006A-04: Add data_authority columns to state_transitions

**Task:** TSK-P2-PREAUTH-006A-04
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006A-03
**Blocks:** TSK-P2-PREAUTH-006B-00
**Failure Signature**: Columns not added or default incorrect => CRITICAL_FAIL

## Objective

Add data_authority, audit_grade, and authority_explanation columns to state_transitions table with default 'non_reproducible'. This task enables the system to track data authority for state transitions, preventing non-auditable state changes.

## Architectural Context

The data_authority, audit_grade, and authority_explanation columns are added to state_transitions with default 'non_reproducible' for data_authority. This provides canonical data authority tracking for state transitions.

## Pre-conditions

- TSK-P2-PREAUTH-006A-03 is complete
- Migration 0121 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0121_create_data_authority_enum.sql | MODIFY | Add columns to state_transitions |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0121 |
| scripts/db/verify_tsk_p2_preauth_006a_04.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not add data_authority column
- If default is not 'non_reproducible'
- If MIGRATION_HEAD is not updated to 0121

## Implementation Steps

### [ID tsk_p2_preauth_006a_04_work_item_01] Add columns to migration 0121
Add columns to migration 0121: ALTER TABLE state_transitions ADD COLUMN data_authority public.data_authority_level NOT NULL DEFAULT 'non_reproducible', ADD COLUMN audit_grade BOOLEAN NOT NULL DEFAULT false, ADD COLUMN authority_explanation TEXT NOT NULL DEFAULT 'No execution context recorded'.

### [ID tsk_p2_preauth_006a_04_work_item_02] Update existing data
Update existing data: UPDATE state_transitions SET data_authority='non_reproducible' WHERE data_authority IS DISTINCT FROM 'non_reproducible'.

### [ID tsk_p2_preauth_006a_04_work_item_03] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0121: echo 0121 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_006a_04_work_item_04] Write verification script
Write verify_tsk_p2_preauth_006a_04.sh that runs psql to verify columns exist and have appropriate defaults.

### [ID tsk_p2_preauth_006a_04_work_item_05] Run verification script
Run verify_tsk_p2_preauth_006a_04.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_006a_04_work_item_01] [ID tsk_p2_preauth_006a_04_work_item_02]
# [ID tsk_p2_preauth_006a_04_work_item_03] [ID tsk_p2_preauth_006a_04_work_item_04]
# [ID tsk_p2_preauth_006a_04_work_item_05]
test -x scripts/db/verify_tsk_p2_preauth_006a_04.sh && bash scripts/db/verify_tsk_p2_preauth_006a_04.sh > evidence/phase2/tsk_p2_preauth_006a_04.json || exit 1

# [ID tsk_p2_preauth_006a_04_work_item_03]
test $(cat schema/migrations/MIGRATION_HEAD) = "0121" || exit 1

# [ID tsk_p2_preauth_006a_04_work_item_05]
test -f evidence/phase2/tsk_p2_preauth_006a_04.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006a_04.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- columns_exist
- defaults_applied
- migration_head

## Rollback

Revert column addition and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0121_create_data_authority_enum.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Default not 'non_reproducible' | Low | Critical | Review default value carefully |
| MIGRATION_HEAD not updated | Low | Medium | Ensure MIGRATION_HEAD update runs |

## Approval

This task modifies database schema. Requires human review before merge.
