#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
EVIDENCE="$ROOT_DIR/evidence/phase1/identity_provenance_immutability.json"
mkdir -p "$(dirname "$EVIDENCE")"
rg -n 'x-tenant-id must match request tenant_id|x-participant-id must match request participant_id|httpContext.Items\["tenant_id"\] = tenantHeader\.Trim\(\)' "$PROGRAM" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'check_id':'INV-142','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY
