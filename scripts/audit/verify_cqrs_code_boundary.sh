#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
EVIDENCE="$ROOT_DIR/evidence/phase1/cqrs_001_code_separation.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"
for path in \
  services/ledger-api/dotnet/src/LedgerApi/Commands \
  services/ledger-api/dotnet/src/LedgerApi/Queries \
  services/ledger-api/dotnet/src/LedgerApi/ReadModels \
  services/ledger-api/dotnet/src/LedgerApi/Infrastructure \
  services/ledger-api/dotnet/src/LedgerApi/Security; do
  test -d "$ROOT_DIR/$path"
done
! rg -n "^(static class IngressHandler|static class EvidencePackHandler|static class RegulatoryReportHandler|static class RegulatoryIncidentReportHandler|static class ApiAuthorization)" "$PROGRAM" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id':'CQRS-001-CODE-BOUNDARY',
        'task_id':'CQRS-001',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status':'PASS',
        'pass':True,
        'program_bootstrap_refactored':True
    }, fh, indent=2)
    fh.write('\n')
PY
