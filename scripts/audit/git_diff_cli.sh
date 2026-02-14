#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/audit/lib/git_diff.sh"

usage() {
  cat <<'EOF'
Usage:
  git_diff_cli.sh range-unified --base <ref> --head <ref> --out <file> [--unified <n>]
  git_diff_cli.sh range-names   --base <ref> --head <ref> [--out <file>]
  git_diff_cli.sh staged-unified --out <file> [--unified <n>]
  git_diff_cli.sh staged-names [--out <file>]
  git_diff_cli.sh worktree-unified --out <file> [--unified <n>]
EOF
}

cmd="${1:-}"
shift || true

base=""
head="HEAD"
out=""
unified=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 ;;
    --head) head="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    --unified) unified="${2:-}"; shift 2 ;;
    *)
      echo "ERROR: unknown_arg:$1" >&2
      usage
      exit 2
      ;;
  esac
done

case "$cmd" in
  range-unified)
    : "${out:?--out is required}"
    git_write_unified_diff_range "${base:-$(git_resolve_base_ref)}" "$head" "$out" "${unified:-0}"
    ;;
  range-names)
    result="$(git_changed_files_range "${base:-$(git_resolve_base_ref)}" "$head")"
    if [[ -n "$out" ]]; then
      printf '%s\n' "$result" > "$out"
    else
      printf '%s\n' "$result"
    fi
    ;;
  staged-unified)
    : "${out:?--out is required}"
    git_write_unified_diff_staged "$out" "${unified:-0}"
    ;;
  staged-names)
    result="$(git_changed_files_staged)"
    if [[ -n "$out" ]]; then
      printf '%s\n' "$result" > "$out"
    else
      printf '%s\n' "$result"
    fi
    ;;
  worktree-unified)
    : "${out:?--out is required}"
    git_write_unified_diff_worktree "$out" "${unified:-3}"
    ;;
  *)
    echo "ERROR: unknown_command:${cmd:-<empty>}" >&2
    usage
    exit 2
    ;;
esac
