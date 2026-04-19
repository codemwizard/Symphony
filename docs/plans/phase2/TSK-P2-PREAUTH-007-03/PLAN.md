# TSK-P2-PREAUTH-007-03: Register INV-176 (state_machine_enforced)

**Task:** TSK-P2-PREAUTH-007-03
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-02
**Blocks:** TSK-P2-PREAUTH-007-04
**Failure Signature**: INV-176 not registered or status not implemented => CRITICAL_FAIL

## Objective

Register INV-176 for state_machine_enforced via trigger layer. Without this invariant, state machine enforcement is not governed, creating risk of invalid state transitions.

## Architectural Context

INV-176 enforces state machine enforcement via the trigger layer in migration 0120. The invariant is verified by verify_tsk_p2_preauth_005_08.sh which checks for proper trigger enforcement including enforce_transition_state_rules(), enforce_transition_authority(), enforce_transition_signature(), enforce_execution_binding(), deny_state_transitions_mutation(), and update_current_state().

## Pre-conditions

- TSK-P2-PREAUTH-007-02 is complete
- INV-176 does not exist in INVARIANTS_MANIFEST.yml or has status other than implemented
- state machine triggers exist in migration 0120

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-176 with status: implemented |
| scripts/audit/verify_tsk_p2_preauth_007_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- If INV-176 is not added to INVARIANTS_MANIFEST.yml
- If status is not set to implemented
- If enforcement is not set to scripts/db/verify_tsk_p2_preauth_005_08.sh

## Implementation Steps

### [ID tsk_p2_preauth_007_03_work_item_01] Add INV-176 to INVARIANTS_MANIFEST.yml
Add INV-176 to INVARIANTS_MANIFEST.yml with: id: INV-176, title: 'state_transitions is enforced via trigger layer', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_preauth_005_08.sh.

### [ID tsk_p2_preauth_007_03_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_03.sh that runs verify_tsk_p2_preauth_005_08.sh to verify INV-176 enforcement.

### [ID tsk_p2_preauth_007_03_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_03.sh to confirm invariant is registered correctly.

## Verification

```bash
# [ID tsk_p2_preauth_007_03_work_item_01] [ID tsk_p2_preauth_007_03_work_item_02]
# [ID tsk_p2_preauth_007_03_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_03.sh && bash scripts/audit/verify_tsk_p2_preauth_007_03.sh > evidence/phase2/tsk_p2_preauth_007_03.json || exit 1

# [ID tsk_p2_preauth_007_03_work_item_01]
grep -A 5 "id: INV-176" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented" &&
grep -A 5 "id: INV-176" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "enforcement" || exit 1

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
- inv_176_registered
- inv_176_status_implemented

## Rollback

Revert INV-176 addition:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-176 not registered | Low | Critical | Review INVARIANTS_MANIFEST.yml after edit |
| Status not implemented | Low | Medium | Ensure status is set to implemented |

## Approval

This task modifies INVARIANTS_MANIFEST.yml. Requires human review before merge.
