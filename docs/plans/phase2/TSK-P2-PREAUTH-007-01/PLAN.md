# TSK-P2-PREAUTH-007-01: Runtime INV ID assignment

**Task:** TSK-P2-PREAUTH-007-01
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-00
**Blocks:** TSK-P2-PREAUTH-007-02
**Failure Signature**: ID assignment logic fails => CRITICAL_FAIL

## Objective

Perform runtime INV ID assignment to determine the next available invariant ID. This is a prerequisite step before registering new invariants INV-175/176/177.

## Architectural Context

INVARIANTS_MANIFEST.yml contains all registered invariants with IDs following the INV-XXX pattern. Runtime ID assignment scans this file to determine the next available ID, ensuring no collisions when adding new invariants.

## Pre-conditions

- TSK-P2-PREAUTH-007-00 PLAN.md exists and passes verification
- INVARIANTS_MANIFEST.yml exists and is valid YAML
- INV-175/176/177 do not exist in INVARIANTS_MANIFEST.yml

## Files to Change

| Path | Type | Change |
|------|------|--------|
| scripts/audit/verify_tsk_p2_preauth_007_01.sh | CREATE | Verification script for ID assignment |

## Stop Conditions

- If runtime INV ID assignment logic fails
- If INVARIANTS_MANIFEST.yml cannot be parsed
- If next available ID cannot be determined

## Implementation Steps

### [ID tsk_p2_preauth_007_01_work_item_01] Use grep to determine next available INV ID
Use grep to determine next available INV ID by scanning INVARIANTS_MANIFEST.yml for highest INV-XXX pattern.

### [ID tsk_p2_preauth_007_01_work_item_02] Write verification script
Write verify_tsk_p2_preauth_007_01.sh that verifies the runtime ID assignment logic works correctly.

### [ID tsk_p2_preauth_007_01_work_item_03] Run verification script
Run verify_tsk_p2_preauth_007_01.sh to confirm ID assignment works.

## Verification

```bash
# [ID tsk_p2_preauth_007_01_work_item_01] [ID tsk_p2_preauth_007_01_work_item_02]
# [ID tsk_p2_preauth_007_01_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_007_01.sh && bash scripts/audit/verify_tsk_p2_preauth_007_01.sh > evidence/phase2/tsk_p2_preauth_007_01.json || exit 1

# [ID tsk_p2_preauth_007_01_work_item_01]
grep -q "INV-" docs/invariants/INVARIANTS_MANIFEST.yml || exit 1

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
