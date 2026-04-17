# TSK-P2-PREAUTH-007-04: Register INV-173 data authority contract

**Task:** TSK-P2-PREAUTH-007-04
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-03
**Blocks:** TSK-P2-PREAUTH-007-05
**Failure Signature**: INV-173 not registered or status not draft => CRITICAL_FAIL

## Objective

Register INV-173 for data authority contract enforcement via triggers and ENUM. Without this invariant, data authority contract is not governed, creating risk of non-auditable data usage.

## Architectural Context

INV-173 enforces data authority contract via the enforce_monitoring_authority() trigger function in migration 0122 and the data_authority_level ENUM type.

## Pre-conditions

- TSK-P2-PREAUTH-007-03 is complete
- INV-173 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- data_authority triggers exist

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-173 with status: draft |
| scripts/audit/verify_tsk_p2_preauth_007_04.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-173 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to draft
- If enforcement_location is not set to schema/migrations/0122

## Implementation Steps

### [ID tsk_p2_preauth_007_04_work_item_01] Add INV-173 to INVARIANTS_MANIFEST.yml
Add INV-173 to INVARIANTS_MANIFEST.yml with: id: INV-173, title: data authority contract, status: draft, enforcement_location: schema/migrations/0122, verification_command: grep -E 'enforce_monitoring_authority.*BEFORE.*INSERT.*OR.*UPDATE.*monitoring_records' schema/migrations/0122.

### [ID tsk_p2_preauth_007_04_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_04.sh that runs grep to verify INV-173 exists in INVARIANTS_MANIFEST.yml with correct fields.

### [ID tsk_p2_preauth_007_04_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_04.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_04_work_item_01] [ID tsk_p2_preauth_007_04_work_item_02]
# [ID tsk_p2_preauth_007_04_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_04.sh && bash scripts/audit/verify_tsk_p2_preauth_007_04.sh > evidence/phase2/tsk_p2_preauth_007_04.json || exit 1

# [ID tsk_p2_preauth_007_04_work_item_01]
grep -A 5 "id: INV-173" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-173" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

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
- inv_173_registered
- inv_173_status_draft

## Rollback

Revert INV-173 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-173 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not draft | Low | Medium | Ensure status is set to draft |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
