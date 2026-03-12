#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-012"
PLAN="docs/plans/phase1/TSK-P1-INT-012/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-012/EXEC_LOG.md"
META="tasks/TSK-P1-INT-012/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_012_retention_policy.json"
AUDIT_DOC="docs/security/AUDIT_LOGGING_PLAN.md"
VPC_DOC="docs/security/SOVEREIGN_VPC_POSTURE.md"
DR_SCRIPT="scripts/dr/generate_tsk_p1_int_007_bundle.sh"

for f in "$PLAN" "$EXEC_LOG" "$META" "$AUDIT_DOC" "$VPC_DOC" "$DR_SCRIPT"; do
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

check_contains "Active evidence" "$AUDIT_DOC" "missing_active_class"
check_contains "Archived evidence" "$AUDIT_DOC" "missing_archived_class"
check_contains "Historical evidence" "$AUDIT_DOC" "missing_historical_class"
check_contains "90 days" "$AUDIT_DOC" "missing_active_window"
check_contains "7 years" "$AUDIT_DOC" "missing_archived_window"
check_contains "10 years" "$AUDIT_DOC" "missing_historical_window"
check_contains 'verifier status is `PASS`' "$AUDIT_DOC" "missing_machine_checkable_trigger"
check_contains "archived evidence remains addressable for bundle reconstruction" "$AUDIT_DOC" "missing_bundle_reconstruction_rule"
check_contains "DR bundle selection must follow the declared retention policy" "$VPC_DOC" "missing_dr_bundle_policy_link"

status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE" "$status" "$(printf '%s\n' "${failures[@]-}")"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, failure_blob = sys.argv[1:]
failures = [m for m in failure_blob.splitlines() if m.strip()]

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": f"{task_id}-RETENTION-POLICY",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int012-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "active_retention_days": 90,
    "archived_retention_years": 7,
    "historical_retention_years": 10,
    "machine_checkable_triggers_present": "missing_machine_checkable_trigger" not in failures,
    "dr_bundle_policy_link_present": "missing_dr_bundle_policy_link" not in failures,
    "failures": failures,
    "mode": "retention_policy_validation",
}
Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "$TASK_ID verification failed: ${failures[*]}" >&2
  exit 1
fi

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
