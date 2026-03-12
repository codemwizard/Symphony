# TSK-P1-INT-010 Plan

Task ID: TSK-P1-INT-010

## objective
Product/demo/doc language synchronization

## scope
1. Dependency completion: TSK-P1-INT-001, TSK-P1-INT-006.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Replace immutability-first messaging with tamper-evident wording.
2. Add signed offline/pre-rail bridge wording.
3. Add explicit acknowledgement dependency wording.

## acceptance_criteria
- Public/demo materials use tamper-evident language.
- Public/demo materials include signed offline/pre-rail bridge framing.
- No unproven WORM or silent-settlement implications remain.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_010.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_010.sh
verification_commands_run:
- rg -n --fixed-strings "tamper-evident" docs/product/greentech4ce/StartUP.md
- python3 inline evidence assertion over evidence/phase1/tsk_p1_int_010_language_sync.json
- bash scripts/audit/verify_tsk_p1_int_010.sh
final_status: planned
origin_task_id: TSK-P1-INT-010
origin_gate_id: TSK_P1_INT_010
