#!/usr/bin/env bash
# Verifies R-002: Tenant allowlist deny-all default
# 1. Unsets allowlist.
# 2. Rejects request with 503 exactly.
# 3. Records evidence.



REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"
EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_002_tenant_allowlist.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

APP_PORT=""
APP_PID=""
start_app() {
    echo "[*] Starting LedgerApi in background..."
    cd "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi"
    dotnet run > /tmp/ledger_api_r002a.log 2>&1 &
    APP_PID=$!
    sleep 3
    for i in {1..30}; do
        APP_PORT=$(grep "Now listening on:" /tmp/ledger_api_r002a.log | grep -oE '[0-9]+$' | head -n 1)
        if [[ -n "$APP_PORT" ]] && curl -s "http://127.0.0.1:$APP_PORT/health" >/dev/null; then
            echo "[*] App is up on port $APP_PORT."
            return 0
        fi
        sleep 1
    done
    echo "[!] App failed to start or port not detected. Logs:"
    cat /tmp/ledger_api_r002a.log
    exit 1
}

stop_app() {
    if [[ -n "$APP_PID" ]]; then
        echo "[*] Stopping LedgerApi (PID: $APP_PID)..."
        kill "$APP_PID" || true
        wait "$APP_PID" 2>/dev/null || true
    fi
}

task_id="R-002"
declare -a checks=()
status="PASS"
deny_all_when_unconfigured=false
returns_503_on_unconfigured_allowlist=false

echo "[*] Booting app WITHOUT tenant allowlist to test deny-all posture"
unset SYMPHONY_KNOWN_TENANTS
# TSK-P1-TEN-RDY: Force production profile to use EnvVarTenantReadinessProbe.
# This ensures the test validates the env-var path, not the DB-backed pilot-demo path.
export SYMPHONY_RUNTIME_PROFILE="production"

export INGRESS_API_KEY="test-ingress-key-123"
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"
start_app
trap stop_app EXIT

# 1. Probe the startup posture via combined /health
export INGRESS_API_KEY="test-ingress-key-123"
health_resp=$(curl -s -f "http://127.0.0.1:$APP_PORT/health")
health_resp_escaped=$(echo "$health_resp" | jq -R -s -c '.')
is_configured=$(echo "$health_resp" | jq -r '.tenant_allowlist_configured')

if [[ "$is_configured" == "false" ]]; then
    checks+=("{\"id\":\"verify-startup-posture-configured-false\",\"description\":\"Verify health endpoint advertises tenant_allowlist_configured=false\",\"status\":\"PASS\",\"details\":{\"raw_response\":$health_resp_escaped}}")
else
    status="FAIL"
    checks+=("{\"id\":\"verify-startup-posture-configured-false\",\"description\":\"Verify health endpoint advertises tenant_allowlist_configured=false\",\"status\":\"FAIL\",\"details\":{\"raw_response\":$health_resp_escaped}}")
fi

# 2. Send tenant-scoped request expecting 503
# TSK-P1-TEN-RDY: No auth headers needed — the TenantReadinessMiddleware returns 503
# BEFORE any authentication check runs. This is the key invariant being verified:
# system readiness (503) takes precedence over authentication (401/403).
http_code=$(curl -s -w "%{http_code}" -o /tmp/r002_resp.json -X GET -H "x-tenant-id: generic-tenant" "http://127.0.0.1:$APP_PORT/v1/evidence-packs/test-123")
resp_body=$(cat /tmp/r002_resp.json)
error_code=$(echo "$resp_body" | jq -r '.error_code')

if [[ "$http_code" == "503" && "$error_code" == "TENANT_ALLOWLIST_UNCONFIGURED" ]]; then
    returns_503_on_unconfigured_allowlist=true
    deny_all_when_unconfigured=true
    checks+=("{\"id\":\"verify-endpoint-503\",\"description\":\"Verify tenant-scoped endpoint returns 503 exactly when unconfigured\",\"status\":\"PASS\",\"details\":{\"http_code\":503,\"error_code\":\"$error_code\"}}")
else
    status="FAIL"
    checks+=("{\"id\":\"verify-endpoint-503\",\"description\":\"Verify tenant-scoped endpoint returns 503 exactly when unconfigured\",\"status\":\"FAIL\",\"details\":{\"http_code\":\"$http_code\",\"error_code\":\"$error_code\",\"body\":\"$resp_body\"}}")
fi

stop_app

checks_json="["$(IFS=,; echo "${checks[*]}")"]"
checks_json=$(echo "$checks_json" | sed 's/\[,/[/g' | sed 's/,,/,/g')
# Preserve previous state for the other test flags in JSON
cat <<EOF > "$EVIDENCE_FILE"
{
  "task_id": "R-002",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": $checks_json,
  "deny_all_when_unconfigured": $deny_all_when_unconfigured,
  "returns_503_on_unconfigured_allowlist": $returns_503_on_unconfigured_allowlist,
  "unknown_tenant_rejected": false,
  "known_tenant_accepted": false
}
EOF

echo "[*] Evidence file successfully generated: $EVIDENCE_FILE"
if [[ "$status" == "FAIL" ]]; then
    echo "[!] Verification FAILED. See evidence file."
    exit 1
else
    echo "[+] Verification PASSED."
fi
