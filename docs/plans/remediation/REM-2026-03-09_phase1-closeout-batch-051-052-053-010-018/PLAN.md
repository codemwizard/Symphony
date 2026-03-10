# Remediation Casefile Plan

failure_signature: PHASE1.CLOSEOUT.BATCH.051_052_053_010_018
origin_task_id: TSK-P1-052
origin_gate_id: INT-G28
repro_command: RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh

## Scope
- Repair deterministic Phase-1 self-test isolation for LedgerApi file-mode self-tests.
- Regenerate missing required Phase-1 evidence so contract and closeout truth matches the codebase.
- Reconcile and close task-pack truth for TSK-P1-018, TSK-P1-051, TSK-P1-052, and TSK-P1-053.
- Keep TSK-P1-010 blocked until its declared prerequisites are complete.

## verification_commands_run
- pending

## final_status
OPEN
