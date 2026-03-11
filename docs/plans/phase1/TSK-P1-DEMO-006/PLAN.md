# TSK-P1-DEMO-006 Plan

Task ID: TSK-P1-DEMO-006
Title: Supplier registry and minimal programme-scoped supplier allowlist enforcement

## intent
Implement the minimum supplier-governance surface required to prove that governed green disbursement is scoped by programme and not globally hardcoded.

## scope
- Supplier registry model with minimum fields needed for UC-01.
- Programme-scoped supplier allowlist relation/binding.
- Enforcement at governed release time.
- `SUPPLIER_NOT_ALLOWLISTED` exception emission.
- Minimal demo/operator-facing confirmation of programme-specific supplier approval state.

## out_of_scope
- Generic supplier onboarding product.
- Full admin back office and broad procurement workflows.

## required_outcomes
1. Supplier approved for Programme A routes successfully in Programme A.
2. Same supplier can be rejected for Programme B.
3. Unknown/non-allowlisted suppliers block release and emit correct exception.
4. Demo visibly shows programme-scoped approval behavior.

## evidence_expectations
- Positive path: supplier approved in programme X.
- Negative path: same supplier denied in programme Y.
- Exception emission path validated.
- No cross-programme leakage.

## remediation_trace
failure_signature: PHASE1.DEMO.006.PROGRAMME_SCOPED_SUPPLIER_POLICY_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_006.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_006.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-006
origin_gate_id: PHASE1_DEMO_SUPPLIER_POLICY
