#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-008"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_008_ack_interrupt.json}"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
READMODEL_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/ReadModels/SupervisoryRevealReadModelHandler.cs"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"

rg -Fq 'SupervisoryRevealReadModelHandler.Handle(tenantId, programId.Trim(), dataSource)' "$PROGRAM_FILE" || { echo 'missing_reveal_datasource_projection' >&2; exit 1; }
rg -Fq 'SupervisoryInstructionDetailReadModelHandler.Handle(tenantId, instructionId.Trim(), dataSource)' "$PROGRAM_FILE" || { echo 'missing_detail_datasource_projection' >&2; exit 1; }
for pattern in 'public.inquiry_state_machine' 'public.supervisor_approval_queue' 'public.supervisor_interrupt_audit_events' 'AWAITING_EXECUTION' 'ack_interrupt_projection_state'; do
  rg -Fq "$pattern" "$READMODEL_FILE" || { echo "missing_projection_pattern:$pattern" >&2; exit 1; }
done
for pattern in 'Acknowledgement State' 'Escalation Tier' 'Supervisor Interrupt' 'PENDING_TASK_UI_WIRE_008'; do
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
export EVIDENCE_LINK_SUBMISSIONS_FILE="$TMP_DIR/submissions.ndjson"
export DEMO_EXCEPTION_LOG_FILE="$TMP_DIR/exceptions.ndjson"
export SYMPHONY_RUNTIME_PROFILE=pilot-demo
export SYMPHONY_ENV=ci
export INGRESS_API_KEY=demo-evidence-key
export ADMIN_API_KEY=demo-admin-key
export SYMPHONY_KNOWN_TENANTS=11111111-1111-1111-1111-111111111111
export DEMO_EVIDENCE_LINK_SIGNING_KEY=test-evidence-signing
export DEMO_INSTRUCTION_SIGNING_KEY=test-instruction-signing

dotnet run --no-launch-profile --project "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj" -- --self-test-supervisory-read-models >"$TMP_DIR/selftest.log" 2>&1
PORT=5191
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
REVEAL_JSON="$TMP_DIR/reveal.json"
DETAIL_JSON="$TMP_DIR/detail.json"
curl -fsS -H 'x-api-key: demo-evidence-key' -H 'x-tenant-id: 11111111-1111-1111-1111-111111111111' \
  "$BASE_URL/v1/supervisory/programmes/program-a/reveal" -o "$REVEAL_JSON"
curl -fsS -H 'x-api-key: demo-evidence-key' -H 'x-tenant-id: 11111111-1111-1111-1111-111111111111' \
  "$BASE_URL/v1/supervisory/instructions/SYM-2026-00041/detail" -o "$DETAIL_JSON"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$REVEAL_JSON" "$DETAIL_JSON"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path, reveal_json, detail_json = sys.argv[1:]
reveal = json.loads(Path(reveal_json).read_text(encoding='utf-8'))
detail = json.loads(Path(detail_json).read_text(encoding='utf-8'))
proof_rows = reveal.get('proof_rows') or []
row = next((r for r in proof_rows if r.get('instruction_id') == 'SYM-2026-00041'), None)
required_reveal_fields = ['acknowledgement_state', 'escalation_tier', 'supervisor_interrupt_state', 'ack_interrupt_projection_state']
missing_row_fields = [k for k in required_reveal_fields if row is None or k not in row]
missing_detail_fields = [k for k in required_reveal_fields if k not in detail]
projection_state = detail.get('ack_interrupt_projection_state')
valid_projection = projection_state in {'LIVE_DB_PROJECTED', 'LIVE_DB_PROJECTED_NO_STATE', 'UNAVAILABLE_STORAGE_MODE_FILE', 'UNAVAILABLE_DB_LOOKUP_ERROR'}
status = 'PASS' if row and not missing_row_fields and not missing_detail_fields and valid_projection else 'FAIL'
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
payload = {
  'check_id': 'TASK-UI-WIRE-008-ACK-INTERRUPT-PROJECTION',
  'task_id': task_id,
  'timestamp_utc': os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
  'git_sha': sha,
  'status': status,
  'pass': status == 'PASS',
  'details': {
    'instruction_id': 'SYM-2026-00041',
    'reveal_missing_fields': missing_row_fields,
    'detail_missing_fields': missing_detail_fields,
    'acknowledgement_state': detail.get('acknowledgement_state'),
    'escalation_tier': detail.get('escalation_tier'),
    'supervisor_interrupt_state': detail.get('supervisor_interrupt_state'),
    'ack_interrupt_projection_state': projection_state,
  }
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
print(f'Evidence written: {out}')
if status != 'PASS':
    raise SystemExit(f'ack_interrupt_projection_validation_failed:{payload["details"]}')
PY
