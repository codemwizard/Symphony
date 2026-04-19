# TSK-P2-REG-003-07: Register INV-178 and update MIGRATION_HEAD

Task: TSK-P2-REG-003-07
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-REG-003-06
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-003-07.INV178_OR_MIGRATION_HEAD_NOT_UPDATED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Register INV-178 for Project DNSH spatial check enforcement and update MIGRATION_HEAD to 0125 to complete the PostGIS spatial tables implementation.

## Architectural Context

INV-178 enforces that project DNSH spatial checks are DB-enforced via PostGIS with versioned dataset and execution binding. This task completes the PostGIS spatial implementation.

## Pre-conditions

- TSK-P2-REG-003-06 (K13 trigger) is complete
- All PostGIS migrations are successful

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/invariants/INVARIANTS_MANIFEST.yml | MODIFY | Add INV-178 with status: implemented |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0125 |
| scripts/db/verify_tsk_p2_reg_003_07.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If INV-178 does not exist in INVARIANTS_MANIFEST.yml
- If INV-178 status is not implemented
- If INV-178 severity is not P0
- If MIGRATION_HEAD is not updated to 0125

## Implementation Steps

### [ID tsk_p2_reg_003_07_work_item_01] Add INV-178 to INVARIANTS_MANIFEST.yml
Add INV-178 to docs/invariants/INVARIANTS_MANIFEST.yml with id: INV-178, title: 'Project DNSH spatial check is DB-enforced via PostGIS with versioned dataset and execution binding', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_reg_003.sh.

### [ID tsk_p2_reg_003_07_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0125: echo 0125 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_reg_003_07_work_item_03] Write verification script
Write verify_tsk_p2_reg_003_07.sh that checks INV-178 exists in INVARIANTS_MANIFEST.yml and MIGRATION_HEAD is 0125.

### [ID tsk_p2_reg_003_07_work_item_04] Run verification script
Run verify_tsk_p2_reg_003_07.sh to confirm registration is successful.

### [ID tsk_p2_reg_003_07_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_07_work_item_01] [ID tsk_p2_reg_003_07_work_item_02]
# [ID tsk_p2_reg_003_07_work_item_03] [ID tsk_p2_reg_003_07_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_003_07.sh && bash scripts/db/verify_tsk_p2_reg_003_07.sh > evidence/phase2/tsk_p2_reg_003_07.json || exit 1

# [ID tsk_p2_reg_003_07_work_item_02]
test "$(cat schema/migrations/MIGRATION_HEAD)" = "0125" || exit 1

# [ID tsk_p2_reg_003_07_work_item_04]
test -f evidence/phase2/tsk_p2_reg_003_07.json || exit 1

# [ID tsk_p2_reg_003_07_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_07.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- inv_178_registered
- inv_178_status
- migration_head
- observed_paths

## Rollback

Revert INV-178 and MIGRATION_HEAD:
```bash
git checkout docs/invariants/INVARIANTS_MANIFEST.yml
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| INV-178 not added to INVARIANTS_MANIFEST.yml | Low | Medium | Review INVARIANTS_MANIFEST.yml edit |
| MIGRATION_HEAD not updated | Low | Medium | Check echo command output |

## Approval

This task modifies INVARIANTS_MANIFEST.yml and MIGRATION_HEAD. Requires human review before merge.
