# Implementation Plan: Refactor Diff-Based Gates to Shared Helper

failure_signature: P0.PARITY.DIFF_GATES.DRIFT
origin_task_id: TSK-P0-154
first_observed_utc: 2026-02-12T00:00:00Z

## intent
Ensure all parity-critical gates derive changed files via the shared helper in range mode.

## candidate_scripts (to confirm during implementation)
- `scripts/audit/enforce_change_rule.sh`
- `scripts/audit/verify_baseline_change_governance.sh`
- Any other gate that unions `git diff`, `git diff --cached`, and worktree diffs

## acceptance
- Each refactored gate calls `scripts/lib/git_diff.sh` for changed-file enumeration.
- No parity-critical gate silently falls back to staged/worktree diffs.

## final_status
OPEN

