#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p1_065_selftest_secret_posture.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
TARGET="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
forbidden='tenant-context-self-test-key|pilot-self-test-key|ten-003-admin-key|phase1-reg-00[23]-self-test-key'
if rg -n --pcre2 "$forbidden" "$ROOT_DIR/$TARGET" >/tmp/tsk_p1_065_hits.txt 2>/dev/null; then
  status="FAIL"
  details="$(tr '\n' ';' </tmp/tsk_p1_065_hits.txt | sed 's/"/\\"/g')"
else
  status="PASS"
  details="no hardcoded self-test secrets found"
fi
write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"TSK-P1-065\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"target\": \"${TARGET}\"" \
  "\"details\": \"${details}\""
rm -f /tmp/tsk_p1_065_hits.txt
[[ "$status" == "PASS" ]] || { echo "TSK-P1-065 verification failed. Evidence: $EVIDENCE_FILE"; exit 1; }
echo "TSK-P1-065 verification passed. Evidence: $EVIDENCE_FILE"
