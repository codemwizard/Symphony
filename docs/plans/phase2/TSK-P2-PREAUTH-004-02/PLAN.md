# TSK-P2-PREAUTH-004-02: Create state_rules table

**Task:** TSK-P2-PREAUTH-004-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-004-01
**Blocks:** TSK-P2-PREAUTH-005-00
**failure_signature**: PHASE2.PREAUTH.TSK-P2-PREAUTH-004-02.TABLE_FAIL
**canonical_reference**: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**origin_task_id**: TSK-P2-PREAUTH-004-02
**repro_command**: bash scripts/db/verify_tsk_p2_preauth_004_02.sh
**verification_commands_run**: bash scripts/db/verify_tsk_p2_preauth_004_02.sh
**final_status**: PLANNED

## Objective

Create the state_rules table to define state transition rules with conditions. This task enables the system to enforce state machine rules, preventing invalid state transitions.

## Architectural Context

The state_rules table stores state transition rules with conditions. UNIQUE constraint on (from_state, to_state) ensures no duplicate rules exist for the same transition.

## Pre-conditions

- TSK-P2-PREAUTH-004-01 is complete
- Migration 0119 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0119_create_policy_decisions.sql | MODIFY | Add state_rules table |
| scripts/db/verify_tsk_p2_preauth_004_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not create state_rules table
- If UNIQUE constraint on (from_state, to_state) is missing

## Implementation Steps

### [ID tsk_p2_preauth_004_02_work_item_01] Add state_rules table to migration 0119
Add state_rules table to migration 0119 with columns: state_rule_id UUID PRIMARY KEY, from_state VARCHAR NOT NULL, to_state VARCHAR NOT NULL, rule_condition TEXT NOT NULL, and UNIQUE constraint on (from_state, to_state).

### [ID tsk_p2_preauth_004_02_work_item_02] Write verification script
Write verify_tsk_p2_preauth_004_02.sh that runs psql to verify table exists and UNIQUE constraint is present.

### [ID tsk_p2_preauth_004_02_work_item_03] Run verification script
Run verify_tsk_p2_preauth_004_02.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_004_02_work_item_01] [ID tsk_p2_preauth_004_02_work_item_02]
# [ID tsk_p2_preauth_004_02_work_item_03]
test -x scripts/db/verify_tsk_p2_preauth_004_02.sh && bash scripts/db/verify_tsk_p2_preauth_004_02.sh > evidence/phase2/tsk_p2_preauth_004_02.json || exit 1

# [ID tsk_p2_preauth_004_02_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_004_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_004_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- unique_constraint_present

## Rollback

Revert state_rules table addition from migration 0119:
```bash
git checkout schema/migrations/0119_create_policy_decisions.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UNIQUE constraint incorrect | Low | High | Review constraint definition carefully |
| Rule condition type incorrect | Low | Medium | Use TEXT for flexibility |

## Approval

This task modifies database schema. Requires human review before merge.
