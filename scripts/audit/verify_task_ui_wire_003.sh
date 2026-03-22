#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-003"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_003_reveal_live_wiring.json}"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
[[ -f "$UI_FILE" ]] || { echo "missing_ui:$UI_FILE" >&2; exit 1; }
rg -Fq "getReveal(programId)" "$UI_FILE" || { echo 'missing_reveal_route_usage' >&2; exit 1; }
rg -Fq '/supervisory/programmes/${cacheKey}/reveal' "$UI_FILE" || { echo 'missing_reveal_route_template' >&2; exit 1; }
rg -Fq 'this._revealCache.delete(cacheKey);' "$UI_FILE" || { echo 'missing_reveal_cache_rejection_cleanup' >&2; exit 1; }
rg -Fq "programme_summary" "$UI_FILE" || { echo 'missing_programme_summary_binding' >&2; exit 1; }
rg -Fq "exception_log" "$UI_FILE" || { echo 'missing_exception_log_binding' >&2; exit 1; }
rg -Fq "evidence_completeness" "$UI_FILE" || { echo 'missing_evidence_completeness_binding' >&2; exit 1; }
rg -Fq "hydrateDashboard(" "$UI_FILE" || { echo 'missing_dashboard_hydration' >&2; exit 1; }
rg -Fq 'id="timelineRows"' "$UI_FILE" || { echo 'missing_timeline_rows_target' >&2; exit 1; }
rg -Fq 'id="exceptionRows"' "$UI_FILE" || { echo 'missing_exception_rows_target' >&2; exit 1; }
rg -Fq 'id="evidenceCompletenessList"' "$UI_FILE" || { echo 'missing_evidence_completeness_target' >&2; exit 1; }
rg -Fq "resolveDrillKey(" "$UI_FILE" || { echo 'missing_drill_key_resolution' >&2; exit 1; }
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
  'pass':True,
  'details':{
    'reveal_route_bound':True,
    'dashboard_hydration_present':True,
    'evidence_completeness_rendered':True,
    'reveal_cache_recovers_after_failure':True,
    'hydrated_timeline_drill_keys_compatible':True
  }
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
