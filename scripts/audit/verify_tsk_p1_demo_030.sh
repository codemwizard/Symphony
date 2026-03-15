#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import json
import subprocess
from pathlib import Path
import yaml

root = Path.cwd()

def sh(cmd: str) -> str:
    return subprocess.check_output(["bash", "-lc", cmd], cwd=root, text=True).strip()

branch = sh("git branch --show-current")
if branch != "feat/demo-deployment-repair":
    raise SystemExit(f"verify_tsk_p1_demo_030: expected branch feat/demo-deployment-repair, got {branch}")

local_main = sh("git rev-parse refs/heads/main")
origin_main = sh("git rev-parse refs/remotes/origin/main")
if local_main != origin_main:
    raise SystemExit("verify_tsk_p1_demo_030: local main is not at parity with origin/main")

expected_titles = {
    "TSK-P1-DEMO-024": "Align demo health endpoints with deployment probes",
    "TSK-P1-DEMO-025": "Complete the host-based demo deployment runtime contract",
    "TSK-P1-DEMO-026": "Keep admin credentials server-side for privileged demo actions",
    "TSK-P1-DEMO-027": "Finish the operator demo gate split",
    "TSK-P1-DEMO-028": "Complete image build flow while keeping host-based publish as the supported demo path",
    "TSK-P1-DEMO-029": "Create the demo provisioning sample pack and signoff threshold guide",
}

observed = {}
for task_id, title in expected_titles.items():
    meta = root / "tasks" / task_id / "meta.yml"
    if not meta.exists():
        raise SystemExit(f"verify_tsk_p1_demo_030: missing {meta}")
    data = yaml.safe_load(meta.read_text(encoding="utf-8"))
    observed_title = data.get("title")
    if observed_title != title:
        raise SystemExit(f"verify_tsk_p1_demo_030: {task_id} title mismatch: {observed_title!r}")
    observed[task_id] = observed_title

if observed["TSK-P1-DEMO-024"] == observed["TSK-P1-DEMO-029"]:
    raise SystemExit("verify_tsk_p1_demo_030: canonical 024 still collides with sample-pack task")

index_text = (root / "docs/tasks/PHASE1_GOVERNANCE_TASKS.md").read_text(encoding="utf-8")
if "### TSK-P1-DEMO-029 — Create the demo provisioning sample pack and signoff threshold guide" not in index_text:
    raise SystemExit("verify_tsk_p1_demo_030: governance task index missing TSK-P1-DEMO-029 entry")
if "### TSK-P1-DEMO-024 — Create the demo provisioning sample pack and signoff threshold guide" in index_text:
    raise SystemExit("verify_tsk_p1_demo_030: governance task index still binds sample-pack work to TSK-P1-DEMO-024")

approval_md = root / "approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.md"
approval_json = root / "approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.approval.json"
if not approval_md.exists() or not approval_json.exists():
    raise SystemExit("verify_tsk_p1_demo_030: repaired-branch approval artifacts missing")

approval_meta = json.loads((root / "evidence/phase1/approval_metadata.json").read_text(encoding="utf-8"))
expected_ref = "approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.md"
if approval_meta.get("human_approval", {}).get("approval_artifact_ref") != expected_ref:
    raise SystemExit("verify_tsk_p1_demo_030: approval metadata does not reference repaired-branch approval artifact")

wave_e_dirty = subprocess.run(
    ["bash", "-lc", "git diff --quiet -- approvals/2026-03-13/BRANCH-feat-ui-wire-wave-e.md approvals/2026-03-13/BRANCH-feat-ui-wire-wave-e.approval.json"],
    cwd=root,
)
if wave_e_dirty.returncode != 0:
    raise SystemExit("verify_tsk_p1_demo_030: stale Wave-E approval files are still modified on repaired branch")

out = {
    "task_id": "TSK-P1-DEMO-030",
    "status": "pass",
    "branch": branch,
    "local_main": local_main,
    "origin_main": origin_main,
    "canonical_task_titles": observed,
    "approval_artifact_ref": expected_ref,
}

evidence = root / "evidence/phase1/tsk_p1_demo_030_branch_repair.json"
evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P1-DEMO-030 verification passed. Evidence: {evidence}")
PY
