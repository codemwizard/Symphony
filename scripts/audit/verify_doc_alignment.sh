#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/doc_alignment.json"

DOC1="$ROOT_DIR/docs/overview/architecture.md"
DOC2="$ROOT_DIR/docs/decisions/ADR-0001-repo-structure.md"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

matches=""
if command -v rg >/dev/null 2>&1; then
  # symphony:allow_or_true (no-match exit codes should not fail the gate; matches are the signal)
  matches="$(rg -n "node|Node.js" "$DOC1" "$DOC2" || true)"
else
  # symphony:allow_or_true (no-match exit codes should not fail the gate; matches are the signal)
  matches="$(grep -nE "node|Node.js" "$DOC1" "$DOC2" || true)"
fi

status="PASS"
if [[ -n "$matches" ]]; then
  status="FAIL"
fi

MATCHES="$matches" STATUS="$status" OUT="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

lines = [ln for ln in os.environ.get("MATCHES", "").splitlines() if ln.strip()]
out = {
  "check_id": "DOC-ALIGNMENT",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ.get("STATUS"),
  "matches": lines,
}
Path(os.environ["OUT"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "Doc alignment verification failed. Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "Doc alignment verification OK. Evidence: $EVIDENCE_FILE"
