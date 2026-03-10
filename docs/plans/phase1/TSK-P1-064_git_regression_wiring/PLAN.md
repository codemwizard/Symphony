# TSK-P1-064 Plan

Failure_Signature: PHASE1.GIT.REGRESSION.WIRING.MISSING
Origin_Task_ID: TSK-P1-064

## Mission
Wire hostile Git plumbing regression tests into enforced guarded flows.

## Constraints
- Regression coverage must be fail-closed.
- The regression itself must not mutate the caller repository.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_064.sh`

## Repro_Command
- `GIT_DIR=.git GIT_WORK_TREE=. bash scripts/audit/test_diff_semantics_parity_hostile_env.sh`

## Evidence Paths
- `evidence/phase1/tsk_p1_064_git_regression_wiring.json`
