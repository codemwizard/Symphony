#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


echo "==> GF-W1-FNC-007B CI Wiring for Confidence Gate Verification"

VIOLATIONS=0
VIOLATION_LIST=""

add_violation() {
  VIOLATIONS=$((VIOLATIONS + 1))
  VIOLATION_LIST="${VIOLATION_LIST}\n   - $1"
}

# Check 1: verify_gf_fnc_007a.sh is wired into pre_ci.sh
echo ""
echo "=== Check 1: Confidence gate verifier wired into pre_ci.sh ==="

if grep -q "verify_gf_fnc_007a.sh" scripts/dev/pre_ci.sh; then
    echo "✅ PASS: verify_gf_fnc_007a.sh is wired into pre_ci.sh"
else
    echo "❌ FAIL: verify_gf_fnc_007a.sh is NOT wired into pre_ci.sh"
    add_violation "MISSING_CI_WIRING: verify_gf_fnc_007a.sh not in pre_ci.sh"
fi

# Check 2: verify_gf_fnc_007a.sh listed in GREEN_FINANCE_VERIFIERS array
echo ""
echo "=== Check 2: Verifier in GREEN_FINANCE_VERIFIERS array ==="

if grep -q "GREEN_FINANCE_VERIFIERS" scripts/dev/pre_ci.sh && grep -q "verify_gf_fnc_007a" scripts/dev/pre_ci.sh; then
    echo "✅ PASS: verify_gf_fnc_007a.sh in GREEN_FINANCE_VERIFIERS"
else
    echo "❌ FAIL: verify_gf_fnc_007a.sh not in GREEN_FINANCE_VERIFIERS"
    add_violation "MISSING_ARRAY_ENTRY: verify_gf_fnc_007a.sh not in GREEN_FINANCE_VERIFIERS array"
fi

# Check 3: verify_gf_fnc_007a.sh exists and is executable
echo ""
echo "=== Check 3: Verifier script exists and is executable ==="

if [[ -x "scripts/db/verify_gf_fnc_007a.sh" ]]; then
    echo "✅ PASS: scripts/db/verify_gf_fnc_007a.sh exists and is executable"
else
    echo "❌ FAIL: scripts/db/verify_gf_fnc_007a.sh missing or not executable"
    add_violation "MISSING_VERIFIER: scripts/db/verify_gf_fnc_007a.sh not found or not executable"
fi

# Check 4: Migration 0113 exists (dependency from FNC-007A)
echo ""
echo "=== Check 4: Migration 0113 exists (FNC-007A dependency) ==="

if [[ -f "schema/migrations/0113_gf_fn_confidence_enforcement.sql" ]]; then
    echo "✅ PASS: Migration 0113_gf_fn_confidence_enforcement.sql exists"
else
    echo "❌ FAIL: Migration 0113_gf_fn_confidence_enforcement.sql missing"
    add_violation "MISSING_MIGRATION: 0113_gf_fn_confidence_enforcement.sql not found"
fi

# Check 5: GF_MIGRATIONS glob covers 01xx range
echo ""
echo "=== Check 5: GF_MIGRATIONS glob covers new migration range ==="

if grep -q "01\[0-9\]\[0-9\]_gf_" scripts/dev/pre_ci.sh; then
    echo "✅ PASS: GF_MIGRATIONS glob covers 01xx migrations"
else
    echo "❌ FAIL: GF_MIGRATIONS glob does not cover 01xx migrations"
    add_violation "MISSING_GLOB: GF_MIGRATIONS does not cover 01xx range"
fi

# Check 6: verify_gf_fnc_007a.sh actually passes
echo ""
echo "=== Check 6: Confidence gate verifier passes ==="

if bash scripts/db/verify_gf_fnc_007a.sh > /dev/null 2>&1; then
    echo "✅ PASS: verify_gf_fnc_007a.sh exits 0"
else
    echo "❌ FAIL: verify_gf_fnc_007a.sh exits non-zero"
    add_violation "VERIFIER_FAILURE: verify_gf_fnc_007a.sh exits non-zero"
fi

# Check 7: No sector-specific terms leaked into CI wiring
echo ""
echo "=== Check 7: Sector neutrality in CI wiring ==="

# Check only the lines we added (the verifier references)
if grep "verify_gf_fnc_007a" scripts/dev/pre_ci.sh | grep -q -i "solar\|plastic\|carbon\|forestry"; then
    echo "❌ FAIL: Sector-specific terms found in CI wiring"
    add_violation "SECTOR_LEAK: CI wiring contains sector-specific terms"
else
    echo "✅ PASS: No sector-specific terms in CI wiring"
fi

# Summary
echo ""
if [[ "$VIOLATIONS" -gt 0 ]]; then
    echo "❌ GF-W1-FNC-007B FAIL: $VIOLATIONS violation(s):$VIOLATION_LIST"
    exit 1
else
    echo "✅ All checks passed for GF-W1-FNC-007B"
    echo "CI Wiring: pre_ci.sh includes verify_gf_fnc_007a.sh"
    echo "Status: READY"
fi

exit 0
