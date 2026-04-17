# TSK-P2-PREAUTH-005-05: Implement enforce_transition_signature() trigger

**Task:** TSK-P2-PREAUTH-005-05
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-04
**Blocks:** TSK-P2-PREAUTH-005-06
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the enforce_transition_signature() trigger function to verify signature is present for signed transitions. This task prevents unsigned authoritative transitions, creating risk of non-repudiable state changes.

## Architectural Context

The enforce_transition_signature() function verifies signature is present for signed transitions. It must be SECURITY DEFINER with hardened search_path. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-04 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add enforce_transition_signature() function |
| scripts/db/verify_tsk_p2_preauth_005_05.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as BEFORE INSERT OR UPDATE on state_transitions

## Implementation Steps

### [ID tsk_p2_preauth_005_05_work_item_01] Add enforce_transition_signature() function to migration 0120
Add enforce_transition_signature() function to migration 0120 as SECURITY DEFINER with SET search_path = pg_catalog, public. Function verifies signature is present for signed transitions and raises GF034 if missing.

### [ID tsk_p2_preauth_005_05_work_item_02] Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions
Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions table.

### [ID tsk_p2_preauth_005_05_work_item_03] Write verification script
Write verify_tsk_p2_preauth_005_05.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_005_05_work_item_04] Run verification script
Run verify_tsk_p2_preauth_005_05.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_005_05_work_item_01] [ID tsk_p2_preauth_005_05_work_item_02]
# [ID tsk_p2_preauth_005_05_work_item_03] [ID tsk_p2_preauth_005_05_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_005_05.sh && bash scripts/db/verify_tsk_p2_preauth_005_05.sh > evidence/phase2/tsk_p2_preauth_005_05.json || exit 1

# [ID tsk_p2_preauth_005_05_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_transition_signature'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_005_05_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_005_05.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_05.json with must_include fields:
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
