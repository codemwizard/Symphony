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


MIGRATION="schema/migrations/0080_gf_adapter_registrations.sql"
META="schema/migrations/0080_gf_adapter_registrations.meta.yml"

echo "==> GF-W1-SCH-001 Adapter Registrations Schema Verification"

# Check if migration exists
if [[ ! -f "$MIGRATION" ]]; then
    echo "❌ FAIL: Migration file not found"
    exit 1
fi
echo "✅ PASS: Migration file exists"

# Check if meta file exists
if [[ ! -f "$META" ]]; then
    echo "❌ FAIL: Meta file not found"
    exit 1
fi
echo "✅ PASS: Meta file exists"

# Check table exists
if grep -q "CREATE TABLE.*adapter_registrations" "$MIGRATION"; then
    echo "✅ PASS: adapter_registrations table created"
else
    echo "❌ FAIL: adapter_registrations table not found"
    exit 1
fi

# Check required fields per DSN-001 spec
echo ""
echo "=== Required Fields ==="

REQUIRED_FIELDS=(
    "adapter_registration_id"
    "tenant_id"
    "adapter_code"
    "methodology_code"
    "methodology_authority"
    "version_code"
    "is_active"
    "payload_schema_refs"
    "checklist_refs"
    "entrypoint_refs"
    "issuance_semantic_mode"
    "retirement_semantic_mode"
    "jurisdiction_compatibility"
    "created_at"
)

for field in "${REQUIRED_FIELDS[@]}"; do
    if grep -q "$field" "$MIGRATION"; then
        echo "✅ PASS: Field $field exists"
    else
        echo "❌ FAIL: Field $field missing"
        exit 1
    fi
done

# Check CHECK constraints
echo ""
echo "=== CHECK Constraints ==="

if grep -q "CHECK.*jsonb_typeof(payload_schema_refs)" "$MIGRATION"; then
    echo "✅ PASS: payload_schema_refs JSONB type CHECK present"
else
    echo "❌ FAIL: payload_schema_refs JSONB type CHECK missing"
    exit 1
fi

if grep -q "CHECK.*jsonb_typeof(checklist_refs)" "$MIGRATION"; then
    echo "✅ PASS: checklist_refs JSONB type CHECK present"
else
    echo "❌ FAIL: checklist_refs JSONB type CHECK missing"
    exit 1
fi

if grep -q "CHECK.*issuance_semantic_mode.*IN" "$MIGRATION"; then
    echo "✅ PASS: issuance_semantic_mode CHECK constraint present"
else
    echo "❌ FAIL: issuance_semantic_mode CHECK constraint missing"
    exit 1
fi

if grep -q "CHECK.*retirement_semantic_mode.*IN" "$MIGRATION"; then
    echo "✅ PASS: retirement_semantic_mode CHECK constraint present"
else
    echo "❌ FAIL: retirement_semantic_mode CHECK constraint missing"
    exit 1
fi

# Check UNIQUE constraint
echo ""
echo "=== Uniqueness Constraint ==="

if grep -q "UNIQUE.*tenant_id.*adapter_code.*methodology_code.*version_code" "$MIGRATION"; then
    echo "✅ PASS: UNIQUE(tenant_id, adapter_code, methodology_code, version_code) present"
else
    echo "❌ FAIL: Required UNIQUE constraint missing"
    exit 1
fi

# Check FK to tenants
echo ""
echo "=== Foreign Keys ==="

if grep -q "tenant_id.*REFERENCES.*tenants" "$MIGRATION"; then
    echo "✅ PASS: FK to tenants table present"
else
    echo "❌ FAIL: FK to tenants table missing"
    exit 1
fi

# Check RLS
echo ""
echo "=== RLS Checks ==="

if grep -q "ENABLE ROW LEVEL SECURITY" "$MIGRATION"; then
    echo "✅ PASS: RLS enabled"
else
    echo "❌ FAIL: RLS not enabled"
    exit 1
fi

if grep -q "CREATE POLICY.*tenant_isolation_adapter_registrations" "$MIGRATION"; then
    echo "✅ PASS: Tenant isolation policy present"
else
    echo "❌ FAIL: Tenant isolation policy missing"
    exit 1
fi


# Check append-only trigger
echo ""
echo "=== Append-Only Enforcement ==="

if grep -q "CREATE OR REPLACE FUNCTION.*adapter_registrations_append_only_trigger" "$MIGRATION"; then
    echo "✅ PASS: Append-only trigger function present"
else
    echo "❌ FAIL: Append-only trigger function missing"
    exit 1
fi

if grep -q "CREATE TRIGGER.*adapter_registrations_append_only" "$MIGRATION"; then
    echo "✅ PASS: Append-only trigger applied"
else
    echo "❌ FAIL: Append-only trigger not applied"
    exit 1
fi

if grep -q "BEFORE UPDATE OR DELETE ON adapter_registrations" "$MIGRATION"; then
    echo "✅ PASS: Trigger fires on UPDATE and DELETE"
else
    echo "❌ FAIL: Trigger does not cover UPDATE and DELETE"
    exit 1
fi

# Check revoke-first privilege posture
echo ""
echo "=== Privilege Posture ==="

if grep -q "REVOKE ALL.*adapter_registrations.*FROM PUBLIC" "$MIGRATION"; then
    echo "✅ PASS: Revoke-first privilege posture applied"
else
    echo "❌ FAIL: Revoke-first privilege posture missing"
    exit 1
fi

if grep -q "GRANT SELECT, INSERT.*adapter_registrations.*TO symphony_command" "$MIGRATION"; then
    echo "✅ PASS: symphony_command granted SELECT, INSERT only"
else
    echo "❌ FAIL: symphony_command grants incorrect"
    exit 1
fi

# Negative check: no UPDATE/DELETE grants to authenticated_role
if grep -q "GRANT.*UPDATE.*adapter_registrations.*TO symphony_command" "$MIGRATION" || \
   grep -q "GRANT.*DELETE.*adapter_registrations.*TO symphony_command" "$MIGRATION"; then
    echo "❌ FAIL: symphony_command has UPDATE/DELETE grants (violates append-only)"
    exit 1
else
    echo "✅ PASS: No UPDATE/DELETE grants to symphony_command"
fi

# Check sector neutrality
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste\|PWRM\|recycl" "$MIGRATION"; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

echo ""
echo "✅ All checks passed for GF-W1-SCH-001"
echo "Migration: 0080_gf_adapter_registrations.sql"

# ── Emit signed evidence ───────────────────────────────────
python3 scripts/audit/sign_evidence.py \
    --write \
    --out "evidence/phase1/gf_sch_001.json" \
    --task "GF-W1-SCH-001" \
    --status "PASS" \
    --source-file "schema/migrations/0080_gf_adapter_registrations.sql" \
    --command-output "{\"check\": \"schema_verification\", \"migration\": \"0080_gf_adapter_registrations.sql\"}"

echo "Status: READY (evidence signed)"

exit 0
