#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/security/THREE_PILLARS_SECURITY.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/three_pillars_doc.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$DOC" ]]; then
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "THREE-PILLARS-DOC",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "missing": ["document"],
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY
  echo "❌ Missing doc: $DOC" >&2
  exit 1
fi

DOC="$DOC" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

text = Path(os.environ["DOC"]).read_text(encoding="utf-8", errors="ignore")
low = text.lower()

required = {
  "current implementation": "Current Implementation",
  "weaknesses": "Weaknesses / Gaps",
  "proposed improvements": "Proposed Improvements",
  "execution guarantee": "Execution Guarantee",
}

missing = []
for key, label in required.items():
  if key not in low:
    missing.append(label)

status = "PASS" if not missing else "FAIL"

out = {
  "check_id": "THREE-PILLARS-DOC",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": status,
  "missing": missing,
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")

if status != "PASS":
  print("❌ Three‑Pillar doc missing required sections: " + ", ".join(missing))
  raise SystemExit(1)

print(f"Three‑Pillar doc verification OK. Evidence: {os.environ['EVIDENCE_FILE']}")
PY
