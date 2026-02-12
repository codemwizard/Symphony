#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "==> Diff semantics parity verifier"

fail() { echo "ERROR: $*" >&2; exit 1; }

# Parity-critical scripts: these must use shared range-only diff helper.
critical=(
  "scripts/audit/enforce_change_rule.sh"
  "scripts/audit/verify_baseline_change_governance.sh"
)

for f in "${critical[@]}"; do
  [[ -f "$f" ]] || fail "missing_file:$f"

  if ! rg -n 'scripts/lib/git_diff\.sh' "$f" >/dev/null 2>&1; then
    fail "missing_git_diff_helper_source:$f"
  fi

  # Forbid staged/worktree diff enumeration in enforcement.
  if rg -n 'git diff --name-only --cached' "$f" >/dev/null 2>&1; then
    fail "forbidden_cached_diff:$f"
  fi
  if rg -n 'git diff --name-only\\b(?!.*merge_base)' "$f" >/dev/null 2>&1; then
    fail "forbidden_direct_name_only_diff:$f"
  fi

  # Forbid union-diff patterns and silent fallbacks.
  if rg -nF '|| true' "$f" >/dev/null 2>&1; then
    fail "forbidden_or_true_fallback:$f"
  fi
done

echo "Diff semantics parity verification passed."
