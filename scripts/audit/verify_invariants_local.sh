#!/usr/bin/env bash
set -euo pipefail

# verify_invariants_local.sh
#
# Local helper that mirrors the CI mechanical gating:
# - computes diff (BASE_REF...HEAD_REF)
# - runs detect_structural_changes
# - if structural_change=true, requires change-rule compliance
# - runs promotion gate + quick generator checks

BASE_REF="${1:-refs/remotes/origin/main}"
HEAD_REF="${2:-HEAD}"
source scripts/audit/lib/git_diff.sh

mkdir -p /tmp/invariants_ai

git fetch --no-tags --depth=1 origin main >/dev/null 2>&1 || true
git_write_unified_diff_range "$BASE_REF" "$HEAD_REF" /tmp/invariants_ai/pr.diff 0

python3 scripts/audit/detect_structural_changes.py --diff-file /tmp/invariants_ai/pr.diff --out /tmp/invariants_ai/detect.json
structural="$(python3 - <<'PY'
import json
d=json.load(open("/tmp/invariants_ai/detect.json"))
print("true" if d.get("structural_change") else "false")
PY
)"

echo "Detector structural_change=${structural}"
if [[ "${structural}" == "true" ]]; then
  BASE_REF="${BASE_REF}" HEAD_REF="${HEAD_REF}" scripts/audit/enforce_change_rule.sh
fi

if [[ -x scripts/audit/enforce_invariant_promotion.sh ]]; then
  scripts/audit/enforce_invariant_promotion.sh
fi

if [[ -x scripts/audit/verify_exception_template.sh ]]; then
  scripts/audit/verify_exception_template.sh
fi

if [[ -x scripts/audit/generate_invariants_quick ]]; then
  scripts/audit/generate_invariants_quick
  git_assert_clean_path docs/invariants/INVARIANTS_QUICK.md
fi

echo "✅ verify_invariants_local passed."
