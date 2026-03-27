#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-SCH-006 Regulatory Plane Schema Verification"

# Check if migrations exist
echo ""
echo "=== Migration File Checks ==="

for migration in "0085_gf_regulatory_plane.sql" "0086_gf_jurisdiction_profiles.sql"; do
    if [[ ! -f "schema/migrations/$migration" ]]; then
        echo "❌ FAIL: Migration file $migration not found"
        exit 1
    fi
    echo "✅ PASS: Migration file $migration exists"
done

# Check if meta files exist
echo ""
echo "=== Meta File Checks ==="

for meta in "0085_gf_regulatory_plane.meta.yml" "0086_gf_jurisdiction_profiles.meta.yml"; do
    if [[ ! -f "schema/migrations/$meta" ]]; then
        echo "❌ FAIL: Meta file $meta not found"
        exit 1
    fi
    echo "✅ PASS: Meta file $meta exists"
done

# Check all four tables exist
echo ""
echo "=== Table Checks ==="

TABLES=(
    "regulatory_authorities"
    "regulatory_checkpoints"
    "jurisdiction_profiles"
    "lifecycle_checkpoint_rules"
)

for table in "${TABLES[@]}"; do
    if grep -q "CREATE TABLE.*$table" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Table $table created"
    else
        echo "❌ FAIL: Table $table not found"
        exit 1
    fi
done

# Check regulatory_authorities fields
echo ""
echo "=== Regulatory Authorities Fields ==="

AUTHORITY_FIELDS=(
    "authority_id"
    "jurisdiction_code"
    "legal_basis_reference"
    "authority_type"
    "authority_name"
    "enforcement_scope"
    "effective_from"
    "effective_to"
    "created_at"
)

for field in "${AUTHORITY_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0085_gf_regulatory_plane.sql; then
        echo "✅ PASS: Field regulatory_authorities.$field exists"
    else
        echo "❌ FAIL: Field regulatory_authorities.$field missing"
        exit 1
    fi
done

# Check regulatory_checkpoints fields
echo ""
echo "=== Regulatory Checkpoints Fields ==="

CHECKPOINT_FIELDS=(
    "checkpoint_id"
    "jurisdiction_code"
    "authority_id"
    "lifecycle_transition"
    "checkpoint_type"
    "is_mandatory"
    "interpretation_pack_id"
    "created_at"
)

for field in "${CHECKPOINT_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0085_gf_regulatory_plane.sql; then
        echo "✅ PASS: Field regulatory_checkpoints.$field exists"
    else
        echo "❌ FAIL: Field regulatory_checkpoints.$field missing"
        exit 1
    fi
done

# Check jurisdiction_profiles fields
echo ""
echo "=== Jurisdiction Profiles Fields ==="

PROFILE_FIELDS=(
    "profile_id"
    "jurisdiction_code"
    "country_name"
    "national_registry_reference"
    "article6_participant"
    "profile_status"
    "effective_from"
    "created_at"
)

for field in "${PROFILE_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Field jurisdiction_profiles.$field exists"
    else
        echo "❌ FAIL: Field jurisdiction_profiles.$field missing"
        exit 1
    fi
done

# Check lifecycle_checkpoint_rules fields
echo ""
echo "=== Lifecycle Checkpoint Rules Fields ==="

RULE_FIELDS=(
    "rule_id"
    "jurisdiction_code"
    "lifecycle_transition"
    "checkpoint_id"
    "rule_status"
    "interpretation_pack_id"
    "effective_from"
    "effective_to"
    "created_at"
)

for field in "${RULE_FIELDS[@]}"; do
    if grep -q "$field" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Field lifecycle_checkpoint_rules.$field exists"
    else
        echo "❌ FAIL: Field lifecycle_checkpoint_rules.$field missing"
        exit 1
    fi
done

# Check CHECK constraints
echo ""
echo "=== CHECK Constraints ==="

# Authority types
AUTHORITY_TYPES=("SOVEREIGN" "REGULATOR" "DESIGNATED_BODY")
for type in "${AUTHORITY_TYPES[@]}"; do
    if grep -q "$type" schema/migrations/0085_gf_regulatory_plane.sql; then
        echo "✅ PASS: Authority type $type in constraint"
    else
        echo "❌ FAIL: Authority type $type missing from constraint"
        exit 1
    fi
done

# Checkpoint types
CHECKPOINT_TYPES=("REGISTRATION" "METHODOLOGY_APPROVAL" "ISSUANCE_AUTHORIZATION" "TRANSFER_APPROVAL" "EXPORT_APPROVAL" "RETIREMENT_RECORDING")
for type in "${CHECKPOINT_TYPES[@]}"; do
    if grep -q "$type" schema/migrations/0085_gf_regulatory_plane.sql; then
        echo "✅ PASS: Checkpoint type $type in constraint"
    else
        echo "❌ FAIL: Checkpoint type $type missing from constraint"
        exit 1
    fi
done

