#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/core_boundary.json"

mkdir -p "$EVIDENCE_DIR"

core_dirs=(
  "$ROOT_DIR/src/Symphony.Core"
  "$ROOT_DIR/src/Symphony.Executor"
)

matches=()

for d in "${core_dirs[@]}"; do
  if [[ -d "$d" ]]; then
    while IFS= read -r -d '' f; do
      matches+=("${f#$ROOT_DIR/}")
    done < <(find "$d" -type f \( -name "*.js" -o -name "*.ts" -o -name "package.json" \) -print0)
  fi
done

printf '%s\n' "${matches[@]}" | python3 - <<PY
import json
import sys
from pathlib import Path
lines = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
out = {"status": "fail" if lines else "pass", "matches": lines}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ ${#matches[@]} -gt 0 ]]; then
  echo "Core boundary lint failed. Node artifacts found in core paths:" >&2
  printf '%s\n' "${matches[@]}" >&2
  exit 1
fi

echo "Core boundary lint passed. Evidence: $EVIDENCE_FILE"
