#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/no_tx_docs.json"
DOC="$ROOT_DIR/docs/operations/DEV_WORKFLOW.md"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

found=0
if command -v rg >/dev/null 2>&1; then
  rg -q "symphony:no_tx" "$DOC" && found=1 || true
else
  grep -q "symphony:no_tx" "$DOC" && found=1 || true
fi

status="PASS"
if [[ "$found" -ne 1 ]]; then
  status="FAIL"
fi

FOUND="$found" STATUS="$status" OUT="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

out = {
  "check_id": "NO-TX-DOCS",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ.get("STATUS"),
  "found": os.environ.get("FOUND") == "1",
}
Path(os.environ["OUT"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "No-tx docs verification failed. Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "No-tx docs verification OK. Evidence: $EVIDENCE_FILE"
