#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/program/fp_001_architecture_freeze.json"
mkdir -p "$(dirname "$EVIDENCE")"
for path in \
  docs/program/architecture_freeze.md \
  docs/program/no_touch_zones.md \
  docs/program/rollback_and_exception_policy.md \
  docs/program/sprint1_change_control.md; do
  [[ -f "$ROOT_DIR/$path" ]] || { echo "missing:$path" >&2; exit 1; }
done
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'task_id':'FP-001','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY
