# TSK-P2-PREAUTH-006B-01: Implement enforce_monitoring_authority() trigger

**Task:** TSK-P2-PREAUTH-006B-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006B-00
**Blocks:** TSK-P2-PREAUTH-006B-02
**Failure Signature**: Function not created or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement the enforce_monitoring_authority() trigger function to prevent invalid data_authority transitions on monitoring_records. This task prevents invalid authority transitions, creating risk of data authority corruption.

## Architectural Context

The enforce_monitoring_authority() function validates data_authority transitions and raises GF037 on invalid transitions. It must be SECURITY DEFINER with hardened search_path.

## Pre-conditions

- TSK-P2-PREAUTH-006B-00 PLAN.md exists and passes verification
- Migration 0122 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0122_create_data_authority_triggers.sql | CREATE | Migration adding enforce_monitoring_authority() |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0122 |
| scripts/db/verify_tsk_p2_preauth_006b_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not exist in pg_proc with exact name
- If function is not SECURITY DEFINER with prosecdef=true
- If trigger is not attached as BEFORE INSERT OR UPDATE on monitoring_records

## Implementation Steps

### [ID tsk_p2_preauth_006b_01_work_item_01] Write migration 0122
Write migration 0122 at schema/migrations/0122_create_data_authority_triggers.sql adding enforce_monitoring_authority() function as SECURITY DEFINER with SET search_path = pg_catalog, public. Function validates data_authority transitions and raises GF037 on invalid transitions.

### [ID tsk_p2_preauth_006b_01_work_item_02] Attach function as BEFORE INSERT OR UPDATE trigger on monitoring_records
Attach function as BEFORE INSERT OR UPDATE trigger on monitoring_records table.

### [ID tsk_p2_preauth_006b_01_work_item_03] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0122: echo 0122 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_006b_01_work_item_04] Write verification script
Write verify_tsk_p2_preauth_006b_01.sh that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached.

### [ID tsk_p2_preauth_006b_01_work_item_05] Run verification script
Run verify_tsk_p2_preauth_006b_01.sh to confirm trigger is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006b_01_work_item_01] [ID tsk_p2_preauth_006b_01_work_item_02]
# [ID tsk_p2_preauth_006b_01_work_item_03] [ID tsk_p2_preauth_006b_01_work_item_04]
# [ID tsk_p2_preauth_006b_01_work_item_05]
test -x scripts/db/verify_tsk_p2_preauth_006b_01.sh && bash scripts/db/verify_tsk_p2_preauth_006b_01.sh > evidence/phase2/tsk_p2_preauth_006b_01.json || exit 1

# [ID tsk_p2_preauth_006b_01_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_monitoring_authority'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_006b_01_work_item_03]
test $(cat schema/migrations/MIGRATION_HEAD) = "0122" || exit 1

# [ID tsk_p2_preauth_006b_01_work_item_05]
test -f evidence/phase2/tsk_p2_preauth_006b_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006b_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- security_definer_present
- trigger_attached
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0122_create_data_authority_triggers.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required for security |
| Search path not hardened | Low | Critical | Use SET search_path = pg_catalog, public |

## Approval

This task modifies database schema with SECURITY DEFINER trigger. Requires human review before merge.
