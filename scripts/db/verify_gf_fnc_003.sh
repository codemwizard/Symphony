#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---

echo "==> GF-W1-FNC-003 Evidence Lineage Functions Verification"

EVIDENCE_DIR="evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/gf_fnc_003.json"
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
    ["attach_evidence"]="p_tenant_id uuid, p_project_id uuid, p_evidence_class text, p_document_type text, p_target_record_type text, p_target_record_id uuid"
    ["link_evidence_to_record"]="p_tenant_id uuid, p_evidence_node_id uuid, p_target_evidence_node_id uuid, p_edge_type text"
    ["query_evidence_lineage"]="p_tenant_id uuid, p_project_id uuid"
    ["get_evidence_node"]="p_tenant_id uuid, p_evidence_node_id uuid"
    ["list_project_evidence"]="p_tenant_id uuid, p_project_id uuid"
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
    --task "GF-W1-FNC-003" \
    --status "$STATUS" \
    --source-file "schema/migrations/0109_gf_fn_evidence_lineage.sql" \
    --command-output "{\"probes\": [$PROBES_JSON]}"

echo "Evidence signed and written to $EVIDENCE_FILE"
if [[ "$STATUS" == "PASS" ]]; then
    exit 0
else
    exit 1
fi
