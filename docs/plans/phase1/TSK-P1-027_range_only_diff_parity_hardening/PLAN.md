# TSK-P1-027 Plan

## Mission
Strengthen `TSK-P1-021` so parity-critical diff workflows are strictly committed-history range-only and staged/worktree semantics are unreachable from parity-critical paths.

## Scope
- Add a dedicated range-only helper surface for parity-critical scripts.
- Isolate staged/worktree helper functions to non-parity tooling.
- Harden parity verifier to reject forbidden helper sourcing and staged/worktree helper calls in parity-critical scripts.
- Add acceptance test harness proving staged/worktree immunity of changed-file decisions.
- Keep evidence deterministic and fail-closed.

## Constraints
- No weakening of existing gates.
- No bypass/placeholder evidence.
- Preserve canonical helper usage and deterministic base-ref resolution.

## Verification
- `bash scripts/audit/test_diff_semantics_parity.sh`
- `bash scripts/audit/verify_diff_semantics_parity.sh`
- `bash scripts/audit/verify_remediation_trace.sh`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Evidence
- `evidence/phase1/git_diff_semantics.json` (extended with helper source checks, forbidden call scan results, and changed-files hash parity)
