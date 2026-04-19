# TSK-P2-PREAUTH-007-05: Promote INV-165/167 and wire pre_ci.sh

**Task:** TSK-P2-PREAUTH-007-05
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-04
**Blocks:** TSK-P2-REG-001-00, TSK-P2-REG-002-00, TSK-P2-REG-004-00
**Failure Signature**: INV-165/167 not promoted or pre_ci.sh missing verifiers => CRITICAL_FAIL

## Objective

Promote INV-165 and INV-167 to implemented status in INVARIANTS_MANIFEST.yml and wire verify_tsk_p2_preauth_006a.sh, verify_tsk_p2_preauth_005_08.sh, verify_tsk_p2_preauth_006c.sh into pre_ci.sh. This completes the invariant registration and CI wiring gate.

## Architectural Context

INV-165 enforces interpretation_version_id for replayability and INV-167 enforces single active interpretation pack per domain. Both were previously in draft status and are now promoted to implemented after their verifiers (verify_tsk_p2_preauth_006a.sh, verify_tsk_p2_preauth_005_08.sh, verify_tsk_p2_preauth_006c.sh) are wired into pre_ci.sh for continuous enforcement.

## Pre-conditions

- TSK-P2-PREAUTH-007-04 is complete
- INV-165 and INV-167 exist in INVARIANTS_MANIFEST.yml with status: draft
- pre_ci.sh exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Update INV-165/167 status to implemented |
| scripts/dev/pre_ci.sh | MODIFY | Wire three new verifiers |
| scripts/audit/verify_tsk_p2_preauth_007_05.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-165 or INV-167 are not promoted to implemented
- If pre_ci.sh does not include all three verifiers

## Implementation Steps

### [ID tsk_p2_preauth_007_05_work_item_01] Update INV-165 status to implemented
Update INV-165 status to implemented in INVARIANTS_MANIFEST.yml.

### [ID tsk_p2_preauth_007_05_work_item_02] Update INV-167 status to implemented
Update INV-167 status to implemented in INVARIANTS_MANIFEST.yml.

### [ID tsk_p2_preauth_007_05_work_item_03] Verify pre_ci.sh includes verify_tsk_p2_preauth_006a.sh
Verify pre_ci.sh includes verify_tsk_p2_preauth_006a.sh.

### [ID tsk_p2_preauth_007_05_work_item_04] Verify pre_ci.sh includes verify_tsk_p2_preauth_005_08.sh
Verify pre_ci.sh includes verify_tsk_p2_preauth_005_08.sh.

### [ID tsk_p2_preauth_007_05_work_item_05] Verify pre_ci.sh includes verify_tsk_p2_preauth_006c.sh
Verify pre_ci.sh includes verify_tsk_p2_preauth_006c.sh.

### [ID tsk_p2_preauth_007_05_work_item_06] Write verification script
Write verify_tsk_p2_preauth_007_05.sh that verifies all above changes.

### [ID tsk_p2_preauth_007_05_work_item_07] Run verification script
Run verify_tsk_p2_preauth_007_05.sh to confirm changes are correct.

## Verification

```bash
# [ID tsk_p2_preauth_007_05_work_item_01] [ID tsk_p2_preauth_007_05_work_item_02]
# [ID tsk_p2_preauth_007_05_work_item_03] [ID tsk_p2_preauth_007_05_work_item_04]
# [ID tsk_p2_preauth_007_05_work_item_05] [ID tsk_p2_preauth_007_05_work_item_06]
# [ID tsk_p2_preauth_007_05_work_item_07]
test -x scripts/audit/verify_tsk_p2_preauth_007_05.sh && bash scripts/audit/verify_tsk_p2_preauth_007_05.sh > evidence/phase2/tsk_p2_preauth_007_05.json || exit 1

# [ID tsk_p2_preauth_007_05_work_item_01]
grep -A 5 "id: INV-165" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented" || exit 1

# [ID tsk_p2_preauth_007_05_work_item_02]
grep -A 5 "id: INV-167" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented" || exit 1

# [ID tsk_p2_preauth_007_05_work_item_03]
grep -q "verify_tsk_p2_preauth_006a.sh" scripts/dev/pre_ci.sh || exit 1

# [ID tsk_p2_preauth_007_05_work_item_04]
grep -q "verify_tsk_p2_preauth_005_08.sh" scripts/dev/pre_ci.sh || exit 1

# [ID tsk_p2_preauth_007_05_work_item_05]
grep -q "verify_tsk_p2_preauth_006c.sh" scripts/dev/pre_ci.sh || exit 1

# [ID tsk_p2_preauth_007_05_work_item_07]
test -f evidence/phase2/tsk_p2_preauth_007_05.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_05.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_165_status_implemented
- inv_167_status_implemented
- pre_ci_wired

## Rollback

Revert invariant status changes:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
git checkout scripts/dev/pre_ci.sh
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-165 not promoted | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| INV-167 not promoted | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| pre_ci.sh missing verifiers | Low | Critical | Review pre_ci.sh after edit |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
