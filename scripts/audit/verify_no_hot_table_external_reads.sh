#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QUERY_FILES="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Queries"
EVIDENCE="$ROOT_DIR/evidence/phase1/proj_002_external_query_cutover.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"
rg -n "instruction_status_projection|evidence_bundle_projection|incident_case_projection" "$QUERY_FILES" >/dev/null
! rg -n "ingress_attestations|payment_outbox_pending|regulatory_incidents|incident_events" "$QUERY_FILES" >/dev/null
dotnet test "$ROOT_DIR/services/ledger-api/dotnet/tests/LedgerApi.Tests" --filter QueryProjection >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id':'PROJ-002-NO-HOT-TABLE-READS',
        'task_id':'PROJ-002',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status':'PASS',
        'pass':True,
        'no_hot_table_reads_detected':True
    }, fh, indent=2)
    fh.write('\n')
PY
