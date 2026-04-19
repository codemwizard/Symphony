# TSK-P2-PREAUTH-007-04: Register INV-177 (phase1_boundary_marked)

**Task:** TSK-P2-PREAUTH-007-04
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-03
**Blocks:** TSK-P2-PREAUTH-007-05
**Failure Signature**: INV-177 not registered or status not implemented => CRITICAL_FAIL

## Objective

Register INV-177 for phase1_boundary_marked in C# read models. Without this invariant, Phase 1 outputs lack non-authoritative markers, creating risk of misinterpreting Phase 1 data as authoritative.

## Architectural Context

INV-177 enforces phase1_boundary_marked in C# read models verified by verify_tsk_p2_preauth_006c.sh. This invariant ensures that Phase 1 outputs carry non-authoritative markers to prevent misinterpretation as authoritative data.

## Pre-conditions

- TSK-P2-PREAUTH-007-03 is complete
- INV-177 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- Phase 1 C# read models exist

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-177 with status: implemented |
| scripts/audit/verify_tsk_p2_preauth_007_04.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-177 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to implemented
- If enforcement is not set to scripts/audit/verify_tsk_p2_preauth_006c.sh

## Implementation Steps

### [ID tsk_p2_preauth_007_04_work_item_01] Add INV-177 to INVARIANTS_MANIFEST.yml
Add INV-177 to INVARIANTS_MANIFEST.yml with: id: INV-177, title: 'Phase 1 C# outputs carry non-authoritative markers', status: implemented, severity: P0, enforcement: scripts/audit/verify_tsk_p2_preauth_006c.sh.

### [ID tsk_p2_preauth_007_04_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_04.sh that runs verify_tsk_p2_preauth_006c.sh to verify INV-177 enforcement.

### [ID tsk_p2_preauth_007_04_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_04.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_04_work_item_01] [ID tsk_p2_preauth_007_04_work_item_02]
# [ID tsk_p2_preauth_007_04_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_04.sh && bash scripts/audit/verify_tsk_p2_preauth_007_04.sh > evidence/phase2/tsk_p2_preauth_007_04.json || exit 1

# [ID tsk_p2_preauth_007_04_work_item_01]
grep -A 5 "id: INV-177" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented" &&
grep -A 5 "id: INV-177" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement" || exit 1

# [ID tsk_p2_preauth_007_04_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_007_04.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_04.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_177_registered
- inv_177_status_implemented

## Rollback

Revert INV-177 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-177 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not implemented | Low | Medium | Ensure status is set to implemented |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
