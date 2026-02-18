# Implementation Plan: Canonical Diff Semantics (Parity)

failure_signature: P0.PARITY.DIFF_SEMANTICS.DRIFT
origin_task_id: TSK-P0-152
first_observed_utc: 2026-02-12T00:00:00Z

## intent
Eliminate CI vs local divergence caused by inconsistent git diff semantics across enforcement gates.

## problem_statement
Different gates currently compute "changed files" differently (range vs staged vs worktree vs unions).
This is a parity killer: CI evaluates commit ranges, while local hooks may evaluate staged/worktree.

## non_negotiables
- CI + pre-push/pre-ci enforcement must use commit-range semantics only.
- No "auto" mode in enforcement. Developer ergonomics can exist only as explicitly-invoked tooling.
- No placeholder/stub evidence to satisfy contract gates.

## canonical_definition
For parity-critical gates, "changed files" means:
- `merge_base = git merge-base <base_ref> <head_ref>`
- `git diff --name-only "${merge_base}...<head_ref>"`

## scope
In scope:
- Introduce a shared diff helper used by all diff-based enforcement gates.
- Refactor parity-critical gates to use the shared helper with `mode=range`.
- Add a verifier that fails if parity-critical scripts use staged/worktree diff fallbacks.

Out of scope:
- Changing invariant meanings, control plane IDs, or contract semantics beyond diff computation.

## tasks
- TSK-P0-153: Shared diff helper library (range-only for enforcement).
- TSK-P0-154: Refactor parity-critical gates to use helper.
- TSK-P0-155: Add verifier to prevent regressions + wire into ordered checks and CI.

## acceptance
- All parity-critical gates use the shared helper in `range` mode.
- No enforcement gate unions staged/worktree diffs.
- Local `scripts/dev/pre_ci.sh` and CI workflow compute the same changed-file list given the same base/head.
- `scripts/audit/run_phase0_ordered_checks.sh` remains the canonical sequence driver (no CI-only hidden gates).

## verification_commands_run (when implementing)
- rg -n "git diff --name-only|--cached" scripts | cat
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/dev/pre_ci.sh

## final_status
OPEN

