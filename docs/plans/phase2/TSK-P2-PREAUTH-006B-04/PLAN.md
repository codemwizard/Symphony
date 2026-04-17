# TSK-P2-PREAUTH-006B-04: Implement upgrade_authority_on_execution_binding() trigger

**Task:** TSK-P2-PREAUTH-006B-04
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006B-03
**Blocks:** TSK-P2-PREAUTH-006B-05
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the upgrade_authority_on_execution_binding() trigger function to automatically upgrade data_authority to 'policy_bound_unsigned' or 'authoritative_signed' when execution_id is present. This task prevents data authority from reflecting execution binding, creating risk of non-auditable data usage.

## Architectural Context

The upgrade_authority_on_execution_binding() function upgrades data_authority to 'policy_bound_unsigned' when execution_id is present and signature is NULL, or 'authoritative_signed' when both execution_id and signature are present. It must be SECURITY DEFINER with hardened search_path.

## Pre-conditions

- TSK-P2-PREAUTH-006B-03 is complete
- Migration 0122 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0122_create_data_authority_triggers.sql | MODIFY | Add upgrade_authority_on_execution_binding() function |
| scripts/db/verify_tsk_p2_preauth_006b_04.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as AFTER INSERT OR UPDATE on state_transitions

## Implementation Steps

### [ID tsk_p2_preauth_006b_04_work_item_01] Add upgrade_authority_on_execution_binding() function to migration 0122
Add upgrade_authority_on_execution_binding() function to migration 0122 as SECURITY DEFINER with SET search_path = pg_catalog, public. Function upgrades data_authority to 'policy_bound_unsigned' when execution_id is present and signature is NULL, or 'authoritative_signed' when both execution_id and signature are present.

### [ID tsk_p2_preauth_006b_04_work_item_02] Attach function as AFTER INSERT OR UPDATE trigger on state_transitions
Attach function as AFTER INSERT OR UPDATE trigger on state_transitions table.

### [ID tsk_p2_preauth_006b_04_work_item_03] Write verification script
Write verify_tsk_p2_preauth_006b_04.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_006b_04_work_item_04] Run verification script
Run verify_tsk_p2_preauth_006b_04.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006b_04_work_item_01] [ID tsk_p2_preauth_006b_04_work_item_02]
# [ID tsk_p2_preauth_006b_04_work_item_03] [ID tsk_p2_preauth_006b_04_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_006b_04.sh && bash scripts/db/verify_tsk_p2_preauth_006b_04.sh > evidence/phase2/tsk_p2_preauth_006b_04.json || exit 1

# [ID tsk_p2_preauth_006b_04_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='upgrade_authority_on_execution_binding'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_006b_04_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_006b_04.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006b_04.json with must_include fields:
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
| Upgrade logic incorrect | Low | Critical | Review upgrade logic carefully |

## Approval

This task modifies database schema with SECURITY DEFINER trigger. Requires human review before merge.
