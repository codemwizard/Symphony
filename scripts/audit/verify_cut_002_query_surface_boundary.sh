#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
EVIDENCE="$ROOT_DIR/evidence/phase1/cut_002_query_surface_boundary.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"

rg -n 'MapGet\("/v1/evidence-packs/\{instruction_id\}"' "$PROGRAM" >/dev/null
rg -n 'EvidencePackHandler\.HandleAsync' "$PROGRAM" >/dev/null
rg -n 'MapGet\("/v1/regulatory/reports/daily"' "$PROGRAM" >/dev/null
rg -n 'RegulatoryReportHandler\.GenerateDailyReportAsync' "$PROGRAM" >/dev/null
rg -n 'MapGet\("/v1/regulatory/incidents/\{incident_id\}/report"' "$PROGRAM" >/dev/null
rg -n 'RegulatoryIncidentReportHandler\.GenerateIncidentReportAsync' "$PROGRAM" >/dev/null
rg -n 'MapPost\("/v1/admin/incidents"' "$PROGRAM" >/dev/null
rg -n 'AuthorizeAdminTenantOnboarding' "$PROGRAM" >/dev/null

dotnet test "$ROOT_DIR/services/ledger-api/dotnet/tests/LedgerApi.Tests" --filter QueryProjection >/dev/null

python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id': 'CUT-002-QUERY-SURFACE-BOUNDARY',
        'task_id': 'CUT-002',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status': 'PASS',
        'public_reads_handler_mediated': True,
        'admin_mutations_separate': True
    }, fh, indent=2)
    fh.write('\n')
PY
