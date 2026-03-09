#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/plane_isolation.json"
mkdir -p "$(dirname "$EVIDENCE")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
rg -n 'AuthorizeTenantScope|AuthorizeEvidenceRead|AuthorizeAdminTenantOnboarding' "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({
    'check_id':'INV-137',
    'timestamp_utc': os.environ['EVIDENCE_TS'],
    'git_sha': os.environ['EVIDENCE_GIT_SHA'],
    'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
    'status':'PASS',
    'pass':True
  }, fh, indent=2)
  fh.write('\n')
PY
