#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-026"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_026_server_side_admin_proxy.json}"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
GUIDE="$ROOT_DIR/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"
SOT="$ROOT_DIR/docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md"

! rg -Fq 'SYMPHONY_UI_ADMIN_API_KEY' "$PROGRAM_FILE" || { echo "admin_key_exposed_in_program" >&2; exit 1; }
! rg -Fq 'x-admin-api-key' "$UI_FILE" || { echo "browser_sends_admin_key" >&2; exit 1; }
rg -Fq 'PilotDemoOperatorCookieName' "$PROGRAM_FILE" || { echo "missing_operator_cookie_session" >&2; exit 1; }
rg -Fq 'TryValidatePilotDemoOperatorCookie' "$PROGRAM_FILE" || { echo "missing_operator_cookie_validation" >&2; exit 1; }
rg -Fq 'app.MapPost("/pilot-demo/api/evidence-links/issue"' "$PROGRAM_FILE" || { echo "missing_pilot_demo_evidence_link_route" >&2; exit 1; }
rg -Fq 'app.MapPost("/pilot-demo/api/instruction-files/generate"' "$PROGRAM_FILE" || { echo "missing_pilot_demo_instruction_generate_route" >&2; exit 1; }
rg -Fq 'ApiAuthorization.AuthorizeEvidenceRead(httpContext, secrets)' "$PROGRAM_FILE" || { echo "missing_browser_read_auth" >&2; exit 1; }
rg -Fq 'server-issued operator session boundary' "$SOT" || { echo "missing_operator_session_doc" >&2; exit 1; }
rg -Fq 'ADMIN_API_KEY` is server-side only' "$GUIDE" || { echo "missing_server_side_admin_doc" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence = sys.argv[1:]
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
Path(evidence).parent.mkdir(parents=True, exist_ok=True)
payload = {
    "check_id": "TSK-P1-DEMO-026-SERVER-SIDE-ADMIN-PROXY",
    "task_id": task_id,
    "timestamp_utc": os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
    "git_sha": sha,
    "status": "PASS",
    "pass": True,
    "details": {
        "admin_secret_browser_exposed": False,
        "browser_sends_admin_header": False,
        "pilot_demo_operator_session_present": True,
        "same_origin_proxy_routes_present": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
