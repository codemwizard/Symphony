# REM-2026-03-09 Invariant process governance batch PLAN

failure_signature: REM.GOVERNANCE.INVPROC_BASELINE_AND_VERIFIER_DRIFT
origin_task_id: TASK-INVPROC-01..05
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## repro_command
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`

## scope
- Canonicalize the governance baseline docs for invariants process authority.
- Add fail-closed parity verifiers for invariant register, CI gate spec, regulator pack template, and governance-link contracts.
- Align PR, exception, and onboarding governance surfaces with invariant-process evidence and approval requirements.

## verification_commands_run
- `bash scripts/audit/verify_invproc_01_governance_baseline.sh`
- `bash scripts/audit/verify_invariant_register_parity.sh`
- `bash scripts/audit/verify_ci_gate_spec_parity.sh`
- `bash scripts/audit/verify_regulator_pack_template.sh`
- `bash scripts/audit/verify_invariant_process_governance_links.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`
