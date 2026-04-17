# TSK-P2-PREAUTH-005-08: Implement update_current_state() trigger

**Task:** TSK-P2-PREAUTH-005-08
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-07
**Blocks:** TSK-P2-PREAUTH-006A-00
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the update_current_state() trigger function to maintain state_current table on state transitions. This task prevents state_current from becoming stale, creating risk of incorrect current state queries.

## Architectural Context

The update_current_state() function inserts or updates state_current table with project_id, to_state, and transition_timestamp. It must be SECURITY DEFINER with hardened search_path. This completes the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-07 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add update_current_state() function |
| scripts/db/verify_tsk_p2_preauth_005_08.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as AFTER INSERT OR UPDATE on state_transitions

## Implementation Steps

### [ID tsk_p2_preauth_005_08_work_item_01] Add update_current_state() function to migration 0120
Add update_current_state() function to migration 0120 as SECURITY DEFINER with SET search_path = pg_catalog, public. Function inserts or updates state_current table with project_id, to_state, and transition_timestamp.

### [ID tsk_p2_preauth_005_08_work_item_02] Attach function as AFTER INSERT OR UPDATE trigger on state_transitions
Attach function as AFTER INSERT OR UPDATE trigger on state_transitions table.

### [ID tsk_p2_preauth_005_08_work_item_03] Write verification script
Write verify_tsk_p2_preauth_005_08.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_005_08_work_item_04] Run verification script
Run verify_tsk_p2_preauth_005_08.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_005_08_work_item_01] [ID tsk_p2_preauth_005_08_work_item_02]
# [ID tsk_p2_preauth_005_08_work_item_03] [ID tsk_p2_preauth_005_08_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_005_08.sh && bash scripts/db/verify_tsk_p2_preauth_005_08.sh > evidence/phase2/tsk_p2_preauth_005_08.json || exit 1

# [ID tsk_p2_preauth_005_08_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='update_current_state'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_005_08_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_005_08.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_08.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- security_definer_present
- trigger_attached

## Rollback

Revert function addition from migration 0120:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required for security |
| Search path not hardened | Low | Critical | Use SET search_path = pg_catalog, public |
| Upsert logic incorrect | Low | High | Test INSERT and UPDATE paths |

## Approval

This task modifies database schema with SECURITY DEFINER trigger (HIGHEST RISK area). Requires human review before merge. This completes the state machine + trigger layer.
