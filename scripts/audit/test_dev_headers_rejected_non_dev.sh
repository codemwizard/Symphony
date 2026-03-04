#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"

EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_012_dev_header_gate.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

APP_PID=""
APP_PORT=""
LOG_FILE="/tmp/ledger_api_r012.log"

cleanup() {
  if [[ -n "$APP_PID" ]]; then
    kill "$APP_PID" >/dev/null 2>&1 || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

start_app() {
  pushd "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi" >/dev/null
  SYMPHONY_ENV=production \
  INGRESS_API_KEY="r012-test-ingress-key" \
  ADMIN_API_KEY="r012-test-admin-key" \
  SYMPHONY_KNOWN_TENANTS="known-tenant-r012" \
  dotnet run >"$LOG_FILE" 2>&1 &
  APP_PID=$!
  popd >/dev/null

  for _ in {1..30}; do
    APP_PORT="$(rg -No 'Now listening on: .*:([0-9]+)$' "$LOG_FILE" -r '$1' | tail -n 1 || true)"
    if [[ -n "$APP_PORT" ]] && curl -fsS "http://127.0.0.1:$APP_PORT/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Failed to start app for R-012. Logs:" >&2
  cat "$LOG_FILE" >&2
  exit 1
}

start_app

payload='{"instruction_id":"r012-inst","participant_id":"part-1","idempotency_key":"idemp-r012","rail_type":"ZIPSS","tenant_id":"known-tenant-r012","payload":{"type":"test"}}'
http_code=$(curl -s -o /tmp/r012_resp.json -w "%{http_code}" \
  -X POST "http://127.0.0.1:$APP_PORT/v1/ingress/instructions" \
  -H "Content-Type: application/json" \
  -H "x-api-key: r012-test-ingress-key" \
  -H "x-tenant-id: known-tenant-r012" \
  -H "x-participant-id: part-1" \
  -H "x-symphony-force-attestation-fail: 1" \
  -d "$payload")

error_code="$(jq -r '.error_code // empty' /tmp/r012_resp.json 2>/dev/null || true)"

status="PASS"
dev_headers_gated=true
if [[ "$http_code" != "403" || "$error_code" != "FORBIDDEN_DEV_HEADER" ]]; then
  status="FAIL"
  dev_headers_gated=false
fi

cat > "$EVIDENCE_FILE" <<JSON
{
  "task_id": "R-012",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": [
    {
      "id": "R-012-A1",
      "description": "dev-only headers are rejected outside dev/ci",
      "status": "$status",
      "details": {
        "http_code": "$http_code",
        "error_code": "$error_code"
      }
    }
  ],
  "dev_headers_gated": $dev_headers_gated
}
JSON

echo "Evidence: $EVIDENCE_FILE"
if [[ "$status" != "PASS" ]]; then
  echo "❌ Dev header gate failed (http=$http_code error=$error_code)"
  exit 1
fi

echo "✅ Dev header gate verified"
