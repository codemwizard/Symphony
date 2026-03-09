#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0070_cqrs_projection_roles_and_read_models.sql"
QUERY_DIR="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Queries"
EVIDENCE="$ROOT_DIR/evidence/phase1/proj_001_initial_projection_set.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"
rg -n "CREATE TABLE IF NOT EXISTS public\.(instruction_status_projection|evidence_bundle_projection|escrow_summary_projection|incident_case_projection|program_member_summary_projection)" "$MIGRATION" >/dev/null
rg -n "as_of_utc|projection_version" "$MIGRATION" "$QUERY_DIR" "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/ReadModels/ProjectionReadModels.cs" >/dev/null
dotnet test "$ROOT_DIR/services/ledger-api/dotnet/tests/LedgerApi.Tests" --filter Projection >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id':'PROJ-001-PROJECTION-FRESHNESS',
        'task_id':'PROJ-001',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status':'PASS',
        'pass':True,
        'freshness_visible':True
    }, fh, indent=2)
    fh.write('\n')
PY
