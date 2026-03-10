#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p1_068_sensitive_endpoint_rate_limits.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
TARGET="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
for pattern in 'AddPolicy\("sensitive-endpoint"' 'MapPost\("/v1/admin/tenants"' 'MapPost\("/v1/admin/incidents"' 'MapPost\("/v1/kyc/hash"' 'RequireRateLimiting\("sensitive-endpoint"\)'; do
  rg -n --pcre2 "$pattern" "$TARGET" >/dev/null
done
write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"TSK-P1-068\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  '"status": "PASS"' \
  '"policy": "sensitive-endpoint"'
echo "TSK-P1-068 verification passed. Evidence: $EVIDENCE_FILE"
