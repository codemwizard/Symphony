#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-12: Attestation Seam Schema
# This script verifies that attestation columns and enums exist on asset_batches with correct constraints

TASK_ID="TSK-P2-PREAUTH-007-12"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_12.json"

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
  jq '.checks += [{"id": "tsk_p2_preauth_007_12_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_12_check_01", "description": "DATABASE_URL is set", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify asset_batches table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'asset_batches');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: asset_batches table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_12_check_02", "description": "asset_batches table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_12_check_02", "description": "asset_batches table exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify all 4 attestation columns exist
REQUIRED_COLUMNS=("invariant_attestation_hash" "invariant_attestation_version" "invariant_attested_at" "invariant_attestation_source")
ALL_COLUMNS_EXIST=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'asset_batches' AND column_name = '$col');" 2>/dev/null | tr -d ' ')
  if [ "$COL_EXISTS" != "t" ]; then
    echo "ERROR: Column $col does not exist in asset_batches table" >&2
    ALL_COLUMNS_EXIST=false
  fi
done

if [ "$ALL_COLUMNS_EXIST" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P1", "description": "Positive test: All 4 attestation columns exist", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P1", "description": "Positive test: All 4 attestation columns exist", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify attestation_source_type enum exists with correct values
ENUM_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_type WHERE typname = 'attestation_source_type');" 2>/dev/null | tr -d ' ')
if [ "$ENUM_EXISTS" != "t" ]; then
  echo "ERROR: attestation_source_type enum does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P2", "description": "Positive test: attestation_source_type enum exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P2", "description": "Positive test: attestation_source_type enum exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 5: Positive test - all columns accept NULL (check via information_schema)
NULLABLE_CHECK=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  IS_NULLABLE=$(psql "$DATABASE_URL" -t -c "SELECT is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'asset_batches' AND column_name = '$col';" 2>/dev/null | tr -d ' ')
  if [ "$IS_NULLABLE" != "YES" ]; then
    echo "ERROR: Column $col is not nullable" >&2
    NULLABLE_CHECK=false
  fi
done

if [ "$NULLABLE_CHECK" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P3", "description": "Positive test: All columns accept NULL", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-P3", "description": "Positive test: All columns accept NULL", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 6: Negative test - verify hash format constraint exists
HASH_CONSTRAINT_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_constraint WHERE conname = 'attestation_hash_format');" 2>/dev/null | tr -d ' ')
if [ "$HASH_CONSTRAINT_EXISTS" = "t" ]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N1", "description": "Negative test: Hash format constraint exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - hash format constraint does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N1", "description": "Negative test: Hash format constraint exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 7: Negative test - verify version positive constraint exists
VERSION_CONSTRAINT_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_constraint WHERE conname = 'attestation_version_positive');" 2>/dev/null | tr -d ' ')
if [ "$VERSION_CONSTRAINT_EXISTS" = "t" ]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N2", "description": "Negative test: Version positive constraint exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - version positive constraint does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N2", "description": "Negative test: Version positive constraint exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 8: Verify constraint logic by checking pg_constraint definition
HASH_CONSTRAINT_DEF=$(psql "$DATABASE_URL" -t -c "SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'attestation_hash_format';" 2>/dev/null)
if [[ "$HASH_CONSTRAINT_DEF" == *"[a-f0-9]{64,128}$"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N3", "description": "Negative test: Hash constraint has correct regex", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - hash constraint does not have correct regex" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-12-N3", "description": "Negative test: Hash constraint has correct regex", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Attestation Seam Schema verified"
