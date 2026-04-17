# TSK-P2-PREAUTH-005-01: Create state_transitions table

**Task:** TSK-P2-PREAUTH-005-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-00
**Blocks:** TSK-P2-PREAUTH-005-02
**Failure Signature**: Migration fails or MIGRATION_HEAD not updated => CRITICAL_FAIL

## Objective

Create the state_transitions table to track all state transitions with execution binding. This task enables the system to record state transitions, preventing non-auditable state changes and lost execution context.

## Architectural Context

The state_transitions table stores all state transition events with execution binding. Indexes on project_id and transition_timestamp ensure efficient querying for project state history. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-00 PLAN.md exists and passes verification
- Migration 0120 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | CREATE | Migration creating state_transitions table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0120 |
| scripts/db/verify_tsk_p2_preauth_005_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration 0120 does not create state_transitions table
- If required indexes are missing
- If MIGRATION_HEAD is not updated to 0120

## Implementation Steps

### [ID tsk_p2_preauth_005_01_work_item_01] Write migration 0120
Write migration 0120 at schema/migrations/0120_create_state_transitions.sql creating state_transitions table with columns: transition_id UUID PRIMARY KEY, project_id UUID NOT NULL, from_state VARCHAR NOT NULL, to_state VARCHAR NOT NULL, transition_timestamp TIMESTAMPTZ NOT NULL, execution_id UUID, policy_decision_id UUID, signature TEXT, and indexes on project_id and transition_timestamp.

### [ID tsk_p2_preauth_005_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0120: echo 0120 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_005_01_work_item_03] Write verification script
Write verify_tsk_p2_preauth_005_01.sh that runs psql to verify table exists and indexes are present.

### [ID tsk_p2_preauth_005_01_work_item_04] Run verification script
Run verify_tsk_p2_preauth_005_01.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_005_01_work_item_01] [ID tsk_p2_preauth_005_01_work_item_02]
# [ID tsk_p2_preauth_005_01_work_item_03] [ID tsk_p2_preauth_005_01_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_005_01.sh && bash scripts/db/verify_tsk_p2_preauth_005_01.sh > evidence/phase2/tsk_p2_preauth_005_01.json || exit 1

# [ID tsk_p2_preauth_005_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0120" || exit 1

# [ID tsk_p2_preauth_005_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_005_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- indexes_present
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| Indexes missing | Low | Critical | Review index definitions carefully |

## Approval

This task modifies database schema (HIGHEST RISK area). Requires human review before merge.
