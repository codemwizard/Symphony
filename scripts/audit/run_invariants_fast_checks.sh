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
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

echo "==> Fast invariants checks (no DB)"

# ---- helpers ----
have_cmd() { command -v "$1" >/dev/null 2>&1; }

run() {
  echo ""
  echo "-> $*"
  "$@"
}

# Prefer repo-local venv python when present (for local/CI parity).
PYTHON_BIN="python3"
if [[ -x "$ROOT/.venv/bin/python3" ]]; then
  PYTHON_BIN="$ROOT/.venv/bin/python3"
fi

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
    run "$PYTHON_BIN" -m py_compile "$f"
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
  run "$PYTHON_BIN" -m unittest -q scripts.audit.tests.test_detect_structural_changes
else
  echo "   (no tests found; skipping)"
fi

# ---- 4) Manifest validation ----
echo ""
echo "==> Manifest validation"
if [[ -f "scripts/audit/validate_invariants_manifest.py" ]]; then
  run "$PYTHON_BIN" scripts/audit/validate_invariants_manifest.py
else
  echo "ERROR: scripts/audit/validate_invariants_manifest.py not found"
  exit 1
fi

# ---- 5) Docs ↔ Manifest consistency ----
echo ""
echo "==> Docs ↔ Manifest consistency"
if [[ -f "scripts/audit/check_docs_match_manifest.py" ]]; then
  run "$PYTHON_BIN" scripts/audit/check_docs_match_manifest.py
else
  echo "ERROR: scripts/audit/check_docs_match_manifest.py not found"
  exit 1
fi

echo ""
echo "==> Doc alignment (core language)"
if [[ -x "scripts/audit/verify_doc_alignment.sh" || -f "scripts/audit/verify_doc_alignment.sh" ]]; then
  run scripts/audit/verify_doc_alignment.sh
else
  echo "ERROR: scripts/audit/verify_doc_alignment.sh not found"
  exit 1
fi

echo ""
echo "==> Three-Pillar model doc verification"
if [[ -x "scripts/audit/verify_three_pillars_doc.sh" || -f "scripts/audit/verify_three_pillars_doc.sh" ]]; then
  run scripts/audit/verify_three_pillars_doc.sh
else
  echo "ERROR: scripts/audit/verify_three_pillars_doc.sh not found"
  exit 1
fi

echo ""
echo "==> Control-plane drift verification"
if [[ -x "scripts/audit/verify_control_planes_drift.sh" || -f "scripts/audit/verify_control_planes_drift.sh" ]]; then
  run scripts/audit/verify_control_planes_drift.sh
else
  echo "ERROR: scripts/audit/verify_control_planes_drift.sh not found"
  exit 1
fi

echo ""
echo "==> CI toolchain verification"
if [[ -x "scripts/audit/verify_ci_toolchain.sh" || -f "scripts/audit/verify_ci_toolchain.sh" ]]; then
  if [[ "${SYMPHONY_SKIP_TOOLCHAIN_CHECK:-0}" == "1" ]]; then
    echo "   (skipping CI toolchain check; SYMPHONY_SKIP_TOOLCHAIN_CHECK=1)"
  else
    run scripts/audit/verify_ci_toolchain.sh
  fi
else
  echo "ERROR: scripts/audit/verify_ci_toolchain.sh not found"
  exit 1
fi

echo ""
echo "==> YAML conventions lint"
if [[ -x "scripts/audit/lint_yaml_conventions.sh" || -f "scripts/audit/lint_yaml_conventions.sh" ]]; then
  run scripts/audit/lint_yaml_conventions.sh
else
  echo "ERROR: scripts/audit/lint_yaml_conventions.sh not found"
  exit 1
fi

echo ""
echo "==> No-tx docs verification"
if [[ -x "scripts/audit/verify_no_tx_docs.sh" || -f "scripts/audit/verify_no_tx_docs.sh" ]]; then
  run scripts/audit/verify_no_tx_docs.sh
else
  echo "ERROR: scripts/audit/verify_no_tx_docs.sh not found"
  exit 1
fi

echo ""
echo "==> Task evidence contract (definitions)"
if [[ -x "scripts/audit/verify_task_evidence_contract.sh" || -f "scripts/audit/verify_task_evidence_contract.sh" ]]; then
  run scripts/audit/verify_task_evidence_contract.sh
