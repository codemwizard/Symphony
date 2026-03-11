# TSK-P1-DEMO-001 Plan

Task ID: TSK-P1-DEMO-001

## objective
Implement a fail-closed pre-coding lock for demo work.

## scope
1. Confirm DB engine + tenant isolation pattern.
2. Confirm append-only evidence_event posture + proof-type registry model.
3. Confirm formal signoff checklist completion.

## acceptance_criteria
1. Missing confirmation => verifier FAIL.
2. Evidence artifact includes all confirmation flags and approval refs.

## remediation_trace
failure_signature: PHASE1.DEMO.001.PRECODING_LOCK_MISSING
repro_command: RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_001.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-001
origin_gate_id: PHASE1_DEMO_PRECODING_LOCK
