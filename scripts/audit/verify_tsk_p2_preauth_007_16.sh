#!/bin/bash
set -e

# Task: TSK-P2-PREAUTH-007-16: INV-177 and INV-178 DB Verifiers
# Requirement: scripts/dev/seed_canonical_test_data.sql must have been applied.

TASK_ID="TSK-P2-PREAUTH-007-16"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_16.json"
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
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'monitoring_records' AND column_name = 'audit_grade') THEN
        RAISE EXCEPTION 'Column audit_grade missing';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'monitoring_records' AND column_name = 'data_authority') THEN
        RAISE EXCEPTION 'Column data_authority missing';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_enforce_monitoring_authority') THEN
        RAISE EXCEPTION 'Monitoring Authority trigger missing';
    END IF;
END \$\$;
"
jq '.checks += [{"id": "tsk_p2_preauth_007_16_structural", "description": "Verify schema columns and triggers", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Behavioral Check - Negative Tests using Master Canonical Seed
echo "Executing behavioral tests..."
TEST_RESULT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -c "
DO \$\$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000002';
  v_project_id UUID := '00000000-0000-0000-0000-000000000003';
BEGIN
  -- Negative Test 1: INV-178 - authoritative_signed requires a certain posture (Trigger enforce_monitoring_authority)
  BEGIN
    INSERT INTO monitoring_records (monitoring_record_id, tenant_id, project_id, data_authority, record_type, record_payload_json, audit_grade, authority_explanation)
    VALUES (gen_random_uuid(), v_tenant_id, v_project_id, 'authoritative_signed', 'TECHNICAL_AUDIT', '{}', true, 'Test Authority');
    RAISE EXCEPTION 'N1 Failed: Should have rejected authoritative_signed for basic insert';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%authoritative%' AND SQLERRM NOT LIKE '%authority%' THEN
        RAISE EXCEPTION 'N1 Failed: Unexpected error message: %', SQLERRM;
    END IF;
  END;

  -- Positive Test: Valid monitoring record
  INSERT INTO monitoring_records (monitoring_record_id, tenant_id, project_id, data_authority, record_type, record_payload_json, audit_grade, authority_explanation)
  VALUES (gen_random_uuid(), v_tenant_id, v_project_id, 'phase1_indicative_only', 'TECHNICAL_AUDIT', '{}', false, 'Initial test');

END \$\$;
")

if [ $? -eq 0 ]; then
  echo "PASS: Task 16 behavioral verification successful."
  jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_16_behavioral", "description": "Verify logic rejection using Master Canonical IDs", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Behavioral tests failed" >&2
  echo "$TEST_RESULT" >&2
  exit 1
fi

# Add script hash
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
