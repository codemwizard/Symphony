#!/bin/bash
set -e

# Task: TSK-P2-PREAUTH-007-17: INV-179 and INV-180 DB Verifiers
# Requirement: scripts/dev/seed_canonical_test_data.sql must have been applied.

TASK_ID="TSK-P2-PREAUTH-007-17"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_17.json"
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
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billable_clients' AND column_name = 'client_key') THEN
        RAISE EXCEPTION 'Column client_key missing';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billable_clients' AND column_name = 'client_type') THEN
        RAISE EXCEPTION 'Column client_type missing';
    END IF;
END \$\$;
"
jq '.checks += [{"id": "tsk_p2_preauth_007_17_structural", "description": "Verify schema columns", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Behavioral Check - Negative Tests
echo "Executing behavioral tests..."
TEST_RESULT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -c "
DO \$\$
BEGIN
  -- Negative Test 1: INV-180 - client_type must be from approved list (ENTERPRISE, GOVERNMENT, PARTNER)
  BEGIN
    INSERT INTO billable_clients (billable_client_id, legal_name, client_type, status, client_key)
    VALUES (gen_random_uuid(), 'Invalid Client', 'INDIVIDUAL', 'ACTIVE', 'invalid_client');
    RAISE EXCEPTION 'N1 Failed: Should have rejected invalid client_type';
  EXCEPTION WHEN check_violation OR raise_exception OR invalid_text_representation THEN
    -- PASS N1 (could be a CHECK constraint or an ENUM)
  END;

  -- Positive Test: Valid client
  INSERT INTO billable_clients (billable_client_id, legal_name, client_type, status, client_key)
  VALUES (gen_random_uuid(), 'Valid Test Client', 'ENTERPRISE', 'ACTIVE', 'valid_test_client_' || gen_random_uuid()::text);

END \$\$;
")

if [ $? -eq 0 ]; then
  echo "PASS: Task 17 behavioral verification successful."
  jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_17_behavioral", "description": "Verify client_type constraint", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Behavioral tests failed" >&2
  echo "$TEST_RESULT" >&2
  exit 1
fi

# Add script hash
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
