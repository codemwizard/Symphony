# TSK-P1-061 Plan

Failure_Signature: PHASE1.GIT.CONTAINMENT.RULE.MISSING
Origin_Task_ID: TSK-P1-061

## Mission
Codify the repository-wide Git containment rule for fixtures and scripts that mutate Git state.

## Constraints
- No new mutable Git fixture may rely on `git -C` alone for containment.
- Canonical references must remain anchored to `docs/operations/AI_AGENT_OPERATION_MANUAL.md`.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_061.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `bash scripts/audit/test_diff_semantics_parity.sh`
- `bash scripts/audit/test_diff_semantics_parity_hostile_env.sh`

## Evidence Paths
- `evidence/phase1/tsk_p1_061_git_containment_rule.json`
