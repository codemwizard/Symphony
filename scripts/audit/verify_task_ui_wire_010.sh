#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-010"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_010_success_gate_panel.json}"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
DEMO011_EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_demo_011_pilot_success_criteria_gate.json"
[[ -f "$DEMO011_EVIDENCE" ]] || { echo "missing_required_evidence:$DEMO011_EVIDENCE" >&2; exit 1; }
for pattern in 'getPilotSuccessPanel()' 'loadPilotSuccessPanel()' 'pilotSuccessPanel'; do
  rg -Fq "$pattern" "$UI_FILE" || { echo "missing_ui_pattern:$pattern" >&2; exit 1; }
done
TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
export SYMPHONY_RUNTIME_PROFILE=pilot-demo
export SYMPHONY_ENV=ci
export INGRESS_API_KEY=demo-evidence-key
export SYMPHONY_KNOWN_TENANTS=11111111-1111-1111-1111-111111111111
PORT=5192
BASE_URL="http://127.0.0.1:${PORT}"
dotnet run --no-launch-profile --project "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" --urls "$BASE_URL" >"$TMP_DIR/server.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 60); do
  if curl -fsS "$BASE_URL/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -fsS "$BASE_URL/health" >/dev/null
PANEL_JSON="$TMP_DIR/pilot_success.json"
curl -fsS -H 'x-api-key: demo-evidence-key' -H 'x-tenant-id: 11111111-1111-1111-1111-111111111111' \
  "$BASE_URL/pilot-demo/api/pilot-success" -o "$PANEL_JSON"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$PANEL_JSON" "$DEMO011_EVIDENCE"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path, panel_json, demo011_evidence = sys.argv[1:]
panel = json.loads(Path(panel_json).read_text(encoding='utf-8'))
demo = json.loads(Path(demo011_evidence).read_text(encoding='utf-8'))
criteria = panel.get('criteria') or []
required_top = ['status','source_of_truth','gate_status','pass_count','fail_count','pending_count','criteria']
missing = [k for k in required_top if k not in panel]
expected_gate = demo.get('status')
status = 'PASS' if not missing and panel.get('gate_status') == expected_gate and len(criteria) >= 5 else 'FAIL'
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
payload = {
  'check_id': 'TASK-UI-WIRE-010-PILOT-SUCCESS-PANEL',
  'task_id': task_id,
  'timestamp_utc': os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
  'git_sha': sha,
  'status': status,
  'pass': status == 'PASS',
  'details': {
    'missing_top_level_fields': missing,
    'criteria_count': len(criteria),
    'gate_status_from_route': panel.get('gate_status'),
    'gate_status_from_demo_011': expected_gate,
    'source_of_truth': panel.get('source_of_truth')
  }
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
print(f'Evidence written: {out}')
if status != 'PASS':
    raise SystemExit(f'pilot_success_panel_validation_failed:{payload["details"]}')
PY
