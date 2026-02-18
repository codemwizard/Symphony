#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/evidence_store_mode_policy.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

STORAGE_MODE="$(printf '%s' "${INGRESS_STORAGE_MODE:-file}" | tr '[:upper:]' '[:lower:]')"
ENVIRONMENT_NAME="$(printf '%s' "${ENVIRONMENT:-local}" | tr '[:upper:]' '[:lower:]')"

status="PASS"
reason="allowed"

case "$STORAGE_MODE" in
  file|db|db_psql|db_npgsql)
    ;;
  *)
    status="FAIL"
    reason="unsupported_storage_mode"
    ;;
esac

if [[ "$status" == "PASS" && "$STORAGE_MODE" == "file" ]]; then
  case "$ENVIRONMENT_NAME" in
    staging|pilot|prod)
      status="FAIL"
      reason="file_mode_blocked_in_environment"
      ;;
  esac
fi

python3 - <<PY
import json
from pathlib import Path
out = Path(r"$EVIDENCE_FILE")
out.write_text(json.dumps({
  "check_id": "PHASE1-EVIDENCE-STORE-MODE-POLICY",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$status",
  "environment": "$ENVIRONMENT_NAME",
  "store_mode": "$STORAGE_MODE",
  "decision": "allow" if "$status" == "PASS" else "deny",
  "reason": "$reason",
  "allowed_modes": ["file", "db", "db_psql", "db_npgsql"],
  "blocked_file_mode_environments": ["staging", "pilot", "prod"]
}, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "Evidence store mode policy verification failed: mode=$STORAGE_MODE env=$ENVIRONMENT_NAME reason=$reason" >&2
  exit 1
fi

echo "Evidence store mode policy verification passed. Evidence: $EVIDENCE_FILE"
