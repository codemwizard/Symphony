#!/bin/bash
# Verification script for TSK-P2-W6-REM-16a
# Verifies placement and integrity of Wave 6 Contract Documents

set -e

TASK_ID="TSK-P2-W6-REM-16a"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_16a.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

FILES=(
    "docs/contracts/TRANSITION_HASH_CONTRACT.md"
    "docs/contracts/ED25519_SIGNING_CONTRACT.md"
    "docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md"
    "docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md"
)

# 1. Check all exist
for FILE in "${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: Missing file $FILE"
        exit 1
    fi
done

# 2. Check Canonical-Reference matches
for FILE in "${FILES[@]}"; do
    EXPECTED="Canonical-Reference: $FILE"
    if ! grep -q "^$EXPECTED" "$FILE"; then
        echo "ERROR: File $FILE missing correct Canonical-Reference header"
        echo "Expected: $EXPECTED"
        exit 1
    fi
done

# 3. Check for placeholder tokens
NEGATIVE_TEST_N1="pass"
for FILE in "${FILES[@]}"; do
    if grep -qE '\b(TODO|FIXME|TBD|PLACEHOLDER|XXX)\b' "$FILE"; then
        echo "ERROR: File $FILE contains placeholder tokens in violation of N1"
        NEGATIVE_TEST_N1="fail"
        exit 1
    fi
done

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "files_exist": "pass",
    "canonical_reference_matches": "pass",
    "no_unresolved_tokens": "pass"
  },
  "negative_test_results": {
    "TSK-P2-W6-REM-16a-N1": "$NEGATIVE_TEST_N1"
  }
}
EOF

echo "Verification successful for $TASK_ID"
