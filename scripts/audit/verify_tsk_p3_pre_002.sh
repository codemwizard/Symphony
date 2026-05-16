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

task_id = "TSK-P3-PRE-002"
doc = Path("docs/PHASE3/PHASE3_CI_TIER_MODEL.md")

def run(cmd):
    return subprocess.check_output(cmd, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

checks = []
def record(cid, passed, detail):
    checks.append({"id": cid, "result": "PASS" if passed else "FAIL", "detail": detail})

text = doc.read_text(encoding="utf-8") if doc.exists() else ""
record("pre002_doc_exists", doc.exists(), "CI tier model exists")
record("pre002_tiers_defined", all(token in text for token in ["`T0`", "`T1`", "`T2`", "`T3`", "`T4`"]), "all five tiers are defined")
record("pre002_invariants_listed", all(f"INV-30{i}" in text for i in range(1, 10)) and "INV-310" in text, "all Phase 3 invariants are referenced by tier")
record("pre002_assignment_rules", "Tier Assignment Rules" in text and "Wave influence" in text, "tier assignment rules are documented")
record("pre002_escalation_policy", "Escalation Matrix" in text and "Failure tier" in text, "escalation policy is documented")

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
