#!/usr/bin/env bash
set -euo pipefail

# Range-only git diff helpers for parity-critical gates.

git_resolve_base_ref() {
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

  if [[ "$ref" == refs/remotes/origin/* ]]; then
    local branch="${ref#refs/remotes/origin/}"
    git fetch --no-tags --prune origin "${branch}:refs/remotes/origin/${branch}" >/dev/null 2>&1 || true
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
