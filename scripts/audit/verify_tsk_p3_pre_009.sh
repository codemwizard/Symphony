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

import yaml  # type: ignore

task_id = "TSK-P3-PRE-009"
generator = Path("scripts/agent/generate_task_pack.py")
registry = Path("docs/PHASE3/phase3_task_registry.yml")
nomenclature = Path("docs/operations/TASK_ID_NOMENCLATURE.md")
matrix = Path("docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md")

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def out(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

matrix_text = matrix.read_text(encoding="utf-8") if matrix.exists() else ""
record("pre009_phase2_reconciled", "FORMALLY UNOPENED" not in matrix_text, "capability matrix no longer labels Phase 2 as formally unopened")

tmpdir = Path(tempfile.mkdtemp(prefix="tsk_p3_pre_009_"))
config = tmpdir / "config.json"
config.write_text(json.dumps({
    "task_id": "TSK-P3-WP-098",
    "title": "Readiness gate smoke task",
    "owner": "ARCHITECT",
    "blast_radius": "DOCS_ONLY",
    "wave": "WP",
    "work": ["[ID smoke_w01] generate smoke task"],
    "acceptance_criteria": ["[ID smoke_w01] smoke task passes schema validation"],
    "verifiers": ["scripts/audit/verify_example.sh"],
    "evidence": {"path": "evidence/phase3/example.json", "must_include": ["task_id", "git_sha", "timestamp_utc", "status", "checks", "observed_hashes"]}
}, indent=2), encoding="utf-8")
gen = run(["python3", str(generator), "--config", str(config), "--phase3", "--base-dir", str(tmpdir)])
val = run(["bash", "-lc", f"PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root {tmpdir/'tasks'} --scope all"])
record("pre009_test_pack_generation", gen.returncode == 0 and val.returncode == 0, "generator and validator succeed on a temp Phase 3 task pack")

record("pre009_nomenclature_exists", nomenclature.exists() and "Approved Phase 3 Group Registry" in nomenclature.read_text(encoding="utf-8"), "nomenclature doc exists with Phase 3 group registry")
registry_data = yaml.safe_load(registry.read_text(encoding="utf-8")) if registry.exists() else {}
entries = registry_data.get("tasks", []) if isinstance(registry_data, dict) else []
record("pre009_registry_populated", registry.exists() and registry_data.get("task_count") == len(entries) and len(entries) > 0, "registry exists, parses, and task_count matches")
pre_ci = run(["bash", "scripts/dev/pre_ci.sh"])
record("pre009_pre_ci", pre_ci.returncode == 0, "full pre_ci passes")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": out(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": out(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(generator), str(registry), str(nomenclature), str(matrix)],
    "observed_hashes": {str(path): sha(path) for path in [generator, registry, nomenclature, matrix] if path.exists()},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
