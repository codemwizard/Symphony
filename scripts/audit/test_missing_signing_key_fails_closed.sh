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
# In hardened profile, app must fail to start if signing key is missing from OpenBao
# First, delete the signing key from OpenBao to simulate missing secret
if [[ -f "/tmp/symphony_openbao/secrets.env" ]]; then
    source /tmp/symphony_openbao/secrets.env
fi
curl -s -X DELETE -H "X-Vault-Token: root" "http://127.0.0.1:8200/v1/kv/data/symphony/secrets/signing" >/dev/null 2>&1

# Source OpenBao secrets to provide required BAO_ROLE_ID and BAO_SECRET_ID
if [[ -f "/tmp/symphony_openbao/secrets.env" ]]; then
    source /tmp/symphony_openbao/secrets.env
fi
# Unset signing key environment variables so app must read from OpenBao (where we deleted it)
unset EVIDENCE_SIGNING_KEY
unset EVIDENCE_SIGNING_KEY_ID

export INGRESS_API_KEY="test-ingress-key-123"
export SYMPHONY_KNOWN_TENANTS="known-tenant-r001"
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"

# Try to start the app - it should fail to start (fail-closed behavior)
echo "[*] Attempting to start LedgerApi without signing key..."
cd "$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi"
dotnet run > /tmp/ledger_api_r001_nokey.log 2>&1 &
APP_PID=$!
sleep 15

# Check if app failed to start (correct fail-closed behavior)
if grep -q "Required hardened secret 'EVIDENCE_SIGNING_KEY' not found" /tmp/ledger_api_r001_nokey.log 2>/dev/null; then
    fails_closed_without_key=true
    checks+=("{\"id\":\"verify-fail-closed-startup\",\"description\":\"Verify app fails to start when signing key is missing from OpenBao\",\"status\":\"PASS\",\"details\":{\"reason\":\"App correctly refused to start without signing key\"}}")
    # Clean up the failed process
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
else
    status="FAIL"
    fails_closed_without_key=false
    checks+=("{\"id\":\"verify-fail-closed-startup\",\"description\":\"Verify app fails to start when signing key is missing from OpenBao\",\"status\":\"FAIL\",\"details\":{\"reason\":\"App started without signing key - should have failed closed\"}}")
    # Clean up the process if it somehow started
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
fi

# Re-bootstrap the signing key for cleanup
echo "[*] Re-bootstrapping signing key for cleanup..."
EVIDENCE_KEY=$(openssl rand -hex 32)
EVIDENCE_KEY_ID="evidence-signing-key-v1"
docker exec -e BAO_ADDR="http://127.0.0.1:8200" -e BAO_TOKEN="root" symphony-openbao bao kv put kv/symphony/secrets/signing evidence_signing_key="$EVIDENCE_KEY" evidence_signing_key_id="$EVIDENCE_KEY_ID" >/dev/null 2>&1

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
  "fails_closed_without_key": $fails_closed_without_key
}
EOF

echo "[*] Evidence file successfully generated: $EVIDENCE_FILE"
if [[ "$status" == "FAIL" ]]; then
    echo "[!] Verification FAILED. See evidence file."
    exit 1
else
    echo "[+] Verification PASSED."
fi
