#!/usr/bin/env bash
# TSK-P3-PRE-001: Verify that ed25519_verify() is callable in the runtime Postgres environment.
# This is a Phase 3 entry blocker. If this script fails, Phase 3 cannot open.
#
# The wave8_crypto extension (migration 0187) provides ed25519_verify().
# Migration 0190 (wave8_cryptographic_enforcement) calls it on every asset_batches INSERT.
# If the extension is absent, the function call fails at runtime — not at schema load time.
#
# Usage:
#   DATABASE_URL=postgres://... ./verify_ed25519_available.sh
#   Or: set PGHOST/PGPORT/PGDATABASE/PGUSER environment variables.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_DIR="$REPO_ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/wave8_crypto_operational_status.json"

mkdir -p "$EVIDENCE_DIR"

# Determine connection string
if [ -n "${DATABASE_URL:-}" ]; then
  PSQL_CONN="$DATABASE_URL"
elif [ -n "${PGDATABASE:-}" ]; then
  PSQL_CONN=""  # psql will use PG* env vars
else
  echo "ERROR: DATABASE_URL or PGDATABASE must be set" >&2
  cat > "$EVIDENCE_FILE" <<EOF
{
  "check_id": "P3-PRE-001-WAVE8-CRYPTO-OPERATIONAL",
  "task_id": "TSK-P3-PRE-001",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "FAIL",
  "pass": false,
  "error": "DATABASE_URL or PGDATABASE not set",
  "ed25519_verify_callable": false
}
EOF
  exit 1
fi

echo "=== TSK-P3-PRE-001: wave8_crypto Extension Verification ==="
echo "Checking if ed25519_verify() is callable..."

# Test 1: Check if the function exists in the catalog
FUNC_EXISTS=$(psql ${PSQL_CONN:+"$PSQL_CONN"} -tAc \
  "SELECT COUNT(*) FROM pg_proc WHERE proname = 'ed25519_verify';" 2>/dev/null || echo "0")

if [ "$FUNC_EXISTS" = "0" ]; then
  echo "FAIL: ed25519_verify() function not found in pg_proc"
  cat > "$EVIDENCE_FILE" <<EOF
{
  "check_id": "P3-PRE-001-WAVE8-CRYPTO-OPERATIONAL",
  "task_id": "TSK-P3-PRE-001",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "FAIL",
  "pass": false,
  "error": "ed25519_verify() not found in pg_proc",
  "ed25519_verify_callable": false,
  "function_exists_in_catalog": false
}
EOF
  exit 1
fi

echo "  Function exists in pg_proc: YES"

# Test 2: Call ed25519_verify() with known-bad inputs — should return FALSE, not error
CALL_RESULT=$(psql ${PSQL_CONN:+"$PSQL_CONN"} -tAc \
  "SELECT ed25519_verify(
    decode(encode(gen_random_bytes(32), 'hex'), 'hex'),
    decode(encode(gen_random_bytes(64), 'hex'), 'hex'),
    decode(encode(gen_random_bytes(32), 'hex'), 'hex')
  );" 2>&1) || true

if [ "$CALL_RESULT" = "f" ] || [ "$CALL_RESULT" = "false" ]; then
  CALLABLE=true
  CALL_STATUS="returned FALSE (expected for bad signature)"
elif [ "$CALL_RESULT" = "t" ] || [ "$CALL_RESULT" = "true" ]; then
  # Astronomically unlikely with random bytes, but technically valid
  CALLABLE=true
  CALL_STATUS="returned TRUE (unexpected but function is callable)"
else
  CALLABLE=false
  CALL_STATUS="error: $CALL_RESULT"
fi

echo "  ed25519_verify() callable: $CALLABLE"
echo "  Call result: $CALL_STATUS"

# Test 3: Check extension is loaded
EXT_EXISTS=$(psql ${PSQL_CONN:+"$PSQL_CONN"} -tAc \
  "SELECT COUNT(*) FROM pg_extension WHERE extname = 'wave8_crypto';" 2>/dev/null || echo "0")

echo "  wave8_crypto extension loaded: $([ "$EXT_EXISTS" != "0" ] && echo YES || echo NO)"

# Emit evidence
if [ "$CALLABLE" = "true" ]; then
  STATUS="PASS"
  EXIT_CODE=0
else
  STATUS="FAIL"
  EXIT_CODE=1
fi

GIT_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

cat > "$EVIDENCE_FILE" <<EOF
{
  "check_id": "P3-PRE-001-WAVE8-CRYPTO-OPERATIONAL",
  "task_id": "TSK-P3-PRE-001",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_sha": "$GIT_SHA",
  "status": "$STATUS",
  "pass": $([ "$STATUS" = "PASS" ] && echo true || echo false),
  "ed25519_verify_callable": $CALLABLE,
  "function_exists_in_catalog": true,
  "extension_loaded": $([ "$EXT_EXISTS" != "0" ] && echo true || echo false),
  "call_result": "$CALL_STATUS"
}
EOF

echo ""
echo "Status: $STATUS"
echo "Evidence: $EVIDENCE_FILE"
exit $EXIT_CODE
