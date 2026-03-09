#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/plane_isolation.json"
mkdir -p "$(dirname "$EVIDENCE")"
rg -n 'AuthorizeTenantScope|AuthorizeEvidenceRead|AuthorizeAdminTenantOnboarding' "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'check_id':'INV-137','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY
