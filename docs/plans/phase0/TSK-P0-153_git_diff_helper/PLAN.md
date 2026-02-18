# Implementation Plan: Shared Git Diff Helper (Range-Only Enforcement)

failure_signature: P0.PARITY.DIFF_HELPER.MISSING_OR_DRIFT
origin_task_id: TSK-P0-153
first_observed_utc: 2026-02-12T00:00:00Z

## intent
Provide one shared implementation for computing changed files, and make it easy for enforcement gates to be consistent.

## deliverables
- `scripts/lib/git_diff.sh` with:
  - `git_changed_files_range <base_ref> <head_ref>`
  - `git_resolve_base_ref` (BASE_REF override, else PR base, else origin/main)
  - stable sorted newline output
- Clear contract: enforcement callers must use range mode only.

## acceptance
- Helper works in both local and CI checkouts (fetch-depth 0 in CI).
- Helper fails loudly if base ref is missing (no silent staged/worktree fallback).

## final_status
OPEN

