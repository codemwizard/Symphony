# TSK-P2-PREAUTH-007-02: Register INV-171 execution truth anchoring

**Task:** TSK-P2-PREAUTH-007-02
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-01
**Blocks:** TSK-P2-PREAUTH-007-03
**Failure Signature**: INV-171 not registered or status not draft => CRITICAL_FAIL

## Objective

Register INV-171 for execution truth anchoring via interpretation_version_id FK. Without this invariant, execution truth anchoring is not governed, creating risk of non-reproducible calculations.

## Architectural Context

INV-171 enforces execution truth anchoring via the interpretation_version_id foreign key referencing interpretation_packs(interpretation_pack_id) in the execution_records table.

## Pre-conditions

- TSK-P2-PREAUTH-007-01 is complete
- INV-171 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- execution_records table exists with interpretation_version_id FK

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-171 with status: draft |
| scripts/audit/verify_tsk_p2_preauth_007_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-171 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to draft
- If enforcement_location is not set to schema/migrations/0118

## Implementation Steps

### [ID tsk_p2_preauth_007_02_work_item_01] Add INV-171 to INVARIANTS_MANIFEST.yml
Add INV-171 to INVARIANTS_MANIFEST.yml with: id: INV-171, title: execution truth anchoring, status: draft, enforcement_location: schema/migrations/0118, verification_command: grep -E 'interpretation_version_id.*REFERENCES.*interpretation_packs' schema/migrations/0118.

### [ID tsk_p2_preauth_007_02_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_02.sh that runs grep to verify INV-171 exists in INVARIANTS_MANIFEST.yml with correct fields.

### [ID tsk_p2_preauth_007_02_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_02.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_02_work_item_01] [ID tsk_p2_preauth_007_02_work_item_02]
# [ID tsk_p2_preauth_007_02_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_02.sh && bash scripts/audit/verify_tsk_p2_preauth_007_02.sh > evidence/phase2/tsk_p2_preauth_007_02.json || exit 1

# [ID tsk_p2_preauth_007_02_work_item_01]
grep -A 5 "id: INV-171" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-171" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

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
- inv_171_registered
- inv_171_status_draft

## Rollback

Revert INV-171 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-171 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not draft | Low | Medium | Ensure status is set to draft |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
