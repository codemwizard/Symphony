#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

TASK_ID="TSK-P2-W5-FIX-05"
EVIDENCE_FILE="evidence/phase2/tsk_p2_w5_fix_05.json"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'nogit')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="${GIT_SHA}-${TIMESTAMP_UTC}"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

echo "==> Verifying TSK-P2-W5-FIX-05: Rename triggers for deterministic execution order"

# Expected trigger names in alphabetical order
EXPECTED_TRIGGERS=(
    "ai_01_update_current_state"
    "bd_01_deny_state_transitions_mutation"
    "bi_01_enforce_transition_authority"
    "bi_02_enforce_execution_binding"
    "bi_03_enforce_transition_state_rules"
    "bi_04_enforce_transition_signature"
    "bi_05_enforce_state_transition_authority"
    "bi_06_upgrade_authority_on_execution_binding"
)

# Old trigger names that should NOT exist
OLD_TRIGGERS=(
    "trg_06_update_current"
    "trg_deny_state_transitions_mutation"
    "trg_enforce_execution_binding"
    "trg_enforce_state_transition_authority"
    "trg_enforce_transition_authority"
    "trg_enforce_transition_signature"
    "trg_enforce_transition_state_rules"
    "trg_upgrade_authority_on_execution_binding"
)

# Check that old triggers are removed
echo "[Check] Verifying old trigger names are removed..."
OLD_TRIGGER_COUNT=0
for old_trigger in "${OLD_TRIGGERS[@]}"; do
    EXISTS="$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_trigger WHERE tgrelid = 'state_transitions'::regclass AND tgname = '$old_trigger' AND NOT tgisinternal")"
    if [ "$EXISTS" = "1" ]; then
        echo "  FAIL: Old trigger $old_trigger still exists"
        OLD_TRIGGER_COUNT=$((OLD_TRIGGER_COUNT + 1))
    fi
done

if [ "$OLD_TRIGGER_COUNT" -gt 0 ]; then
    echo "FAIL: $OLD_TRIGGER_COUNT old triggers still exist"
    exit 1
fi
echo "PASS: All old triggers removed"

# Check that new triggers exist with correct names
echo "[Check] Verifying new trigger names exist..."
NEW_TRIGGER_COUNT=0
NEW_TRIGGERS_FOUND=()

for new_trigger in "${EXPECTED_TRIGGERS[@]}"; do
    EXISTS="$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_trigger WHERE tgrelid = 'state_transitions'::regclass AND tgname = '$new_trigger' AND NOT tgisinternal")"
    if [ "$EXISTS" = "1" ]; then
        NEW_TRIGGER_COUNT=$((NEW_TRIGGER_COUNT + 1))
        NEW_TRIGGERS_FOUND+=("$new_trigger")
    else
        echo "  FAIL: New trigger $new_trigger not found"
    fi
done

if [ "$NEW_TRIGGER_COUNT" != "8" ]; then
    echo "FAIL: Expected 8 new triggers, found $NEW_TRIGGER_COUNT"
    exit 1
fi
echo "PASS: All 8 new triggers exist"

# Verify alphabetical order matches expected sequence
echo "[Check] Verifying trigger order is deterministic (alphabetical)..."
ACTUAL_ORDER="$(psql "$DATABASE_URL" -tAc "SELECT tgname FROM pg_trigger WHERE tgrelid = 'state_transitions'::regclass AND NOT tgisinternal ORDER BY tgname")"

# Convert to array for comparison
mapfile -t ACTUAL_ARRAY <<< "$ACTUAL_ORDER"
MATCHES=true
for i in "${!EXPECTED_TRIGGERS[@]}"; do
    if [ "${ACTUAL_ARRAY[$i]}" != "${EXPECTED_TRIGGERS[$i]}" ]; then
        MATCHES=false
        echo "  Mismatch at position $i: expected ${EXPECTED_TRIGGERS[$i]}, got ${ACTUAL_ARRAY[$i]}"
    fi
done

if [ "$MATCHES" = false ]; then
    echo "FAIL: Trigger order does not match expected sequence"
    echo "Actual order: ${ACTUAL_ARRAY[@]}"
    echo "Expected order: ${EXPECTED_TRIGGERS[@]}"
    exit 1
fi
echo "PASS: Trigger order matches expected sequence"

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
      "name": "old_triggers_removed",
      "status": "PASS",
      "description": "All old trigger names removed"
    },
    {
      "name": "new_triggers_exist",
      "status": "PASS",
      "description": "All 8 new triggers with bi_XX_/bd_XX_/ai_XX_ prefixes exist"
    },
    {
      "name": "trigger_order_deterministic",
      "status": "PASS",
      "description": "Trigger order is deterministic (alphabetical by name)"
    }
  ],
  "trigger_order_before": [
    "trg_06_update_current",
    "trg_deny_state_transitions_mutation",
    "trg_enforce_execution_binding",
    "trg_enforce_state_transition_authority",
    "trg_enforce_transition_authority",
    "trg_enforce_transition_signature",
    "trg_enforce_transition_state_rules",
    "trg_upgrade_authority_on_execution_binding"
  ],
  "trigger_order_after": $(printf '%s\n' "${EXPECTED_TRIGGERS[@]}" | jq -R . | jq -s .),
  "old_triggers_removed": true,
  "notes": "PostgreSQL fires same-event triggers in alphabetical order. bi_XX_ prefix guarantees deterministic execution order."
}
EOF

echo "==> Evidence written to $EVIDENCE_FILE"
echo "==> All checks passed"
