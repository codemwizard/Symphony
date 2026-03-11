# TSK-P1-DEMO-010 Plan

Task ID: TSK-P1-DEMO-010
Title: Day 61–90 Supervisory Reveal rehearsal and fallback artifacts

## intent
Convert the GreenTech4CE demo into a deterministic, repeatable supervisory reveal executable in under ten minutes.

## required_reveal_flow
1. Programme overview.
2. Settled/authorized instruction drill-down.
3. Hold-path drill-down.
4. Export/reporting step.
5. One optional risk-triggered hold example.

## sim_swap_positioning
SIM-swap remains in scope only as a risk-triggered hold example. It must remain subordinate to the governed-disbursement story and must not be presented as Symphony’s primary product identity.

## in_scope
- Operator-runbook reveal sequence.
- Timing discipline and click order.
- Fallback pack generation.

## out_of_scope
- Generic fraud-platform storytelling.
- Phase-2 rail activation narrative.

## remediation_trace
failure_signature: PHASE1.DEMO.010.REVEAL_REHEARSAL_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_010.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_010.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-010
origin_gate_id: PHASE1_DEMO_REVEAL
