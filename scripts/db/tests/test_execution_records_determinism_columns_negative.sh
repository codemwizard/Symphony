#!/usr/bin/env bash
# ============================================================
# test_execution_records_determinism_columns_negative.sh
# Task: TSK-P2-PREAUTH-003-REM-01 (negative-test harness)
#
# N1: drop input_hash column and assert the verifier exits non-zero, then restore.
# N2: set MIGRATION_HEAD to a value other than 0131 and assert verifier exits non-zero.
# Both checks must exit 0 themselves when their forbidden state causes the
# verifier to fail correctly (i.e. fail-closed).
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERIFIER="$ROOT_DIR/scripts/db/verify_execution_records_determinism_columns.sh"
HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"

test -x "$VERIFIER" || { echo "ERR: verifier not executable at $VERIFIER" >&2; exit 1; }

restore_column() {
    # Re-add column to leave DB in expand-phase state. Idempotent.
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c \
        "ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS input_hash TEXT;" >/dev/null
}

echo "==> N1: drop input_hash column and confirm verifier fails"
# execution_records has append-only trigger but triggers on UPDATE/DELETE only;
# DDL (ALTER) is not blocked.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c \
    "ALTER TABLE public.execution_records DROP COLUMN IF EXISTS input_hash CASCADE;" >/dev/null

if bash "$VERIFIER" >/dev/null 2>&1; then
    echo "FAIL: N1 verifier passed with a column missing" >&2
    restore_column
    exit 1
fi
restore_column
echo "PASS: N1 (verifier correctly failed on missing column)"

echo "==> N2: set MIGRATION_HEAD to 0130 and confirm verifier fails"
ORIG_HEAD="$(cat "$HEAD_FILE")"
printf '0130\n' > "$HEAD_FILE"
if bash "$VERIFIER" >/dev/null 2>&1; then
    echo "FAIL: N2 verifier passed with MIGRATION_HEAD=0130" >&2
    printf '%s' "$ORIG_HEAD" > "$HEAD_FILE"
    exit 1
fi
printf '%s' "$ORIG_HEAD" > "$HEAD_FILE"
echo "PASS: N2 (verifier correctly failed on MIGRATION_HEAD drift)"

echo "PASS: REM-01 negative tests"
