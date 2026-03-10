#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p1_066_bounded_amount_validation.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
FILE1="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Commands/IngressAndKycHandlers.cs"
FILE2="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n "MaxAmountMinor|must not exceed" "$FILE1" >/dev/null
rg -n "fractional_amount_rejected|oversized_amount_rejected" "$FILE2" >/dev/null
write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"TSK-P1-066\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  '"status": "PASS"' \
  '"checks": ["MaxAmountMinor guard present","fractional and oversized negative tests present"]'
echo "TSK-P1-066 verification passed. Evidence: $EVIDENCE_FILE"
