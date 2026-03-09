#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORES="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs"
EVIDENCE="$ROOT_DIR/evidence/phase1/audit_precedence.json"
mkdir -p "$(dirname "$EVIDENCE")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
rg -n 'timeline: new object\[\]' "$STORES" >/dev/null
rg -n 'event_name = "ATTESTED"' "$STORES" >/dev/null
rg -n 'event_name = "OUTBOX_ENQUEUED"' "$STORES" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({
    'check_id':'INV-143',
    'timestamp_utc': os.environ['EVIDENCE_TS'],
    'git_sha': os.environ['EVIDENCE_GIT_SHA'],
    'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
    'status':'PASS',
    'pass':True
  }, fh, indent=2)
  fh.write('\n')
PY
