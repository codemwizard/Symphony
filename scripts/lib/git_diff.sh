#!/usr/bin/env bash
set -euo pipefail

# Shared git-diff helpers for parity-critical gates.
# Contract:
# - Enforcement gates MUST use commit-range semantics (merge-base...HEAD) only.
# - No implicit staged/worktree fallback is permitted in enforcement.

git_resolve_base_ref() {
  # Priority:
  # 1) BASE_REF env override (explicit)
  # 2) REMEDIATION_TRACE_BASE_REF (shared env file)
  # 3) GitHub PR base ref (refs/remotes/origin/<branch>)
  # 4) refs/remotes/origin/main
  if [[ -n "${BASE_REF:-}" ]]; then
    printf '%s\n' "$BASE_REF"
    return 0
  fi
  if [[ -n "${REMEDIATION_TRACE_BASE_REF:-}" ]]; then
    printf '%s\n' "$REMEDIATION_TRACE_BASE_REF"
    return 0
  fi
  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    printf 'refs/remotes/origin/%s\n' "$GITHUB_BASE_REF"
    return 0
  fi
  printf '%s\n' "refs/remotes/origin/main"
}

git_ensure_ref() {
  local ref="$1"
  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    return 0
  fi

  # Best-effort fetch for refs/remotes/origin/<branch> refs to reduce local friction.
  if [[ "$ref" == refs/remotes/origin/* ]]; then
    if command -v git >/dev/null 2>&1; then
      local branch="${ref#refs/remotes/origin/}"
      git fetch --no-tags --prune origin "${branch}:refs/remotes/origin/${branch}" >/dev/null 2>&1 || true
    fi
  fi

  git rev-parse --verify "$ref" >/dev/null 2>&1
}

git_merge_base() {
  local base_ref="${1:-}"
  local head_ref="${2:-HEAD}"
  if [[ -z "$base_ref" ]]; then
    base_ref="$(git_resolve_base_ref)"
  fi
  if ! git_ensure_ref "$base_ref"; then
    echo "ERROR: base_ref_not_found:$base_ref" >&2
    return 1
  fi
  local merge_base
  merge_base="$(git merge-base "$base_ref" "$head_ref" 2>/dev/null || true)"
  if [[ -z "$merge_base" ]]; then
    echo "ERROR: merge_base_unresolved:${base_ref}...${head_ref}" >&2
    return 1
  fi
  printf '%s\n' "$merge_base"
}

git_changed_files_range() {
  local base_ref="${1:-}"
  local head_ref="${2:-HEAD}"

  if [[ -z "$base_ref" ]]; then
    base_ref="$(git_resolve_base_ref)"
  fi

  if ! git_ensure_ref "$base_ref"; then
    echo "ERROR: base_ref_not_found:$base_ref" >&2
    return 1
  fi

  local merge_base
  merge_base="$(git_merge_base "$base_ref" "$head_ref")" || return 1

  # Stable, newline-separated list.
  git diff --name-only "${merge_base}...${head_ref}" | LC_ALL=C sort -u
}

git_write_unified_diff_range() {
  local base_ref="${1:-}"
  local head_ref="${2:-HEAD}"
  local out_file="${3:-}"
  local unified="${4:-0}"
  if [[ -z "$out_file" ]]; then
    echo "ERROR: out_file_required" >&2
    return 1
  fi
  local merge_base
  merge_base="$(git_merge_base "$base_ref" "$head_ref")" || return 1
  git diff --no-color --no-ext-diff --unified="$unified" "${merge_base}...${head_ref}" > "$out_file"
}

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
