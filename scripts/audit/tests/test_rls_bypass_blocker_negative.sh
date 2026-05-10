#!/usr/bin/env bash
# test_rls_bypass_blocker_negative.sh
# TSK-P2-RLS-BYPASS-008 — Negative tests for verify_rls_bypass_blocker_resolution.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERIFIER="$ROOT_DIR/scripts/audit/verify_rls_bypass_blocker_resolution.sh"
PASS=0
FAIL=0
TOTAL=0

run_test() {
  local id="$1" desc="$2"
  TOTAL=$((TOTAL + 1))
  echo "── $id: $desc"
}

pass() { PASS=$((PASS + 1)); echo "   ✅ PASS"; }
fail() { FAIL=$((FAIL + 1)); echo "   ❌ FAIL: $1"; }

FIXTURE_DIR="$(mktemp -d)"
trap "rm -rf '$FIXTURE_DIR'" EXIT
mkdir -p "$FIXTURE_DIR/scripts/audit" "$FIXTURE_DIR/scripts/lib" "$FIXTURE_DIR/.venv/bin" "$FIXTURE_DIR/evidence/phase2" "$FIXTURE_DIR/docs/governance"

if [[ -f "$VERIFIER" ]]; then
  cp "$VERIFIER" "$FIXTURE_DIR/scripts/audit/"
fi
if [[ -f "$ROOT_DIR/scripts/lib/evidence.sh" ]]; then
  cp "$ROOT_DIR/scripts/lib/evidence.sh" "$FIXTURE_DIR/scripts/lib/"
fi
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  ln -sf "$(readlink -f "$ROOT_DIR/.venv/bin/python3")" "$FIXTURE_DIR/.venv/bin/python3" 2>/dev/null || true
fi

# ── N1: Index missing prerequisite evidence path ──────────────────────────────
run_test "N1" "Verifier rejects index missing a prerequisite evidence path"

# Setup fixture index without TSK-001 evidence path
cat > "$FIXTURE_DIR/docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md" <<EOF
# Index
DOES NOT trigger or claim Phase-2 closeout
TSK-P2-RLS-BYPASS-001
TSK-P2-RLS-BYPASS-002
TSK-P2-RLS-BYPASS-003
TSK-P2-RLS-BYPASS-004
TSK-P2-RLS-BYPASS-005
TSK-P2-RLS-BYPASS-006
TSK-P2-RLS-BYPASS-007
evidence/phase2/rls_bypass_runtime_removal.json
evidence/phase2/rls_bypass_seed_refactor.json
evidence/phase2/rls_bypass_policy_migration.json
evidence/phase2/rls_no_app_bypass_policies.json
evidence/phase2/rls_bypass_baseline_refresh.json
evidence/phase2/rls_bypass_runtime_isolation.json
EOF

# Create dummy evidence files so missing_evidence is only triggered by the index
for f in evidence/phase2/rls_bypass_dependency_inventory.json \
         evidence/phase2/rls_bypass_runtime_removal.json \
         evidence/phase2/rls_bypass_seed_refactor.json \
         evidence/phase2/rls_bypass_policy_migration.json \
         evidence/phase2/rls_no_app_bypass_policies.json \
         evidence/phase2/rls_bypass_baseline_refresh.json \
         evidence/phase2/rls_bypass_runtime_isolation.json; do
  echo '{"status":"PASS","observed_hashes":{},"execution_trace":[],"terminal_bypass_count":0,"bypass_setting_used":false,"positive_test_passed":true,"negative_test_passed":true}' > "$FIXTURE_DIR/$f"
done

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_blocker_resolution.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject index missing prerequisite evidence"
else
  # Check if missing_evidence was populated
  if grep -q "rls_bypass_dependency_inventory" "$FIXTURE_DIR/evidence/phase2/rls_bypass_blocker_resolution.json"; then
    pass
  else
    fail "Verifier rejected but did not report missing_evidence correctly"
  fi
fi

# ── N2: Inadmissible prerequisite evidence ────────────────────────────────────
run_test "N2" "Verifier rejects prerequisite evidence missing structural fields"

# Restore full index
cat > "$FIXTURE_DIR/docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md" <<EOF
DOES NOT trigger or claim Phase-2 closeout
TSK-P2-RLS-BYPASS-001
TSK-P2-RLS-BYPASS-002
TSK-P2-RLS-BYPASS-003
TSK-P2-RLS-BYPASS-004
TSK-P2-RLS-BYPASS-005
TSK-P2-RLS-BYPASS-006
TSK-P2-RLS-BYPASS-007
evidence/phase2/rls_bypass_dependency_inventory.json
evidence/phase2/rls_bypass_runtime_removal.json
evidence/phase2/rls_bypass_seed_refactor.json
evidence/phase2/rls_bypass_policy_migration.json
evidence/phase2/rls_no_app_bypass_policies.json
evidence/phase2/rls_bypass_baseline_refresh.json
evidence/phase2/rls_bypass_runtime_isolation.json
EOF

# Make one evidence file inadmissible (missing execution_trace)
echo '{"status":"PASS","observed_hashes":{}}' > "$FIXTURE_DIR/evidence/phase2/rls_bypass_dependency_inventory.json"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_blocker_resolution.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject inadmissible prerequisite evidence"
else
  if grep -q "missing structural fields" "$FIXTURE_DIR/evidence/phase2/rls_bypass_blocker_resolution.json"; then
    pass
  else
    fail "Verifier rejected but did not report inadmissible_evidence correctly"
  fi
fi

# ── N3: Overbroad claims in index ─────────────────────────────────────────────
run_test "N3" "Verifier rejects index claiming Phase-2 closeout"

# Restore valid evidence
echo '{"status":"PASS","observed_hashes":{},"execution_trace":[]}' > "$FIXTURE_DIR/evidence/phase2/rls_bypass_dependency_inventory.json"

# Make index overclaim
echo "This triggers Phase-2 closeout" >> "$FIXTURE_DIR/docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_blocker_resolution.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject overbroad claims in index"
else
  if grep -q "Index explicitly claims closeout" "$FIXTURE_DIR/evidence/phase2/rls_bypass_blocker_resolution.json"; then
    pass
  else
    fail "Verifier rejected but did not report overbroad_claims correctly"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  TSK-P2-RLS-BYPASS-008 Negative Tests"
echo "  Total: $TOTAL  Pass: $PASS  Fail: $FAIL"
echo "════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
