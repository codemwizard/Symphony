# TSK-P1-064 Plan

## Mission
Wire hostile Git plumbing regression tests into enforced guarded flows.

## Constraints
- Regression coverage must be fail-closed.
- The regression itself must not mutate the caller repository.

## Verification Commands
- `rg -n "test_diff_semantics_parity_hostile_env.sh" scripts/dev/pre_ci.sh scripts/audit/run_phase0_ordered_checks.sh .github/workflows`
- `bash scripts/audit/test_diff_semantics_parity_hostile_env.sh`

## Evidence Paths
- `evidence/phase1/git_diff_semantics.json`
