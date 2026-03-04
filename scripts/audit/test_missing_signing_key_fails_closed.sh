#!/usr/bin/env bash
# Verifies R-001: Fail Hard on Missing Signing Keys
# 1. Scans for hardcoded literal dev keys
# 2. Uses Semgrep to ensure no `?? "literal"` fallback patterns exist for EVIDENCE_SIGNING_KEY
# 3. Boots app, tests /health for false capability
# 4. Calls signing endpoint and verifies 503 HTTP status and correct error payload



REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"
EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_001_signing_keys.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

APP_PORT=""
APP_PID=""
start_app() {
    echo "[*] Starting LedgerApi in background..."
    cd "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi"
    dotnet run > /tmp/ledger_api_r001.log 2>&1 &
    APP_PID=$!
    # Wait for the app to be responsive
    sleep 3
    for i in {1..10}; do
        APP_PORT=$(grep "Now listening on:" /tmp/ledger_api_r001.log | grep -oE '[0-9]+$' | head -n 1)
        if [[ -n "$APP_PORT" ]] && curl -s "http://127.0.0.1:$APP_PORT/health" >/dev/null; then
            echo "[*] App is up on port $APP_PORT."
            return 0
        fi
        sleep 1
    done
    echo "[!] App failed to start or port not detected. Logs:"
    cat /tmp/ledger_api_r001.log
    exit 1
}

stop_app() {
    if [[ -n "$APP_PID" ]]; then
        echo "[*] Stopping LedgerApi (PID: $APP_PID)..."
        kill "$APP_PID" || true
        wait "$APP_PID" 2>/dev/null || true
    fi
}

task_id="R-001"
# Ensure we map empty strings to jq compat representations
declare -a checks=()
status="PASS"
hardcoded_fallbacks_found=0
fails_closed_without_key=true
signing_capable_at_startup=false
signing_endpoint_returns_503_when_key_missing=false

echo "[*] Checking for hardcoded string literals: 'dev-signing-key'"
lit_count=$(rg --vimgrep 'dev-signing-key|phase1-reg-.*-dev-signing-key' "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs" | wc -l)
if [[ "$lit_count" -gt 0 ]]; then
    status="FAIL"
    hardcoded_fallbacks_found=$lit_count
    checks+=("{\"id\":\"verify-literal-keys-removed\",\"description\":\"Verify 'dev-signing-key' literals are removed\",\"status\":\"FAIL\",\"details\":{\"count\":$lit_count}}")
else
    checks+=("{\"id\":\"verify-literal-keys-removed\",\"description\":\"Verify 'dev-signing-key' literals are removed\",\"status\":\"PASS\",\"details\":{}}")
fi

echo "[*] Checking Semgrep blocklist for coalesce fallbacks on EVIDENCE_SIGNING_KEY"
export PATH="$HOME/.local/bin:$PATH"
if semgrep --config "$REPO_ROOT/security/semgrep/rules.yml" --error --quiet "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi"; then
    checks+=("{\"id\":\"verify-structural-fallbacks-removed\",\"description\":\"Verify ?? coalesce fallbacks are structurally removed\",\"status\":\"PASS\",\"details\":{}}")
else
    status="FAIL"
    hardcoded_fallbacks_found=$((hardcoded_fallbacks_found + 1))
    checks+=("{\"id\":\"verify-structural-fallbacks-removed\",\"description\":\"Verify ?? coalesce fallbacks are structurally removed\",\"status\":\"FAIL\",\"details\":{\"reason\":\"semgrep identified violations\"}}")
fi

echo "[*] Booting app WITHOUT signing keys to test fail-closed posture"
unset EVIDENCE_SIGNING_KEY
unset EVIDENCE_SIGNING_KEY_ID

export INGRESS_API_KEY="test-ingress-key-123"
export SYMPHONY_KNOWN_TENANTS="known-tenant-r001"
start_app
trap stop_app EXIT

# 1. Probe the startup posture via combined /health
health_resp=$(curl -s -f "http://127.0.0.1:$APP_PORT/health")
health_resp_escaped=$(echo "$health_resp" | jq -R -s -c '.')
is_present=$(echo "$health_resp" | jq -r '.signing_key_present')

if [[ "$is_present" == "false" ]]; then
    checks+=("{\"id\":\"verify-startup-posture-false\",\"description\":\"Verify health endpoint advertises signing_key_present=false\",\"status\":\"PASS\",\"details\":{\"raw_response\":$health_resp_escaped}}")
else
    status="FAIL"
    signing_capable_at_startup=true
    checks+=("{\"id\":\"verify-startup-posture-false\",\"description\":\"Verify health endpoint advertises signing_key_present=false\",\"status\":\"FAIL\",\"details\":{\"raw_response\":$health_resp_escaped}}")
fi

# 2. Probe the physical endpoint mapping to 503
http_code=$(curl -s -w "%{http_code}" -o /tmp/r001_resp.json -X GET -H "x-api-key: test-ingress-key-123" -H "x-tenant-id: known-tenant-r001" "http://127.0.0.1:$APP_PORT/v1/regulatory/reports/daily?date=2026-03-01")
resp_body=$(cat /tmp/r001_resp.json)
error_code=$(echo "$resp_body" | jq -r '.error_code')

if [[ "$http_code" == "503" && "$error_code" == "SIGNING_CAPABILITY_MISSING" ]]; then
    signing_endpoint_returns_503_when_key_missing=true
    checks+=("{\"id\":\"verify-endpoint-503\",\"description\":\"Verify regulatory endpoint returns 503 exactly\",\"status\":\"PASS\",\"details\":{\"http_code\":503,\"error_code\":\"$error_code\"}}")
else
    status="FAIL"
    fails_closed_without_key=false
    checks+=("{\"id\":\"verify-endpoint-503\",\"description\":\"Verify regulatory endpoint returns 503 exactly\",\"status\":\"FAIL\",\"details\":{\"http_code\":\"$http_code\",\"error_code\":\"$error_code\",\"body\":\"$resp_body\"}}")
fi

stop_app

# Formatting the JSON arrays inside the main evidence writer function
checks_json="["$(IFS=,; echo "${checks[*]}")"]"
checks_json=$(echo "$checks_json" | sed 's/\[,/[/g')

cat <<EOF > "$EVIDENCE_FILE"
{
  "task_id": "R-001",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": $checks_json,
  "hardcoded_fallbacks_found": $hardcoded_fallbacks_found,
  "fails_closed_without_key": $fails_closed_without_key,
  "signing_capable_at_startup": $signing_capable_at_startup,
  "signing_endpoint_returns_503_when_key_missing": $signing_endpoint_returns_503_when_key_missing
}
EOF

echo "[*] Evidence file successfully generated: $EVIDENCE_FILE"
if [[ "$status" == "FAIL" ]]; then
    echo "[!] Verification FAILED. See evidence file."
    exit 1
else
    echo "[+] Verification PASSED."
fi
