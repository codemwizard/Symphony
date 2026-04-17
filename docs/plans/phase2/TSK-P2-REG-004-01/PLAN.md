# TSK-P2-REG-004-01: Verify function exists and promote INV-169

**Task:** TSK-P2-REG-004-01
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-REG-004-00
**Blocks: []
**Failure Signature**: Function not found or INV-169 not promoted => CRITICAL_FAIL

## Objective

Verify check_reg26_separation() function exists in the database and promote INV-169 to implemented status.

## Architectural Context

INV-169 enforces REG26 separation via check_reg26_separation() function. This task verifies the function exists and promotes the invariant.

## Pre-conditions

- TSK-P2-REG-004-00 PLAN.md exists and passes verification
- check_reg26_separation() function should exist in database

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Update INV-169 to status: implemented |
| scripts/db/verify_tsk_p2_reg_004_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If check_reg26_separation() function does not exist in pg_proc
- If verify_gf_sch_008.sh fails
- If INV-169 status is not updated to implemented

## Implementation Steps

### [ID tsk_p2_reg_004_01_work_item_01] Query pg_proc for check_reg26_separation()
Run exact psql query: psql -c "SELECT 1 FROM pg_proc WHERE proname='check_reg26_separation'" | grep -q '1 row'.

### [ID tsk_p2_reg_004_01_work_item_02] Run verify_gf_sch_008.sh
Run scripts/db/verify_gf_sch_008.sh to verify schema conformance.

### [ID tsk_p2_reg_004_01_work_item_03] Update INV-169 in INVARIANTS_MANIFEST.yml
Update INV-169 to status: implemented in docs/invariants/INVARIANTS_MANIFEST.yml.

### [ID tsk_p2_reg_004_01_work_item_04] Write verification script
Write verify_tsk_p2_reg_004_01.sh that runs psql query and checks INV-169 status.

### [ID tsk_p2_reg_004_01_work_item_05] Run verification script
Run verify_tsk_p2_reg_004_01.sh to confirm changes are successful.

### [ID tsk_p2_reg_004_01_work_item_06] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_004_01_work_item_01] [ID tsk_p2_reg_004_01_work_item_02]
# [ID tsk_p2_reg_004_01_work_item_03] [ID tsk_p2_reg_004_01_work_item_04]
# [ID tsk_p2_reg_004_01_work_item_05]
test -x scripts/db/verify_tsk_p2_reg_004_01.sh && bash scripts/db/verify_tsk_p2_reg_004_01.sh > evidence/phase2/tsk_p2_reg_004_01.json || exit 1

# [ID tsk_p2_reg_004_01_work_item_05]
test -f evidence/phase2/tsk_p2_reg_004_01.json || exit 1

# [ID tsk_p2_reg_004_01_work_item_06]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_004_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- inv_169_implemented
- observed_paths

## Rollback

Revert INV-169 status:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not found in pg_proc | Low | Critical | Check function name and schema |
| INV-169 status not updated | Low | Medium | Review INVARIANTS_MANIFEST.yml edit |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
