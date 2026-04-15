#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-001"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
LEGACY_FILE="$ROOT_DIR/src/supervisory-dashboard/legacy.html"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_001_shell_port.json}"
for f in "$UI_FILE" "$LEGACY_FILE" "$PROGRAM_FILE"; do
  [[ -f "$f" ]] || { echo "missing_required_file:$f" >&2; exit 1; }
done
required_ids=(programme-summary-panel timeline-panel evidence-completeness-panel exception-log-panel export-trigger raw-artifact-drilldown)
for id in "${required_ids[@]}"; do
  rg -Fq "$id" "$UI_FILE" || { echo "missing_ui_compat_id:$id" >&2; exit 1; }
done
! rg -qi 'fonts.googleapis.com|fonts.gstatic.com|live rail|real-time rail settlement|production settlement execution' "$UI_FILE" || { echo 'forbidden_ui_dependency_or_claim' >&2; exit 1; }
rg -Fq 'app.MapGet("/pilot-demo/supervisory"' "$PROGRAM_FILE" || { echo 'missing_supervisory_route' >&2; exit 1; }
rg -Fq 'app.MapGet("/pilot-demo/supervisory-legacy"' "$PROGRAM_FILE" || { echo 'missing_legacy_route' >&2; exit 1; }
rg -Fq 'runtimeProfile' "$PROGRAM_FILE" || { echo 'missing_runtime_profile_guard' >&2; exit 1; }
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-001-SHELL-PORT',
  'task_id':task_id,
  'timestamp_utc':os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True,
  'details':{
    'pilot_demo_primary_route_present':True,
    'pilot_demo_legacy_route_present':True,
    'compatibility_ids_preserved':True,
    'remote_assets_removed':True,
    'forbidden_claim_substrings_absent':True
  }
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
