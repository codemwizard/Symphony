#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-006"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_006_instruction_detail.json}"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
DOC_FILE="$ROOT_DIR/docs/operations/SUPERVISORY_REVEAL_API_V2.md"
rg -Fq 'app.MapGet("/v1/supervisory/instructions/{instructionId}/detail"' "$PROGRAM_FILE" || { echo 'missing_detail_route' >&2; exit 1; }
rg -Fq 'fetch(`${SYMPHONY_API_BASE}/supervisory/instructions/${encodeURIComponent(instructionId)}/detail`' "$UI_FILE" || { echo 'missing_detail_route_fetch' >&2; exit 1; }
rg -Fq 'ack_interrupt_projection_state' "$UI_FILE" || { echo 'missing_ack_projection_ui' >&2; exit 1; }
rg -Fq 'GET /v1/supervisory/instructions/{instructionId}/detail' "$DOC_FILE" || { echo 'missing_detail_doc' >&2; exit 1; }
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
PORT=5190
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
DETAIL_JSON="$TMP_DIR/detail.json"
curl -fsS \
  -H 'x-api-key: demo-evidence-key' \
  -H 'x-tenant-id: 11111111-1111-1111-1111-111111111111' \
  "$BASE_URL/v1/supervisory/instructions/SYM-2026-00041/detail" \
  -o "$DETAIL_JSON"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$DETAIL_JSON"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path, detail_json = sys.argv[1:]
detail = json.loads(Path(detail_json).read_text(encoding='utf-8'))
proof_rows = detail.get('proof_rows') or []
raw_artifacts = detail.get('raw_artifacts') or []
required_top = ['instruction_id', 'instruction_status', 'proof_rows', 'raw_artifacts', 'supplier_policy_context', 'acknowledgement_state', 'escalation_tier', 'supervisor_interrupt_state', 'ack_interrupt_projection_state']
missing_top = [key for key in required_top if key not in detail]
proof_types = {row.get('proof_type_id') for row in proof_rows}
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
payload = {
    'check_id': 'TASK-UI-WIRE-006-INSTRUCTION-DETAIL',
    'task_id': task_id,
    'timestamp_utc': os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
    'git_sha': sha,
    'status': 'PASS' if not missing_top and len(raw_artifacts) >= 4 and {'PT-001','PT-002','PT-003','PT-004'}.issubset(proof_types) else 'FAIL',
    'pass': not missing_top and len(raw_artifacts) >= 4 and {'PT-001','PT-002','PT-003','PT-004'}.issubset(proof_types),
    'details': {
        'missing_top_level_fields': missing_top,
        'raw_artifact_count': len(raw_artifacts),
        'proof_types': sorted(proof_types),
        'ack_interrupt_projection_state': detail.get('ack_interrupt_projection_state')
    }
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
print(f'Evidence written: {out}')
if payload['status'] != 'PASS':
    raise SystemExit(f'detail_route_validation_failed:{payload["details"]}')
PY
