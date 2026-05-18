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

task_id = "TSK-P3-SUPPORT-MIG-001"
contract = Path("docs/architecture/PHASE3_REPLAY_MIGRATION_AND_BACKFILL_CONTRACT.md")
verifier = Path("scripts/agent/verify_tsk_p3_support_mig_001.sh")
runtime_index = Path("docs/tasks/PHASE3_RUNTIME_TASKS.md")
registry = Path("docs/PHASE3/phase3_task_registry.yml")
meta = Path("tasks/TSK-P3-SUPPORT-MIG-001/meta.yml")
plan = Path("docs/plans/phase3/TSK-P3-SUPPORT-MIG-001/PLAN.md")
exec_log = Path("docs/plans/phase3/TSK-P3-SUPPORT-MIG-001/EXEC_LOG.md")

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
record("MIG-FILES-EXIST", exists_ok, "contract, verifier, runtime index, registry, meta, plan, and exec log exist")

text = contract.read_text(encoding="utf-8") if contract.exists() else ""

required_tokens = [
    "P3-SURF-001",
    "P3-SURF-002",
    "P3-SURF-003",
    "P3-SURF-004",
    "P3-SURF-005",
    "P3-SURF-006",
    "additive-only",
    "replay_hash_continuity",
    "structural_lineage_equality",
    "semantic_admissibility_equivalence",
    "projection_equivalence",
    "read-only",
    "destructive historical rewrites",
    "undeclared ordering assumptions",
    "undeclared authority-transfer ownership assumptions",
]
missing = [token for token in required_tokens if token not in text]
record("MIG-REQUIRED-TOKENS", not missing, "contract covers all six owning surfaces and replay-equality/anti-drift tokens" if not missing else f"missing tokens: {missing}")

heading_tokens = [
    "## Additive-Only Reconciliation Rule",
    "## Canonical Owning Surface Coverage",
    "## Replay-Equality Declaration Rules",
    "## Ontology-Transition Guards",
    "## Fixture-Equality Preservation",
    "## Deterministic Ordering And Tie-Break Rules",
    "## Prohibited Drift",
    "## Runtime And Verifier Boundary",
]
missing_headings = [token for token in heading_tokens if token not in text]
record("MIG-HEADINGS", not missing_headings, "contract includes required migration/backfill planning sections" if not missing_headings else f"missing headings: {missing_headings}")

surface_coverage_tokens = [
    "dependency graph lineage",
    "policy and authority lineage",
    "projection legitimacy records",
    "contradiction findings, quarantine, supersession, and escalation",
    "failure trees and provenance continuity",
    "authority scope and delegation enforcement",
]
missing_coverage = [token for token in surface_coverage_tokens if token not in text]
record("MIG-SURFACE-COVERAGE", not missing_coverage, "contract explicitly binds all six owning surface families" if not missing_coverage else f"missing coverage tokens: {missing_coverage}")

runtime_index_text = runtime_index.read_text(encoding="utf-8") if runtime_index.exists() else ""
registry_text = registry.read_text(encoding="utf-8") if registry.exists() else ""
runtime_ok = "| TSK-P3-SUPPORT-MIG-001 |" in runtime_index_text
registry_ok = "task_id: TSK-P3-SUPPORT-MIG-001" in registry_text
record("MIG-RUNTIME-INDEX", runtime_ok, "runtime task index contains support migration task")
record("MIG-REGISTRY", registry_ok, "phase3 task registry contains support migration task")

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
