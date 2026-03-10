# TSK-P1-062 Plan

Failure_Signature: PHASE1.GIT.WORKTREE.HYGIENE.MISSING
Origin_Task_ID: TSK-P1-062

## Mission
Resolve contaminated and stale worktree state and add fail-closed worktree hygiene checks.

## Constraints
- Preserve forensic evidence until an explicit retention decision is recorded.
- Do not silently destroy investigative artifacts.

## Verification Commands
- `git worktree list --porcelain`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `git worktree list --porcelain`
- `git worktree prune --dry-run`

## Evidence Paths
- `evidence/phase0/remediation_trace.json`
