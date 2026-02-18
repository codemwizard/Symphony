#!/usr/bin/env bash
set -euo pipefail

# Development-only helpers that intentionally read staged/worktree state.

git_changed_files_staged() {
  git diff --cached --name-only | LC_ALL=C sort -u
}

git_write_unified_diff_staged() {
  local out_file="${1:-}"
  local unified="${2:-0}"
  if [[ -z "$out_file" ]]; then
    echo "ERROR: out_file_required" >&2
    return 1
  fi
  git diff --cached --no-color --no-ext-diff --unified="$unified" > "$out_file"
}

git_write_unified_diff_staged_path() {
  local pathspec="${1:-}"
  local out_file="${2:-}"
  local unified="${3:-0}"
  if [[ -z "$pathspec" ]]; then
    echo "ERROR: pathspec_required" >&2
    return 1
  fi
  if [[ -z "$out_file" ]]; then
    echo "ERROR: out_file_required" >&2
    return 1
  fi
  git diff --cached --no-color --no-ext-diff --unified="$unified" -- "$pathspec" > "$out_file"
}

git_write_unified_diff_worktree() {
  local out_file="${1:-}"
  local unified="${2:-3}"
  if [[ -z "$out_file" ]]; then
    echo "ERROR: out_file_required" >&2
    return 1
  fi
  git diff --no-color --no-ext-diff --unified="$unified" > "$out_file"
}

git_assert_clean_path() {
  local pathspec="${1:-}"
  if [[ -z "$pathspec" ]]; then
    echo "ERROR: pathspec_required" >&2
    return 1
  fi
  git diff --exit-code -- "$pathspec"
}
