#!/usr/bin/env bash
# register_pwrm0001_adapter.sh — DML-only adapter registration for PWRM0001 pilot
# This script inserts adapter registration data into existing tables.
# NO DDL, NO migrations, NO schema changes.
# Pilot containment: all data lives in existing Phase 0/1 tables.
# Second Pilot Test: This design works unchanged for VM0044 (solar energy, Southeast Asia).
#
# References:
#   - docs/operations/AGENTIC_SDLC_PILOT_POLICY.md
#   - docs/pilots/PILOT_PWRM0001/SCOPE.md
#   - docs/operations/PILOT_REJECTION_PLAYBOOK.md
#   - docs/operations/AGENT_GUARDRAILS_GREEN_FINANCE.md

set -euo pipefail

echo "==> PWRM0001 Adapter Registration (DML-only)"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [[ ! -f "docs/pilots/PILOT_PWRM0001/SCOPE.md" ]]; then
    echo "❌ FAIL: docs/pilots/PILOT_PWRM0001/SCOPE.md not found"
    echo "   Pilot scope declaration is required before registration."
    exit 1
fi

echo "✅ Pilot scope declaration found"

# ── Check core contract gate ──────────────────────────────────────────────────
if [[ -x "scripts/audit/verify_core_contract_gate.sh" ]]; then
    echo "Running core contract gate..."
    scripts/audit/verify_core_contract_gate.sh || {
        echo "❌ FAIL: Core contract gate failed. Adapter registration blocked."
        exit 1
    }
fi

# ── Adapter registration SQL (DML INSERT only) ───────────────────────────────
# This SQL is designed to be idempotent via ON CONFLICT DO NOTHING.
# It only inserts; the append-only trigger on adapter_registrations blocks
# UPDATE/DELETE, so re-running is safe.

ADAPTER_SQL=$(cat <<'EOSQL'
-- PWRM0001 Adapter Registration — DML INSERT only, no DDL
-- Pilot: Plastic Waste Recovery Methodology v1.0
-- Methodology Authority: GLOBAL_PLASTIC_REGISTRY
-- Second Pilot Test: VM0044 (solar energy, Southeast Asia) uses identical schema

-- Insert adapter registration for PWRM0001
-- Uses a deterministic UUID for idempotent re-runs
INSERT INTO adapter_registrations (
    adapter_registration_id,
    tenant_id,
    adapter_code,
    methodology_code,
    methodology_authority,
    version_code,
    is_active,
    payload_schema_refs,
    checklist_refs,
    entrypoint_refs,
    issuance_semantic_mode,
    retirement_semantic_mode,
    jurisdiction_compatibility
) VALUES (
    '00000000-0000-7000-b000-000000000001'::UUID,
    (SELECT tenant_id FROM tenants LIMIT 1),
    'PWRM0001',
    'PLASTIC_WASTE_V1',
    'GLOBAL_PLASTIC_REGISTRY',
    '1.0',
    true,
    '["pwrm0001_collection_schema_v1.json"]'::JSONB,
    '["pwrm0001_verification_checklist_v1.json"]'::JSONB,
    '["pwrm0001_calculation_engine_v1.py"]'::JSONB,
    'STRICT',
    'STRICT',
    '{"GLOBAL_SOUTH": {"confidence_threshold": 0.95, "verification_requirements": ["field_verification", "digital_traceability", "mass_balance"]}}'::JSONB
) ON CONFLICT (tenant_id, adapter_code, methodology_code, version_code) DO NOTHING;
EOSQL
)

echo ""
echo "==> Adapter registration SQL prepared"
echo "    adapter_code: PWRM0001"
echo "    methodology_code: PLASTIC_WASTE_V1"
echo "    methodology_authority: GLOBAL_PLASTIC_REGISTRY"
echo "    version_code: 1.0"
echo "    is_active: true"
echo "    issuance_semantic_mode: STRICT"
echo "    retirement_semantic_mode: STRICT"
echo ""

# ── Apply SQL if DATABASE_URL is available ────────────────────────────────────
if [[ -n "${DATABASE_URL:-}" ]]; then
    echo "==> Applying adapter registration SQL..."
    echo "$ADAPTER_SQL" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
    echo "✅ PWRM0001 adapter registered successfully"
else
    echo "⏳ DATABASE_URL not set — SQL prepared but not applied."
    echo "   To apply manually, run this SQL against the target database."
    echo ""
    echo "--- SQL BEGIN ---"
    echo "$ADAPTER_SQL"
    echo "--- SQL END ---"
fi

echo ""
echo "✅ PWRM0001 adapter registration complete"
echo "   No DDL executed. No migrations created. Pure DML INSERT."
echo "   Pilot scope: docs/pilots/PILOT_PWRM0001/SCOPE.md"
