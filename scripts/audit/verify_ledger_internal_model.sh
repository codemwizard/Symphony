#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="LEDGER-001"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase2/ledger_001_internal_model.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"

pass=true
checks=()

check_file() {
  local path="$1"
  if [[ -f "$ROOT_DIR/$path" ]]; then
    checks+=("{\"check\":\"file:$path\",\"pass\":true}")
  else
    checks+=("{\"check\":\"file:$path\",\"pass\":false}")
    pass=false
  fi
}

check_rg() {
  local pattern="$1"
  local path="$2"
  if rg -n "$pattern" "$ROOT_DIR/$path" >/dev/null; then
    checks+=("{\"check\":\"rg:$pattern:$path\",\"pass\":true}")
  else
    checks+=("{\"check\":\"rg:$pattern:$path\",\"pass\":false}")
    pass=false
  fi
}

check_file "docs/plans/phase2/LEDGER-001/PLAN.md"
check_file "docs/architecture/adrs/ADR-0002-ledger-immutability-reconciliation.md"
check_file "schema/migrations/0071_phase2_internal_ledger_core.sql"
check_rg "posting-set model|event taxonomy|compensation model|escrow|freeze|FX" "docs/plans/phase2/LEDGER-001/PLAN.md"
check_rg "INV-156|INV-157|INV-158" "docs/invariants/INVARIANTS_MANIFEST.yml"
check_rg "internal_ledger_journals|internal_ledger_postings|create_internal_ledger_journal|verify_internal_ledger_journal_balance" "schema/migrations/0071_phase2_internal_ledger_core.sql"

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
  "check_id": "LEDGER-001-INTERNAL-MODEL",
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
