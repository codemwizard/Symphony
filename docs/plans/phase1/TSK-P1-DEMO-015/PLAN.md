# TSK-P1-DEMO-015 Plan

Task ID: TSK-P1-DEMO-015

## objective
Split core and demo verification pipelines to reduce coupling and CI noise.

## scope
1. Keep core pre_ci production-focused.
2. Add demo pre_ci entrypoint for reveal/demo checks.
3. Preserve gate truthfulness across both paths.

## guardrails
- No business logic changes.
- No schema changes.
- No feature expansion.
- Timebox: 2-3 engineering days; overrun requires re-approval.

## remediation_trace
failure_signature: PHASE1.DEMO.015.PIPELINE_SPLIT_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_015.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_015.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-015
origin_gate_id: PHASE1_DEMO_DECOUPLING_PIPELINE
