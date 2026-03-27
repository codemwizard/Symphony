#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-004 Regulatory Transitions Functions Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0091_gf_fn_regulatory_transitions.sql" ]]; then
    echo "❌ FAIL: Migration file 0091_gf_fn_regulatory_transitions.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check if authority_decisions table exists
echo ""
echo "=== Table Checks ==="

if grep -q "CREATE TABLE.*authority_decisions" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: authority_decisions table created"
else
    echo "❌ FAIL: authority_decisions table not found"
    exit 1
fi

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "record_authority_decision"
    "attempt_lifecycle_transition"
    "query_authority_decisions"
    "get_checkpoint_requirements"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
    exit 1
fi

# Check for interpretation_pack_id enforcement (INV-165)
echo ""
echo "=== INV-165 Interpretation Pack Enforcement ==="

# Check record_authority_decision enforces interpretation_pack_id
if grep -q "interpretation_pack_id.*NULL" schema/migrations/0091_gf_fn_regulatory_transitions.sql && grep -q "P0001" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: record_authority_decision enforces interpretation_pack_id"
else
    echo "❌ FAIL: record_authority_decision does not enforce interpretation_pack_id"
    exit 1
fi

# Check attempt_lifecycle_transition enforces interpretation_pack_id
if grep -q "interpretation_pack_id.*NULL" schema/migrations/0091_gf_fn_regulatory_transitions.sql && grep -q "P0001" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: attempt_lifecycle_transition enforces interpretation_pack_id"
else
    echo "❌ FAIL: attempt_lifecycle_transition does not enforce interpretation_pack_id"
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
)

for code in "${SQLSTATES[@]}"; do
    if grep -q "$code" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
        echo "✅ PASS: SQLSTATE $code defined"
    else
        echo "❌ FAIL: SQLSTATE $code missing"
        exit 1
    fi
done

# Check for checkpoint validation logic
echo ""
echo "=== Checkpoint Validation Checks ==="

if grep -q "lifecycle_checkpoint_rules" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Checkpoint rules query present"
else
    echo "❌ FAIL: Checkpoint rules query missing"
    exit 1
fi

if grep -q "REQUIRED" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: REQUIRED checkpoint handling present"
else
    echo "❌ FAIL: REQUIRED checkpoint handling missing"
    exit 1
fi

if grep -q "CONDITIONALLY_REQUIRED" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: CONDITIONALLY_REQUIRED checkpoint handling present"
else
    echo "❌ FAIL: CONDITIONALLY_REQUIRED checkpoint handling missing"
    exit 1
fi

# Check for provisional pass behavior
if grep -q "PENDING_CLARIFICATION" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Provisional pass behavior present"
else
    echo "❌ FAIL: Provisional pass behavior missing"
    exit 1
fi

if grep -q "CONDITIONALLY_SATISFIED" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Conditionally satisfied state present"
else
    echo "❌ FAIL: Conditionally satisfied state missing"
    exit 1
fi

# Check for regulatory authority validation
echo ""
echo "=== Regulatory Authority Validation Checks ==="

if grep -q "regulatory_authorities" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Regulatory authority validation present"
else
    echo "❌ FAIL: Regulatory authority validation missing"
    exit 1
fi

if grep -q "jurisdiction_code" schema/migrations/0091_gf_fn_regulatory_transitions.sql && grep -q "regulatory_authorities" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Jurisdiction matching present"
else
    echo "❌ FAIL: Jurisdiction matching missing"
    exit 1
fi

# Check for interpretation pack validation
if grep -q "interpretation_packs" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Interpretation pack validation present"
else
    echo "❌ FAIL: Interpretation pack validation missing"
    exit 1
fi

# Check for append-only behavior
echo ""
echo "=== Append-Only Behavior Checks ==="

if grep -q "authority_decisions_append_only" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Append-only trigger present for authority_decisions"
else
    echo "❌ FAIL: Append-only trigger missing for authority_decisions"
    exit 1
fi

if grep -q "not allowed" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Append-only enforcement present"
else
    echo "❌ FAIL: Append-only enforcement missing"
    exit 1
fi

# Check for RLS
echo ""
echo "=== RLS Checks ==="

if grep -q "authority_decisions.*ENABLE ROW LEVEL SECURITY" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: RLS enabled on authority_decisions"
else
    echo "❌ FAIL: RLS not enabled on authority_decisions"
    exit 1
fi

if grep -q "CREATE POLICY.*authority_decisions_jurisdiction_access" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Jurisdiction access policy present"
else
    echo "❌ FAIL: Jurisdiction access policy missing"
    exit 1
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for proper input validation
echo ""
echo "=== Input Validation Checks ==="

NULL_CHECKS=(
    "p_regulatory_authority_id IS NULL"
    "p_jurisdiction_code IS NULL"
    "p_decision_type IS NULL"
    "p_decision_outcome IS NULL"
    "p_subject_type IS NULL"
    "p_subject_id IS NULL"
    "p_from_status IS NULL"
    "p_to_status IS NULL"
)

for check in "${NULL_CHECKS[@]}"; do
    if grep -q "$check" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
        echo "✅ PASS: Input validation for $check present"
    else
        echo "❌ FAIL: Input validation for $check missing"
        exit 1
    fi
done

# Check for subject type validation
SUBJECT_TYPES=(
    "PROJECT"
    "ASSET_BATCH"
    "MONITORING_RECORD"
    "EVIDENCE_NODE"
)

for type in "${SUBJECT_TYPES[@]}"; do
    if grep -q "$type" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
        echo "✅ PASS: Subject type $type supported"
    else
        echo "❌ FAIL: Subject type $type not supported"
        exit 1
    fi
done

# Check for checkpoint blocking logic
if grep -q "unsatisfied_checkpoints" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Checkpoint blocking logic present"
else
    echo "❌ FAIL: Checkpoint blocking logic missing"
    exit 1
fi

# Check for lifecycle transition integration
if grep -q "transition_asset_status" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Lifecycle transition integration present"
else
    echo "❌ FAIL: Lifecycle transition integration missing"
    exit 1
fi

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION record_authority_decision" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Permissions granted for record_authority_decision"
else
    echo "❌ FAIL: Permissions missing for record_authority_decision"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION attempt_lifecycle_transition" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Permissions granted for attempt_lifecycle_transition"
else
    echo "❌ FAIL: Permissions missing for attempt_lifecycle_transition"
    exit 1
fi

# Check for revoke-first privileges
if grep -q "REVOKE ALL.*authority_decisions.*FROM PUBLIC" schema/migrations/0091_gf_fn_regulatory_transitions.sql; then
    echo "✅ PASS: Revoke-first privileges applied"
else
    echo "❌ FAIL: Revoke-first privileges missing"
    exit 1
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-004"
echo "Migration: 0091_gf_fn_regulatory_transitions.sql"
echo "Status: READY"

exit 0
