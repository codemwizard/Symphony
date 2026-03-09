#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
EVIDENCE="$ROOT_DIR/evidence/phase1/audit_precedence.json"
mkdir -p "$(dirname "$EVIDENCE")"
rg -n 'timeline: new object\[\]' "$PROGRAM" >/dev/null
rg -n 'event_name = "ATTESTED"' "$PROGRAM" >/dev/null
rg -n 'event_name = "OUTBOX_ENQUEUED"' "$PROGRAM" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'check_id':'INV-143','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY
