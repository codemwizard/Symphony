#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 <<'PY'
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

task_id = "TSK-P3-PRE-006"
validator = Path("scripts/audit/verify_task_meta_schema.sh")

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def out(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

tmpdir = Path(tempfile.mkdtemp(prefix="tsk_p3_pre_006_"))
root = tmpdir / "tasks"
root.mkdir(parents=True, exist_ok=True)

base = """schema_version: 1
phase: '3'
wave: 'WP'
task_id: TSK-P3-WP-001
title: "Valid phase 3 task"
owner_role: ARCHITECT
status: planned
depends_on: []
touches:
  - tasks/TSK-P3-WP-001/meta.yml
invariants:
  - INV-301
work:
  - "[ID w01] do one thing"
acceptance_criteria:
  - "[ID w01] one thing is verified"
verification:
  - echo ok
evidence:
  - path: evidence/phase3/example.json
    must_include:
      - task_id
failure_modes:
  - "missing => FAIL"
must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
  - docs/operations/TASK_ID_NOMENCLATURE.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
  - docs/PHASE3/PHASE3_INVARIANT_REGISTER.md
implementation_plan: docs/plans/phase3/TSK-P3-WP-001/PLAN.md
implementation_log: docs/plans/phase3/TSK-P3-WP-001/EXEC_LOG.md
notes: test
client: cursor
assigned_agent: architect
model: test
"""

def write_meta(name, text):
    d = root / name
    d.mkdir(parents=True, exist_ok=True)
    (d / "meta.yml").write_text(text, encoding="utf-8")

write_meta("valid", base)
write_meta("bad_id", base.replace("TSK-P3-WP-001", "TSK-P3-PREAUTH-001"))
write_meta("bad_wave", base.replace("wave: 'WP'", "wave: 'PREAUTH'"))
write_meta("bad_inv", base.replace("INV-301", "INV-201"))
write_meta("bad_read", base.replace("  - docs/operations/TASK_ID_NOMENCLATURE.md\n", ""))

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

valid = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash {validator} --mode strict --allow-legacy --root {root/'valid'} --scope all"])
bad_id = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash {validator} --mode strict --allow-legacy --root {root/'bad_id'} --scope all"])
bad_wave = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash {validator} --mode strict --allow-legacy --root {root/'bad_wave'} --scope all"])
bad_inv = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash {validator} --mode strict --allow-legacy --root {root/'bad_inv'} --scope all"])
bad_read = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash {validator} --mode strict --allow-legacy --root {root/'bad_read'} --scope all"])

record("pre006_valid_passes", valid.returncode == 0, "valid Phase 3 task meta passes strict validation")
record("pre006_invalid_id_rejected", bad_id.returncode != 0 and "phase3_task_id_invalid" in (bad_id.stdout + bad_id.stderr), "invalid Phase 3 task ID is rejected")
record("pre006_invalid_wave_rejected", bad_wave.returncode != 0 and "phase3_wave_invalid" in (bad_wave.stdout + bad_wave.stderr), "invalid Phase 3 wave is rejected")
record("pre006_invalid_invariant_rejected", bad_inv.returncode != 0 and "phase3_invalid_invariants" in (bad_inv.stdout + bad_inv.stderr), "out-of-range invariant is rejected")
record("pre006_missing_reads_rejected", bad_read.returncode != 0 and "phase3_missing_must_read" in (bad_read.stdout + bad_read.stderr), "missing Phase 3 must_read entries are rejected")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": out(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": out(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(validator)],
    "observed_hashes": {str(validator): sha(validator)},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
