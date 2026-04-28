#!/bin/bash
# Verification script for TSK-P2-W6-REM-19: Trigger Topology Freeze
# Enforces exact baseline of 9 triggers on state_transitions

set -e

TASK_ID="TSK-P2-W6-REM-19"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_19.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running trigger topology freeze verification for $TASK_ID..."

# Fetch current topology from DB
# Note: information_schema.triggers represents multiple events (INSERT OR UPDATE) as multiple rows
CURRENT_TOPOLOGY=$(psql "$DATABASE_URL" -tAc "
SELECT trigger_name, action_timing, event_manipulation, action_orientation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'state_transitions' 
ORDER BY trigger_name, event_manipulation;
")

# Define the expected exact baseline (expanded for event_manipulation)
EXPECTED_TOPOLOGY="ai_01_update_current_state|AFTER|INSERT|ROW|EXECUTE FUNCTION update_current_state()
bd_01_deny_state_transitions_mutation|BEFORE|DELETE|ROW|EXECUTE FUNCTION deny_state_transitions_mutation()
bd_01_deny_state_transitions_mutation|BEFORE|UPDATE|ROW|EXECUTE FUNCTION deny_state_transitions_mutation()
bi_01_enforce_transition_authority|BEFORE|INSERT|ROW|EXECUTE FUNCTION enforce_transition_authority()
bi_01_enforce_transition_authority|BEFORE|UPDATE|ROW|EXECUTE FUNCTION enforce_transition_authority()
bi_02_enforce_execution_binding|BEFORE|INSERT|ROW|EXECUTE FUNCTION enforce_execution_binding()
bi_02_enforce_execution_binding|BEFORE|UPDATE|ROW|EXECUTE FUNCTION enforce_execution_binding()
bi_03_enforce_transition_state_rules|BEFORE|INSERT|ROW|EXECUTE FUNCTION enforce_transition_state_rules()
bi_03_enforce_transition_state_rules|BEFORE|UPDATE|ROW|EXECUTE FUNCTION enforce_transition_state_rules()
bi_04_enforce_transition_signature|BEFORE|INSERT|ROW|EXECUTE FUNCTION enforce_transition_signature()
bi_04_enforce_transition_signature|BEFORE|UPDATE|ROW|EXECUTE FUNCTION enforce_transition_signature()
bi_05_enforce_state_transition_authority|BEFORE|INSERT|ROW|EXECUTE FUNCTION enforce_state_transition_authority()
bi_05_enforce_state_transition_authority|BEFORE|UPDATE|ROW|EXECUTE FUNCTION enforce_state_transition_authority()
bi_06_upgrade_authority_on_execution_binding|BEFORE|INSERT|ROW|EXECUTE FUNCTION upgrade_authority_on_execution_binding()
bi_06_upgrade_authority_on_execution_binding|BEFORE|UPDATE|ROW|EXECUTE FUNCTION upgrade_authority_on_execution_binding()
tr_add_signature_placeholder|BEFORE|INSERT|ROW|EXECUTE FUNCTION add_signature_placeholder_posture()"

if [ "$CURRENT_TOPOLOGY" != "$EXPECTED_TOPOLOGY" ]; then
  echo "FAIL: Trigger topology drift detected."
  echo "Expected:"
  echo "$EXPECTED_TOPOLOGY"
  echo "Got:"
  echo "$CURRENT_TOPOLOGY"
  exit 1
fi

echo "Topology perfectly matches baseline."

# Count distinct triggers to ensure it is exactly 9
TRIGGER_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT count(distinct trigger_name) FROM information_schema.triggers WHERE event_object_table = 'state_transitions';")
if [ "$TRIGGER_COUNT" != "9" ]; then
  echo "FAIL: Expected exactly 9 distinct triggers, found $TRIGGER_COUNT"
  exit 1
fi

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "topology_frozen": true,
    "distinct_trigger_count": 9
  }
}
EOF

echo "Verification successful for $TASK_ID"
