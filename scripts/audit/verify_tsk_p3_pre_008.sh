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

import yaml  # type: ignore

task_id = "TSK-P3-PRE-008"
registry = Path("docs/PHASE3/phase3_task_registry.yml")

def out(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

data = yaml.safe_load(registry.read_text(encoding="utf-8")) if registry.exists() else {}
entries = data.get("tasks", []) if isinstance(data, dict) else []
task_ids = {entry.get("task_id") for entry in entries if isinstance(entry, dict)}

actual_ids = set()
for meta in Path("tasks").glob("TSK-P3-*/meta.yml"):
    meta_obj = yaml.safe_load(meta.read_text(encoding="utf-8"))
    actual_ids.add(meta_obj["task_id"])

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

record("pre008_registry_exists", registry.exists(), "registry exists")
record("pre008_task_count", data.get("task_count") == len(entries), "task_count matches registry entry count")
record("pre008_all_phase3_tasks_present", task_ids == actual_ids, "registry contains all current Phase 3 tasks")
record("pre008_entry_shape", all(entry.get("task_type") in data.get("approved_task_types", []) and entry.get("wave") in data.get("approved_waves", []) and entry.get("ci_tier") in data.get("approved_ci_tiers", []) for entry in entries), "every task has valid task_type, wave, and ci_tier")
verify_entries = [entry for entry in entries if entry.get("task_type") == "VERIFY"]
record("pre008_verify_links", all(entry.get("verifies") in task_ids for entry in verify_entries), "every VERIFY task points at an existing IMPL task")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": out(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": out(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(registry)] + [str(p) for p in Path("tasks").glob("TSK-P3-*/meta.yml")],
    "observed_hashes": {str(registry): sha(registry)} | {str(p): sha(p) for p in Path("tasks").glob("TSK-P3-*/meta.yml")},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
