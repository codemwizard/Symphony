#!/usr/bin/env bash
# TSK-P3-W8-ARCH-001 Verifier: Validate TamperEvidentChain.ExtractLeafHashes bridge and tests.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p3_w8_arch_001_hash_chain_bridge.json"
mkdir -p "$EVIDENCE_DIR"

PASS=true
GIT_SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

CHAIN_FILE="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Commands/TamperEvidentChain.cs"

# Check 1: ExtractLeafHashes method exists
if grep -q "ExtractLeafHashes" "$CHAIN_FILE" 2>/dev/null; then
  echo "✓ ExtractLeafHashes method present in TamperEvidentChain.cs"
  METHOD_EXISTS=true
else
  echo "✗ ExtractLeafHashes method missing"
  METHOD_EXISTS=false
  PASS=false
fi

# Check 2: LeafHashEntry record exists
if grep -q "LeafHashEntry" "$CHAIN_FILE" 2>/dev/null; then
  echo "✓ LeafHashEntry record type present"
  RECORD_EXISTS=true
else
  echo "✗ LeafHashEntry record type missing"
  RECORD_EXISTS=false
  PASS=false
fi

# Check 3: Bridge tests exist and pass
TEST_FILE="$ROOT/services/ledger-api/dotnet/tests/LedgerApi.Tests/EpochSealingCommandTests.cs"
if grep -q "ExtractLeafHashes" "$TEST_FILE" 2>/dev/null; then
  echo "✓ ExtractLeafHashes tests present in test file"
  BRIDGE_TESTS_EXIST=true
else
  echo "✗ ExtractLeafHashes tests missing"
  BRIDGE_TESTS_EXIST=false
  PASS=false
fi

# Check 4: Round-trip test exists (app chain → extract → Merkle → verify)
if grep -q "RoundTrip_WriteExtractSealVerify" "$TEST_FILE" 2>/dev/null; then
  echo "✓ Round-trip integration test present"
  ROUNDTRIP_EXISTS=true
else
  echo "✗ Round-trip integration test missing"
  ROUNDTRIP_EXISTS=false
  PASS=false
fi

# Check 5: Tests pass
BRIDGE_TESTS=$(dotnet test "$ROOT/services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj" \
  --verbosity quiet --filter "FullyQualifiedName~ExtractLeafHashes|FullyQualifiedName~RoundTrip" 2>&1 | tail -5)
if echo "$BRIDGE_TESTS" | grep -q "Passed:"; then
  FAILED=$(echo "$BRIDGE_TESTS" | grep -oP 'Failed: \K\d+' || echo "0")
  TESTS_PASS=$( [ "${FAILED:-0}" = "0" ] && echo true || echo false )
  echo "✓ Bridge tests pass: $TESTS_PASS"
  [ "$TESTS_PASS" = "false" ] && PASS=false
else
  TESTS_PASS=false
  echo "✗ Bridge test run failed"
  PASS=false
fi

STATUS=$( [ "$PASS" = "true" ] && echo "PASS" || echo "FAIL" )

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P3-W8-ARCH-001",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$STATUS",
  "extract_leaf_hashes_method": $METHOD_EXISTS,
  "leaf_hash_entry_record": $RECORD_EXISTS,
  "bridge_tests_exist": $BRIDGE_TESTS_EXIST,
  "roundtrip_test_exists": $ROUNDTRIP_EXISTS,
  "tests_pass": $TESTS_PASS
}
EOF

echo ""; echo "Status: $STATUS"; echo "Evidence: $EVIDENCE_FILE"
[ "$PASS" = "true" ] && exit 0 || exit 1
