# TSK-CLEAN-001 Plan

failure_signature: PHASE1.TSK.CLEAN.001.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-CLEAN-001

## repro_command
- git push -u origin task/TSK-CLEAN-001

## scope
- Reconcile task metadata statuses with implementation truth.
- No acceptance criteria, invariant IDs, evidence paths, or code logic changes.

## implementation_steps
1. Update allowed `status` fields in task meta files per task instruction.
2. Emit cleanup evidence artifact for reconciliation.
3. Run local verifiers and pre_ci.

## verification_commands_run
- grep -R "status:" tasks/
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh

## final_status
- in_progress
