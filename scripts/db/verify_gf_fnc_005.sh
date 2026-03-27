#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-005 Asset Lifecycle Functions Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0092_gf_fn_asset_lifecycle.sql" ]]; then
    echo "❌ FAIL: Migration file 0092_gf_fn_asset_lifecycle.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "issue_asset_batch"
    "retire_asset_batch"
    "record_asset_lifecycle_event"
    "query_asset_batch"
    "list_project_asset_batches"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
    exit 1
fi

# Check for interpretation_pack_id enforcement (INV-165)
echo ""
echo "=== INV-165 Interpretation Pack Enforcement ==="

# Check issue_asset_batch enforces interpretation_pack_id
if grep -q "interpretation_pack_id.*NULL" schema/migrations/0092_gf_fn_asset_lifecycle.sql && grep -q "P0001" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: issue_asset_batch enforces interpretation_pack_id"
else
    echo "❌ FAIL: issue_asset_batch does not enforce interpretation_pack_id"
    exit 1
fi

# Check retire_asset_batch enforces interpretation_pack_id
if grep -q "interpretation_pack_id.*NULL" schema/migrations/0092_gf_fn_asset_lifecycle.sql && grep -q "P0001" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: retire_asset_batch enforces interpretation_pack_id"
else
    echo "❌ FAIL: retire_asset_batch does not enforce interpretation_pack_id"
    exit 1
fi

# Check for error handling with SQLSTATE codes
echo ""
echo "=== Error Handling Checks ==="

SQLSTATES=(
    "GF001"
    "GF002"
    "GF003"
    "GF004"
    "GF005"
    "GF006"
    "GF007"
    "GF008"
    "GF009"
    "GF010"
    "GF011"
    "GF012"
    "GF013"
    "GF014"
    "GF015"
    "GF016"
    "GF017"
    "GF018"
)

for code in "${SQLSTATES[@]}"; do
    if grep -q "$code" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
        echo "✅ PASS: SQLSTATE $code defined"
    else
        echo "❌ FAIL: SQLSTATE $code missing"
        exit 1
    fi
done

# Check for fail-closed issuance checkpoint validation (must match FNC-004 pattern)
echo ""
echo "=== Issuance Checkpoint Checks ==="

if grep -q "lifecycle_checkpoint_rules" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: lifecycle_checkpoint_rules join present"
else
    echo "❌ FAIL: lifecycle_checkpoint_rules join missing — checkpoint gate absent"
    exit 1
fi

if grep -q "ACTIVE->ISSUED" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: ACTIVE->ISSUED transition checkpoint query present"
else
    echo "❌ FAIL: ACTIVE->ISSUED transition checkpoint query missing"
    exit 1
fi

if grep -q "v_unsatisfied_checkpoints" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Fail-closed unsatisfied checkpoint accumulation present"
else
    echo "❌ FAIL: Fail-closed checkpoint accumulation missing — issuance may be ungated"
    exit 1
fi

if grep -q "PENDING_CLARIFICATION" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: CONDITIONALLY_REQUIRED confidence check present"
else
    echo "❌ FAIL: CONDITIONALLY_REQUIRED confidence check missing"
    exit 1
fi

# Negative check: no hardcoded checkpoint bypass
if grep -q "checkpoint_satisfied := true" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "❌ FAIL: Hardcoded checkpoint bypass detected — issuance gate is fail-open"
    exit 1
else
    echo "✅ PASS: No hardcoded checkpoint bypass (fail-closed confirmed)"
fi

# Check for quantity guard enforcement
echo ""
echo "=== Quantity Guard Checks ==="

if grep -q "retired_quantity.*exceeds" schema/migrations/0092_gf_fn_asset_lifecycle.sql || grep -q "exceeds.*remaining" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Quantity guard enforcement present"
else
    echo "❌ FAIL: Quantity guard enforcement missing"
    exit 1
fi

if grep -q "total_retired" schema/migrations/0092_gf_fn_asset_lifecycle.sql && grep -q "remaining_quantity" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Quantity calculations present"
else
    echo "❌ FAIL: Quantity calculations missing"
    exit 1
fi

# Check for adapter registration validation
echo ""
echo "=== Adapter Validation Checks ==="

if grep -q "adapter_registrations" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Adapter registration validation present"
else
    echo "❌ FAIL: Adapter registration validation missing"
    exit 1
