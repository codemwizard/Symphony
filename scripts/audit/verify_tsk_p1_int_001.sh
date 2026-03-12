#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-001"
PLAN="docs/plans/phase1/TSK-P1-INT-001/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-001/EXEC_LOG.md"
META="tasks/TSK-P1-INT-001/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_001_claim_reframe.json"

for f in "$PLAN" "$EXEC_LOG" "$META"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

required_sections=("objective" "scope" "implementation_steps" "acceptance_criteria" "remediation_trace")
missing=()
for s in "${required_sections[@]}"; do
  if ! rg -n "^## ${s}$" "$PLAN" >/dev/null 2>&1; then
    missing+=("$s")
  fi
done

status="PASS"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE" "$status" "$(printf '%s\n' "${missing[@]-}")"
import json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, missing_blob = sys.argv[1:]
missing=[m for m in missing_blob.splitlines() if m.strip()]

def git_sha():
    try:
        return subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload={
  "check_id": f"{task_id}-PLAN-SCAFFOLD",
  "task_id": task_id,
  "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
  "git_sha": git_sha(),
  "status": status,
  "pass": status == "PASS",
  "missing_sections": missing,
  "mode": "plan_scaffold_validation"
}
Path(evidence_path).write_text(json.dumps(payload, indent=2)+"\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "$TASK_ID verification failed: missing plan sections (${missing[*]})" >&2
  exit 1
fi

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
