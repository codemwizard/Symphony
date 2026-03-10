#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p1_067_db_error_sanitization.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
TARGET="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs"
if rg -n --pcre2 'Fail\(ex\.Message\)|db_failed:\{ex\.Message\}|ReportLookup\([^\n]*ex\.Message' "$TARGET" >/tmp/tsk_p1_067_hits.txt 2>/dev/null; then
  status="FAIL"
  details="$(tr '\n' ';' </tmp/tsk_p1_067_hits.txt | sed 's/"/\\"/g')"
else
  status="PASS"
  details="raw db exception messages removed from client-facing store results"
fi
write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"TSK-P1-067\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"details\": \"${details}\""
rm -f /tmp/tsk_p1_067_hits.txt
[[ "$status" == "PASS" ]] || { echo "TSK-P1-067 verification failed. Evidence: $EVIDENCE_FILE"; exit 1; }
echo "TSK-P1-067 verification passed. Evidence: $EVIDENCE_FILE"
