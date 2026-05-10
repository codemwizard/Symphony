#!/usr/bin/env bash
# test_rls_bypass_runtime_negative.sh
# TSK-P2-RLS-BYPASS-007 — Negative tests for verify_rls_bypass_runtime_isolation.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERIFIER="$ROOT_DIR/scripts/audit/verify_rls_bypass_runtime_isolation.sh"
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
mkdir -p "$FIXTURE_DIR/scripts/audit" "$FIXTURE_DIR/scripts/lib" "$FIXTURE_DIR/.venv/bin" "$FIXTURE_DIR/evidence/phase2"
if [[ -f "$VERIFIER" ]]; then
  cp "$VERIFIER" "$FIXTURE_DIR/scripts/audit/"
fi
if [[ -f "$ROOT_DIR/scripts/lib/evidence.sh" ]]; then
  cp "$ROOT_DIR/scripts/lib/evidence.sh" "$FIXTURE_DIR/scripts/lib/"
fi
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  ln -sf "$(readlink -f "$ROOT_DIR/.venv/bin/python3")" "$FIXTURE_DIR/.venv/bin/python3" 2>/dev/null || true
fi

export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"

# ── N1: Verifier detects bypass_rls usage ───────────────────────────────────
run_test "N1" "Verifier rejects itself if it uses app.bypass_rls"

cat > "$FIXTURE_DIR/scripts/audit/verify_n1.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# CRITICAL: This file sets app.bypass_rls
# set_config('app.bypass_rls', 'on', true)
exit 1
EOF
chmod +x "$FIXTURE_DIR/scripts/audit/verify_n1.sh"

# Actually, the verifier script fails immediately if `set_config('app.bypass_rls'` is in the code.
# Let's test the self-check mechanism.
cp "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_runtime_isolation.sh" "$FIXTURE_DIR/scripts/audit/verify_n1_real.sh"
sed -i "s/SELF_BYPASS_COUNT=\${SELF_BYPASS_COUNT:-0}/SELF_BYPASS_COUNT=1/" "$FIXTURE_DIR/scripts/audit/verify_n1_real.sh"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_n1_real.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject itself when bypass_rls self-check failed"
else
  pass
fi

# ── N3: Verifier detects session_replication_role usage ───────────────────────
run_test "N3" "Verifier rejects itself if it uses session_replication_role"

cp "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_runtime_isolation.sh" "$FIXTURE_DIR/scripts/audit/verify_n3.sh"
sed -i "s/SELF_REPL_SET_COUNT=\${SELF_REPL_SET_COUNT:-0}/SELF_REPL_SET_COUNT=1/" "$FIXTURE_DIR/scripts/audit/verify_n3.sh"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_n3.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject itself when session_replication_role self-check failed"
else
  pass
fi

# ── N2: Verifier detects cross-tenant success ─────────────────────────────────
run_test "N2" "Verifier rejects cross-tenant access that succeeds"

cp "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_runtime_isolation.sh" "$FIXTURE_DIR/scripts/audit/verify_n2.sh"
# Modify the script to simulate a cross-tenant read returning rows (simulating success of cross-tenant access)
sed -i "s/negative_count=\$(echo \"\$negative_result\" | tail -1)/negative_count=5/" "$FIXTURE_DIR/scripts/audit/verify_n2.sh"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_n2.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject itself when cross-tenant access succeeded"
else
  pass
fi

# ── N4: Verifier detects app.bypass_rls in active policies ────────────────────
run_test "N4" "Verifier rejects database with app.bypass_rls in active policies"

cp "$FIXTURE_DIR/scripts/audit/verify_rls_bypass_runtime_isolation.sh" "$FIXTURE_DIR/scripts/audit/verify_n4.sh"
# Simulate finding policies with bypass_rls
sed -i "s/bypass_policies=\${bypass_policies:-0}/bypass_policies=2/" "$FIXTURE_DIR/scripts/audit/verify_n4.sh"

if (
  export ROOT_DIR="$FIXTURE_DIR"
  bash "$FIXTURE_DIR/scripts/audit/verify_n4.sh" >/dev/null 2>&1
); then
  fail "Verifier did not reject database with contaminated policies"
else
  pass
fi

echo ""
echo "════════════════════════════════════════"
echo "  TSK-P2-RLS-BYPASS-007 Negative Tests"
echo "  Total: $TOTAL  Pass: $PASS  Fail: $FAIL"
echo "════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
