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

task_id = "TSK-P3-PRE-007"
registry = Path("docs/PHASE3/phase3_task_registry.yml")

def out(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

text = registry.read_text(encoding="utf-8") if registry.exists() else ""
data = yaml.safe_load(text) if registry.exists() else {}

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

record("pre007_registry_exists", registry.exists(), "registry file exists")
record("pre007_header_contract", "Governance contract" in text and "task_type vocabulary" in text and "ci_tier vocabulary" in text, "header comments document the schema and governance contract")
record("pre007_examples_present", isinstance(data.get("schema_examples"), list) and len(data.get("schema_examples", [])) >= 3, "schema examples are present")
record("pre007_example_types", {"IMPL", "VERIFY", "CERT"}.issubset({item.get("task_type") for item in data.get("schema_examples", [])}), "example tasks include IMPL, VERIFY, and CERT")
record("pre007_yaml_shape", isinstance(data.get("approved_task_types"), list) and isinstance(data.get("approved_ci_tiers"), list) and isinstance(data.get("tasks"), list), "registry YAML shape is valid")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": out(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": out(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(registry)],
    "observed_hashes": {str(registry): sha(registry)} if registry.exists() else {},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
