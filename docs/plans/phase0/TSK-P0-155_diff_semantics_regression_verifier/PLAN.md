# Implementation Plan: Diff Semantics Regression Verifier

failure_signature: P0.PARITY.DIFF_SEMANTICS.REGRESSION
origin_task_id: TSK-P0-155
first_observed_utc: 2026-02-12T00:00:00Z

## intent
Prevent reintroduction of staged/worktree diff fallbacks in parity-critical enforcement scripts.

## deliverables
- `scripts/audit/verify_diff_semantics_parity.sh` which fails if:
  - parity-critical scripts contain `git diff --name-only --cached`
  - parity-critical scripts contain union-diff patterns (range + cached + worktree)
  - parity-critical scripts call `git diff --name-only` directly instead of shared helper
- Wire into:
  - `scripts/audit/run_phase0_ordered_checks.sh`
  - `.github/workflows/invariants.yml`

## acceptance
- Verifier runs fast and deterministically.
- Verifier is fail-closed in CI and pre-ci.

## final_status
OPEN

