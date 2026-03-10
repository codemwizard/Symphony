# TSK-P1-073 Plan

Failure_Signature: PHASE1.DEBUG.073.REMEDIATION_ARTIFACT_FRESHNESS.MISSING
Origin_Task_ID: TSK-P1-073

## Mission
Fail closed when a branch changes guarded execution surfaces without also refreshing remediation or task casefiles.

## Constraints
- Accept either task casefiles or `REM-*` remediation casefiles as valid freshness artifacts.
- Enforce the rule in both fast checks and `pre_ci`.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_073.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD bash scripts/audit/verify_remediation_artifact_freshness.sh`

## Evidence Paths
- `evidence/phase1/tsk_p1_073_remediation_artifact_freshness.json`
