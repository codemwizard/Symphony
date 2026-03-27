#!/usr/bin/env bash
# scripts/audit/generate_gf_evidence.sh
#
# PURPOSE
# -------
# Runs each GF verifier script and writes structured evidence JSON files.
# This bridges the gap between "verifier passes" and "evidence file exists"
# that the Phase 2 entry gate checks for.
#
# The GF verifier scripts are static file checks (they grep migration SQL).
# They do NOT require a running PostgreSQL instance. They print PASS/FAIL
# to stdout and exit 0 or 1. This wrapper captures each result and writes
# it as a structured JSON evidence file matching the contract expected by
# verify_gf_phase2_entry_gate.sh.
#
# USAGE
# -----
# bash scripts/audit/generate_gf_evidence.sh
#
# Run this after verifier scripts are confirmed correct. The evidence files
# are committed to the repo and checked by the Phase 2 entry gate.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GENERATED=0
FAILED=0

# ---------------------------------------------------------------------------
# Helper: run a verifier and write evidence JSON
# ---------------------------------------------------------------------------
generate_evidence() {
    local label="$1"
    local verifier="$2"
    local evidence_path="$3"

    local evidence_dir
    evidence_dir=$(dirname "$evidence_path")
    mkdir -p "$evidence_dir"

    local output=""
    local exit_code=0

    echo "Running $verifier..."
    output=$("$verifier" 2>&1) || exit_code=$?

    local status="PASS"
    if [[ "$exit_code" -ne 0 ]]; then
        status="FAIL"
        ((FAILED++)) || true
    fi

    # Count PASS/FAIL lines from verifier output
    local pass_count fail_count
    pass_count=$(echo "$output" | grep -c "PASS" || true)
    fail_count=$(echo "$output" | grep -c "FAIL" || true)

    # Extract individual check results from output
    local checks_json="[]"
    checks_json=$(echo "$output" | python3 -c "
import json, sys
checks = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    if 'PASS' in line or 'FAIL' in line:
        status = 'PASS' if 'PASS' in line else 'FAIL'
        # Remove status prefix markers for cleaner message
        msg = line.replace('✅ ', '').replace('❌ ', '').strip()
        checks.append({'check': msg, 'status': status})
print(json.dumps(checks))
" 2>/dev/null || echo "[]")

    cat > "$evidence_path" <<JSON
{
  "evidence_id": "$label",
  "generated_by": "scripts/audit/generate_gf_evidence.sh",
  "verifier": "$verifier",
  "timestamp": "$TIMESTAMP",
  "status": "$status",
  "exit_code": $exit_code,
  "summary": {
    "pass_count": $pass_count,
    "fail_count": $fail_count
  },
  "checks": $checks_json
}
JSON

    echo "  → $evidence_path ($status)"
    ((GENERATED++)) || true
}

echo "==> Generating GF Evidence Files"
echo ""

# ---------------------------------------------------------------------------
# Phase 0 schema evidence
# ---------------------------------------------------------------------------
generate_evidence "gf_sch_001" \
    "scripts/db/verify_gf_sch_001.sh" \
    "evidence/phase0/gf_sch_001.json"

generate_evidence "gf_sch_002" \
    "scripts/db/verify_gf_sch_002.sh" \
    "evidence/phase0/gf_sch_002.json"

generate_evidence "gf_monitoring_records" \
    "scripts/db/verify_gf_monitoring_records.sh" \
    "evidence/phase0/gf_monitoring_records.json"

generate_evidence "gf_evidence_lineage" \
    "scripts/db/verify_gf_evidence_lineage.sh" \
    "evidence/phase0/gf_evidence_lineage.json"

generate_evidence "gf_asset_lifecycle" \
    "scripts/db/verify_gf_asset_lifecycle.sh" \
    "evidence/phase0/gf_asset_lifecycle.json"

generate_evidence "gf_regulatory_plane" \
    "scripts/db/verify_gf_regulatory_plane.sh" \
    "evidence/phase0/gf_regulatory_plane.json"

generate_evidence "gf_sch_008" \
    "scripts/db/verify_gf_sch_008.sh" \
    "evidence/phase0/gf_sch_008.json"

# SCH-009 closeout evidence (if verifier exists)
if [[ -x scripts/db/verify_gf_sch_009.sh ]]; then
    generate_evidence "gf_sch_009" \
        "scripts/db/verify_gf_sch_009.sh" \
        "evidence/phase0/gf_sch_009.json"
else
    echo "SKIP: scripts/db/verify_gf_sch_009.sh not found (SCH-009 closeout)"
fi

# ---------------------------------------------------------------------------
# Phase 1 function evidence
# ---------------------------------------------------------------------------
generate_evidence "gf_fnc_001" \
    "scripts/db/verify_gf_fnc_001.sh" \
    "evidence/phase1/gf_fnc_001.json"

generate_evidence "gf_fnc_002" \
    "scripts/db/verify_gf_fnc_002.sh" \
    "evidence/phase1/gf_fnc_002.json"

generate_evidence "gf_fnc_003" \
    "scripts/db/verify_gf_fnc_003.sh" \
    "evidence/phase1/gf_fnc_003.json"

generate_evidence "gf_fnc_004" \
    "scripts/db/verify_gf_fnc_004.sh" \
    "evidence/phase1/gf_fnc_004.json"

generate_evidence "gf_fnc_005" \
    "scripts/db/verify_gf_fnc_005.sh" \
    "evidence/phase1/gf_fnc_005.json"

generate_evidence "gf_fnc_006" \
    "scripts/db/verify_gf_fnc_006.sh" \
    "evidence/phase1/gf_fnc_006.json"

echo ""
echo "============================================================"
echo "Evidence files generated: $GENERATED"
echo "Verifier failures:       $FAILED"

if [[ "$FAILED" -gt 0 ]]; then
    echo "⚠️  Some verifiers failed — evidence files written with status: FAIL"
    echo "   Fix the verifier failures before committing evidence."
    exit 1
else
    echo "✅ All evidence files generated with status: PASS"
    exit 0
fi
