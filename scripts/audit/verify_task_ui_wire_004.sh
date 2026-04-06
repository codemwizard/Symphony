#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-004"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_004_operator_action_wiring.json}"
[[ -f "$PROGRAM_FILE" ]] || { echo "missing_program:$PROGRAM_FILE" >&2; exit 1; }
[[ -f "$UI_FILE" ]] || { echo "missing_ui:$UI_FILE" >&2; exit 1; }
! rg -Fq 'adminApiKey = Environment.GetEnvironmentVariable("SYMPHONY_UI_ADMIN_API_KEY")' "$PROGRAM_FILE" || { echo 'admin_key_exposed_in_ui_context' >&2; exit 1; }
! rg -Fq 'ctx.adminApiKey' "$UI_FILE" || { echo 'admin_key_used_in_client_context' >&2; exit 1; }
! rg -Fq 'x-admin-api-key' "$UI_FILE" || { echo 'client_sends_admin_api_key' >&2; exit 1; }
rg -Fq 'app.MapPost("/pilot-demo/api/evidence-links/issue"' "$PROGRAM_FILE" || { echo 'missing_evidence_link_proxy_route' >&2; exit 1; }
rg -Fq 'app.MapPost("/pilot-demo/api/instruction-files/generate"' "$PROGRAM_FILE" || { echo 'missing_instruction_generate_proxy_route' >&2; exit 1; }
rg -Fq 'app.MapPost("/v1/instruction-files/verify-ref"' "$PROGRAM_FILE" || { echo 'missing_instruction_verify_ref_route' >&2; exit 1; }
rg -Fq 'instruction_file_ref' "$PROGRAM_FILE" || { echo 'missing_instruction_file_ref_contract' >&2; exit 1; }
python3 - <<'PY' "$PROGRAM_FILE"
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding='utf-8')
start = text.find('app.MapPost("/pilot-demo/api/instruction-files/generate"')
if start < 0:
    raise SystemExit('missing_instruction_generate_proxy_route')
end = text.find('app.MapPost("/v1/instruction-files/verify"', start)
segment = text[start:end if end > start else None]
if 'AuthorizeAdminTenantOnboarding(httpContext)' not in segment:
    raise SystemExit('pilot_demo_generate_route_not_admin_guarded')
if 'AuthorizeEvidenceRead(httpContext)' in segment:
    raise SystemExit('pilot_demo_generate_route_uses_evidence_read')
PY
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence_path = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-004-OPERATOR-ACTIONS',
  'task_id':task_id,
  'timestamp_utc':os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True,
  'details':{
    'admin_secret_not_exposed_to_browser':True,
    'client_admin_header_absent':True,
    'privileged_proxy_routes_present':True,
    'browser_safe_verify_ref_route_present':True,
    'pilot_demo_generate_route_admin_guarded':True
  }
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
