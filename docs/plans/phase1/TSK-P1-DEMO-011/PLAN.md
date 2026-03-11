# TSK-P1-DEMO-011 Plan

Task ID: TSK-P1-DEMO-011
Title: Pilot success criteria verifier gate

## intent
Translate demo and pilot-readiness claims into mechanical pass/fail thresholds.

## core_principle
Reveal must present interpreted evidence state first and raw artifacts second.

## source_of_truth
`Symphony_PRD_GreenTech4CE(3).docx`, Section 6 ("Pilot Success Criteria"), including Section 6.3 ("Regulatory Success Criteria — The BoZ Test").

## required_gate_assertions
1. Applicable criteria and thresholds from `Symphony_PRD_GreenTech4CE(3).docx` Section 6 are encoded as machine checks.
2. Missing threshold evidence fails closed.
3. Interpreted evidence state is visible in reveal.
4. Raw artifacts available via drill-down.

## remediation_trace
failure_signature: PHASE1.DEMO.011.SUCCESS_GATE_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_011.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_011.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-011
origin_gate_id: PHASE1_DEMO_SUCCESS_GATE
