#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-010"
PLAN="docs/plans/phase1/TSK-P1-INT-010/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-010/EXEC_LOG.md"
META="tasks/TSK-P1-INT-010/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_010_language_sync.json"
TARGET_DOC="docs/product/greentech4ce/StartUP.md"

for f in "$PLAN" "$EXEC_LOG" "$META" "$TARGET_DOC"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

failures=()
check_contains() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if ! rg -n --fixed-strings "$pattern" "$file" >/dev/null 2>&1; then
    failures+=("$label")
  fi
}

check_contains "tamper-evident" "$TARGET_DOC" "missing_tamper_evident_wording"
check_contains "signed offline/pre-rail bridge" "$TARGET_DOC" "missing_signed_offline_bridge_wording"
check_contains "explicit acknowledgement" "$TARGET_DOC" "missing_acknowledgement_wording"
check_contains "AWAITING_EXECUTION" "$TARGET_DOC" "missing_awaiting_execution_wording"

status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE" "$status" "$TARGET_DOC" "$(printf '%s\n' "${failures[@]-}")"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, target_doc, failure_blob = sys.argv[1:]
failures = [m for m in failure_blob.splitlines() if m.strip()]

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": f"{task_id}-LANGUAGE-SYNC",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int010-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "target_doc": target_doc,
    "tamper_evident_language_present": "missing_tamper_evident_wording" not in failures,
    "signed_offline_bridge_language_present": "missing_signed_offline_bridge_wording" not in failures,
    "acknowledgement_dependency_present": "missing_acknowledgement_wording" not in failures,
    "awaiting_execution_state_visible": "missing_awaiting_execution_wording" not in failures,
    "failures": failures,
    "mode": "semantic_language_validation",
}
Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "$TASK_ID verification failed: ${failures[*]}" >&2
  exit 1
fi

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
