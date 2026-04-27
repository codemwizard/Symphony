#!/bin/bash
set -e

# Task: TSK-P2-PREAUTH-007-15: INV-175 and INV-176 DB Verifiers
# Requirement: scripts/dev/seed_canonical_test_data.sql must have been applied.

TASK_ID="TSK-P2-PREAUTH-007-15"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_15.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize JSON output
mkdir -p "$(dirname "$EVIDENCE_PATH")"
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": [],
  "observed_hashes": []
}
EOF

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL not set" >&2
  exit 1
fi

# Check 1: Structural Check
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'data_authority') THEN
        RAISE EXCEPTION 'Column data_authority missing';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'bi_03_enforce_transition_state_rules') THEN
        RAISE EXCEPTION 'State Machine trigger bi_03 missing';
    END IF;
END \$\$;
"
jq '.checks += [{"id": "tsk_p2_preauth_007_15_structural", "description": "Verify schema columns and triggers", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Behavioral Check - Negative Tests using Master Canonical Seed
echo "Executing behavioral tests..."
TEST_RESULT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -c "
DO \$\$
DECLARE
  v_project_id UUID := '00000000-0000-0000-0000-000000000003';
  v_execution_id UUID := '00000000-0000-0000-0000-000000000005';
  v_policy_id UUID := '00000000-0000-0000-0000-000000000006';
  v_interpretation_id UUID := '00000000-0000-0000-0000-000000000004';
  v_hash TEXT := '1111111111111111111111111111111111111111111111111111111111111111';
  v_sig TEXT := '11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111';
BEGIN
  -- Negative Test 1: INV-175 - authoritative_signed requires execution_id (Trigger enforce_execution_binding)
  BEGIN
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, execution_id, policy_decision_id, transition_hash, data_authority, interpretation_version_id, signature)
    VALUES (gen_random_uuid(), v_project_id, 'ASSET_BATCH', gen_random_uuid(), 'draft', 'pending', NULL, v_policy_id, v_hash, 'authoritative_signed', v_interpretation_id, v_sig);
    RAISE EXCEPTION 'N1 Failed: Should have rejected NULL execution_id for authoritative_signed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%Transition without execution binding%' THEN
        RAISE EXCEPTION 'N1 Failed: Unexpected error message: %', SQLERRM;
    END IF;
  END;

  -- Negative Test 2: INV-176 - Invalid State Transition (completed -> draft)
  BEGIN
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, execution_id, policy_decision_id, transition_hash, data_authority, interpretation_version_id, signature)
    VALUES (gen_random_uuid(), v_project_id, 'ASSET_BATCH', gen_random_uuid(), 'completed', 'draft', v_execution_id, v_policy_id, v_hash, 'phase1_indicative_only', v_interpretation_id, v_sig);
    RAISE EXCEPTION 'N2 Failed: Should have rejected invalid state transition (completed -> draft)';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%Invalid state transition%' THEN
        RAISE EXCEPTION 'N2 Failed: Unexpected error message: %', SQLERRM;
    END IF;
  END;

  -- Positive Test: Valid transition with full context
  INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, execution_id, policy_decision_id, transition_hash, data_authority, interpretation_version_id, signature)
  VALUES (gen_random_uuid(), v_project_id, 'ASSET_BATCH', gen_random_uuid(), 'draft', 'pending', v_execution_id, v_policy_id, v_hash, 'phase1_indicative_only', v_interpretation_id, v_sig);

END \$\$;
")

if [ $? -eq 0 ]; then
  echo "PASS: Task 15 behavioral verification successful."
  jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_15_behavioral", "description": "Verify logic rejection using Master Canonical IDs", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Behavioral tests failed" >&2
  echo "$TEST_RESULT" >&2
  exit 1
fi

# Add script hash
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
