# TSK-P1-INT-011 Plan

Task ID: TSK-P1-INT-011

## objective
Semantic closeout gate for proven tamper-evident integrity and offline verification

## scope
1. Dependency completion: TSK-P1-INT-003, TSK-P1-INT-004, TSK-P1-INT-005, TSK-P1-INT-006, TSK-P1-INT-008, TSK-P1-INT-009B, TSK-P1-INT-010, TSK-P1-INT-012.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Rerun the predecessor verifiers for INT-003, INT-004, INT-005, INT-006, INT-008, STOR-001, INT-009B, INT-010, and INT-012.
2. Parse semantic fields from the regenerated evidence artifacts, not file existence.
3. Fail on missing tamper semantics, governance states, offline-proof flags, restore parity, language sync, or retention linkage.

## acceptance_criteria
- Gate enforces semantic flags and expected predecessor fields.
- Gate fails when tamper-trigger semantics are missing.
- Gate fails when offline verification is not isolated/bundle-only.
- Gate fails when retention/archival policy is absent or disconnected.
- Gate fails on placeholder bundles or restore stubs.

## exact_checks
- `INT-003` tamper-trigger semantics must match the expected CHAIN payload/current hash codes.
- `INT-004` must prove `AWAITING_EXECUTION`, `ESCALATED`, and settlement-guard controls.
- `INT-005` must prove the restricted-path cases pass and retention class stays `FIC_AML_CUSTOMER_ID`.
- `INT-006` must prove the signed offline/pre-rail bridge is a governed control path, not a workaround.
- `INT-008` must prove shared-nothing, bundle-only offline verification with tamper rejection.
- `INT-009B` must prove measured restore parity on `seaweedfs` with integrity verifier parity preserved.
- `INT-010` must prove the public-facing language sync flags remain true.
- `INT-012` must prove the retention boundary and DR-bundle linkage remain true.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_011.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_011.sh
verification_commands_run:
- python3 inline evidence assertion over evidence/phase1/tsk_p1_int_011_closeout_gate.json
- bash scripts/audit/verify_tsk_p1_int_011.sh
final_status: planned
origin_task_id: TSK-P1-INT-011
origin_gate_id: TSK_P1_INT_011
