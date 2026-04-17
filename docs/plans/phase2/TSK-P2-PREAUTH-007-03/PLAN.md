# TSK-P2-PREAUTH-007-03: Register INV-172 state machine enforcement

**Task:** TSK-P2-PREAUTH-007-03
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-02
**Blocks:** TSK-P2-PREAUTH-007-04
**Failure Signature**: INV-172 not registered or status not draft => CRITICAL_FAIL

## Objective

Register INV-172 for state machine enforcement via triggers. Without this invariant, state machine enforcement is not governed, creating risk of invalid state transitions.

## Architectural Context

INV-172 enforces state machine enforcement via the enforce_transition_state_rules() trigger function in migration 0120.

## Pre-conditions

- TSK-P2-PREAUTH-007-02 is complete
- INV-172 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- enforce_transition_state_rules() trigger exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-172 with status: draft |
| scripts/audit/verify_tsk_p2_preauth_007_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-172 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to draft
- If enforcement_location is not set to schema/migrations/0120

## Implementation Steps

### [ID tsk_p2_preauth_007_03_work_item_01] Add INV-172 to INVARIANTS_MANIFEST.yml
Add INV-172 to INVARIANTS_MANIFEST.yml with: id: INV-172, title: state machine enforcement, status: draft, enforcement_location: schema/migrations/0120, verification_command: grep -E 'enforce_transition_state_rules.*BEFORE.*INSERT.*OR.*UPDATE.*state_transitions' schema/migrations/0120.

### [ID tsk_p2_preauth_007_03_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_03.sh that runs grep to verify INV-172 exists in INVARIANTS_MANIFEST.yml with correct fields.

### [ID tsk_p2_preauth_007_03_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_03.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_03_work_item_01] [ID tsk_p2_preauth_007_03_work_item_02]
# [ID tsk_p2_preauth_007_03_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_03.sh && bash scripts/audit/verify_tsk_p2_preauth_007_03.sh > evidence/phase2/tsk_p2_preauth_007_03.json || exit 1

# [ID tsk_p2_preauth_007_03_work_item_01]
grep -A 5 "id: INV-172" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: draft" || exit 1
grep -A 5 "id: INV-172" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement_location" || exit 1

# [ID tsk_p2_preauth_007_03_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_007_03.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_03.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_172_registered
- inv_172_status_draft

## Rollback

Revert INV-172 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-172 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not draft | Low | Medium | Ensure status is set to draft |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
