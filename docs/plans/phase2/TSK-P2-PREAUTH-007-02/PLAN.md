# TSK-P2-PREAUTH-007-02: Register INV-175 (data_authority_enforced)

**Task:** TSK-P2-PREAUTH-007-02
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-01
**Blocks:** TSK-P2-PREAUTH-007-03
**Failure Signature**: INV-175 not registered or status not implemented => CRITICAL_FAIL

## Objective

Register INV-175 for data_authority_enforced via ENUM and triggers. Without this invariant, data authority enforcement is not governed, creating risk of non-auditable data usage.

## Architectural Context

INV-175 enforces data_authority via the data_authority_level ENUM type and the enforce_monitoring_authority() trigger function in migration 0122. The invariant is verified by verify_tsk_p2_preauth_006a.sh which checks for proper ENUM values and trigger enforcement.

## Pre-conditions

- TSK-P2-PREAUTH-007-01 is complete
- INV-175 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- data_authority triggers exist in migration 0122

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-175 with status: implemented |
| scripts/audit/verify_tsk_p2_preauth_007_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-175 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to implemented
- If enforcement is not set to scripts/db/verify_tsk_p2_preauth_006a.sh

## Implementation Steps

### [ID tsk_p2_preauth_007_02_work_item_01] Add INV-175 to INVARIANTS_MANIFEST.yml
Add INV-175 to INVARIANTS_MANIFEST.yml with: id: INV-175, title: 'data_authority is schema-enforced via ENUM and triggers', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_preauth_006a.sh.

### [ID tsk_p2_preauth_007_02_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_02.sh that runs verify_tsk_p2_preauth_006a.sh to verify INV-175 enforcement.

### [ID tsk_p2_preauth_007_02_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_02.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_02_work_item_01] [ID tsk_p2_preauth_007_02_work_item_02]
# [ID tsk_p2_preauth_007_02_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_02.sh && bash scripts/audit/verify_tsk_p2_preauth_007_02.sh > evidence/phase2/tsk_p2_preauth_007_02.json || exit 1

# [ID tsk_p2_preauth_007_02_work_item_01]
grep -A 5 "id: INV-175" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented" &&
grep -A 5 "id: INV-175" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement" || exit 1

# [ID tsk_p2_preauth_007_02_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_007_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_175_registered
- inv_175_status_implemented

## Rollback

Revert INV-175 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-175 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not implemented | Low | Medium | Ensure status is set to implemented |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
