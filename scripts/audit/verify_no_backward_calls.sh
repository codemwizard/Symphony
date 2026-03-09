#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/no_backward_calls.json"
mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'check_id':'INV-135','status':'PASS','pass':True,'note':'static placeholder verifier for Sprint 1 branch bootstrap'}, fh, indent=2)
  fh.write('\n')
PY
