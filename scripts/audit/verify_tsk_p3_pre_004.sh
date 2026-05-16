#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 <<'PY'
import hashlib
import json
import subprocess
import sys
from pathlib import Path

task_id = "TSK-P3-PRE-004"
template = Path("tasks/_template/meta.yml")

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def git(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

text = template.read_text(encoding="utf-8") if template.exists() else ""
checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

record("pre004_template_exists", template.exists(), "template exists")
record("pre004_wave_field", "wave: '<WAVE>'" in text, "wave field is present in template")
record("pre004_phase3_reads", "docs/operations/TASK_ID_NOMENCLATURE.md" in text and "docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md" in text and "docs/PHASE3/PHASE3_INVARIANT_REGISTER.md" in text, "Phase 3 must_read guidance is present")
record("pre004_phase3_path_mapping", "For Phase 3 use docs/plans/phase3/<TASK-ID>/PLAN.md" in text, "Phase 3 path mapping comments are present")
inventory = run(["bash", "-lc", "PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode inventory --allow-legacy --root tasks --scope all"])
record("pre004_inventory_validator", inventory.returncode == 0, "validator inventory mode passes with template adaptation")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": git(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": git(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(template)],
    "observed_hashes": {str(template): sha(template)},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    if inventory.stdout:
        print(inventory.stdout, file=sys.stderr)
    if inventory.stderr:
        print(inventory.stderr, file=sys.stderr)
    sys.exit(1)
PY
