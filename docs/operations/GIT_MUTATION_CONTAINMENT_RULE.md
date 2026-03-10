# Git Mutation Containment Rule

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Purpose: define the reusable engineering rule for any fixture, test, helper, or runner that mutates Git state.

## Scope
This rule applies to any script or test that may:
- create commits
- create, rename, or delete branches
- create or prune worktrees
- update refs directly
- stage or reset indexes in disposable repositories
- fetch or otherwise materialize remote-tracking refs for guarded execution

## Mandatory Controls
1. Scrub inherited Git plumbing before mutating state.
   Required variables to clear unless a script proves a tighter contract:
   - `GIT_DIR`
   - `GIT_WORK_TREE`
   - `GIT_INDEX_FILE`
   - `GIT_COMMON_DIR`
   - `GIT_OBJECT_DIRECTORY`
   - `GIT_ALTERNATE_OBJECT_DIRECTORIES`
   - `GIT_PREFIX`

2. Assert repository identity before mutation.
   Minimum assertions:
   - disposable fixture repo top-level equals the intended temp directory
   - disposable fixture repo git dir equals the intended `.git` directory
   - caller repo identity is unchanged after hostile-environment regression coverage

3. Do not treat `git -C` alone as containment.
   `git -C` changes cwd for a Git command. It does not neutralize inherited Git plumbing from parent shells, hooks, or nested subprocesses.

4. Apply containment at both levels.
   - fixture-level containment inside the mutating script
   - runner-level containment in the caller or orchestrator that invokes the fixture

5. Prefer disposable repositories for mutating tests.
   Any fixture that creates commits, branches, or staged state must operate inside a disposable repository unless the task explicitly audits an existing live repo.

6. Fail closed on stale worktree state.
   Guarded flows must detect prunable worktrees or stale disposable worktree paths and stop with actionable guidance instead of proceeding silently.

7. Record remediation when production-affecting guardrails change.
   If a Git containment fix changes guarded execution, the branch diff must carry remediation/task casefile freshness in the same change set.

## Approved Enforcement Seams
- `scripts/audit/test_diff_semantics_parity.sh`
- `scripts/audit/test_diff_semantics_parity_hostile_env.sh`
- `scripts/audit/run_phase0_ordered_checks.sh`
- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_remediation_trace.sh`
- `scripts/audit/verify_remediation_artifact_freshness.sh`

## Prohibited Assumptions
- inherited shell environment is safe by default
- local worktree state is disposable unless verified
- a passing local rerun is enough if the committed branch diff changed afterward
- branch-scoped approval or remediation evidence can be reused across unrelated branches
