# TASK-INVPROC-06 Plan

## Mission
Wire invariants process governance verifiers into CI and closeout.

## Constraints
- Preserve existing gate order and fail-closed semantics.
- No bypass for missing governance evidence.

## Verification Commands
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`
- `rg -n "verify_invariant_register_parity.sh|verify_ci_gate_spec_parity.sh|verify_regulator_pack_template.sh|verify_invariant_process_governance_links.sh" scripts/audit/run_invariants_fast_checks.sh .github/workflows/invariants.yml`

## Evidence Paths
- `evidence/phase1/invproc_06_ci_wiring_closeout.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
