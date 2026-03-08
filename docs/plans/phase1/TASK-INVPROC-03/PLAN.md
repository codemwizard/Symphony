# TASK-INVPROC-03 Plan

## Mission
Implement CI gate specification drift verifier.

## Constraints
- Must validate real workflow/pre_ci definitions, not prose-only checks.
- Fail closed when required jobs/commands are missing.

## Verification Commands
- `bash scripts/audit/verify_ci_gate_spec_parity.sh`
- `rg -n "verify_ci_gate_spec_parity.sh" scripts/audit/run_invariants_fast_checks.sh`

## Evidence Paths
- `evidence/phase1/invproc_03_ci_gate_spec_parity.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
