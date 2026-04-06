#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-007"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_007_export.json}"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
rg -Fq 'app.MapPost("/v1/supervisory/programmes/{programId}/export"' "$PROGRAM_FILE" || { echo 'missing_export_route' >&2; exit 1; }
rg -Fq 'deterministic_fingerprint' "$PROGRAM_FILE" || { echo 'missing_export_fingerprint' >&2; exit 1; }
rg -Fq '/pilot-demo/artifacts/reporting_pack_sample.json' "$PROGRAM_FILE" || { echo 'missing_export_json_artifact_route' >&2; exit 1; }
rg -Fq '/pilot-demo/artifacts/reporting_pack_sample.pdf' "$PROGRAM_FILE" || { echo 'missing_export_pdf_artifact_route' >&2; exit 1; }
rg -Fq 'exportProgrammeReport(programId)' "$UI_FILE" || { echo 'missing_export_adapter_method' >&2; exit 1; }

TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  if [[ -f "$TMP_DIR/orig_reporting_pack_sample.json" ]]; then
    cp "$TMP_DIR/orig_reporting_pack_sample.json" "$ROOT_DIR/evidence/phase1/reporting_pack_sample.json"
  else
    rm -f "$ROOT_DIR/evidence/phase1/reporting_pack_sample.json"
  fi
  if [[ -f "$TMP_DIR/orig_reporting_pack_sample.pdf" ]]; then
    cp "$TMP_DIR/orig_reporting_pack_sample.pdf" "$ROOT_DIR/evidence/phase1/reporting_pack_sample.pdf"
  else
    rm -f "$ROOT_DIR/evidence/phase1/reporting_pack_sample.pdf"
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PORT=5188
BASE_URL="http://127.0.0.1:${PORT}"
export SYMPHONY_RUNTIME_PROFILE=pilot-demo
export SYMPHONY_ENV=ci
export INGRESS_API_KEY=demo-evidence-key
export ADMIN_API_KEY=demo-admin-key
export SYMPHONY_KNOWN_TENANTS=11111111-1111-1111-1111-111111111111
export DEMO_EVIDENCE_LINK_SIGNING_KEY=test-evidence-signing
export DEMO_INSTRUCTION_SIGNING_KEY=test-instruction-signing
export EVIDENCE_SIGNING_KEY=test-evidence-signing

if [[ -f "$ROOT_DIR/evidence/phase1/reporting_pack_sample.json" ]]; then
  cp "$ROOT_DIR/evidence/phase1/reporting_pack_sample.json" "$TMP_DIR/orig_reporting_pack_sample.json"
fi
if [[ -f "$ROOT_DIR/evidence/phase1/reporting_pack_sample.pdf" ]]; then
  cp "$ROOT_DIR/evidence/phase1/reporting_pack_sample.pdf" "$TMP_DIR/orig_reporting_pack_sample.pdf"
fi

dotnet run --no-launch-profile --project "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" --urls "$BASE_URL" >"$TMP_DIR/server.log" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 60); do
  if curl -fsS "$BASE_URL/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -fsS "$BASE_URL/health" >/dev/null

ROUTE_JSON="$TMP_DIR/route.json"
curl -fsS -X POST \
  -H 'x-api-key: demo-evidence-key' \
  -H 'x-tenant-id: 11111111-1111-1111-1111-111111111111' \
  "$BASE_URL/v1/supervisory/programmes/PGM-ZAMBIA-GRN-001/export" \
  -o "$ROUTE_JSON"

ROUTE_FP="$(python3 - <<'PY' "$ROUTE_JSON"
import json, sys
print(json.loads(open(sys.argv[1], encoding='utf-8').read()).get("deterministic_fingerprint",""))
PY
)"

bash "$ROOT_DIR/scripts/dev/generate_programme_reporting_pack.sh" "$TMP_DIR"
GEN_FP="$(python3 - <<'PY' "$TMP_DIR/reporting_pack_sample.json"
import json, sys
print(json.loads(open(sys.argv[1], encoding='utf-8').read()).get("deterministic_fingerprint",""))
PY
)"

[[ -n "$ROUTE_FP" && "$ROUTE_FP" == "$GEN_FP" ]] || { echo "export_route_fingerprint_mismatch" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$ROUTE_FP"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence_path, route_fp = sys.argv[1:]
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
out.write_text(json.dumps({
  'check_id':'TASK-UI-WIRE-007-EXPORT',
  'task_id':task_id,
  'timestamp_utc':os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
  'git_sha':sha,
  'status':'PASS',
  'pass':True,
  'details':{
    'http_route_verified':True,
    'deterministic_fingerprint':route_fp
  }
}, indent=2)+"\n", encoding='utf-8')
print(f'Evidence written: {out}')
PY
