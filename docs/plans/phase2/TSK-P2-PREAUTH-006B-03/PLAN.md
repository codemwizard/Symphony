# TSK-P2-PREAUTH-006B-03: Implement enforce_state_transition_authority() trigger

**Task:** TSK-P2-PREAUTH-006B-03
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006B-02
**Blocks:** TSK-P2-PREAUTH-006B-04
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the enforce_state_transition_authority() trigger function to prevent invalid data_authority transitions on state_transitions. This task prevents invalid authority transitions, creating risk of data authority corruption.

## Architectural Context

The enforce_state_transition_authority() function validates data_authority transitions and raises GF037 on invalid transitions. It must be SECURITY DEFINER with hardened search_path.

## Pre-conditions

- TSK-P2-PREAUTH-006B-02 is complete
- Migration 0122 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0122_create_data_authority_triggers.sql | MODIFY | Add enforce_state_transition_authority() function |
| scripts/db/verify_tsk_p2_preauth_006b_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as BEFORE INSERT OR UPDATE on state_transitions

## Implementation Steps

### [ID tsk_p2_preauth_006b_03_work_item_01] Add enforce_state_transition_authority() function to migration 0122
Add enforce_state_transition_authority() function to migration 0122 as SECURITY DEFINER with SET search_path = pg_catalog, public. Function validates data_authority transitions and raises GF037 on invalid transitions.

### [ID tsk_p2_preauth_006b_03_work_item_02] Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions
Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions table.

### [ID tsk_p2_preauth_006b_03_work_item_03] Write verification script
Write verify_tsk_p2_preauth_006b_03.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_006b_03_work_item_04] Run verification script
Run verify_tsk_p2_preauth_006b_03.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006b_03_work_item_01] [ID tsk_p2_preauth_006b_03_work_item_02]
# [ID tsk_p2_preauth_006b_03_work_item_03] [ID tsk_p2_preauth_006b_03_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_006b_03.sh && bash scripts/db/verify_tsk_p2_preauth_006b_03.sh > evidence/phase2/tsk_p2_preauth_006b_03.json || exit 1

# [ID tsk_p2_preauth_006b_03_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_state_transition_authority'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_006b_03_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_006b_03.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006b_03.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- security_definer_present
- trigger_attached

## Rollback

Revert function addition from migration 0122:
```bash
git checkout schema/migrations/0122_create_data_authority_triggers.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required for security |
| Search path not hardened | Low | Critical | Use SET search_path = pg_catalog, public |

## Approval

This task modifies database schema with SECURITY DEFINER trigger. Requires human review before merge.
