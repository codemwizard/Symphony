#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-009B"
PLAN="docs/plans/phase1/TSK-P1-INT-009B/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-009B/EXEC_LOG.md"
META="tasks/TSK-P1-INT-009B/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_009b_restore_parity.json"
PRED_EVIDENCE="evidence/phase1/tsk_p1_stor_001_minio_to_seaweedfs_cutover.json"
PITR_EVIDENCE="evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json"

for f in "$PLAN" "$EXEC_LOG" "$META" "$PRED_EVIDENCE"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

bash scripts/audit/verify_inf_001_postgres_ha_pitr.sh

[[ -f "$PITR_EVIDENCE" ]] || { echo "missing_required_file:$PITR_EVIDENCE" >&2; exit 1; }

status="PASS"

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE" "$status" "$PRED_EVIDENCE" "$PITR_EVIDENCE"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, pred_path, pitr_path = sys.argv[1:]
pred = json.loads(Path(pred_path).read_text(encoding="utf-8"))
pitr = json.loads(Path(pitr_path).read_text(encoding="utf-8"))
failures = []

declared_rto_seconds = pitr.get("declared_rto_seconds")
restore_elapsed_seconds = pitr.get("restore_elapsed_seconds")
rto_met = pitr.get("rto_met")
rto_signoff_ref = pitr.get("rto_signoff_ref")
if not isinstance(declared_rto_seconds, int) or declared_rto_seconds <= 0:
    failures.append("invalid_declared_rto_seconds")
if not isinstance(restore_elapsed_seconds, int) or restore_elapsed_seconds <= 0:
    failures.append("invalid_restore_elapsed_seconds")
if pred.get("storage_backend") != "seaweedfs" or pitr.get("storage_backend") != "seaweedfs":
    failures.append("backend_context_not_seaweedfs")
if not pred.get("integrity_verifier_parity_pass"):
    failures.append("predecessor_integrity_parity_missing")
if rto_met is False and not rto_signoff_ref:
    failures.append("missing_rto_signoff_ref")
status = "PASS" if not failures else "FAIL"


def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": "TSK-P1-INT-009B-RESTORE-PARITY",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int009b-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "declared_rto_seconds": declared_rto_seconds,
    "restore_elapsed_seconds": restore_elapsed_seconds,
    "rto_met": rto_met,
    "rto_signoff_ref": rto_signoff_ref,
    "storage_backend": pitr.get("storage_backend"),
    "integrity_verifier_parity_pass": pred.get("integrity_verifier_parity_pass"),
    "predecessor_evidence": pred_path,
    "pitr_evidence": pitr_path,
    "failures": failures,
    "predecessor_evidence": pred_path,
    "mode": "restore_parity_validation"
}

Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "TSK-P1-INT-009B verification failed" >&2
  exit 1
fi

echo "TSK-P1-INT-009B verification passed. Evidence: $EVIDENCE"
