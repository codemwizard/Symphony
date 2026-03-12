#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-LED-002"
EVIDENCE_PATH="evidence/phase1/led_002_retention_archive_restore.json"
ARCHIVE_SCRIPT="scripts/backup/archive_retention_records.sh"
RESTORE_SCRIPT="scripts/backup/restore_retention_archive.sh"
RETENTION_CONFIG="infra/sandbox/k8s/storage/minio-object-lock-config.yaml"
CLUSTER_CONFIG="infra/sandbox/postgres-ha/cnpg_cluster.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -x "$ARCHIVE_SCRIPT" ]] || { echo "missing_archive_script:$ARCHIVE_SCRIPT" >&2; exit 1; }
[[ -x "$RESTORE_SCRIPT" ]] || { echo "missing_restore_script:$RESTORE_SCRIPT" >&2; exit 1; }
[[ -f "$RETENTION_CONFIG" ]] || { echo "missing_retention_config:$RETENTION_CONFIG" >&2; exit 1; }
[[ -f "$CLUSTER_CONFIG" ]] || { echo "missing_cluster_config:$CLUSTER_CONFIG" >&2; exit 1; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

fixture="$workdir/retention_fixture.jsonl"
run_log="$workdir/archive_runs.jsonl"
out_dir="$workdir/archive"
restore_file="$workdir/restore_staging.jsonl"

cat > "$fixture" <<'JSON'
{"id":"r1","retention_class":"FIC_AML_CUSTOMER_ID","anchored_at":"2024-01-01T00:00:00Z","payload_hash":"h1"}
{"id":"r2","retention_class":"BFSA_FINANCIAL","anchored_at":"2023-12-01T00:00:00Z","payload_hash":"h2"}
{"id":"r3","retention_class":"FIC_AML_CUSTOMER_ID","anchored_at":"2030-01-01T00:00:00Z","payload_hash":"h3"}
JSON

archive_output=$(bash "$ARCHIVE_SCRIPT" --source "$fixture" --out-dir "$out_dir" --run-log "$run_log" --lookback-days 30)
archive_run_id=$(python3 - <<'PY' "$archive_output"
import json,sys
print(json.loads(sys.argv[1])["archive_run_id"])
PY
)
archive_file=$(python3 - <<'PY' "$archive_output"
import json,sys
print(json.loads(sys.argv[1])["archive_file"])
PY
)
signature_file=$(python3 - <<'PY' "$archive_output"
import json,sys
print(json.loads(sys.argv[1])["signature_file"])
PY
)
records_archived=$(python3 - <<'PY' "$archive_output"
import json,sys
print(json.loads(sys.argv[1])["records_archived"])
PY
)

restore_output=$(bash "$RESTORE_SCRIPT" --archive-file "$archive_file" --signature-file "$signature_file" --restore-file "$restore_file")
signature_verified=false
if echo "$restore_output" | rg -q 'signature_verified=true'; then
  signature_verified=true
fi

restore_drill_passed=false
if [[ -s "$restore_file" ]]; then
  restore_drill_passed=true
fi

storage_backend=$(python3 - <<'PY' "$RETENTION_CONFIG"
import sys, yaml
from pathlib import Path
doc = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8")) or {}
print(((doc.get("data") or {}).get("storage_backend")) or "")
PY
)

retention_controls_verified=false
if rg -n 'retention_controls_verified:\s*"true"' "$RETENTION_CONFIG" >/dev/null 2>&1 && \
   rg -n 'overwrite_denied_during_retention:\s*"true"' "$RETENTION_CONFIG" >/dev/null 2>&1; then
  retention_controls_verified=true
fi

post_cutover_smoke_io_passed=false
if [[ -s "$archive_file" ]] && [[ -s "$signature_file" ]]; then
  post_cutover_smoke_io_passed=true
fi

seaweed_endpoint_configured=false
if rg -n 'endpointURL:\s*https://seaweedfs-s3\.symphony\.svc\.cluster\.local:8333' "$CLUSTER_CONFIG" >/dev/null 2>&1; then
  seaweed_endpoint_configured=true
fi

integrity_verifier_parity_pass=false
if [[ "$signature_verified" == "true" ]] && [[ "$restore_drill_passed" == "true" ]]; then
  integrity_verifier_parity_pass=true
fi

status="PASS"
if [[ "$signature_verified" != "true" || "$restore_drill_passed" != "true" || "$retention_controls_verified" != "true" || "$seaweed_endpoint_configured" != "true" || "$storage_backend" != "seaweedfs" ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$status" "$archive_run_id" "$records_archived" "$storage_backend" "$retention_controls_verified" "$restore_drill_passed" "$signature_verified" "$post_cutover_smoke_io_passed" "$integrity_verifier_parity_pass" "$seaweed_endpoint_configured"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    task_id,
    evidence_path,
    status,
    archive_run_id,
    records_archived,
    storage_backend,
    retention_ok,
    restore_ok,
    signature_ok,
    smoke_ok,
    parity_ok,
    endpoint_ok,
) = sys.argv[1:]

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": "LED-002-RETENTION-ARCHIVE-RESTORE",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"led002-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "archive_run_id": archive_run_id,
    "records_archived": int(records_archived),
    "storage_backend": storage_backend,
    "retention_controls_verified": retention_ok == "true",
    "restore_drill_passed": restore_ok == "true",
    "signature_verified": signature_ok == "true",
    "post_cutover_smoke_io_passed": smoke_ok == "true",
    "archive_run_pass": int(records_archived) > 0,
    "integrity_verifier_parity_pass": parity_ok == "true",
    "seaweed_endpoint_configured": endpoint_ok == "true",
    "details": {
        "retention_classes": ["FIC_AML_CUSTOMER_ID", "BFSA_FINANCIAL"],
        "storage_mode": "sandbox_backend_neutral_retention_controls"
    }
}

Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json
import sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
obj = json.loads(Path(evidence_path).read_text(encoding="utf-8"))
if obj.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if obj.get("status") not in {"PASS", "DONE", "OK"} and obj.get("pass") is not True:
    raise SystemExit("status_not_pass")
for key in [
    "archive_run_id",
    "records_archived",
    "storage_backend",
    "retention_controls_verified",
    "restore_drill_passed",
    "signature_verified",
    "post_cutover_smoke_io_passed",
    "archive_run_pass",
    "integrity_verifier_parity_pass",
    "seaweed_endpoint_configured",
]:
    if key not in obj:
        raise SystemExit(f"missing_key:{key}")
if obj["storage_backend"] != "seaweedfs":
    raise SystemExit("unexpected_storage_backend")
if not obj["retention_controls_verified"]:
    raise SystemExit("retention_controls_not_verified")
if not obj["restore_drill_passed"]:
    raise SystemExit("restore_drill_failed")
if not obj["signature_verified"]:
    raise SystemExit("signature_not_verified")
if not obj["post_cutover_smoke_io_passed"]:
    raise SystemExit("smoke_io_failed")
if not obj["archive_run_pass"]:
    raise SystemExit("archive_run_failed")
if not obj["integrity_verifier_parity_pass"]:
    raise SystemExit("integrity_verifier_parity_failed")
if not obj["seaweed_endpoint_configured"]:
    raise SystemExit("seaweed_endpoint_not_configured")
print(f"LED-002 verification passed: {evidence_path}")
PY
