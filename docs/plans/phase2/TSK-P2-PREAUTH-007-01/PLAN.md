# TSK-P2-PREAUTH-007-01: Register INV-170 interpretation_pack temporal uniqueness

**Task:** TSK-P2-PREAUTH-007-01
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-00
**Blocks:** TSK-P2-PREAUTH-007-02
**Failure Signature**: INV-170 not registered or status not draft => CRITICAL_FAIL

## Objective

Register INV-170 for interpretation_pack temporal uniqueness enforcement. Without this invariant, temporal uniqueness of interpretation packs is not governed, creating risk of inconsistent policy application across time periods.

## Architectural Context

INV-170 enforces temporal uniqueness of interpretation packs via the UNIQUE constraint on (project_id, interpretation_pack_id, effective_from) in the interpretation_packs table.

## Pre-conditions

- TSK-P2-PREAUTH-007-00 PLAN.md exists and passes verification
- INV-170 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- interpretation_packs table exists with temporal uniqueness constraint

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-170 with status: draft |
| scripts/audit/verify_tsk_p2_preauth_007_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-170 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to draft
- If enforcement_location is not set to schema/migrations/0116

## Implementation Steps

### [ID tsk_p2_preauth_007_01_work_item_01] Add INV-170 to INVARIANTS_MANIFEST.yml
Add INV-170 to INVARIANTS_MANIFEST.yml with: id: INV-170, title: interpretation_pack temporal uniqueness, status: draft, enforcement_location: schema/migrations/0116, verification_command: grep -E 'UNIQUE.*project_id.*interpretation_pack_id.*effective_from' schema/migrations/0116.

### [ID tsk_p2_preauth_007_01_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_01.sh that runs grep to verify INV-170 exists in INVARIANTS_MANIFEST.yml with correct fields.

### [ID tsk_p2_preauth_007_01_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_01.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_01_work_item_01] [ID tsk_p2_preauth_007_01_work_item_02]
# [ID tsk_p2_preauth_007_01_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_01.sh && bash scripts/audit/verify_tsk_p2_preauth_007_01.sh > evidence/phase2/tsk_p2_preauth_007_01.json || exit 1

# [ID tsk_p2_preauth_007_01_work_item_01]
grep -A 5 "id: INV-170" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-170" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

# [ID tsk_p2_preauth_007_01_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_007_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_170_registered
- inv_170_status_draft

## Rollback

Revert INV-170 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-170 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not draft | Low | Medium | Ensure status is set to draft |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
