# TSK-P2-PREAUTH-005-02: Create state_current table

**Task:** TSK-P2-PREAUTH-005-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-01
**Blocks:** TSK-P2-PREAUTH-005-03
**Failure Signature**: Table not created or PK missing => CRITICAL_FAIL

## Objective

Create the state_current table to track current state for each project. This task enables the system to efficiently query current state, preventing performance degradation and incorrect state queries.

## Architectural Context

The state_current table stores the current state for each project. project_id is PRIMARY KEY ensuring one row per project. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-01 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add state_current table |
| scripts/db/verify_tsk_p2_preauth_005_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not create state_current table
- If project_id PRIMARY KEY is missing

## Implementation Steps

### [ID tsk_p2_preauth_005_02_work_item_01] Add state_current table to migration 0120
Add state_current table to migration 0120 with columns: project_id UUID PRIMARY KEY, current_state VARCHAR NOT NULL, state_since TIMESTAMPTZ NOT NULL.

### [ID tsk_p2_preauth_005_02_work_item_02] Write verification script
Write verify_tsk_p2_preauth_005_02.sh that runs psql to verify table exists and project_id is PRIMARY KEY.

### [ID tsk_p2_preauth_005_02_work_item_03] Run verification script
Run verify_tsk_p2_preauth_005_02.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_005_02_work_item_01] [ID tsk_p2_preauth_005_02_work_item_02]
# [ID tsk_p2_preauth_005_02_work_item_03]
test -x scripts/db/verify_tsk_p2_preauth_005_02.sh && bash scripts/db/verify_tsk_p2_preauth_005_02.sh > evidence/phase2/tsk_p2_preauth_005_02.json || exit 1

# [ID tsk_p2_preauth_005_02_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_005_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- primary_key_present

## Rollback

Revert state_current table addition from migration 0120:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PRIMARY KEY incorrect | Low | Critical | Review PK definition carefully |
| state_since type incorrect | Low | Medium | Use TIMESTAMPTZ for timezone awareness |

## Approval

This task modifies database schema (HIGHEST RISK area). Requires human review before merge.
