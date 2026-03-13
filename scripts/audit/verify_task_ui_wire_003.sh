#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-003"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_003_reveal_live_wiring.json}"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
[[ -f "$UI_FILE" ]] || { echo "missing_ui:$UI_FILE" >&2; exit 1; }
rg -Fq "/v1/supervisory/programmes/" "$UI_FILE" || { echo 'missing_reveal_route_usage' >&2; exit 1; }
rg -Fq "programme_summary" "$UI_FILE" || { echo 'missing_programme_summary_binding' >&2; exit 1; }
rg -Fq "exception_log" "$UI_FILE" || { echo 'missing_exception_log_binding' >&2; exit 1; }
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence_path = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-003-REVEAL-WIRING',
  'task_id':task_id,
  'timestamp_utc':os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