else
  echo "ERROR: scripts/audit/verify_task_evidence_contract.sh not found"
  exit 1
fi

echo ""
echo "==> Phase-0 contract validation"
if [[ -x "scripts/audit/verify_phase0_contract.sh" || -f "scripts/audit/verify_phase0_contract.sh" ]]; then
  run bash scripts/audit/verify_phase0_contract.sh
else
  echo "ERROR: scripts/audit/verify_phase0_contract.sh not found"
  exit 1
fi

echo ""
echo "==> Phase-0 contract evidence status"
if [[ -x "scripts/audit/verify_phase0_contract_evidence_status.sh" || -f "scripts/audit/verify_phase0_contract_evidence_status.sh" ]]; then
  if [[ "${SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS:-0}" == "1" ]]; then
    echo "   (skipping contract evidence status; SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1)"
  else
    run bash scripts/audit/verify_phase0_contract_evidence_status.sh
  fi
else
  echo "ERROR: scripts/audit/verify_phase0_contract_evidence_status.sh not found"
  exit 1
fi

echo ""
echo "==> Compliance manifest verification"
if [[ -x "scripts/audit/verify_compliance_manifest.sh" || -f "scripts/audit/verify_compliance_manifest.sh" ]]; then
  run bash scripts/audit/verify_compliance_manifest.sh
else
  echo "ERROR: scripts/audit/verify_compliance_manifest.sh not found"
  exit 1
fi

echo ""
echo "==> SQLSTATE map drift check"
if [[ -x "scripts/audit/check_sqlstate_map_drift.sh" || -f "scripts/audit/check_sqlstate_map_drift.sh" ]]; then
  run bash scripts/audit/check_sqlstate_map_drift.sh
else
  echo "ERROR: scripts/audit/check_sqlstate_map_drift.sh not found"
  exit 1
fi

echo ""
echo "==> Baseline change governance"
if [[ -x "scripts/audit/verify_baseline_change_governance.sh" || -f "scripts/audit/verify_baseline_change_governance.sh" ]]; then
  run bash scripts/audit/verify_baseline_change_governance.sh
else
  echo "ERROR: scripts/audit/verify_baseline_change_governance.sh not found"
  exit 1
fi

echo ""
echo "==> Rebaseline strategy (day-zero baseline)"
if [[ -x "scripts/audit/verify_rebaseline_strategy.sh" || -f "scripts/audit/verify_rebaseline_strategy.sh" ]]; then
  run bash scripts/audit/verify_rebaseline_strategy.sh
else
  echo "ERROR: scripts/audit/verify_rebaseline_strategy.sh not found"
  exit 1
fi

echo ""
echo "==> Phase-0 implementation plan check"
if [[ -x "scripts/audit/verify_phase0_impl_plan.sh" || -f "scripts/audit/verify_phase0_impl_plan.sh" ]]; then
  run bash scripts/audit/verify_phase0_impl_plan.sh
else
  echo "ERROR: scripts/audit/verify_phase0_impl_plan.sh not found"
  exit 1
fi

echo ""
echo "==> Proxy resolution invariant (roadmap declaration)"
if [[ -x "scripts/audit/verify_proxy_resolution_invariant.sh" || -f "scripts/audit/verify_proxy_resolution_invariant.sh" ]]; then
  run bash scripts/audit/verify_proxy_resolution_invariant.sh
else
  echo "ERROR: scripts/audit/verify_proxy_resolution_invariant.sh not found"
  exit 1
fi

EVIDENCE_DIR="$ROOT/evidence/phase0"
mkdir -p "$EVIDENCE_DIR"
python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "INVARIANTS-DOCS-MATCH",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "PASS",
  "check": "docs_match_manifest",
}
Path(f"$EVIDENCE_DIR/invariants_docs_match.json").write_text(json.dumps(out, indent=2))
PY

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
echo "==> Emit roadmap evidence (fail-closed under DB exhaustion)"
EVIDENCE_DIR="$ROOT/evidence/phase0"
mkdir -p "$EVIDENCE_DIR"
python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-FAIL-CLOSED-ROADMAP",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "PASS",
  "invariant": "INV-039",
  "note": "roadmap only"
}
Path(f"$EVIDENCE_DIR/db_fail_closed_roadmap.json").write_text(json.dumps(out, indent=2))
PY

echo ""
echo "✅ Fast invariants checks PASSED."
