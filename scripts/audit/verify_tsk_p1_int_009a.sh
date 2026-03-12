#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-009A"
PLAN="docs/plans/phase1/TSK-P1-INT-009A/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-009A/EXEC_LOG.md"
META="tasks/TSK-P1-INT-009A/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_009a_storage_policy_rescope.json"
POLICY_DOC="docs/operations/STORAGE_AND_INTEGRITY_POSITION_MINIO_TO_SEAWEEDFS.md"
STOR_META="tasks/TSK-P1-STOR-001/meta.yml"
REGISTRY="docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml"

for f in "$PLAN" "$EXEC_LOG" "$META" "$POLICY_DOC" "$STOR_META" "$REGISTRY"; do
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

check_contains "The default Phase-1 restore-time objective is 4 hours (14400 seconds)." "$POLICY_DOC" "missing_rto_cap"
check_contains "promotion requires an" "$POLICY_DOC" "missing_signoff_exception_rule"
check_contains "Does not become Symphony’s root trust claim." "$POLICY_DOC" "missing_non_trust_root_statement"
check_contains "Acceptance must stay backend-neutral: smoke IO, archive run, restore drill," "$POLICY_DOC" "missing_backend_neutral_policy_acceptance"
check_contains "Acceptance remains backend-neutral: smoke IO, archive run, restore drill, retention controls, and integrity verifier parity are the governing outcomes" "$STOR_META" "missing_stor_backend_neutral_acceptance"
check_contains 'post_cutover_smoke_io_passed=true' "$STOR_META" "missing_stor_smoke_io_gate"
check_contains 'integrity_verifier_parity_pass=true' "$STOR_META" "missing_stor_integrity_parity_gate"
check_contains 'scripts/audit/verify_tsk_p1_int_009a.sh:' "$REGISTRY" "missing_registry_int009a_script"
check_contains 'evidence/phase1/tsk_p1_int_009a_storage_policy_rescope.json' "$REGISTRY" "missing_registry_int009a_evidence"
check_contains 'scripts/audit/verify_tsk_p1_stor_001.sh:' "$REGISTRY" "missing_registry_stor001_script"
check_contains 'evidence/phase1/tsk_p1_stor_001_minio_to_seaweedfs_cutover.json' "$REGISTRY" "missing_registry_stor001_evidence"
check_contains 'scripts/audit/verify_tsk_p1_int_009b.sh:' "$REGISTRY" "missing_registry_int009b_script"
check_contains 'evidence/phase1/tsk_p1_int_009b_restore_parity.json' "$REGISTRY" "missing_registry_int009b_evidence"

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
failures = [line for line in failure_blob.splitlines() if line.strip()]


def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": "TSK-P1-INT-009A-STORAGE-POLICY",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int009a-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "storage_trust_model": "tamper_evident_architecture",
    "default_rto_seconds": 14400,
    "signoff_exception_rule_required": True,
    "stor001_backend_neutral_acceptance": status == "PASS" or "missing_stor_backend_neutral_acceptance" not in failures,
    "registry_mappings_present": all(not item.startswith("missing_registry_") for item in failures),
    "failures": failures,
    "mode": "semantic_policy_validation"
}

Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "TSK-P1-INT-009A verification failed: ${failures[*]}" >&2
  exit 1
fi

echo "TSK-P1-INT-009A verification passed. Evidence: $EVIDENCE"
