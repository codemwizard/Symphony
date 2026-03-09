#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="S5-GATE-001"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase2/s5_gate_001_boundary_approval.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"

pass=true
checks=()

require_file() {
  local path="$1"
  if [[ -f "$ROOT_DIR/$path" ]]; then
    checks+=("{\"check\":\"file:$path\",\"pass\":true}")
  else
    checks+=("{\"check\":\"file:$path\",\"pass\":false}")
    pass=false
  fi
}

require_rg() {
  local pattern="$1"
  local path="$2"
  if rg -n "$pattern" "$ROOT_DIR/$path" >/dev/null; then
    checks+=("{\"check\":\"rg:$pattern:$path\",\"pass\":true}")
  else
    checks+=("{\"check\":\"rg:$pattern:$path\",\"pass\":false}")
    pass=false
  fi
}

require_file "docs/plans/phase2/SPRINT5_LANE_B_BLOCKERS.md"
require_file "tasks/LEDGER-001/meta.yml"
require_file "tasks/LEDGER-002/meta.yml"
require_rg "Lane A|Lane B|key-management architecture|authority model for governance events|external verification artifact format" "docs/plans/phase2/SPRINT5_LANE_B_BLOCKERS.md"
require_rg "S5-GATE-001" "tasks/LEDGER-001/meta.yml"
require_rg "S5-GATE-001" "tasks/LEDGER-002/meta.yml"

checks_json="$(printf '%s\n' "${checks[@]}" | python3 - <<'PY'
import json,sys
items=[json.loads(line) for line in sys.stdin if line.strip()]
print(json.dumps(items))
PY
)"

python3 - <<PY
import json
from pathlib import Path
payload = {
  "check_id": "S5-GATE-001-BOUNDARY-APPROVAL",
  "task_id": "$TASK_ID",
  "timestamp_utc": "$ts",
  "git_sha": "$git_sha_val",
  "schema_fingerprint": "$schema_fp",
  "status": "PASS" if "$pass" == "true" else "FAIL",
  "pass": "$pass" == "true",
  "details": {
    "checks": json.loads('''$checks_json''')
  }
}
Path("$EVIDENCE_PATH").write_text(json.dumps(payload, indent=2) + "\\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
