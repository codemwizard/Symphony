#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-003 Evidence Lineage Functions Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0090_gf_fn_evidence_lineage.sql" ]]; then
    echo "❌ FAIL: Migration file 0090_gf_fn_evidence_lineage.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "attach_evidence"
    "link_evidence_to_record"
    "query_evidence_lineage"
    "get_evidence_node"
    "list_project_evidence"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
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
    "GF015"
    "GF016"
    "GF017"
    "GF018"
    "GF019"
)

for code in "${SQLSTATES[@]}"; do
    if grep -q "$code" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: SQLSTATE $code defined"
    else
        echo "❌ FAIL: SQLSTATE $code missing"
        exit 1
    fi
done

# Check for evidence class validation (universal taxonomy)
echo ""
echo "=== Evidence Class Validation Checks ==="

EVIDENCE_CLASSES=(
    "RAW_SOURCE"
    "ATTESTED_SOURCE"
    "NORMALIZED_RECORD"
    "ANALYST_FINDING"
    "VERIFIER_FINDING"
    "REGULATORY_EXPORT"
    "ISSUANCE_ARTIFACT"
)

for class in "${EVIDENCE_CLASSES[@]}"; do
    if grep -q "$class" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: Evidence class $class in taxonomy"
    else
        echo "❌ FAIL: Evidence class $class missing from taxonomy"
        exit 1
    fi
done

# Check for edge type validation
echo ""
echo "=== Edge Type Validation Checks ==="

EDGE_TYPES=(
    "SUPPORTS"
    "REFUTES"
    "DOCUMENTS"
    "VALIDATES"
    "ATTESTS_TO"
    "DERIVED_FROM"
    "CORROBORATES"
)

for edge in "${EDGE_TYPES[@]}"; do
    if grep -q "$edge" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: Edge type $edge in validation"
    else
        echo "❌ FAIL: Edge type $edge missing from validation"
        exit 1
    fi
done

# Check for tenant isolation
echo ""
echo "=== Tenant Isolation Checks ==="

if grep -q "tenant_id.*!=.*p_tenant_id" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Cross-tenant linkage prevention present"
else
    echo "❌ FAIL: Cross-tenant linkage prevention missing"
    exit 1
fi

# Check for self-loop prevention
if grep -q "Self-loop not allowed" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Self-loop prevention present"
else
    echo "❌ FAIL: Self-loop prevention missing"
    exit 1
fi

# Check for target record type validation
echo ""
echo "=== Target Record Type Validation Checks ==="

TARGET_TYPES=(
    "PROJECT"
    "MONITORING_RECORD"
    "ASSET_BATCH"
    "EVIDENCE_NODE"
)

for type in "${TARGET_TYPES[@]}"; do
    if grep -q "$type" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: Target record type $type supported"
    else
        echo "❌ FAIL: Target record type $type not supported"
        exit 1
    fi
done

# Check for evidence_nodes table integration
echo ""
echo "=== Table Integration Checks ==="

if grep -q "INSERT INTO evidence_nodes" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: evidence_nodes table integration present"
else
    echo "❌ FAIL: evidence_nodes table integration missing"
    exit 1
fi

if grep -q "INSERT INTO evidence_edges" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: evidence_edges table integration present"
else
    echo "❌ FAIL: evidence_edges table integration missing"
    exit 1
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
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
    "p_evidence_node_id IS NULL"
    "p_evidence_class IS NULL"
    "p_document_type IS NULL"
    "p_target_record_type IS NULL"
    "p_target_record_id IS NULL"
    "p_edge_type IS NULL"
)

for check in "${NULL_CHECKS[@]}"; do
    if grep -q "$check" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
        echo "✅ PASS: Input validation for $check present"
    else
        echo "❌ FAIL: Input validation for $check missing"
        exit 1
    fi
done

# Check for project validation
if grep -q "asset_batches" schema/migrations/0090_gf_fn_evidence_lineage.sql && grep -q "project_id" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Project validation present"
else
    echo "❌ FAIL: Project validation missing"
    exit 1
fi

# Check for monitoring record validation
if grep -q "monitoring_records" schema/migrations/0090_gf_fn_evidence_lineage.sql && grep -q "monitoring_record_id" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Monitoring record validation present"
else
    echo "❌ FAIL: Monitoring record validation missing"
    exit 1
fi

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION attach_evidence" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Permissions granted for attach_evidence"
else
    echo "❌ FAIL: Permissions missing for attach_evidence"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION link_evidence_to_record" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Permissions granted for link_evidence_to_record"
else
    echo "❌ FAIL: Permissions missing for link_evidence_to_record"
    exit 1
fi

# Check for append-only behavior (functions should only INSERT)
echo ""
echo "=== Append-Only Behavior Check ==="

# Functions should only do INSERT operations, no UPDATE/DELETE on evidence tables
if grep -q "UPDATE.*evidence" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "❌ FAIL: UPDATE operations on evidence tables detected"
    exit 1
else
    echo "✅ PASS: No UPDATE operations on evidence tables"
fi

if grep -q "DELETE.*evidence" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "❌ FAIL: DELETE operations on evidence tables detected"
    exit 1
else
    echo "✅ PASS: No DELETE operations on evidence tables"
fi

# Check for evidence class rejection (negative test scenario)
if grep -q "Invalid evidence class" schema/migrations/0090_gf_fn_evidence_lineage.sql; then
    echo "✅ PASS: Evidence class rejection logic present"
else
    echo "❌ FAIL: Evidence class rejection logic missing"
    exit 1
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-003"
echo "Migration: 0090_gf_fn_evidence_lineage.sql"
echo "Status: READY"

exit 0
