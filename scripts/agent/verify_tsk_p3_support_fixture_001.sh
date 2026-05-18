#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 <<'PY'
import hashlib
import json
import subprocess
import sys
from pathlib import Path

task_id = "TSK-P3-SUPPORT-FIXTURE-001"
contract = Path("docs/architecture/PHASE3_CANONICAL_REPLAY_FIXTURE_CONTRACT.md")
verifier = Path("scripts/agent/verify_tsk_p3_support_fixture_001.sh")
runtime_index = Path("docs/tasks/PHASE3_RUNTIME_TASKS.md")
registry = Path("docs/PHASE3/phase3_task_registry.yml")
meta = Path("tasks/TSK-P3-SUPPORT-FIXTURE-001/meta.yml")
plan = Path("docs/plans/phase3/TSK-P3-SUPPORT-FIXTURE-001/PLAN.md")
exec_log = Path("docs/plans/phase3/TSK-P3-SUPPORT-FIXTURE-001/EXEC_LOG.md")

targets = [contract, verifier, runtime_index, registry, meta, plan, exec_log]
checks = []
observed_paths = []
observed_hashes = {}
command_outputs = []
execution_trace = []

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()

def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def record(check_id: str, passed: bool, detail: str) -> None:
    checks.append({"id": check_id, "result": "PASS" if passed else "FAIL", "detail": detail})
    execution_trace.append(f"{check_id}:{'PASS' if passed else 'FAIL'}:{detail}")

git_sha = run(["git", "rev-parse", "HEAD"])
timestamp_utc = run(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"])

exists_ok = all(p.exists() for p in targets)
record("FIXTURE-FILES-EXIST", exists_ok, "contract, verifier, runtime index, registry, meta, plan, and exec log exist")

text = contract.read_text(encoding="utf-8") if contract.exists() else ""

required_tokens = [
    "P3-SURF-001",
    "P3-SURF-002",
    "P3-SURF-003",
    "P3-SURF-006",
    "additive-only",
    "Wave 1 lineage meaning",
    "Wave 1 authority meaning",
    "lineage_valid",
    "lineage_invalid",
    "authority_valid",
    "authority_invalid",
    "delegation_valid",
    "delegation_invalid",
    "legitimacy_projection_valid",
    "legitimacy_projection_invalid",
    "negative_sqlstate",
    "wave1_semantics_preserved",
]
missing = [token for token in required_tokens if token not in text]
record("FIXTURE-REQUIRED-TOKENS", not missing, "contract covers all owning surfaces, fixture families, and additive reconciliation rules" if not missing else f"missing tokens: {missing}")

heading_tokens = [
    "## Additive-Only Reconciliation Rule",
    "## Canonical Fixture Families",
    "## Deterministic Fixture Identity",
    "## Fixture Coverage Matrix",
    "## Replay Safety",
]
missing_headings = [token for token in heading_tokens if token not in text]
record("FIXTURE-HEADINGS", not missing_headings, "contract includes required fixture sections" if not missing_headings else f"missing headings: {missing_headings}")

coverage_expectations = [
    "valid dependency traversal",
    "valid policy and authority lineage traversal",
    "illegitimate-ancestor blocking",
    "out-of-scope and revoked-authority blocking",
    "deterministic positive and negative replay closure",
]
missing_coverage = [token for token in coverage_expectations if token not in text]
record("FIXTURE-COVERAGE", not missing_coverage, "contract declares required cross-surface fixture coverage" if not missing_coverage else f"missing coverage tokens: {missing_coverage}")

runtime_index_text = runtime_index.read_text(encoding="utf-8") if runtime_index.exists() else ""
registry_text = registry.read_text(encoding="utf-8") if registry.exists() else ""
runtime_ok = "| TSK-P3-SUPPORT-FIXTURE-001 |" in runtime_index_text
registry_ok = "task_id: TSK-P3-SUPPORT-FIXTURE-001" in registry_text
record("FIXTURE-RUNTIME-INDEX", runtime_ok, "runtime task index contains support fixture task")
record("FIXTURE-REGISTRY", registry_ok, "phase3 task registry contains support fixture task")

for path in targets:
    if path.exists():
        observed_paths.append(str(path))
        observed_hashes[str(path)] = sha256(path)

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
command_outputs.append(f"git_sha={git_sha}")
command_outputs.append(f"timestamp_utc={timestamp_utc}")
command_outputs.extend([f"{item['id']}={item['result']}" for item in checks])

payload = {
    "task_id": task_id,
    "git_sha": git_sha,
    "timestamp_utc": timestamp_utc,
    "status": status,
    "checks": checks,
    "observed_paths": observed_paths,
    "observed_hashes": observed_hashes,
    "command_outputs": command_outputs,
    "execution_trace": execution_trace,
}

print(json.dumps(payload, indent=2))

if status != "PASS":
    sys.exit(1)
PY
