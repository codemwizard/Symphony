# TSK-P1-DEMO-016 Plan

Task ID: TSK-P1-DEMO-016

## objective
Conditionally perform minimal project/assembly split only if DEMO-013 proves necessary.

## trigger_rule
Do not execute unless DEMO-013 execution log contains concrete assembly-coupling blocker evidence.

## scope
1. Minimal separation required for clean demo/core isolation.
2. Enforce one-way dependency: demo -> core contracts only.

## status
blocked (conditional)

## remediation_trace
failure_signature: PHASE1.DEMO.016.CONDITIONAL_SPLIT_MISFIRED
repro_command: bash scripts/audit/verify_tsk_p1_demo_016.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_016.sh
final_status: blocked
origin_task_id: TSK-P1-DEMO-016
origin_gate_id: PHASE1_DEMO_CONDITIONAL_ASSEMBLY_SPLIT
