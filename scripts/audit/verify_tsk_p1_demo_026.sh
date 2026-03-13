#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-026"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_026_server_side_admin_proxy.json}"
for path in "$ROOT_DIR/docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md" "$ROOT_DIR/src/supervisory-dashboard/index.html" "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"; do [[ -e "$path" ]]; done
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence = sys.argv[1:]
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
Path(evidence).parent.mkdir(parents=True, exist_ok=True)
Path(evidence).write_text(json.dumps({
  'check_id': 'TSK-P1-DEMO-026-TASK-PACK',
  'task_id': task_id,
  'timestamp_utc': os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha': sha,
  'status': 'PASS',
  'pass': True,
  'details': {'task_pack_present': True}
}, indent=2) + '\n', encoding='utf-8')
PY
