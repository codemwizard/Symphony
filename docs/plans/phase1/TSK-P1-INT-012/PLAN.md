# TSK-P1-INT-012 Plan

Task ID: TSK-P1-INT-012

## objective
Evidence retention and archival boundary policy

## scope
1. Dependency completion: TSK-P1-INT-001, TSK-P1-INT-007.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Define active, archived, and historical evidence classes and retention windows.
2. Define archival eligibility and rotation boundaries.
3. Tie DR bundle selection to declared retention policy.

## acceptance_criteria
- Retention windows are defined for all evidence classes.
- Archival triggers are machine-checkable.
- DR bundle selection follows declared policy.
- No silent deletion before verification and audit obligations are satisfied.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_012.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_012.sh
verification_commands_run:
- rg -n --fixed-strings "Active evidence" docs/security/AUDIT_LOGGING_PLAN.md
- python3 inline evidence assertion over evidence/phase1/tsk_p1_int_012_retention_policy.json
- bash scripts/audit/verify_tsk_p1_int_012.sh
final_status: planned
origin_task_id: TSK-P1-INT-012
origin_gate_id: TSK_P1_INT_012
