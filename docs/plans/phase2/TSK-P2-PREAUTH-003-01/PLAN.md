# TSK-P2-PREAUTH-003-01: Create execution_records table

**Task:** TSK-P2-PREAUTH-003-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-003-00
**Blocks:** TSK-P2-PREAUTH-003-02
**failure_signature**: PHASE2.PREAUTH.TSK-P2-PREAUTH-003-01.MIGRATION_FAIL
**canonical_reference**: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**origin_task_id**: TSK-P2-PREAUTH-003-01
**repro_command**: bash scripts/db/verify_tsk_p2_preauth_003_01.sh
**verification_commands_run**: bash scripts/db/verify_tsk_p2_preauth_003_01.sh
**final_status**: PASS

## Objective

Create the execution_records table to anchor execution truth with timestamps. This task enables the system to track execution events, preventing non-reproducible calculations and audit failures.

## Architectural Context

The execution_records table stores execution events with timestamps and project references. Indexes on project_id and execution_timestamp ensure efficient querying for project execution history.

## Pre-conditions

- TSK-P2-PREAUTH-003-00 PLAN.md exists and passes verification
- Migration 0118 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0118_create_execution_records.sql | CREATE | Migration creating execution_records table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0118 |
| scripts/db/verify_tsk_p2_preauth_003_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration 0118 does not create execution_records table
- If required indexes are missing
- If MIGRATION_HEAD is not updated to 0118

## Implementation Steps

### [ID tsk_p2_preauth_003_01_work_item_01] Write migration 0118
Write migration 0118 at schema/migrations/0118_create_execution_records.sql creating execution_records table with columns: execution_id UUID PRIMARY KEY, project_id UUID NOT NULL, execution_timestamp TIMESTAMPTZ NOT NULL, and indexes on project_id and execution_timestamp.

### [ID tsk_p2_preauth_003_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0118: echo 0118 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_003_01_work_item_03] Write verification script
Write verify_tsk_p2_preauth_003_01.sh that runs psql to verify table exists and indexes are present.

### [ID tsk_p2_preauth_003_01_work_item_04] Run verification script
Run verify_tsk_p2_preauth_003_01.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_003_01_work_item_01] [ID tsk_p2_preauth_003_01_work_item_02]
# [ID tsk_p2_preauth_003_01_work_item_03] [ID tsk_p2_preauth_003_01_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_003_01.sh && bash scripts/db/verify_tsk_p2_preauth_003_01.sh > evidence/phase2/tsk_p2_preauth_003_01.json || exit 1

# [ID tsk_p2_preauth_003_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0118" || exit 1

# [ID tsk_p2_preauth_003_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_003_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_003_01.json with must_include fields:
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
git checkout schema/migrations/0118_create_execution_records.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| Indexes missing | Low | High | Review index definitions carefully |

## Approval

This task modifies database schema. Requires human review before merge.
