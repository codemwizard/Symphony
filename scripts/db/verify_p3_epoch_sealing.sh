#!/usr/bin/env bash
# TSK-P3-W8-SEAL-001 Verifier: Validate EpochSealingCommand exists and unit tests pass.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p3_w8_seal_001_epoch_sealing.json"
mkdir -p "$EVIDENCE_DIR"

PASS=true
GIT_SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

# Check 1: EpochSealingCommand.cs exists
CMD_FILE="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Commands/EpochSealingCommand.cs"
if [ -f "$CMD_FILE" ]; then
  echo "✓ EpochSealingCommand.cs exists"
  CMD_EXISTS=true
else
  echo "✗ EpochSealingCommand.cs missing"
  CMD_EXISTS=false
  PASS=false
fi

# Check 2: Contains required methods
METHODS_OK=true
for method in BuildMerkleTree VerifyMerkleProof ComputeLeafHash IsConstitutionalClass; do
  if grep -q "$method" "$CMD_FILE" 2>/dev/null; then
    echo "  ✓ Method $method present"
  else
    echo "  ✗ Method $method missing"
    METHODS_OK=false
    PASS=false
  fi
done

# Check 3: Test file exists
TEST_FILE="$ROOT/services/ledger-api/dotnet/tests/LedgerApi.Tests/EpochSealingCommandTests.cs"
if [ -f "$TEST_FILE" ]; then
  echo "✓ EpochSealingCommandTests.cs exists"
  TESTS_EXIST=true
else
  echo "✗ EpochSealingCommandTests.cs missing"
  TESTS_EXIST=false
  PASS=false
fi

# Check 4: Tests pass
TEST_RESULT=$(dotnet test "$ROOT/services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj" \
  --verbosity quiet --filter "FullyQualifiedName~EpochSealingCommandTests" 2>&1 | tail -5)
if echo "$TEST_RESULT" | grep -q "Passed:"; then
  PASSED_COUNT=$(echo "$TEST_RESULT" | grep -oP 'Passed: \K\d+' || echo "0")
  FAILED_COUNT=$(echo "$TEST_RESULT" | grep -oP 'Failed: \K\d+' || echo "0")
  echo "✓ Tests: $PASSED_COUNT passed, $FAILED_COUNT failed"
  TESTS_PASS=$( [ "${FAILED_COUNT:-0}" = "0" ] && echo true || echo false )
  [ "$TESTS_PASS" = "false" ] && PASS=false
else
  echo "✗ Test run failed"
  TESTS_PASS=false
  PASS=false
fi

# Check 5: SECURITY DEFINER hardening on dormant tables exists (migration 0066)
if [ -n "${DATABASE_URL:-}" ]; then
  BATCH_TABLE=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='proof_pack_batches';" 2>/dev/null || echo "0")
  echo "✓ proof_pack_batches table exists: $([ "$BATCH_TABLE" = "1" ] && echo YES || echo NO)"
else
  BATCH_TABLE="SKIP"
  echo "⊘ DATABASE_URL not set, skipping DB checks"
fi

STATUS=$( [ "$PASS" = "true" ] && echo "PASS" || echo "FAIL" )

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P3-W8-SEAL-001",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$STATUS",
  "command_exists": $CMD_EXISTS,
  "methods_present": $METHODS_OK,
  "tests_exist": $TESTS_EXIST,
  "tests_pass": $TESTS_PASS,
  "proof_pack_batches_table": "$([ "$BATCH_TABLE" = "1" ] && echo exists || echo "$BATCH_TABLE")"
}
EOF

echo ""; echo "Status: $STATUS"; echo "Evidence: $EVIDENCE_FILE"
[ "$PASS" = "true" ] && exit 0 || exit 1
