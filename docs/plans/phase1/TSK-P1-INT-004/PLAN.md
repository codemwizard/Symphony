# TSK-P1-INT-004 Plan

Task ID: TSK-P1-INT-004

## objective
AWAITING_EXECUTION with mandatory acknowledgement escalation and supervisor recovery

## scope
1. Dependency completion: TSK-P1-INT-001.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Introduce AWAITING_EXECUTION state for post-egress pre-acknowledgement lifecycle.
2. Implement timed tiered escalation for missing acknowledgement.
3. Reuse existing supervisor approval queue and stored procedures for Tier-3 interrupt flow.
4. Extend supervisor queue status model to include recovery-compatible states required by interrupt lifecycle (including ESCALATED and RESET), with auditable transition controls.
5. Persist interrupt actions (acknowledge, resume, reset) in evidence-visible audit trail.
6. Define RESET semantics explicitly as "return from ESCALATED to AWAITING_EXECUTION with acknowledgement requirement still active"; RESET must never imply settlement or acknowledgement bypass.
7. Refresh the governed schema baseline and baseline ADR log so baseline drift closes at migration cutoff `0073_int_004_ack_gap_controls.sql`.

## acceptance_criteria
- No instruction is silently marked settled without explicit acknowledgement or approved verified equivalent.
- Tier-3 escalation creates mandatory supervisor-visible interrupt and explicit escalation artifact.
- Supervisor interrupt transitions workflow into known degraded-but-safe state.
- Recovery path supports explicit acknowledge/resume/reset actions with auditable evidence.
- No parallel supervisor queue is introduced; existing queue path is extended and reused.
- RESET action is mechanically constrained to return to AWAITING_EXECUTION and preserve acknowledgement requirement.
- Recovery actions are recorded in append-only audit evidence even if queue row state is updated in place.
- Schema baseline artifacts are refreshed through migration cutoff `0073_int_004_ack_gap_controls.sql`, and the baseline ADR log records the update.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_004.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_004.sh
verification_commands_run:
- rg -n "AWAITING_EXECUTION|ESCALATED|RESET|supervisor_interrupt_audit_events|ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT" schema/migrations/0073_int_004_ack_gap_controls.sql
- rg -n "0073_int_004_ack_gap_controls.sql" schema/baselines/current/baseline.cutoff docs/decisions/ADR-0010-baseline-policy.md
- python3 - <<'PY'
  import json
  from pathlib import Path
  path = Path("evidence/phase1/tsk_p1_int_004_ack_gap_controls.json")
  payload = json.loads(path.read_text(encoding="utf-8"))
  assert payload["status"] == "PASS"
  assert payload["controls"]["queue_reused_not_parallel"] is True
  assert payload["controls"]["reset_returns_to_awaiting_execution"] is True
  print("PASS")
  PY
- bash scripts/audit/verify_tsk_p1_int_004.sh
final_status: planned
origin_task_id: TSK-P1-INT-004
origin_gate_id: TSK_P1_INT_004
