# TSK-P2-PREAUTH-007-05: Register INV-174 append-only state transitions and INV-175 execution binding

**Task:** TSK-P2-PREAUTH-007-05
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-04
**Blocks: []
**Failure Signature**: Either invariant not registered or status not draft => CRITICAL_FAIL

## Objective

Register INV-174 for append-only state transitions and INV-175 for execution binding requirement. Without these invariants, state transition immutability and execution binding are not governed, creating risk of audit trail corruption and non-reproducible calculations.

## Architectural Context

INV-174 enforces append-only state transitions via the deny_state_transitions_mutation() trigger function in migration 0120. INV-175 enforces execution binding requirement via the enforce_execution_binding() trigger function in migration 0120.

## Pre-conditions

- TSK-P2-PREAUTH-007-04 is complete
- INV-174 and INV-175 do not exist in INVARIANTS_MANIFEST.yml or have status other than implemented
- deny_state_transitions_mutation() and enforce_execution_binding() triggers exist

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-174 and INV-175 with status: draft |
| scripts/audit/verify_tsk_p2_preauth_007_05.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-174 or INV-175 are not added to INVARIANTS_MANIFEST.yml
- If either status is not set to draft
- If enforcement_location is not set to schema/migrations/0120

## Implementation Steps

### [ID tsk_p2_preauth_007_05_work_item_01] Add INV-174 to INVARIANTS_MANIFEST.yml
Add INV-174 to INVARIANTS_MANIFEST.yml with: id: INV-174, title: append-only state transitions, status: draft, enforcement_location: schema/migrations/0120, verification_command: grep -E 'deny_state_transitions_mutation.*BEFORE.*UPDATE.*OR.*DELETE.*state_transitions' schema/migrations/0120.

### [ID tsk_p2_preauth_007_05_work_item_02] Add INV-175 to INVARIANTS_MANIFEST.yml
Add INV-175 to INVARIANTS_MANIFEST.yml with: id: INV-175, title: execution binding requirement, status: draft, enforcement_location: schema/migrations/0120, verification_command: grep -E 'enforce_execution_binding.*BEFORE.*INSERT.*OR.*UPDATE.*state_transitions' schema/migrations/0120.

### [ID tsk_p2_preauth_007_05_work_item_03] Write verification script
Write verify_tsk_p2_preauth_007_05.sh that runs grep to verify INV-174 and INV-175 exist in INVARIANTS_MANIFEST.yml with correct fields.

### [ID tsk_p2_preauth_007_05_work_item_04] Run verification script
Run verify_tsk_p2_preauth_007_05.sh to confirm invariants are registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_05_work_item_01] [ID tsk_p2_preauth_007_05_work_item_02]
# [ID tsk_p2_preauth_007_05_work_item_03] [ID tsk_p2_preauth_007_05_work_item_04]
test -x scripts/audit/verify_tsk_p2_preauth_007_05.sh && bash scripts/audit/verify_tsk_p2_preauth_007_05.sh > evidence/phase2/tsk_p2_preauth_007_05.json || exit 1

# [ID tsk_p2_preauth_007_05_work_item_01]
grep -A 5 "id: INV-174" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-174" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

# [ID tsk_p2_preauth_007_05_work_item_02]
grep -A 5 "id: INV-175" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-175" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

# [ID tsk_p2_preauth_007_05_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_007_05.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_05.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_174_registered
- inv_175_registered
- both_status_draft

## Rollback

Revert both invariant additions:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-174 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| INV-175 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Either status not draft | Low | Medium | Ensure status is set to draft |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
