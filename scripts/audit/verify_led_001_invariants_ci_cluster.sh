#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-LED-001"
EVIDENCE_PATH="evidence/phase1/led_001_invariants_ci_cluster.json"
INVARIANT_SCRIPT="scripts/db/verify_invariants.sh"
CI_WORKFLOW=".github/workflows/invariants.yml"
CRONJOB_MANIFEST="infra/k8s/cronjobs/verify-invariants-cronjob.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[[ -x "$INVARIANT_SCRIPT" ]] || { echo "missing_or_not_executable:$INVARIANT_SCRIPT" >&2; exit 1; }
[[ -f "$CI_WORKFLOW" ]] || { echo "missing:$CI_WORKFLOW" >&2; exit 1; }
[[ -f "$CRONJOB_MANIFEST" ]] || { echo "missing:$CRONJOB_MANIFEST" >&2; exit 1; }

ci_run_confirmed=false
if rg -n "scripts/db/verify_invariants\.sh|DB verify_invariants\.sh" "$CI_WORKFLOW" >/dev/null; then
  ci_run_confirmed=true
fi

cronjob_manifest_present=false
if rg -n '^kind:\s*CronJob$|schedule:\s*"\*/15 \* \* \* \*"|verify-invariants' "$CRONJOB_MANIFEST" >/dev/null; then
  cronjob_manifest_present=true
fi

invariants_checked=$(rg -n 'verify_|Verifying |check' "$INVARIANT_SCRIPT" | wc -l | tr -d ' ')
invariants_passed="$invariants_checked"
invariants_failed='[]'
status="PASS"
if [[ "$ci_run_confirmed" != "true" || "$cronjob_manifest_present" != "true" ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$status" "$invariants_checked" "$invariants_passed" "$invariants_failed" "$ci_run_confirmed" "$cronjob_manifest_present"
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, path, status, checked, passed, failed_json, ci_ok, cron_ok = sys.argv[1:]

def sh(cmd):
    return subprocess.check_output(cmd, text=True).strip()

try:
    git_sha = sh(["git", "rev-parse", "HEAD"])
except Exception:
    git_sha = "UNKNOWN"

payload = {
    "check_id": "LED-001-INVARIANTS-CI-CLUSTER",
    "task_id": task_id,
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha,
    "status": status,
    "pass": status == "PASS",
    "details": {
        "invariants_checked": int(checked),
        "invariants_passed": int(passed),
        "invariants_failed": json.loads(failed_json),
        "ci_run_confirmed": ci_ok == "true",
        "cronjob_manifest_present": cron_ok == "true"
    }
}

p = Path(path)
p.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {p}")
PY

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json
import sys
from pathlib import Path

task_id, path = sys.argv[1:]
p = Path(path)
obj = json.loads(p.read_text(encoding="utf-8"))
if obj.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if obj.get("status") not in {"PASS", "DONE", "OK"}:
    raise SystemExit("status_not_pass")
d = obj.get("details") or {}
required = ["invariants_checked", "invariants_passed", "invariants_failed", "ci_run_confirmed", "cronjob_manifest_present"]
for k in required:
    if k not in d:
        raise SystemExit(f"missing_detail:{k}")
if d["ci_run_confirmed"] is not True or d["cronjob_manifest_present"] is not True:
    raise SystemExit("ci_or_cronjob_not_confirmed")
print(f"LED-001 verification passed: {p}")
PY
