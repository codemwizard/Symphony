#!/bin/bash
# [ID tsk_p1_demo_031_verification_script]
# Proof-Carrying Evidence script for Pilot Demo Gaps

set -e

EVIDENCE_FILE="evidence/phase1/tsk_p1_demo_031_verification.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

echo "{\"check_id\": \"TSK-P1-DEMO-031\", \"task_id\": \"TSK-P1-DEMO-031\", \"git_sha\": \"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)\", \"timestamp_utc\": \"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)\", \"status\": \"PASS\", \"checks\": [], \"observed_paths\": [], \"observed_hashes\": [], \"command_outputs\": [], \"execution_trace\": []}" > "$EVIDENCE_FILE"

OVERALL_PASS=true

function add_check() {
    local name=$1
    local status=$2
    local detail=$3
    python3 -c "import json; d = json.load(open('$EVIDENCE_FILE')); d['checks'].append({'name': '$name', 'status': '$status', 'detail': '$detail'}); json.dump(d, open('$EVIDENCE_FILE', 'w'), indent=2)"
    if [ "$status" != "PASS" ]; then
        OVERALL_PASS=false
    fi
}

function add_trace() {
    local msg=$1
    python3 -c "import json; d = json.load(open('$EVIDENCE_FILE')); d['execution_trace'].append('$msg'); json.dump(d, open('$EVIDENCE_FILE', 'w'), indent=2)"
}

function observe_file() {
    local path=$1
    if [ -f "$path" ]; then
        local hash=$(sha256sum "$path" | awk '{print $1}')
        python3 -c "import json; d = json.load(open('$EVIDENCE_FILE')); d['observed_paths'].append('$path'); d['observed_hashes'].append({'$path': '$hash'}); json.dump(d, open('$EVIDENCE_FILE', 'w'), indent=2)"
    fi
}

# Check UI changes — Worker Link component
add_trace "Checking src/supervisory-dashboard/index.html for Demo Worker Link..."
if grep -q "Demo Worker Link" src/supervisory-dashboard/index.html; then
    add_check "ui_demo_control" "PASS" "Demo Worker Link card found"
else
    add_check "ui_demo_control" "FAIL" "Demo Worker Link card missing"
fi

# Check UI changes — Slideout drill-down panel
if grep -q "slideout" src/supervisory-dashboard/index.html; then
    add_check "ui_drilldown" "PASS" "Slideout drilldown panel found"
else
    add_check "ui_drilldown" "FAIL" "Slideout drilldown panel missing"
fi

# Check DB migration
add_trace "Checking migration 0114 for grants..."
if [ -f "schema/migrations/0114_grant_onboarding_tables_to_app_role.sql" ]; then
    observe_file "schema/migrations/0114_grant_onboarding_tables_to_app_role.sql"
    if grep -q "GRANT SELECT, INSERT, UPDATE ON public.tenant_registry" schema/migrations/0114_grant_onboarding_tables_to_app_role.sql; then
        add_check "db_grants" "PASS" "Grants found in migration 0114"
    else
        add_check "db_grants" "FAIL" "Grants missing in migration 0114"
    fi
else
    add_check "db_grants" "FAIL" "Migration 0114 missing"
fi

# Check C# changes
add_trace "Checking Pwrm0001ArtifactTypes.cs for new proof types..."
if grep -q "INVENTORY_RECEIPT" services/ledger-api/dotnet/src/LedgerApi/Commands/Pwrm0001ArtifactTypes.cs; then
    add_check "cs_proof_types" "PASS" "INVENTORY_RECEIPT proof type found"
else
    add_check "cs_proof_types" "FAIL" "INVENTORY_RECEIPT proof type missing"
fi

observe_file "src/supervisory-dashboard/index.html"
observe_file "services/ledger-api/dotnet/src/LedgerApi/Commands/Pwrm0001ArtifactTypes.cs"

# Set final status based on check results
if [ "$OVERALL_PASS" = true ]; then
    python3 -c "import json; d = json.load(open('$EVIDENCE_FILE')); d['status'] = 'PASS'; json.dump(d, open('$EVIDENCE_FILE', 'w'), indent=2)"
else
    python3 -c "import json; d = json.load(open('$EVIDENCE_FILE')); d['status'] = 'FAIL'; json.dump(d, open('$EVIDENCE_FILE', 'w'), indent=2)"
fi

echo "Verification complete."
