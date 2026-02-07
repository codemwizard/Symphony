#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase0/semgrep_sast.json"

if [[ ! -f "$EVIDENCE" ]]; then
  echo "ERROR: missing evidence file: evidence/phase0/semgrep_sast.json" >&2
  exit 1
fi

PYTHON_BIN="python3"
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  PYTHON_BIN="$ROOT_DIR/.venv/bin/python3"
fi

"$PYTHON_BIN" - <<'PY' "$EVIDENCE"
import json,sys
from pathlib import Path

p = Path(sys.argv[1])
d = json.loads(p.read_text(encoding="utf-8"))

missing = [k for k in ("check_id","timestamp_utc","git_sha","status","semgrep_version","scanned_roots","findings") if k not in d]
if missing:
    raise SystemExit(f"Missing keys in semgrep evidence: {missing}")

if d["status"] not in ("PASS","FAIL","SKIPPED"):
    raise SystemExit("Invalid status in semgrep evidence")

if not isinstance(d.get("scanned_roots"), list):
    raise SystemExit("scanned_roots must be a list")

print("OK")
PY

echo "Semgrep evidence verification OK: evidence/phase0/semgrep_sast.json"
