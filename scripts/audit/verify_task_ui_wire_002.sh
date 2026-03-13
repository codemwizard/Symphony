#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-002"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
FALLBACK_FILE="$ROOT_DIR/src/supervisory-dashboard/data/supervisory_hybrid_fallback.json"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_002_adapter_alignment.json}"
[[ -f "$UI_FILE" ]] || { echo "missing_ui:$UI_FILE" >&2; exit 1; }
[[ -f "$FALLBACK_FILE" ]] || { echo "missing_fallback_fixture:$FALLBACK_FILE" >&2; exit 1; }
rg -Fq "const DATA_MODE = (window.SYMPHONY_UI_CONTEXT?.dataMode || 'HYBRID');" "$UI_FILE" || { echo 'wrong_default_data_mode' >&2; exit 1; }
rg -Fq "const SYMPHONY_API_BASE = '/v1';" "$UI_FILE" || { echo 'wrong_api_base' >&2; exit 1; }
! rg -Fq '/api/v1' "$UI_FILE" || { echo 'legacy_api_base_remaining' >&2; exit 1; }
rg -Fq 'x-tenant-id' "$UI_FILE" || { echo 'missing_tenant_header_handling' >&2; exit 1; }
rg -Fq 'Demo-backed fallback active' "$UI_FILE" || { echo 'missing_explicit_hybrid_fallback_label' >&2; exit 1; }
rg -Fq '__SYMPHONY_UI_CONTEXT__' "$UI_FILE" || { echo 'missing_ui_context_template_placeholder' >&2; exit 1; }
rg -Fq '__SYMPHONY_HYBRID_FALLBACK__' "$UI_FILE" || { echo 'missing_hybrid_fallback_template_placeholder' >&2; exit 1; }
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -Fq 'Replace("__SYMPHONY_UI_CONTEXT__"' "$PROGRAM_FILE" || { echo 'missing_ui_context_injection' >&2; exit 1; }
rg -Fq 'Replace("__SYMPHONY_HYBRID_FALLBACK__"' "$PROGRAM_FILE" || { echo 'missing_fallback_injection' >&2; exit 1; }
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$FALLBACK_FILE"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path, fallback_file = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
with open(fallback_file, encoding='utf-8') as fh:
    fallback = json.load(fh)
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-002-ADAPTER-ALIGNMENT',
  'task_id':task_id,
  'timestamp_utc':os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True,
  'details':{
    'api_base_v1':True,
    'hybrid_default':True,
    'tenant_header_handling':True,
    'explicit_fallback_labeling':True,
    'fallback_fixture_keys':sorted(fallback.keys())
  }
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
