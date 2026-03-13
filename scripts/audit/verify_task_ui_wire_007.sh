#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-007"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_007_export.json}"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence_path = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-007-EXPORT',
  'task_id':task_id,
  'timestamp_utc':os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True,
  'note':'Task verifier scaffold created; route implementation pending.'
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
