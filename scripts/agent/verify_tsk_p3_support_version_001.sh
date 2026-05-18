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

task_id = "TSK-P3-SUPPORT-VERSION-001"
contract = Path("docs/architecture/PHASE3_REPLAY_CONTINUITY_AND_VERSIONING_CONTRACT.md")
verifier = Path("scripts/agent/verify_tsk_p3_support_version_001.sh")
runtime_index = Path("docs/tasks/PHASE3_RUNTIME_TASKS.md")
registry = Path("docs/PHASE3/phase3_task_registry.yml")
meta = Path("tasks/TSK-P3-SUPPORT-VERSION-001/meta.yml")
plan = Path("docs/plans/phase3/TSK-P3-SUPPORT-VERSION-001/PLAN.md")
exec_log = Path("docs/plans/phase3/TSK-P3-SUPPORT-VERSION-001/EXEC_LOG.md")

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
record("VERSION-FILES-EXIST", exists_ok, "contract, verifier, runtime index, registry, meta, plan, and exec log exist")

text = contract.read_text(encoding="utf-8") if contract.exists() else ""

required_tokens = [
    "P3-SURF-001",
    "P3-SURF-002",
    "P3-SURF-003",
    "schema_migration_head",
    "proof_schema_version",
    "policy_format_version",
    "projection_algorithm_version",
    "lineage_provenance_id",
    "replay_context_hash",
    "phase2_compatibility_intent",
    "replay-hash regression",
    "deployment lifecycle",
    "public API versioning",
]
missing = [token for token in required_tokens if token not in text]
record("VERSION-REQUIRED-TOKENS", not missing, "contract covers all owning surfaces and replay continuity anchors" if not missing else f"missing tokens: {missing}")

heading_tokens = [
    "## Canonical Replay Continuity Anchors",
    "## Deterministic Versioning Rules",
    "## Compatibility Classes",
    "## Replay-Hash Regression Expectations",
    "## Phase 2 Compatibility Intent",
    "## Runtime And Verifier Boundary",
]
missing_headings = [token for token in heading_tokens if token not in text]
record("VERSION-HEADINGS", not missing_headings, "contract includes required versioning sections" if not missing_headings else f"missing headings: {missing_headings}")

compatibility_classes = [
    "schema_compatible",
    "proof_compatible",
    "policy_format_compatible",
    "projection_compatible",
    "phase2_admissible_intent_only",
]
missing_classes = [token for token in compatibility_classes if token not in text]
record("VERSION-COMPATIBILITY-CLASSES", not missing_classes, "contract declares all required compatibility classes" if not missing_classes else f"missing classes: {missing_classes}")

non_goal_tokens = [
    "deployment lifecycle versioning",
    "release train semantics",
    "public API compatibility policy",
    "product versioning language",
]
missing_non_goals = [token for token in non_goal_tokens if token not in text]
record("VERSION-NON-GOALS", not missing_non_goals, "contract explicitly excludes lifecycle and product-versioning drift" if not missing_non_goals else f"missing non-goal tokens: {missing_non_goals}")

runtime_index_text = runtime_index.read_text(encoding="utf-8") if runtime_index.exists() else ""
registry_text = registry.read_text(encoding="utf-8") if registry.exists() else ""
runtime_ok = "| TSK-P3-SUPPORT-VERSION-001 |" in runtime_index_text
registry_ok = "task_id: TSK-P3-SUPPORT-VERSION-001" in registry_text
record("VERSION-RUNTIME-INDEX", runtime_ok, "runtime task index contains support version task")
record("VERSION-REGISTRY", registry_ok, "phase3 task registry contains support version task")

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
