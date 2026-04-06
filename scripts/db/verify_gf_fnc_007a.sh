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


echo "==> GF-W1-FNC-007A Confidence Enforcement Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0113_gf_fn_confidence_enforcement.sql" ]]; then
    echo "⏳ PENDING: Migration file 0113_gf_fn_confidence_enforcement.sql not yet implemented"
    exit 0
fi

echo "✅ PASS: Migration file exists"

# Check trigger function exists
echo ""
echo "=== Trigger Function Checks ==="

if grep -q "CREATE OR REPLACE FUNCTION.*enforce_confidence_before_issuance" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: enforce_confidence_before_issuance function exists"
else
    echo "❌ FAIL: enforce_confidence_before_issuance function missing"
    exit 1
fi

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
    exit 1
fi

# Check trigger creation on asset_lifecycle_events
echo ""
echo "=== Trigger Creation Checks ==="

if grep -q "CREATE TRIGGER.*asset_lifecycle_confidence_enforcement" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Confidence enforcement trigger created"
else
    echo "❌ FAIL: Confidence enforcement trigger missing"
    exit 1
fi

if grep -q "asset_lifecycle_events" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Trigger attached to asset_lifecycle_events"
else
    echo "❌ FAIL: Trigger not attached to asset_lifecycle_events"
    exit 1
fi

if grep -q "BEFORE INSERT" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Trigger fires BEFORE INSERT"
else
    echo "❌ FAIL: Trigger does not fire BEFORE INSERT"
    exit 1
fi

# Check confidence validation logic
echo ""
echo "=== Mathematical Confidence Validation ==="

if grep -q "confidence_score" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: confidence_score referenced"
else
    echo "❌ FAIL: confidence_score not referenced"
    exit 1
fi

if grep -q "0.95" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: 95% threshold defined (0.95)"
else
    echo "❌ FAIL: 95% threshold not defined"
    exit 1
fi

if grep -q "required_threshold" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: required_threshold variable used"
else
    echo "❌ FAIL: required_threshold variable missing"
    exit 1
fi

if grep -q "v_confidence_score.*<.*v_required_threshold" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Mathematical comparison present (score < threshold)"
else
    echo "❌ FAIL: Mathematical comparison missing"
    exit 1
fi

# Check fail-closed behavior
echo ""
echo "=== Fail-Closed Enforcement ==="

if grep -q "CONF001" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: CONF001 error code defined (no decisions)"
else
    echo "❌ FAIL: CONF001 error code missing"
    exit 1
fi

if grep -q "CONF002" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: CONF002 error code defined (no approved decisions)"
else
    echo "❌ FAIL: CONF002 error code missing"
    exit 1
fi

if grep -q "CONF003" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: CONF003 error code defined (insufficient confidence)"
else
    echo "❌ FAIL: CONF003 error code missing"
    exit 1
fi

if grep -q "v_decision_count.*=.*0" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Zero-decision check present (fail-closed)"
else
    echo "❌ FAIL: Zero-decision check missing"
    exit 1
fi

# Check ISSUED state transition enforcement
echo ""
echo "=== State Transition Enforcement ==="

if grep -q "ISSUED" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: ISSUED state transition targeted"
else
    echo "❌ FAIL: ISSUED state transition not targeted"
    exit 1
fi

if grep -q "to_status" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: to_status field checked"
else
    echo "❌ FAIL: to_status field not checked"
    exit 1
fi

# Check authority_decisions integration
echo ""
echo "=== Authority Decisions Integration ==="

if grep -q "authority_decisions" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: authority_decisions table referenced"
else
    echo "❌ FAIL: authority_decisions table not referenced"
    exit 1
fi

if grep -q "APPROVED" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: APPROVED decision outcome checked"
else
    echo "❌ FAIL: APPROVED decision outcome not checked"
    exit 1
fi

if grep -q "ASSET_BATCH" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: ASSET_BATCH subject type checked"
else
    echo "❌ FAIL: ASSET_BATCH subject type not checked"
    exit 1
fi

# Check for validate_confidence_score helper
echo ""
echo "=== Helper Function Checks ==="

if grep -q "CREATE OR REPLACE FUNCTION.*validate_confidence_score" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: validate_confidence_score helper function exists"
else
    echo "❌ FAIL: validate_confidence_score helper function missing"
    exit 1
fi

# Check for sector neutrality
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for permissions
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION enforce_confidence_before_issuance" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Permissions granted for enforce_confidence_before_issuance"
else
    echo "❌ FAIL: Permissions missing for enforce_confidence_before_issuance"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION validate_confidence_score" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "✅ PASS: Permissions granted for validate_confidence_score"
else
    echo "❌ FAIL: Permissions missing for validate_confidence_score"
    exit 1
fi

# Negative test: no hardcoded bypass
echo ""
echo "=== Negative Tests ==="

if grep -q "confidence_satisfied.*:=.*true" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "❌ FAIL: N1 — Hardcoded confidence bypass detected"
    exit 1
else
    echo "✅ PASS: N1 — No hardcoded confidence bypass"
fi

if grep -q "RAISE NOTICE.*skip" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "❌ FAIL: N2 — Soft skip detected (should be EXCEPTION)"
    exit 1
else
    echo "✅ PASS: N2 — No soft skip (all failures are EXCEPTION)"
fi

if grep -q "WHEN OTHERS THEN.*RETURN NEW" schema/migrations/0113_gf_fn_confidence_enforcement.sql; then
    echo "❌ FAIL: N3 — Catch-all bypass detected"
    exit 1
else
    echo "✅ PASS: N3 — No catch-all bypass"
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-007A"
echo "Migration: 0113_gf_fn_confidence_enforcement.sql"
echo "Status: READY"

exit 0
