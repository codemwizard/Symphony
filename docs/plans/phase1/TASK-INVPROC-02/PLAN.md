# TASK-INVPROC-02 Plan

## Mission
Implement invariant register to manifest parity verifier.

## Constraints
- Fail closed on parity mismatches.
- Use manifest as authoritative invariant source.
- Deterministic output and evidence.

## Verification Commands
- `bash scripts/audit/verify_invariant_register_parity.sh`
- `rg -n "verify_invariant_register_parity.sh" scripts/audit/run_invariants_fast_checks.sh`

## Evidence Paths
- `evidence/phase1/invproc_02_register_parity.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
