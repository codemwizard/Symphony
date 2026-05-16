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

task_id = "TSK-P3-PRE-005"
generator = Path("scripts/agent/generate_task_pack.py")

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def out(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

tmpdir = Path(tempfile.mkdtemp(prefix="tsk_p3_pre_005_"))
config = tmpdir / "valid.json"
config.write_text(json.dumps({
    "task_id": "TSK-P3-WP-099",
    "title": "Test generator path for phase 3",
    "owner": "ARCHITECT",
    "phase": "3",
    "blast_radius": "DOCS_ONLY",
    "wave": "WP",
    "work": ["[ID test_w01] create a test task pack"],
    "acceptance_criteria": ["[ID test_w01] generated meta and plan exist"],
    "verifiers": ["scripts/audit/verify_example.sh"],
    "evidence": {"path": "evidence/phase3/example.json", "must_include": ["task_id", "git_sha", "timestamp_utc", "status", "checks", "observed_hashes"]}
}, indent=2), encoding="utf-8")

valid = run(["python3", str(generator), "--config", str(config), "--phase3", "--base-dir", str(tmpdir)])
meta = tmpdir / "tasks" / "TSK-P3-WP-099" / "meta.yml"
plan = tmpdir / "docs" / "plans" / "phase3" / "TSK-P3-WP-099" / "PLAN.md"
meta_text = meta.read_text(encoding="utf-8") if meta.exists() else ""
plan_text = plan.read_text(encoding="utf-8") if plan.exists() else ""
record("pre005_valid_generation", valid.returncode == 0 and meta.exists() and plan.exists(), "Phase 3 generator produces task pack in temp output root")
record("pre005_wave_and_reads", "wave: 'WP'" in meta_text and "docs/operations/TASK_ID_NOMENCLATURE.md" in meta_text and "docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md" in meta_text, "generated meta includes Phase 3 wave and must_read defaults")
record("pre005_plan_references", "PHASE3_CAPABILITY_BOUNDARY.md" in plan_text and "TASK_ID_NOMENCLATURE.md" in plan_text, "generated PLAN references Phase 3 constitutional docs")

bad_config = tmpdir / "invalid.json"
bad_config.write_text(json.dumps({
    "task_id": "TSK-P3-PREAUTH-001",
    "title": "Bad phase 3 id",
    "owner": "ARCHITECT",
    "phase": "3",
    "blast_radius": "DOCS_ONLY",
    "wave": "PREAUTH",
    "work": ["[ID bad_w01] invalid config"],
    "acceptance_criteria": ["[ID bad_w01] generation must fail"],
    "verifiers": ["scripts/audit/verify_example.sh"],
    "evidence": {"path": "evidence/phase3/example.json", "must_include": ["task_id", "git_sha", "timestamp_utc", "status", "checks", "observed_hashes"]}
}, indent=2), encoding="utf-8")
bad = run(["python3", str(generator), "--config", str(bad_config), "--base-dir", str(tmpdir)])
record("pre005_invalid_id_rejected", bad.returncode != 0 and "Invalid Phase 3 task_id" in (bad.stderr + bad.stdout), "generator rejects invalid Phase 3 task IDs")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": out(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": out(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(generator)],
    "observed_hashes": {str(generator): sha(generator)},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
