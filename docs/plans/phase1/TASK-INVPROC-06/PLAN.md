# TASK-INVPROC-06 Plan

## Mission
Wire invariants process governance verifiers into CI and closeout.

## Constraints
- Preserve existing gate order and fail-closed semantics.
- No bypass for missing governance evidence.

## Verification Commands
- `bash scripts/audit/verify_invproc_06_ci_wiring_closeout.sh`
- `bash scripts/audit/verify_human_governance_review_signoff.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`

## Evidence Paths
- `evidence/phase1/invproc_06_ci_wiring_closeout.json`
- `evidence/phase1/human_governance_review_signoff.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
