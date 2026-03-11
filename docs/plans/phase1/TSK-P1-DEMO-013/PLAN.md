# TSK-P1-DEMO-013 Plan

Task ID: TSK-P1-DEMO-013

## objective
Extract demo/self-test runtime concerns out of production Program bootstrap.

## scope
1. Move demo/self-test execution path to dedicated demo runner/host.
2. Keep production host clean from demo-only route/flag wiring.

## guardrails
- No business logic changes.
- No schema changes.
- No feature expansion.
- Timebox: 2-3 engineering days; overrun requires re-approval.

## remediation_trace
failure_signature: PHASE1.DEMO.013.DEMO_HOST_EXTRACTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_013.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_013.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-013
origin_gate_id: PHASE1_DEMO_DECOUPLING_HOST
