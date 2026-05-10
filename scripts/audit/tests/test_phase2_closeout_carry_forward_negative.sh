#!/usr/bin/env bash
# test_phase2_closeout_carry_forward_negative.sh
# TSK-P2-RLS-BYPASS-009 — Negative tests for verify_phase2_closeout_carry_forward_obligations.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERIFIER="$ROOT_DIR/scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh"
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
mkdir -p "$FIXTURE_DIR/scripts/audit" "$FIXTURE_DIR/scripts/lib" "$FIXTURE_DIR/.venv/bin" "$FIXTURE_DIR/evidence/phase2" "$FIXTURE_DIR/docs/governance" "$FIXTURE_DIR/docs/PHASE2" "$FIXTURE_DIR/docs/operations"

if [[ -f "$VERIFIER" ]]; then
  cp "$VERIFIER" "$FIXTURE_DIR/scripts/audit/"
fi
if [[ -f "$ROOT_DIR/scripts/lib/evidence.sh" ]]; then
  cp "$ROOT_DIR/scripts/lib/evidence.sh" "$FIXTURE_DIR/scripts/lib/"
fi
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  ln -sf "$(readlink -f "$ROOT_DIR/.venv/bin/python3")" "$FIXTURE_DIR/.venv/bin/python3" 2>/dev/null || true
fi

# ── N1: Missing Obligation ───────────────────────────────────────────────────
run_test "N1" "Verifier rejects record missing an obligation"

cat > "$FIXTURE_DIR/docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md" <<EOF
# Phase-2 Closeout: Carry-Forward Obligations
Methodology Adapter Extraction
Dwell-Time Forensic Enforcement
EOF

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject record missing Sovereign Authorization Schema"
else
  if grep -q "Missing required obligation.*Sovereign Authorization Schema" "$FIXTURE_DIR/evidence/phase2/phase2_closeout_carry_forward_obligations.json"; then
    pass
  else
    fail "Verifier rejected but did not report missing obligation correctly"
  fi
fi

# ── N2: Prohibited Future-Phase Artifacts ────────────────────────────────────
run_test "N2" "Verifier rejects presence of future-phase artifacts/namespaces"

# Restore full record
cat > "$FIXTURE_DIR/docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md" <<EOF
# Phase-2 Closeout: Carry-Forward Obligations
Methodology Adapter Extraction
Dwell-Time Forensic Enforcement
Sovereign Authorization Schema
EOF

# Create prohibited namespace
mkdir -p "$FIXTURE_DIR/docs/PHASE3"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject prohibited namespace docs/PHASE3"
else
  if grep -q "docs/PHASE3" "$FIXTURE_DIR/evidence/phase2/phase2_closeout_carry_forward_obligations.json"; then
    pass
  else
    fail "Verifier rejected but did not report docs/PHASE3 correctly"
  fi
fi
rm -rf "$FIXTURE_DIR/docs/PHASE3"

# ── N3: Dwell-Time Claimed as Implemented ────────────────────────────────────
run_test "N3" "Verifier rejects record if current Phase-2 artifact claims dwell-time is implemented"

# Create a conflict in docs/PHASE2/PHASE2_CONTRACT.md
echo "Dwell-time forensic enforcement is now fully implemented." > "$FIXTURE_DIR/docs/PHASE2/PHASE2_CONTRACT.md"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject conflict where dwell-time is claimed as implemented"
else
  if grep -q "Conflict in docs/PHASE2/PHASE2_CONTRACT.md.*implemented" "$FIXTURE_DIR/evidence/phase2/phase2_closeout_carry_forward_obligations.json"; then
    pass
  else
    fail "Verifier rejected but did not report claim conflict correctly"
  fi
fi
rm -f "$FIXTURE_DIR/docs/PHASE2/PHASE2_CONTRACT.md"

# ── N4: Prohibited Readiness/Opening Language ────────────────────────────────
run_test "N4" "Verifier rejects record using prohibited readiness language"

echo "This record signifies that Wave 9 ready and we are proceeding to Phase-3 opening." >> "$FIXTURE_DIR/docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject prohibited readiness language"
else
  if grep -q "Prohibited readiness language found" "$FIXTURE_DIR/evidence/phase2/phase2_closeout_carry_forward_obligations.json"; then
    pass
  else
    fail "Verifier rejected but did not report prohibited language correctly"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  TSK-P2-RLS-BYPASS-009 Negative Tests"
echo "  Total: $TOTAL  Pass: $PASS  Fail: $FAIL"
echo "════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
