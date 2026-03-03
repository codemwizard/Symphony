#!/usr/bin/env bash
# Verifies R-002: Tenant allowlist unknown reject
# 1. Configures allowlist.
# 2. Rejects request with 403.
# 3. Accepts request with 200 for known tenant.
# 4. Merges evidence with previous run.



REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"
EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_002_tenant_allowlist.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

APP_PORT=""
APP_PID=""
start_app() {
    echo "[*] Starting LedgerApi in background..."
    cd "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi"
    dotnet run > /tmp/ledger_api_r002b.log 2>&1 &
    APP_PID=$!
    sleep 3
    for i in {1..10}; do
        APP_PORT=$(grep "Now listening on:" /tmp/ledger_api_r002b.log | grep -oE '[0-9]+$' | head -n 1)
        if [[ -n "$APP_PORT" ]] && curl -s "http://127.0.0.1:$APP_PORT/health" >/dev/null; then
            echo "[*] App is up on port $APP_PORT."
            return 0
        fi
        sleep 1
    done
    echo "[!] App failed to start or port not detected. Logs:"
    cat /tmp/ledger_api_r002b.log
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
unknown_tenant_rejected=false
known_tenant_accepted=false

# Load what we already set from the deny-all test if it ran
if [[ -f "$EVIDENCE_FILE" ]]; then
    deny_val=$(jq -r '.deny_all_when_unconfigured // false' "$EVIDENCE_FILE")
    [[ "$deny_val" == "true" ]] && deny_all_when_unconfigured=true || deny_all_when_unconfigured=false

    ret_val=$(jq -r '.returns_503_on_unconfigured_allowlist // false' "$EVIDENCE_FILE")
    [[ "$ret_val" == "true" ]] && returns_503_on_unconfigured_allowlist=true || returns_503_on_unconfigured_allowlist=false
    
    prev_checks=$(jq -c '.checks[]? // empty' "$EVIDENCE_FILE")
    if [[ -n "$prev_checks" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && checks+=("$line")
        done <<< "$prev_checks"
    fi
    prev_status=$(jq -r '.status // "FAIL"' "$EVIDENCE_FILE")
    if [[ "$prev_status" == "FAIL" ]]; then
       status="FAIL"
    fi
else
    deny_all_when_unconfigured=false
    returns_503_on_unconfigured_allowlist=false
fi

echo "[*] Booting app WITH tenant allowlist to test 403 posture"
export SYMPHONY_KNOWN_TENANTS="known-tenant-foo,known-tenant-bar"

export INGRESS_API_KEY="test-ingress-key-123"
start_app
trap stop_app EXIT

# 1. Probe the startup posture via combined /health
health_resp=$(curl -s -f "http://127.0.0.1:$APP_PORT/health")
health_resp_escaped=$(echo "$health_resp" | jq -R -s -c '.')
is_configured=$(echo "$health_resp" | jq -r '.tenant_allowlist_configured')

if [[ "$is_configured" == "true" ]]; then
    checks+=("{\"id\":\"verify-startup-posture-configured-true\",\"description\":\"Verify health endpoint advertises tenant_allowlist_configured=true\",\"status\":\"PASS\",\"details\":{\"raw_response\":$health_resp_escaped}}")
else
    status="FAIL"
    checks+=("{\"id\":\"verify-startup-posture-configured-true\",\"description\":\"Verify health endpoint advertises tenant_allowlist_configured=true\",\"status\":\"FAIL\",\"details\":{\"raw_response\":$health_resp_escaped}}")
fi

# 2. Send tenant-scoped request expecting 403 (allowlist configured, but tenant unknown)
http_code=$(curl -s -w "%{http_code}" -o /tmp/r002_resp.json -X GET -H "x-api-key: test-ingress-key-123" -H "x-tenant-id: generic-tenant" "http://127.0.0.1:$APP_PORT/v1/evidence-packs/test-123")
resp_body=$(cat /tmp/r002_resp.json)
error_code=$(echo "$resp_body" | jq -r '.error_code')

if [[ "$http_code" == "403" && "$error_code" == "FORBIDDEN_UNKNOWN_TENANT" ]]; then
    unknown_tenant_rejected=true
    checks+=("{\"id\":\"verify-endpoint-403\",\"description\":\"Verify tenant-scoped endpoint returns 403 when tenant unknown\",\"status\":\"PASS\",\"details\":{\"http_code\":403,\"error_code\":\"$error_code\"}}")
else
    status="FAIL"
    checks+=("{\"id\":\"verify-endpoint-403\",\"description\":\"Verify tenant-scoped endpoint returns 403 when tenant unknown\",\"status\":\"FAIL\",\"details\":{\"http_code\":\"$http_code\",\"error_code\":\"$error_code\",\"body\":\"$resp_body\"}}")
fi

# 3. Send known tenant expecting 200 (or 404 for missing resource, but not 403/503)
http_code_known=$(curl -s -w "%{http_code}" -o /dev/null -X GET -H "x-api-key: test-ingress-key-123" -H "x-tenant-id: known-tenant-bar" "http://127.0.0.1:$APP_PORT/v1/evidence-packs/test-123")

if [[ "$http_code_known" != "403" && "$http_code_known" != "503" ]]; then
    known_tenant_accepted=true
    checks+=("{\"id\":\"verify-endpoint-known-allowed\",\"description\":\"Verify tenant-scoped endpoint allows known tenant\",\"status\":\"PASS\",\"details\":{\"http_code\":$http_code_known}}")
else
    status="FAIL"
    checks+=("{\"id\":\"verify-endpoint-known-allowed\",\"description\":\"Verify tenant-scoped endpoint allows known tenant\",\"status\":\"FAIL\",\"details\":{\"http_code\":\"$http_code_known\"}}")
fi

stop_app

checks_json="["$(IFS=,; echo "${checks[*]}")"]"
checks_json=$(echo "$checks_json" | sed 's/\[,/[/g' | sed 's/,,/,/g')
cat <<EOF > "$EVIDENCE_FILE"
{
  "task_id": "R-002",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": $checks_json,
  "deny_all_when_unconfigured": $deny_all_when_unconfigured,
  "returns_503_on_unconfigured_allowlist": $returns_503_on_unconfigured_allowlist,
  "unknown_tenant_rejected": $unknown_tenant_rejected,
  "known_tenant_accepted": $known_tenant_accepted
}
EOF

echo "[*] Evidence file successfully generated: $EVIDENCE_FILE"
if [[ "$status" == "FAIL" ]]; then
    echo "[!] Verification FAILED. See evidence file."
    exit 1
else
    echo "[+] Verification PASSED."
fi
