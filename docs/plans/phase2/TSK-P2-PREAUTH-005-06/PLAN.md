# TSK-P2-PREAUTH-005-06: Implement enforce_execution_binding() trigger

**Task:** TSK-P2-PREAUTH-005-06
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-05
**Blocks:** TSK-P2-PREAUTH-005-07
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the enforce_execution_binding() trigger function to verify execution_id is present for reproducible transitions. This task prevents non-reproducible state transitions, creating risk of untraceable state changes.

## Architectural Context

The enforce_execution_binding() function verifies execution_id is present for reproducible transitions. It must be SECURITY DEFINER with hardened search_path. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-05 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add enforce_execution_binding() function |
| scripts/db/verify_tsk_p2_preauth_005_06.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as BEFORE INSERT OR UPDATE on state_transitions

## Implementation Steps

### [ID tsk_p2_preauth_005_06_work_item_01] Add enforce_execution_binding() function to migration 0120
Add enforce_execution_binding() function to migration 0120 as SECURITY DEFINER with SET search_path = pg_catalog, public. Function verifies execution_id is present for reproducible transitions and raises GF035 if missing.

### [ID tsk_p2_preauth_005_06_work_item_02] Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions
Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions table.

### [ID tsk_p2_preauth_005_06_work_item_03] Write verification script
Write verify_tsk_p2_preauth_005_06.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_005_06_work_item_04] Run verification script
Run verify_tsk_p2_preauth_005_06.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_005_06_work_item_01] [ID tsk_p2_preauth_005_06_work_item_02]
# [ID tsk_p2_preauth_005_06_work_item_03] [ID tsk_p2_preauth_005_06_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_005_06.sh && bash scripts/db/verify_tsk_p2_preauth_005_06.sh > evidence/phase2/tsk_p2_preauth_005_06.json || exit 1

# [ID tsk_p2_preauth_005_06_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_execution_binding'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_005_06_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_005_06.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_06.json with must_include fields:
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

## Approval

This task modifies database schema with SECURITY DEFINER trigger (HIGHEST RISK area). Requires human review before merge.
