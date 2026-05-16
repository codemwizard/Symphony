#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 <<'PY'
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

task_id = "TSK-P3-PRE-003"
doc = Path("docs/operations/TASK_ID_NOMENCLATURE.md")

def run(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

text = doc.read_text(encoding="utf-8") if doc.exists() else ""
checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

record("pre003_doc_exists", doc.exists(), "nomenclature doc exists")
record("pre003_regex_present", "TSK-P3-(ACT|PRE|CLEAN|GOV|WP|SUPPORT|CI|W" in text, "Phase 3 regex is documented")
required_groups = ["ACT", "PRE", "CLEAN", "GOV", "WP", "SUPPORT", "CI", "W1", "W10"]
record("pre003_group_registry", all(group in text for group in required_groups), "Phase 3 approved group registry is documented")
legacy_markers = ["TSK-P0 | 143", "TSK-P1 | 128", "TASK-GOV | 19", "Legacy note:"]
record("pre003_legacy_inventory", all(marker in text for marker in legacy_markers), "legacy inventory includes usage counts and legacy warning")
record("pre003_validation_rules", "Legacy families from Phases 0-2 are rejected" in text and "Invalid for Phase 3" in text, "validation rules explicitly reject legacy families for Phase 3")

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": run(["git", "rev-parse", "HEAD"]),
    "timestamp_utc": run(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "status": status,
    "checks": checks,
    "observed_paths": [str(doc)] if doc.exists() else [],
    "observed_hashes": {str(doc): sha(doc)} if doc.exists() else {},
}
print(json.dumps(payload, indent=2))
if status != "PASS":
    sys.exit(1)
PY
