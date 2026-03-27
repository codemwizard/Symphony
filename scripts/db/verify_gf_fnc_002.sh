#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-002 Monitoring Record Ingestion Function Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0089_gf_fn_monitoring_ingestion.sql" ]]; then
    echo "❌ FAIL: Migration file 0089_gf_fn_monitoring_ingestion.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "record_monitoring_record"
    "query_monitoring_records"
    "get_monitoring_record_payload"
    "validate_payload_against_schema"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
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
)

for code in "${SQLSTATES[@]}"; do
    if grep -q "$code" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
        echo "✅ PASS: SQLSTATE $code defined"
    else
        echo "❌ FAIL: SQLSTATE $code missing"
        exit 1
    fi
done

# Check for project validation
echo ""
echo "=== Project Validation Checks ==="

if grep -q "asset_batches" schema/migrations/0089_gf_fn_monitoring_ingestion.sql && grep -q "project_id" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Project existence validation present"
else
    echo "❌ FAIL: Project existence validation missing"
    exit 1
fi

if grep -q "status.*ACTIVE" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Project active status validation present"
else
    echo "❌ FAIL: Project active status validation missing"
    exit 1
fi

# Check for methodology validation
if grep -q "methodology_version_id" schema/migrations/0089_gf_fn_monitoring_ingestion.sql && grep -q "matches" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Methodology version validation present"
else
    echo "❌ FAIL: Methodology version validation missing"
    exit 1
fi

# Check for payload validation (neutral - no field extraction)
echo ""
echo "=== Payload Validation Checks ==="

if grep -q "jsonb_typeof.*record_payload_json.*object" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Payload JSON type validation present"
else
    echo "❌ FAIL: Payload JSON type validation missing"
    exit 1
fi

if grep -q "payload_schema_reference_id" schema/migrations/0089_gf_fn_monitoring_ingestion.sql && grep -q "NULL" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Payload schema reference validation present"
else
    echo "❌ FAIL: Payload schema reference validation missing"
    exit 1
fi

# CRITICAL: Check for NO payload field extraction (Rule 10 compliance)
echo ""
echo "=== Payload Field Extraction Check (Rule 10) ==="

# Look for any ->> operator which indicates field extraction
if grep -q "->>" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "❌ FAIL: Payload field extraction detected (->> operator found) - Rule 10 violation"
    exit 1
else
    echo "✅ PASS: No payload field extraction detected"
fi

# Look for any -> operator which also indicates field access
if grep -q "record_payload_json->" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "❌ FAIL: Payload field access detected (-> operator found) - Rule 10 violation"
    exit 1
else
    echo "✅ PASS: No payload field access detected"
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for proper input validation
echo ""
echo "=== Input Validation Checks ==="

NULL_CHECKS=(
    "p_tenant_id IS NULL"
    "p_project_id IS NULL"
    "p_methodology_version_id IS NULL"
    "p_record_type IS NULL"
    "p_event_timestamp IS NULL"
    "p_record_payload_json IS NULL"
    "p_payload_schema_reference_id IS NULL"
)

for check in "${NULL_CHECKS[@]}"; do
    if grep -q "$check" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
        echo "✅ PASS: Input validation for $check present"
    else
        echo "❌ FAIL: Input validation for $check missing"
        exit 1
    fi
done

# Check for tenant validation
if grep -q "tenant_id" schema/migrations/0089_gf_fn_monitoring_ingestion.sql && grep -q "p_tenant_id" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Tenant validation present"
else
    echo "❌ FAIL: Tenant validation missing"
    exit 1
fi

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION record_monitoring_record" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Permissions granted for record_monitoring_record"
else
    echo "❌ FAIL: Permissions missing for record_monitoring_record"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION query_monitoring_records" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Permissions granted for query_monitoring_records"
else
    echo "❌ FAIL: Permissions missing for query_monitoring_records"
    exit 1
fi

# Check for schema registry validation
if grep -q "schema_registry" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Schema registry validation present"
else
    echo "❌ FAIL: Schema registry validation missing"
    exit 1
fi

# Check for monitoring_records table integration
if grep -q "INSERT INTO monitoring_records" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Monitoring records table integration present"
else
    echo "❌ FAIL: Monitoring records table integration missing"
    exit 1
fi

# Ensure function does not interpret payload semantics
echo ""
echo "=== Payload Semantics Check ==="

# The function should only validate payload structure, never interpret content
if grep -q "jsonb_typeof" schema/migrations/0089_gf_fn_monitoring_ingestion.sql && \
   ! grep -q "record_payload_json->>" schema/migrations/0089_gf_fn_monitoring_ingestion.sql; then
    echo "✅ PASS: Function validates payload structure without interpreting semantics"
else
    echo "❌ FAIL: Function may be interpreting payload semantics"
    exit 1
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-002"
echo "Migration: 0089_gf_fn_monitoring_ingestion.sql"
echo "Status: READY"

exit 0
