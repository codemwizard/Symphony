# TSK-P1-DEMO-014 Plan

Task ID: TSK-P1-DEMO-014

## objective
Implement explicit production vs pilot-demo profile wiring.

## scope
1. Profile switch declaration.
2. Demo route/component exposure restricted to pilot-demo.

## guardrails
- No business logic changes.
- No schema changes.
- No feature expansion.
- Timebox: 2-3 engineering days; overrun requires re-approval.

## remediation_trace
failure_signature: PHASE1.DEMO.014.PROFILE_WIRING_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_014.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_014.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-014
origin_gate_id: PHASE1_DEMO_DECOUPLING_PROFILE
