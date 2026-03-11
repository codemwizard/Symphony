# TSK-P1-DEMO-009 Plan

Task ID: TSK-P1-DEMO-009

## objective
Implement deterministic reporting export for programme-period evidence packaging.

## scope
1. Report schema and generators.
2. JSON + PDF output.
3. Operator-facing trigger.

## remediation_trace
failure_signature: PHASE1.DEMO.009.REPORTING_EXPORT_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_009.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_009.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-009
origin_gate_id: PHASE1_DEMO_REPORTING_EXPORT
