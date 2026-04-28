#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

TASK_ID="TSK-P2-W5-FIX-04"
EVIDENCE_FILE="evidence/phase2/tsk_p2_w5_fix_04.json"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'nogit')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="${GIT_SHA}-${TIMESTAMP_UTC}"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

echo "==> Verifying TSK-P2-W5-FIX-04: Harden all Wave 5 trigger functions with SECURITY DEFINER"

# Target functions
FUNCTIONS=(
    "enforce_transition_state_rules"
    "enforce_transition_authority"
    "enforce_transition_signature"
    "enforce_execution_binding"
    "deny_state_transitions_mutation"
    "update_current_state"
)

# Check prosecdef for all functions
echo "[Check] Verifying prosecdef=true for all 6 functions..."
PROSECDEF_COUNT=0
PROSECDEF_RESULTS=()

for func in "${FUNCTIONS[@]}"; do
    RESULT="$(psql "$DATABASE_URL" -tAc "SELECT prosecdef FROM pg_proc WHERE proname = '$func'")"
    if [ "$RESULT" = "t" ]; then
        PROSECDEF_COUNT=$((PROSECDEF_COUNT + 1))
        PROSECDEF_RESULTS+=("$func:PASS")
        echo "  $func: prosecdef=true"
    else
        PROSECDEF_RESULTS+=("$func:FAIL (prosecdef=$RESULT)")
        echo "  $func: FAIL (prosecdef=$RESULT)"
    fi
done

if [ "$PROSECDEF_COUNT" != "6" ]; then
    echo "FAIL: Expected 6 functions with prosecdef=true, found $PROSECDEF_COUNT"
    exit 1
fi
echo "PASS: All 6 functions have prosecdef=true"

# Check proconfig (search_path) for all functions
echo "[Check] Verifying search_path = pg_catalog, public for all 6 functions..."
PROCONFIG_COUNT=0
PROCONFIG_RESULTS=()

for func in "${FUNCTIONS[@]}"; do
    PROCONFIG="$(psql "$DATABASE_URL" -tAc "SELECT proconfig FROM pg_proc WHERE proname = '$func'")"
    if echo "$PROCONFIG" | grep -q "search_path.*pg_catalog.*public"; then
        PROCONFIG_COUNT=$((PROCONFIG_COUNT + 1))
        PROCONFIG_RESULTS+=("$func:PASS")
        echo "  $func: search_path configured"
    else
        PROCONFIG_RESULTS+=("$func:FAIL (proconfig=$PROCONFIG)")
        echo "  $func: FAIL (proconfig=$PROCONFIG)"
    fi
done

if [ "$PROCONFIG_COUNT" != "6" ]; then
    echo "FAIL: Expected 6 functions with search_path configured, found $PROCONFIG_COUNT"
    exit 1
fi
echo "PASS: All 6 functions have search_path = pg_catalog, public"

# Generate evidence
cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "run_id": "$RUN_ID",
  "status": "PASS",
  "checks": [
    {
      "name": "prosecdef_verified",
      "status": "PASS",
      "description": "All 6 trigger functions have prosecdef=true"
    },
    {
      "name": "proconfig_verified",
      "status": "PASS",
      "description": "All 6 trigger functions have search_path = pg_catalog, public"
    }
  ],
  "functions_hardened": [
    "enforce_transition_state_rules",
    "enforce_transition_authority",
    "enforce_transition_signature",
    "enforce_execution_binding",
    "deny_state_transitions_mutation",
    "update_current_state"
  ],
  "prosecdef_verified": true,
  "proconfig_verified": true,
  "prosecdef_results": $(printf '%s\n' "${PROSECDEF_RESULTS[@]}" | jq -R . | jq -s .),
  "proconfig_results": $(printf '%s\n' "${PROCONFIG_RESULTS[@]}" | jq -R . | jq -s .),
  "notes": "SECURITY DEFINER hardening applied to all Wave 5 trigger functions per AGENTS.md mandate"
}
EOF

echo "==> Evidence written to $EVIDENCE_FILE"
echo "==> All checks passed"
