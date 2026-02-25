#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/core_boundary.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

core_dirs=(
  "$ROOT_DIR/src/Symphony.Core"
  "$ROOT_DIR/src/Symphony.Executor"
)

matches=()
MATCHES_FILE="$(mktemp)"
trap 'rm -f "$MATCHES_FILE"' EXIT

for d in "${core_dirs[@]}"; do
  if [[ -d "$d" ]]; then
    while IFS= read -r -d '' f; do
      matches+=("${f#$ROOT_DIR/}")
    done < <(find "$d" -type f \( -name "*.js" -o -name "*.ts" -o -name "package.json" \) -print0)
  fi
done

if [[ ${#matches[@]} -gt 0 ]]; then
  printf '%s\n' "${matches[@]}" > "$MATCHES_FILE"
fi

MATCHES_FILE="$MATCHES_FILE" python3 - <<PY
import json
import os
from pathlib import Path
matches_file = Path(os.environ["MATCHES_FILE"])
lines = []
if matches_file.exists():
    lines = [l.strip() for l in matches_file.read_text(encoding="utf-8").splitlines() if l.strip()]
out = {
    "check_id": "SEC-CORE-BOUNDARY",
    "timestamp_utc": "${EVIDENCE_TS}",
    "git_sha": "${EVIDENCE_GIT_SHA}",
    "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
    "status": "FAIL" if lines else "PASS",
    "matches": lines,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ ${#matches[@]} -gt 0 ]]; then
  echo "Core boundary lint failed. Node artifacts found in core paths:" >&2
  printf '%s\n' "${matches[@]}" >&2
  exit 1
fi

echo "Core boundary lint passed. Evidence: $EVIDENCE_FILE"
