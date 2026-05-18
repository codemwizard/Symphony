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

task_id = "TSK-P3-SUPPORT-CONTRACT-001"
contract = Path("docs/architecture/PHASE3_LINEAGE_PROOF_AND_REPLAY_PACKAGE_CONTRACT.md")
verifier = Path("scripts/agent/verify_tsk_p3_support_contract_001.sh")
runtime_index = Path("docs/tasks/PHASE3_RUNTIME_TASKS.md")
registry = Path("docs/PHASE3/phase3_task_registry.yml")
meta = Path("tasks/TSK-P3-SUPPORT-CONTRACT-001/meta.yml")
plan = Path("docs/plans/phase3/TSK-P3-SUPPORT-CONTRACT-001/PLAN.md")
exec_log = Path("docs/plans/phase3/TSK-P3-SUPPORT-CONTRACT-001/EXEC_LOG.md")

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
record("CONTRACT-FILES-EXIST", exists_ok, "contract, verifier, runtime index, registry, meta, plan, and exec log exist")

text = contract.read_text(encoding="utf-8") if contract.exists() else ""

required_tokens = [
    "P3-SURF-001",
    "P3-SURF-002",
    "lineage_provenance_id",
    "phase2_compatibility_intent",
    "offline replay package",
    "must not collapse runtime/verifier trust boundaries",
    "deterministic ordering",
    "immutable provenance identifier",
]
missing = [token for token in required_tokens if token not in text]
record("CONTRACT-REQUIRED-TOKENS", not missing, "contract includes both owning surfaces, provenance, replay, and trust-boundary terms" if not missing else f"missing tokens: {missing}")

heading_tokens = [
    "## Shared Proof Fields",
    "## Surface-Specific Proof Shape",
    "## Offline Replay Package Schema Inputs",
    "## Runtime And Verifier Segregation",
    "## Phase 2 Compatibility Intent",
]
missing_headings = [token for token in heading_tokens if token not in text]
record("CONTRACT-HEADINGS", not missing_headings, "contract includes required proof/replay sections" if not missing_headings else f"missing headings: {missing_headings}")

surface001_fields = ["node_id", "node_key", "node_kind", "dependency_kind", "upstream_node_id", "downstream_node_id"]
surface002_fields = ["policy_artifact_id", "artifact_key", "artifact_class", "authority_lineage_id", "authority_key", "authority_source_kind"]
missing_surface001 = [token for token in surface001_fields if token not in text]
missing_surface002 = [token for token in surface002_fields if token not in text]
record("CONTRACT-SURFACE-FIELDS", not missing_surface001 and not missing_surface002,
       "surface-specific proof fields are declared for both lineage surfaces" if not missing_surface001 and not missing_surface002
       else f"missing P3-SURF-001 fields={missing_surface001}; missing P3-SURF-002 fields={missing_surface002}")

replay_inputs = [
    "package_schema_version",
    "target_surface_set",
    "baseline_cutoff",
    "dependency_lineage_inputs",
    "policy_authority_lineage_inputs",
    "reconstruction_ordering_rules",
    "evidence_namespace",
]
missing_inputs = [token for token in replay_inputs if token not in text]
record("CONTRACT-REPLAY-PACKAGE-INPUTS", not missing_inputs,
       "offline replay package schema inputs are declared" if not missing_inputs else f"missing replay package inputs: {missing_inputs}")

forbidden_tokens = [
    "public API schema",
    "runtime transport protocol",
    "external integration schema",
]
forbidden_present = [token for token in forbidden_tokens if token in text and "This contract does not define:" not in text]
record("CONTRACT-NO-PRODUCT-DRIFT", not forbidden_present, "contract does not declare product/runtime API semantics" if not forbidden_present else f"forbidden tokens present in active contract body: {forbidden_present}")

runtime_index_text = runtime_index.read_text(encoding="utf-8") if runtime_index.exists() else ""
registry_text = registry.read_text(encoding="utf-8") if registry.exists() else ""
runtime_ok = "| TSK-P3-SUPPORT-CONTRACT-001 |" in runtime_index_text
registry_ok = "task_id: TSK-P3-SUPPORT-CONTRACT-001" in registry_text
record("CONTRACT-RUNTIME-INDEX", runtime_ok, "runtime task index contains support contract task")
record("CONTRACT-REGISTRY", registry_ok, "phase3 task registry contains support contract task")

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
