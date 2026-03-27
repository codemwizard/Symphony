#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

bash -lc 'ls tasks/TSK-P1-241 docs/plans/phase1/TSK-P1-241 docs/tasks >/dev/null &&
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/TSK-P1-241 --json > /tmp/tsk_p1_241_meta_schema.json &&
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-241 --json > /tmp/tsk_p1_241_pack_readiness.json &&
python3 - <<'"'"'PY'"'"' > evidence/phase1/tsk_p1_241_parent_task_pack.json
import hashlib
import json
from pathlib import Path

root = Path(".")
observed_files = sorted(str(p) for p in (root / "tasks" / "TSK-P1-241").glob("*"))
observed_files += sorted(str(p) for p in (root / "docs" / "plans" / "phase1" / "TSK-P1-241").glob("*"))
observed_files += ["docs/tasks/DEFERRED_INBOX.md", "docs/tasks/PHASE1_GOVERNANCE_TASKS.md"]

def digest(path_str):
    path = root / path_str
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

meta_report = json.loads(Path("/tmp/tsk_p1_241_meta_schema.json").read_text())
readiness_report = json.loads(Path("/tmp/tsk_p1_241_pack_readiness.json").read_text())

report = {
    "task_id": "TSK-P1-241",
    "git_sha": "UNSET",
    "timestamp_utc": "UNSET",
    "status": "PASS" if meta_report["status"] == "PASS" and readiness_report["status"] == "PASS" else "FAIL",
    "checks": {
        "task_meta_schema": meta_report["status"],
        "task_pack_readiness": readiness_report["status"],
    },
    "observed_paths": observed_files,
    "observed_hashes": {path: digest(path) for path in observed_files},
    "command_outputs": {
        "task_meta_schema": meta_report,
        "task_pack_readiness": readiness_report,
    },
    "execution_trace": [
        "bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/TSK-P1-241 --json",
        "bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-241 --json",
    ],
    "child_task_boundaries": [
        "TSK-P1-242:runtime_host_path_authority",
        "guarded_execution_core",
        "repository_filesystem_integrity",
        "evidence_finalization",
        "adversarial_verifier_suite",
        "optional_invariant_promotion",
    ],
    "dependency_edges": [
        "TSK-P1-241->TSK-P1-242",
        "TSK-P1-242->guarded_execution_core",
        "guarded_execution_core->repository_filesystem_integrity",
        "guarded_execution_core->evidence_finalization",
        "repository_filesystem_integrity+evidence_finalization->adversarial_verifier_suite",
    ],
    "inbox_entry_ref": "docs/tasks/DEFERRED_INBOX.md",
    "phase1_index_ref": "docs/tasks/PHASE1_GOVERNANCE_TASKS.md",
}

print(json.dumps(report, indent=2))
if report["status"] != "PASS":
    raise SystemExit(1)
PY'
