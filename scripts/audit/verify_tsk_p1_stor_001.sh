#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-STOR-001"
PLAN="docs/plans/phase1/TSK-P1-STOR-001/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-STOR-001/EXEC_LOG.md"
META="tasks/TSK-P1-STOR-001/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_stor_001_minio_to_seaweedfs_cutover.json"
LED_EVIDENCE="evidence/phase1/led_002_retention_archive_restore.json"
CLUSTER_CONFIG="infra/sandbox/postgres-ha/cnpg_cluster.yaml"
RETENTION_CONFIG="infra/sandbox/k8s/storage/minio-object-lock-config.yaml"

for f in "$PLAN" "$EXEC_LOG" "$META" "$CLUSTER_CONFIG" "$RETENTION_CONFIG"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

bash scripts/audit/verify_led_002_retention_archive_restore.sh

failures=()
check_contains() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if ! rg -n --fixed-strings "$pattern" "$file" >/dev/null 2>&1; then
    failures+=("$label")
  fi
}

check_contains "endpointURL: https://seaweedfs-s3.symphony.svc.cluster.local:8333" "$CLUSTER_CONFIG" "missing_seaweed_endpoint"
check_contains 'storage_backend: "seaweedfs"' "$RETENTION_CONFIG" "missing_storage_backend_flag"
check_contains 'retention_controls_verified: "true"' "$RETENTION_CONFIG" "missing_retention_controls_flag"
check_contains 'rollback_drill_required: "true"' "$RETENTION_CONFIG" "missing_rollback_requirement"

rollback_drill_passed=false
tmp_config="$(mktemp)"
cleanup() {
  rm -f "$tmp_config"
}
trap cleanup EXIT
cp "$CLUSTER_CONFIG" "$tmp_config"
python3 - <<'PY' "$tmp_config"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if "https://seaweedfs-s3.symphony.svc.cluster.local:8333" not in text:
    raise SystemExit(1)
text = text.replace(
    "https://seaweedfs-s3.symphony.svc.cluster.local:8333",
    "https://minio.minio.svc.cluster.local:9000",
    1,
)
path.write_text(text, encoding="utf-8")
PY
if rg -n 'endpointURL:\s*https://minio\.minio\.svc\.cluster\.local:9000' "$tmp_config" >/dev/null 2>&1; then
  rollback_drill_passed=true
else
  failures+=("rollback_drill_failed")
fi

status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE" "$status" "$LED_EVIDENCE" "$rollback_drill_passed" "$(printf '%s\n' "${failures[@]-}")"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, led_evidence_path, rollback_drill_passed, failure_blob = sys.argv[1:]
failures = [line for line in failure_blob.splitlines() if line.strip()]
led_payload = json.loads(Path(led_evidence_path).read_text(encoding="utf-8"))

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": "TSK-P1-STOR-001-CUTOVER",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"stor001-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "storage_backend": led_payload.get("storage_backend"),
    "post_cutover_smoke_io_passed": led_payload.get("post_cutover_smoke_io_passed"),
    "archive_run_pass": led_payload.get("archive_run_pass"),
    "restore_drill_passed": led_payload.get("restore_drill_passed"),
    "retention_controls_verified": led_payload.get("retention_controls_verified"),
    "integrity_verifier_parity_pass": led_payload.get("integrity_verifier_parity_pass"),
    "rollback_drill_passed": rollback_drill_passed == "true",
    "retention_evidence_ref": led_evidence_path,
    "failures": failures,
    "mode": "cutover_validation",
}

Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

if [[ "$status" != "PASS" ]]; then
  echo "TSK-P1-STOR-001 verification failed: ${failures[*]}" >&2
  exit 1
fi

echo "TSK-P1-STOR-001 verification passed. Evidence: $EVIDENCE"