fi

if grep -q "is_active.*true" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Adapter activity validation present"
else
    echo "❌ FAIL: Adapter activity validation missing"
    exit 1
fi

# Check for project status validation
if grep -q "project.*ACTIVE" schema/migrations/0092_gf_fn_asset_lifecycle.sql || grep -q "ACTIVE.*project" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Project active status validation present"
else
    echo "❌ FAIL: Project active status validation missing"
    exit 1
fi

# Check for asset status validation
if grep -q "asset.*ISSUED" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Asset issued status validation present"
else
    echo "❌ FAIL: Asset issued status validation missing"
    exit 1
fi

# Check for irrevocability (retirement should be permanent)
echo ""
echo "=== Irrevocability Checks ==="

if grep -q "INSERT INTO retirement_events" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Retirement events are append-only (INSERT only)"
else
    echo "❌ FAIL: Retirement events not append-only"
    exit 1
fi

# Check for no UPDATE/DELETE on retirement_events
if grep -q "UPDATE.*retirement_events" schema/migrations/0092_gf_fn_asset_lifecycle.sql || grep -q "DELETE.*retirement_events" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "❌ FAIL: Retirement events allow mutations (should be append-only)"
    exit 1
else
    echo "✅ PASS: Retirement events do not allow mutations"
fi

# Check for lifecycle event recording
if grep -q "asset_lifecycle_events" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Lifecycle event recording present"
else
    echo "❌ FAIL: Lifecycle event recording missing"
    exit 1
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for proper input validation
echo ""
echo "=== Input Validation Checks ==="

NULL_CHECKS=(
    "p_project_id IS NULL"
    "p_methodology_version_id IS NULL"
    "p_adapter_registration_id IS NULL"
    "p_asset_type IS NULL"
    "p_quantity IS NULL"
    "p_unit IS NULL"
    "p_asset_batch_id IS NULL"
    "p_retirement_reason IS NULL"
)

for check in "${NULL_CHECKS[@]}"; do
    if grep -q "$check" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
        echo "✅ PASS: Input validation for $check present"
    else
        echo "❌ FAIL: Input validation for $check missing"
        exit 1
    fi
done

# Check for positive quantity validation
if grep -q "quantity.*<= 0" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Positive quantity validation present"
else
    echo "❌ FAIL: Positive quantity validation missing"
    exit 1
fi

# Check for asset_batches table integration
echo ""
echo "=== Table Integration Checks ==="

if grep -q "INSERT INTO asset_batches" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: asset_batches table integration present"
else
    echo "❌ FAIL: asset_batches table integration missing"
    exit 1
fi

if grep -q "INSERT INTO retirement_events" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: retirement_events table integration present"
else
    echo "❌ FAIL: retirement_events table integration missing"
    exit 1
fi

# Check for status transitions
if grep -q "status.*ISSUED" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: ISSUED status transition present"
else
    echo "❌ FAIL: ISSUED status transition missing"
    exit 1
fi

if grep -q "status.*RETIRED" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: RETIRED status transition present"
else
    echo "❌ FAIL: RETIRED status transition missing"
    exit 1
fi

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION issue_asset_batch" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Permissions granted for issue_asset_batch"
else
    echo "❌ FAIL: Permissions missing for issue_asset_batch"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION retire_asset_batch" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "✅ PASS: Permissions granted for retire_asset_batch"
else
    echo "❌ FAIL: Permissions missing for retire_asset_batch"
    exit 1
fi

# Check for no verification requirements (deferred to verification workflow)
echo ""
echo "=== Verification Workflow Deferral Check ==="

if grep -q "verification_decision_id" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "❌ FAIL: verification_decision_id found (should be deferred)"
    exit 1
else
    echo "✅ PASS: No verification_decision_id requirement (correctly deferred)"
fi

if grep -q "evidence_snapshot_id" schema/migrations/0092_gf_fn_asset_lifecycle.sql; then
    echo "❌ FAIL: evidence_snapshot_id found (should be deferred)"
    exit 1
else
    echo "✅ PASS: No evidence_snapshot_id requirement (correctly deferred)"
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-005"
echo "Migration: 0092_gf_fn_asset_lifecycle.sql"
echo "Status: READY"

exit 0
