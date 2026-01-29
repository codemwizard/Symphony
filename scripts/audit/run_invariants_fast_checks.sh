#!/usr/bin/env bash
set -euo pipefail

# run_invariants_fast_checks.sh
#
# Fast, dependency-light invariants verification intended for:
# - local pre-push / pre-PR checks
# - the first CI job (fail fast, avoid expensive DB work)
#
# What it does:
#  1) Shell syntax check on audit scripts
#  2) Python syntax check on audit python files
#  3) Unit tests for detectors (unittest or pytest if present)
#  4) Validate INVARIANTS_MANIFEST.yml (schema + uniqueness + implemented verification not TODO)
#  5) Check docs (Implemented/Roadmap) are consistent with manifest (no drift)
#  6) Regenerate QUICK and fail if it differs from committed output
#  7) Optional: validate exception templates if exceptions exist
#
# Exit non-zero on failure.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Fast invariants checks (no DB)"

# ---- helpers ----
have_cmd() { command -v "$1" >/dev/null 2>&1; }

run() {
  echo ""
  echo "-> $*"
  "$@"
}

# ---- 1) Shell syntax checks ----
echo ""
echo "==> Shell syntax checks"
SHELL_SCRIPTS=(
  "scripts/audit/enforce_change_rule.sh"
  "scripts/audit/enforce_invariant_promotion.sh"
  "scripts/audit/new_invariant.sh"
  "scripts/audit/record_invariants_exception.sh"
  "scripts/audit/verify_exception_template.sh"
  "scripts/audit/verify_invariants_local.sh"
)
for f in "${SHELL_SCRIPTS[@]}"; do
  if [[ -f "$f" ]]; then
    run bash -n "$f"
  fi
done

# ---- 2) Python syntax checks ----
echo ""
echo "==> Python syntax checks"
PY_FILES=(
  "scripts/audit/detect_structural_changes.py"
  "scripts/audit/detect_structural_sql_changes.py"
  "scripts/audit/auto_create_exception_from_detect.py"
  "scripts/audit/generate_invariants_quick.py"
  "scripts/audit/validate_invariants_manifest.py"
  "scripts/audit/check_docs_match_manifest.py"
)
for f in "${PY_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    run python3 -m py_compile "$f"
  fi
done

# ---- 3) Unit tests (detectors) ----
echo ""
echo "==> Detector unit tests"
# Prefer pytest if available, otherwise try unittest
if have_cmd pytest && [[ -d "scripts/audit/tests" ]]; then
  run pytest -q scripts/audit/tests
elif [[ -f "scripts/audit/tests/test_detect_structural_changes.py" ]]; then
  # Run as unittest module if it is written that way
  # (If it isn't, this will fail loudly, which is fine — you can switch to pytest.)
  run python3 -m unittest -q scripts.audit.tests.test_detect_structural_changes
else
  echo "   (no tests found; skipping)"
fi

# ---- 4) Manifest validation ----
echo ""
echo "==> Manifest validation"
if [[ -f "scripts/audit/validate_invariants_manifest.py" ]]; then
  run python3 scripts/audit/validate_invariants_manifest.py
else
  echo "ERROR: scripts/audit/validate_invariants_manifest.py not found"
  exit 1
fi

# ---- 5) Docs ↔ Manifest consistency ----
echo ""
echo "==> Docs ↔ Manifest consistency"
if [[ -f "scripts/audit/check_docs_match_manifest.py" ]]; then
  run python3 scripts/audit/check_docs_match_manifest.py
else
  echo "ERROR: scripts/audit/check_docs_match_manifest.py not found"
  exit 1
fi

echo ""
echo "==> QUICK regeneration drift check"
if [[ -x "scripts/audit/generate_invariants_quick" ]]; then
  run scripts/audit/generate_invariants_quick
  run git diff --exit-code docs/invariants/INVARIANTS_QUICK.md
elif [[ -f "scripts/audit/generate_invariants_quick.py" ]]; then
  run python3 scripts/audit/generate_invariants_quick.py
  run git diff --exit-code docs/invariants/INVARIANTS_QUICK.md
else
  echo "ERROR: scripts/audit/generate_invariants_quick not found"
  exit 1
fi

# ---- 7) Exception template validation (optional) ----
echo ""
echo "==> Exception template validation (optional)"
if [[ -x "scripts/audit/verify_exception_template.sh" || -f "scripts/audit/verify_exception_template.sh" ]]; then
  if [[ -d "docs/invariants/exceptions" ]] && compgen -G "docs/invariants/exceptions/*.md" >/dev/null; then
    run scripts/audit/verify_exception_template.sh
  else
    echo "   (no exception files present; skipping)"
  fi
else
  echo "   (verify_exception_template.sh missing; skipping)"
fi

echo ""
echo "✅ Fast invariants checks PASSED."