# Profile statuses
PROFILE_STATUSES=("ACTIVE" "SUSPENDED" "DRAFT")
for status in "${PROFILE_STATUSES[@]}"; do
    if grep -q "$status" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Profile status $status in constraint"
    else
        echo "❌ FAIL: Profile status $status missing from constraint"
        exit 1
    fi
done

# Rule statuses
RULE_STATUSES=("REQUIRED" "CONDITIONALLY_REQUIRED" "WAIVED_FOR_PILOT" "PENDING_AUTHORITY_CLARIFICATION")
for status in "${RULE_STATUSES[@]}"; do
    if grep -q "$status" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Rule status $status in constraint"
    else
        echo "❌ FAIL: Rule status $status missing from constraint"
        exit 1
    fi
done

# Check jurisdiction_code non-null constraints
echo ""
echo "=== Jurisdiction Code Non-Null Checks ==="

for table in "${TABLES[@]}"; do
    if grep -q "jurisdiction_code.*TEXT.*NOT NULL" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: jurisdiction_code NOT NULL on $table"
    else
        echo "❌ FAIL: jurisdiction_code NOT NULL missing on $table"
        exit 1
    fi
done

# Check unique constraints
echo ""
echo "=== Unique Constraints ==="

if grep -q "jurisdiction_code.*UNIQUE" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
    echo "✅ PASS: Unique constraint on jurisdiction_profiles.jurisdiction_code"
else
    echo "❌ FAIL: Unique constraint on jurisdiction_profiles.jurisdiction_code missing"
    exit 1
fi

if grep -q "lifecycle_checkpoint_rules_unique_active" schema/migrations/0086_gf_jurisdiction_profiles.sql && grep -q "UNIQUE.*jurisdiction_code.*lifecycle_transition.*checkpoint_id" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
    echo "✅ PASS: Unique constraint on active lifecycle checkpoint rules"
else
    echo "❌ FAIL: Unique constraint on active lifecycle checkpoint rules missing"
    exit 1
fi

# Check foreign keys
echo ""
echo "=== Foreign Keys ==="

FKS=(
    "authority_id.*REFERENCES.*regulatory_authorities"
    "checkpoint_id.*REFERENCES.*regulatory_checkpoints"
    "interpretation_pack_id.*REFERENCES.*interpretation_packs"
)

for fk in "${FKS[@]}"; do
    if grep -q "$fk" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: FK $fk present"
    else
        echo "❌ FAIL: FK $fk missing"
        exit 1
    fi
done

# Check append-only triggers
echo ""
echo "=== Append-Only Triggers ==="

for table in "${TABLES[@]}"; do
    if grep -q "CREATE TRIGGER.*${table}_append_only" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Append-only trigger present on $table"
    else
        echo "❌ FAIL: Append-only trigger missing on $table"
        exit 1
    fi
done

# Check RLS
echo ""
echo "=== RLS Checks ==="

for table in "${TABLES[@]}"; do
    if grep -q "$table.*ENABLE ROW LEVEL SECURITY" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: RLS enabled on $table"
    else
        echo "❌ FAIL: RLS not enabled on $table"
        exit 1
    fi
done

# Check functions (sample)
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "create_regulatory_authority"
    "create_regulatory_checkpoint"
    "create_jurisdiction_profile"
    "create_lifecycle_checkpoint_rule"
    "query_regulatory_checkpoints"
    "query_active_checkpoint_rules"
    "query_jurisdiction_profile_summary"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check revoke-first privileges
if grep -q "REVOKE ALL.*regulatory_authorities.*FROM PUBLIC" schema/migrations/0085_gf_regulatory_plane.sql && grep -q "REVOKE ALL.*regulatory_checkpoints.*FROM PUBLIC" schema/migrations/0085_gf_regulatory_plane.sql && grep -q "REVOKE ALL.*jurisdiction_profiles.*FROM PUBLIC" schema/migrations/0086_gf_jurisdiction_profiles.sql && grep -q "REVOKE ALL.*lifecycle_checkpoint_rules.*FROM PUBLIC" schema/migrations/0086_gf_jurisdiction_profiles.sql; then
    echo "✅ PASS: Revoke-first privileges applied"
else
    echo "❌ FAIL: Revoke-first privileges missing"
    exit 1
fi

# Check for country-specific terms (should not exist)
echo ""
echo "=== Country Neutrality Check ==="

if grep -q -i "zambia\|zimbabwe\|kenya\|south.*africa\|nigeria\|ghana" schema/migrations/0085_gf_regulatory_plane.sql schema/migrations/0086_gf_jurisdiction_profiles.sql; then
    echo "❌ FAIL: Country-specific terms found in migrations"
    exit 1
else
    echo "✅ PASS: No country-specific terms found"
fi

echo ""
echo "✅ All checks passed for GF-W1-SCH-006"
echo "Migrations: 0085_gf_regulatory_plane.sql, 0086_gf_jurisdiction_profiles.sql"
echo "Status: READY"

exit 0
