# TSK-P2-PREAUTH-004-03-DAG PLAN: Add Missing DAG Node

**Task:** TSK-P2-PREAUTH-004-03-DAG
**Owner:** ARCHITECT
**Depends on:** TSK-P2-PREAUTH-004-01-REM
**Blocks:** TSK-P2-PREAUTH-004-CLEANUP

## Objective

Wave 4 audit identified that TSK-P2-PREAUTH-004-03 node is missing from phase2_pre_atomic_dag.yml. The checkpoint/AUTH-BIND depends only on 004-02, but should depend on 004-03 to complete the authority binding chain. This task adds the missing 004-03 node and updates the checkpoint dependency.

## Architectural Context

TSK-P2-PREAUTH-004-03 (Register and verify authority transition binding invariant) is already completed with INV-138 registered and verified. However, the DAG was never updated to include the node, creating a gap in the dependency chain. The correct ordering should be: 004-01 → 004-02 → 004-03 → checkpoint/AUTH-BIND.

## Pre-conditions

- TSK-P2-PREAUTH-004-01-REM is completed
- TSK-P2-PREAUTH-004-03 task is completed (verified in PHASE2_TASKS.md)
- phase2_pre_atomic_dag.yml exists and is valid YAML

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/tasks/phase2_pre_atomic_dag.yml | MODIFY | Add 004-03 node and update checkpoint dependency |

## Stop Conditions

- If DAG syntax validation fails → STOP
- If 004-03 task is not completed → STOP

## Implementation Steps

### [ID tsk_p2_preauth_004_03_dag_01] Add 004-03 node to DAG

Add TSK-P2-PREAUTH-004-03 node to docs/tasks/phase2_pre_atomic_dag.yml with:
- id: TSK-P2-PREAUTH-004-03
- stage: 2-authority-binding
- title: "Register and verify authority transition binding invariant"
- depends_on: [TSK-P2-PREAUTH-004-02]
- kind: task

### [ID tsk_p2_preauth_004_03_dag_02] Update checkpoint dependency

Update checkpoint/AUTH-BIND depends_on in docs/tasks/phase2_pre_atomic_dag.yml to include TSK-P2-PREAUTH-004-03.

Current depends_on: [TSK-P2-PREAUTH-004-02]
Updated depends_on: [TSK-P2-PREAUTH-004-03]

This ensures the ordering: 004-01 → 004-02 → 004-03 → checkpoint/AUTH-BIND

## Verification

```bash
# [ID tsk_p2_preauth_004_03_dag_01] [ID tsk_p2_preauth_004_03_dag_02]
grep 'TSK-P2-PREAUTH-004-03' docs/tasks/phase2_pre_atomic_dag.yml || exit 1

# [ID tsk_p2_preauth_004_03_dag_02]
grep -A 3 'checkpoint/AUTH-BIND' docs/tasks/phase2_pre_atomic_dag.yml | grep 'TSK-P2-PREAUTH-004-03' || exit 1
```

## Evidence Contract

None (docs-only task, no evidence emission)

## Remediation Trace Compliance

Not required (docs-only change, not production-affecting).

## Regulated Surface Compliance

None of the files modified by this task are in REGULATED_SURFACE_PATHS.yml. Approval metadata is not required.

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| DAG syntax validation fails | Low | Medium | Verify YAML syntax before commit |
| Breaking existing DAG dependencies | Low | High | Review existing dependencies before modification |

## Approval

This task does not modify regulated surfaces. No approval metadata required.
