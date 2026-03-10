# TSK-P1-071 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Task: TSK-P1-071
Failure Signature: PHASE1.DEBUG.071.FAILURE_LAYER_TAXONOMY_MISSING
failure_signature: PHASE1.DEBUG.071.FAILURE_LAYER_TAXONOMY_MISSING
origin_task_id: TSK-P1-071
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Add failure-layer classification to local gate output.
- Distinguish branch-content, source-control parity, bootstrap/toolchain, shared governance state, and DB/environment failures.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_071.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
