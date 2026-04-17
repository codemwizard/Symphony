# TSK-P2-PREAUTH-004-01: Create policy_decisions table

**Task:** TSK-P2-PREAUTH-004-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-004-00
**Blocks:** TSK-P2-PREAUTH-004-02
**Failure Signature**: Migration fails or MIGRATION_HEAD not updated => CRITICAL_FAIL

## Objective

Create the policy_decisions table to track policy decisions with timestamps. This task enables the system to record policy decisions, preventing non-auditable policy application.

## Architectural Context

The policy_decisions table stores policy decision events with timestamps and project references. Index on project_id ensures efficient querying for project policy history.

## Pre-conditions

- TSK-P2-PREAUTH-004-00 PLAN.md exists and passes verification
- Migration 0119 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0119_create_policy_decisions.sql | CREATE | Migration creating policy_decisions table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0119 |
| scripts/db/verify_tsk_p2_preauth_004_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration 0119 does not create policy_decisions table
- If required indexes are missing
- If MIGRATION_HEAD is not updated to 0119

## Implementation Steps

### [ID tsk_p2_preauth_004_01_work_item_01] Write migration 0119
Write migration 0119 at schema/migrations/0119_create_policy_decisions.sql creating policy_decisions table with columns: policy_decision_id UUID PRIMARY KEY, project_id UUID NOT NULL, decision_type VARCHAR NOT NULL, decision_timestamp TIMESTAMPTZ NOT NULL, and index on project_id.

### [ID tsk_p2_preauth_004_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0119: echo 0119 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_004_01_work_item_03] Write verification script
Write verify_tsk_p2_preauth_004_01.sh that runs psql to verify table exists and index is present.

### [ID tsk_p2_preauth_004_01_work_item_04] Run verification script
Run verify_tsk_p2_preauth_004_01.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_004_01_work_item_01] [ID tsk_p2_preauth_004_01_work_item_02]
# [ID tsk_p2_preauth_004_01_work_item_03] [ID tsk_p2_preauth_004_01_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_004_01.sh && bash scripts/db/verify_tsk_p2_preauth_004_01.sh > evidence/phase2/tsk_p2_preauth_004_01.json || exit 1

# [ID tsk_p2_preauth_004_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0119" || exit 1

# [ID tsk_p2_preauth_004_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_004_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_004_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- index_present
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0119_create_policy_decisions.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| Index missing | Low | High | Review index definitions carefully |

## Approval

This task modifies database schema. Requires human review before merge.
