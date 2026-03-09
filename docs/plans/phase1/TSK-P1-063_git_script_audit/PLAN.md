# TSK-P1-063 Plan

Failure_Signature: PHASE1.GIT.SCRIPT.AUDIT.INCOMPLETE
Origin_Task_ID: TSK-P1-063

## Mission
Audit and harden other mutable Git scripts against inherited Git plumbing.

## Constraints
- Cover hooks, nested shells, temporary worktrees, and disposable repositories.
- Produce an explicit inventory rather than ad hoc one-off fixes.

## Verification Commands
- `rg -n "git -C|git worktree|git checkout|git branch|git commit" scripts .githooks`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `rg -n "git -C|git worktree|git checkout|git branch|git commit" scripts .githooks`

## Evidence Paths
- `evidence/phase0/remediation_trace.json`
