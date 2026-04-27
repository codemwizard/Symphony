#!/bin/bash
set -e

# Task: TSK-P2-PREAUTH-007-18: INV-181 and INV-182 DB Verifiers
# Requirement: scripts/dev/seed_canonical_test_data.sql must have been applied.

TASK_ID="TSK-P2-PREAUTH-007-18"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_18.json"
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
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'taxonomy_aligned') THEN
        RAISE EXCEPTION 'Column taxonomy_aligned missing';
    END IF;
END \$\$;
"
jq '.checks += [{"id": "tsk_p2_preauth_007_18_structural", "description": "Verify schema columns", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Behavioral Check - Negative Tests using Master Canonical Seed
echo "Executing behavioral tests..."
TEST_RESULT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -c "
DO \$\$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
  -- Negative Test 1: taxonomy_aligned is NOT NULL (Schema enforcement)
  BEGIN
    INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned)
    VALUES (gen_random_uuid(), v_tenant_id, 'Null Test Project', 'ACTIVE', NULL);
    RAISE EXCEPTION 'N1 Failed: Should have rejected NULL for taxonomy_aligned';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%null value%' AND SQLERRM NOT LIKE '%not-null%' THEN
        RAISE EXCEPTION 'N1 Failed: Unexpected error message: %', SQLERRM;
    END IF;
  END;

  -- Negative Test 2: taxonomy_aligned = true is blocked by K13 Kill Switch
  BEGIN
    INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned)
    VALUES (gen_random_uuid(), v_tenant_id, 'Blocked Project', 'ACTIVE', true);
    RAISE EXCEPTION 'N2 Failed: Should have rejected taxonomy_aligned=true (K13 Kill Switch)';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%K13 violation%' THEN
        RAISE EXCEPTION 'N2 Failed: Unexpected error message: %', SQLERRM;
    END IF;
  END;

  -- Positive Test: Valid project (taxonomy_aligned must be false currently)
  INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned)
  VALUES (gen_random_uuid(), v_tenant_id, 'Valid Test Project', 'ACTIVE', false);

END \$\$;
")

if [ $? -eq 0 ]; then
  echo "PASS: Task 18 behavioral verification successful."
  jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_18_behavioral", "description": "Verify NOT NULL and K13 Kill Switch logic", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Behavioral tests failed" >&2
  echo "$TEST_RESULT" >&2
  exit 1
fi

# Add script hash
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
