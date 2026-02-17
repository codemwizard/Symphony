#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/structural_doc_linkage.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
CHECK_ID="STRUCTURAL-DOC-LINKAGE"

# Default range for local usage if not provided
HEAD_REF="${HEAD_REF:-HEAD}"
source "$ROOT_DIR/scripts/audit/lib/git_diff_range_only.sh"
BASE_REF="${BASE_REF:-$(git_resolve_base_ref)}"

# Compute diff range (parity-critical). If base ref is missing, fail closed.
if ! git_ensure_ref "$BASE_REF"; then
  echo "❌ BASE_REF not found; cannot enforce change-rule (fail-closed)" >&2
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "$CHECK_ID",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "structural_change": False,
  "reason": "BASE_REF not found"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
  exit 1
fi

# Run detector
TMP_DIR=/tmp/invariants_ai
mkdir -p "$TMP_DIR"

git_write_unified_diff_range "$BASE_REF" "$HEAD_REF" "$TMP_DIR/pr.diff" 0
python3 "$ROOT_DIR/scripts/audit/detect_structural_changes.py" --diff-file "$TMP_DIR/pr.diff" --out "$TMP_DIR/detect.json"

structural=$(python3 - <<PY
import json
print("true" if json.load(open("/tmp/invariants_ai/detect.json")).get("structural_change") else "false")
PY
)

if [[ "$structural" == "true" ]]; then
  # Require threat/compliance doc updates
  if ! git_changed_files_range "$BASE_REF" "$HEAD_REF" | grep -Eq "docs/architecture/(THREAT_MODEL|COMPLIANCE_MAP)\.md"; then
    python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "$CHECK_ID",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "reason": "missing threat/compliance updates"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
    echo "❌ Structural change detected but threat/compliance docs not updated" >&2
    exit 1
  fi
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "$CHECK_ID",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "PASS",
  "structural_change": "$structural" == "true"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

echo "✅ Change rule OK: no structural changes detected."
