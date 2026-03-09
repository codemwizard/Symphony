# TSK-P1-062 Plan

## Mission
Resolve contaminated and stale worktree state and add fail-closed worktree hygiene checks.

## Constraints
- Preserve forensic evidence until an explicit retention decision is recorded.
- Do not silently destroy investigative artifacts.

## Verification Commands
- `git worktree list --porcelain`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Evidence Paths
- `evidence/phase0/remediation_trace.json`
