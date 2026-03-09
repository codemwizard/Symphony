#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml"
CONTRACT="$ROOT_DIR/docs/PHASE1/phase1_contract.yml"
EVIDENCE="$ROOT_DIR/evidence/invariants/inv_001_governance_upgrade.json"
mkdir -p "$(dirname "$EVIDENCE")"
for inv in INV-135 INV-136 INV-137 INV-142 INV-143 INV-144 INV-146 INV-147; do
  rg -n "id: $inv|invariant_id: \"$inv\"" "$MANIFEST" "$CONTRACT" >/dev/null
 done
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'task_id':'INV-001','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY
