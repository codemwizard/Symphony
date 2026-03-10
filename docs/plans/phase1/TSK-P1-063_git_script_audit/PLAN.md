# TSK-P1-063 Plan

Failure_Signature: PHASE1.GIT.SCRIPT.AUDIT.INCOMPLETE
Origin_Task_ID: TSK-P1-063

## Mission
Audit and harden other mutable Git scripts against inherited Git plumbing.

## Constraints
- Cover hooks, nested shells, temporary worktrees, and disposable repositories.
- Produce an explicit inventory rather than ad hoc one-off fixes.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_063.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `rg -n "git -C|git worktree|git checkout|git branch|git commit" scripts .githooks`

## Evidence Paths
- `evidence/phase1/tsk_p1_063_git_script_audit.json`
