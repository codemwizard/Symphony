# TSK-P1-069 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Task: TSK-P1-069
Failure Signature: PHASE1.DEBUG.069.FAIL_FIRST_TRIAGE_NOT_SURFACED
failure_signature: PHASE1.DEBUG.069.FAIL_FIRST_TRIAGE_NOT_SURFACED
origin_task_id: TSK-P1-069
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Add a fail-first triage banner to `scripts/dev/pre_ci.sh`.
- Point failure output to the canonical remediation policy and workflow.
- Make first-failure isolation more visible than blind rerun behavior.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_069.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
