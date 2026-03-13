#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-009"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_009_sim_swap.json}"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
DOC_FILE="$ROOT_DIR/docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md"
for pattern in 'SIM-Swap Risk Hold' '(Phase 1 · DEMO_BACKED)' 'Backing mode: DEMO_BACKED for Phase 1.'; do
  rg -Fq "$pattern" "$UI_FILE" || { echo "missing_ui_pattern:$pattern" >&2; exit 1; }
done
rg -Fq '| SIM-swap | DEMO_BACKED | Phase-1 decision; future task required for LIVE |' "$DOC_FILE" || { echo 'missing_doc_sim_swap_matrix_entry' >&2; exit 1; }
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
payload = {
  'check_id': 'TASK-UI-WIRE-009-SIM-SWAP-TRUTH',
  'task_id': task_id,
  'timestamp_utc': os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha': sha,
  'status': 'PASS',
  'pass': True,
  'details': {
    'panel_visible': True,
    'backing_mode': 'DEMO_BACKED',
    'phase_scope': 'Phase 1',
    'future_live_upgrade_requires_new_task': True
  }
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
print(f'Evidence written: {out}')
PY
