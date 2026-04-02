#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---

echo "==> GF-W1-FNC-002 Monitoring Ingestion Functions Verification"

EVIDENCE_DIR="evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/gf_fnc_002.json"
mkdir -p "$EVIDENCE_DIR"

if [[ -z "${DATABASE_URL:-}" ]]; then
    echo "ERROR: DATABASE_URL is required" >&2
    exit 1
fi

# Extract DB name from URL
DB_NAME=$(echo "$DATABASE_URL" | sed 's/.*\///')
ADMIN_USER="symphony_admin"

# Function signatures to check
declare -A FUNCTIONS=(
    ["record_monitoring_record"]="p_tenant_id uuid, p_project_id uuid, p_record_type text, p_record_payload_json jsonb"
    ["query_monitoring_records"]="p_tenant_id uuid, p_project_id uuid"
    ["get_monitoring_record_payload"]="p_tenant_id uuid, p_monitoring_record_id uuid"
    ["validate_payload_against_schema"]="p_payload jsonb, p_payload_schema_reference_id uuid"
)

PROBE_RESULTS=()
ALL_PASSED=true

for func in "${!FUNCTIONS[@]}"; do
    echo "🔎 Probing function: $func..."
    
    # Query database for function existence and properties
    QUERY=$(cat <<EOF
SELECT 
    CASE WHEN p.prosecdef THEN 'passed' ELSE 'failed' END as security_definer,
    CASE WHEN 'search_path=pg_catalog, public' = ANY(p.proconfig) THEN 'passed' ELSE 'failed' END as search_path_hardened
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = '$func';
EOF
)

    RESULT=$(docker exec symphony-postgres psql -U "$ADMIN_USER" -d "$DB_NAME" -t -A -c "$QUERY")
    
    if [[ -z "$RESULT" ]]; then
        echo "  ❌ FAIL: $func not found in database"
        PROBE_RESULTS+=("{\"probe\": \"$func\", \"status\": \"FAIL\", \"reason\": \"function_missing\"}")
        ALL_PASSED=false
    else
        SEC_DEF=$(echo "$RESULT" | cut -d'|' -f1)
        SEARCH_PATH=$(echo "$RESULT" | cut -d'|' -f2)
        
        if [[ "$SEC_DEF" == "passed" && "$SEARCH_PATH" == "passed" ]]; then
            echo "  ✅ PASS: $func is hardened"
            PROBE_RESULTS+=("{\"probe\": \"$func\", \"status\": \"PASS\"}")
        else
            echo "  ❌ FAIL: $func hardening violation (sec_def=$SEC_DEF, path=$SEARCH_PATH)"
            PROBE_RESULTS+=("{\"probe\": \"$func\", \"status\": \"FAIL\", \"reason\": \"sec_def=$SEC_DEF, path=$SEARCH_PATH\"}")
            ALL_PASSED=false
        fi
    fi
done

# Output signed evidence
STATUS="PASS"
[[ "$ALL_PASSED" == "false" ]] && STATUS="FAIL"

PROBES_JSON=$(IFS=,; echo "${PROBE_RESULTS[*]}")

python3 scripts/audit/sign_evidence.py \
    --write \
    --out "$EVIDENCE_FILE" \
    --task "GF-W1-FNC-002" \
    --status "$STATUS" \
    --source-file "schema/migrations/0108_gf_fn_monitoring_ingestion.sql" \
    --command-output "{\"probes\": [$PROBES_JSON]}"

echo "Evidence signed and written to $EVIDENCE_FILE"
if [[ "$STATUS" == "PASS" ]]; then
    exit 0
else
    exit 1
fi
