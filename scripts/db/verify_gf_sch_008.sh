#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-SCH-008 Verifier Registry Schema Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0087_gf_verifier_registry.sql" ]]; then
    echo "❌ FAIL: Migration file 0087_gf_verifier_registry.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check if meta file exists
if [[ ! -f "schema/migrations/0087_gf_verifier_registry.meta.yml" ]]; then
    echo "❌ FAIL: Meta file 0087_gf_verifier_registry.meta.yml not found"
    exit 1
fi

echo "✅ PASS: Meta file exists"

# Check both tables exist
echo ""
echo "=== Table Checks ==="

TABLES=(
    "verifier_registry"
    "verifier_project_assignments"
)

for table in "${TABLES[@]}"; do
    if grep -q "CREATE TABLE.*$table" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Table $table created"
    else
        echo "❌ FAIL: Table $table not found"
        exit 1
    fi
done

# Check verifier_registry fields
echo ""
echo "=== Verifier Registry Fields ==="

REGISTRY_FIELDS=(
    "verifier_id"
    "tenant_id"
    "jurisdiction_code"
    "verifier_name"
    "role_type"
    "accreditation_reference"
    "accreditation_authority"
    "accreditation_expiry"
    "methodology_scope"
    "jurisdiction_scope"
    "is_active"
    "deactivated_at"
    "deactivation_reason"
    "created_at"
    "created_by"
)

for field in "${REGISTRY_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Field verifier_registry.$field exists"
    else
        echo "❌ FAIL: Field verifier_registry.$field missing"
        exit 1
    fi
done

# Check verifier_project_assignments fields
echo ""
echo "=== Verifier Project Assignments Fields ==="

ASSIGNMENT_FIELDS=(
    "assignment_id"
    "verifier_id"
    "project_id"
    "assigned_role"
    "assigned_at"
    "assigned_by"
)

for field in "${ASSIGNMENT_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Field verifier_project_assignments.$field exists"
    else
        echo "❌ FAIL: Field verifier_project_assignments.$field missing"
        exit 1
    fi
done

# CHECK constraints
echo ""
echo "=== CHECK Constraints ==="

# Role type constraint
ROLE_TYPES=("VALIDATOR" "VERIFIER" "VALIDATOR_VERIFIER")
for role in "${ROLE_TYPES[@]}"; do
    if grep -q "$role" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Role type $role in constraint"
    else
        echo "❌ FAIL: Role type $role missing from constraint"
        exit 1
    fi
done

# Assigned role constraint
ASSIGNED_ROLES=("VALIDATOR" "VERIFIER")
for role in "${ASSIGNED_ROLES[@]}"; do
    if grep -q "$role" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Assigned role $role in constraint"
    else
        echo "❌ FAIL: Assigned role $role missing from constraint"
        exit 1
    fi
done

# Check foreign keys
echo ""
echo "=== Foreign Keys ==="

FKS=(
    "tenant_id.*REFERENCES.*tenants"
    "verifier_id.*REFERENCES.*verifier_registry"
    "project_id.*REFERENCES.*projects"
)

for fk in "${FKS[@]}"; do
    if grep -q "$fk" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: FK $fk present"
    else
        echo "❌ FAIL: FK $fk missing"
        exit 1
    fi
done

# Check triggers
echo ""
echo "=== Trigger Checks ==="

TRIGGERS=(
    "verifier_registry_append_only"
    "verifier_project_assignments_append_only"
)

for trigger in "${TRIGGERS[@]}"; do
    if grep -q "CREATE TRIGGER.*$trigger" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Trigger $trigger present"
    else
        echo "❌ FAIL: Trigger $trigger missing"
        exit 1
    fi
done

# Check Regulation 26 function
echo ""
echo "=== Regulation 26 Function ==="

if grep -q "CREATE OR REPLACE FUNCTION.*check_reg26_separation" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "✅ PASS: check_reg26_separation function exists"
else
    echo "❌ FAIL: check_reg26_separation function missing"
    exit 1
fi

if grep -q "SECURITY DEFINER" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "✅ PASS: Function is SECURITY DEFINER"
else
    echo "❌ FAIL: Function not SECURITY DEFINER"
    exit 1
fi

if grep -q "GF001.*Regulation 26 violation" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "✅ PASS: Regulation 26 error message present"
else
    echo "❌ FAIL: Regulation 26 error message missing"
    exit 1
fi

# Check RLS
echo ""
echo "=== RLS Checks ==="

for table in "${TABLES[@]}"; do
    if grep -q "$table.*ENABLE ROW LEVEL SECURITY" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: RLS enabled on $table"
    else
        echo "❌ FAIL: RLS not enabled on $table"
        exit 1
    fi
done

if grep -q "CREATE POLICY.*verifier_registry_tenant_isolation" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "✅ PASS: Verifier registry tenant isolation policy exists"
else
    echo "❌ FAIL: Verifier registry tenant isolation policy missing"
    exit 1
fi

# Check functions
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "register_verifier"
    "assign_verifier_to_project"
    "query_active_verifiers"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check indexes (sample)
echo ""
echo "=== Index Checks ==="

INDEXES=(
    "idx_verifier_registry_tenant_id"
    "idx_verifier_registry_role_type"
    "idx_verifier_registry_active"
    "idx_verifier_project_assignments_verifier"
    "idx_verifier_project_assignments_project"
    "idx_verifier_project_assignments_reg26"
    "idx_verifier_registry_methodology_gin"
    "idx_verifier_registry_jurisdiction_gin"
    "idx_verifier_registry_cert_ref"
)

for index in "${INDEXES[@]}"; do
    if grep -q "$index" schema/migrations/0087_gf_verifier_registry.sql; then
        echo "✅ PASS: Index $index exists"
    else
        echo "❌ FAIL: Index $index missing"
        exit 1
    fi
done

# Check revoke-first privileges
if grep -q "REVOKE ALL.*verifier_registry.*FROM PUBLIC" schema/migrations/0087_gf_verifier_registry.sql && grep -q "REVOKE ALL.*verifier_project_assignments.*FROM PUBLIC" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "✅ PASS: Revoke-first privileges applied"
else
    echo "❌ FAIL: Revoke-first privileges missing"
    exit 1
fi

# Check for sector-specific terms (should not exist)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0087_gf_verifier_registry.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

echo ""
echo "✅ All checks passed for GF-W1-SCH-008"
echo "Migration: 0087_gf_verifier_registry.sql"
echo "Status: READY"

exit 0
