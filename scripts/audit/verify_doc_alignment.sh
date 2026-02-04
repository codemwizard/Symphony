#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/doc_alignment.json"

DOC1="$ROOT_DIR/docs/overview/architecture.md"
DOC2="$ROOT_DIR/docs/decisions/ADR-0001-repo-structure.md"

mkdir -p "$EVIDENCE_DIR"

matches=""
if command -v rg >/dev/null 2>&1; then
  matches="$(rg -n "node|Node.js" "$DOC1" "$DOC2" || true)"
else
  matches="$(grep -nE "node|Node.js" "$DOC1" "$DOC2" || true)"
fi

status="pass"
if [[ -n "$matches" ]]; then
  status="fail"
fi

MATCHES="$matches" STATUS="$status" OUT="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

lines = [ln for ln in os.environ.get("MATCHES", "").splitlines() if ln.strip()]
out = {"status": os.environ.get("STATUS"), "matches": lines}
Path(os.environ["OUT"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "pass" ]]; then
  echo "Doc alignment verification failed. Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "Doc alignment verification OK. Evidence: $EVIDENCE_FILE"
