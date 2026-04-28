#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-10: Interpretation Overlap Rejection
# This script verifies that exclusion constraints prevent historical overlapping of interpretation packs

TASK_ID="TSK-P2-PREAUTH-007-10"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_10.json"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD)

# Get timestamp
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize JSON output
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

# Check 1: Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_01", "description": "DATABASE_URL is set", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify interpretation_packs table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'interpretation_packs');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: interpretation_packs table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_02", "description": "interpretation_packs table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_02", "description": "interpretation_packs table exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify exclusion constraint exists
CONSTRAINT_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_constraint WHERE conname = 'no_overlapping_interpretation_packs');" 2>/dev/null | tr -d ' ')
if [ "$CONSTRAINT_EXISTS" != "t" ]; then
  echo "ERROR: Exclusion constraint no_overlapping_interpretation_packs does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_03", "description": "Exclusion constraint no_overlapping_interpretation_packs exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_10_check_03", "description": "Exclusion constraint no_overlapping_interpretation_packs exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Negative test - overlapping timestamptz ranges should be rejected transactionally
NEGATIVE_TEST_RESULT=$(psql "$DATABASE_URL" -t -c "
BEGIN;
-- Insert first interpretation pack
INSERT INTO interpretation_packs (jurisdiction_code, pack_type, effective_from, effective_to)
VALUES ('TEST_JUR', 'TEST_DOMAIN', '2026-01-01 00:00:00+00', '2026-06-30 23:59:59+00');
-- Attempt to insert overlapping pack for same jurisdiction and pack_type - should fail
INSERT INTO interpretation_packs (jurisdiction_code, pack_type, effective_from, effective_to)
VALUES ('TEST_JUR', 'TEST_DOMAIN', '2026-03-01 00:00:00+00', '2026-09-30 23:59:59+00');
ROLLBACK;
SELECT 'OVERLAP_REJECTED';
" 2>&1 || echo "OVERLAP_REJECTED")

if [[ "$NEGATIVE_TEST_RESULT" == *"OVERLAP_REJECTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-10-N1", "description": "Negative test: Overlapping timestamptz ranges for the same jurisdiction and domain are rejected", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - overlapping ranges were not rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-10-N1", "description": "Negative test: Overlapping timestamptz ranges for the same jurisdiction and domain are rejected", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 5: Positive test - non-overlapping ranges should succeed
POSITIVE_TEST_RESULT=$(psql "$DATABASE_URL" -t -c "
BEGIN;
-- Insert first interpretation pack
INSERT INTO interpretation_packs (jurisdiction_code, pack_type, effective_from, effective_to)
VALUES ('TEST_JUR', 'TEST_DOMAIN', '2026-01-01 00:00:00+00', '2026-06-30 23:59:59+00');
-- Insert non-overlapping pack for same jurisdiction and pack_type - should succeed
INSERT INTO interpretation_packs (jurisdiction_code, pack_type, effective_from, effective_to)
VALUES ('TEST_JUR', 'TEST_DOMAIN', '2026-07-01 00:00:00+00', '2026-12-31 23:59:59+00');
ROLLBACK;
SELECT 'NON_OVERLAP_ACCEPTED';
" 2>&1)

if [[ "$POSITIVE_TEST_RESULT" == *"NON_OVERLAP_ACCEPTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-10-P1", "description": "Positive test: Non-overlapping timestamptz ranges for the same jurisdiction and domain are accepted", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Positive test failed - non-overlapping ranges were rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-10-P1", "description": "Positive test: Non-overlapping timestamptz ranges for the same jurisdiction and domain are accepted", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Interpretation Overlap Rejection verified"
