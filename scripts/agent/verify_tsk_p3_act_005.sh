#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 <<'PY'
import fnmatch
import hashlib
import json
import subprocess
import sys
from pathlib import Path

task_id = "TSK-P3-ACT-005"
manifest = Path("docs/plans/phase3/phase3_artifact_classification_manifest.json")
summary = Path("docs/plans/phase3/PHASE3_OPENED_PHASE_ARTIFACT_CLASSIFICATION.md")
task_index = Path("docs/tasks/PHASE3_ACTIVATION_TASKS.md")
envelope = Path("docs/operations/PHASE_EXECUTION_ENVELOPE.md")
readme = Path("docs/PHASE3/README.md")
source_pack = Path("docs/PHASE3/PHASE3_SOURCE_PACK.md")
master_plan = Path("docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md")
opening_act = Path("docs/PHASE3/PHASE3_OPENING_ACT.md")
evidence_file = Path("evidence/phase3/tsk_p3_act_005_artifact_normalization.json")

targets = [manifest, summary, task_index, envelope, readme, source_pack, master_plan, opening_act]
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
record("P3-ACT5-FILES-EXIST", exists_ok, "classification manifest, summary, and task index exist")

manifest_data = json.loads(manifest.read_text(encoding="utf-8")) if manifest.exists() else {}
rules = manifest_data.get("rules", [])
classes = set(manifest_data.get("classes", {}).keys())
record("P3-ACT5-MANIFEST-SHAPE", bool(rules) and {"admissible_opened_phase_activation", "historical_planning_only", "regenerate_required"}.issubset(classes), "classification manifest contains required classes and rules")

files = []
for base in [Path("docs/plans/phase3"), Path("evidence/phase3")]:
    for path in sorted(p for p in base.rglob("*") if p.is_file()):
        files.append(path.as_posix())

unclassified = []
multi_classified = []
admissible_non_activation = []
for path in files:
    matching = [rule for rule in rules if fnmatch.fnmatch(path, rule["pattern"])]
    if len(matching) == 0:
        unclassified.append(path)
        continue
    if len(matching) > 1:
        multi_classified.append(path)
        continue
    klass = matching[0]["class"]
    if path.startswith("evidence/phase3/") and klass == "admissible_opened_phase_activation" and not fnmatch.fnmatch(path, "evidence/phase3/tsk_p3_act_00[1-5]_*.json"):
        admissible_non_activation.append(path)

record("P3-ACT5-COVERAGE", not unclassified and not multi_classified, "every current Phase 3 plan and evidence artifact is classified exactly once" if not unclassified and not multi_classified else f"unclassified={unclassified}; multi_classified={multi_classified}")
record("P3-ACT5-ADMISSIBLE-SET", not admissible_non_activation, "only activation evidence is classified as admissible opened-phase proof" if not admissible_non_activation else f"non-activation admissible evidence={admissible_non_activation}")

summary_text = summary.read_text(encoding="utf-8") if summary.exists() else ""
required_summary = [
    "admissible_opened_phase_activation",
    "historical_planning_only",
    "regenerate_required",
    "TSK-P3-W1-*",
    "TSK-P3-W8-*",
]
missing_summary = [token for token in required_summary if token not in summary_text]
record("P3-ACT5-SUMMARY-CONTENT", not missing_summary, "human-readable summary explains classification rules and legacy artifact handling" if not missing_summary else f"missing summary tokens: {missing_summary}")

task_index_text = task_index.read_text(encoding="utf-8") if task_index.exists() else ""
task_index_ok = "TSK-P3-ACT-005" in task_index_text and "tsk_p3_act_005_artifact_normalization.json" in task_index_text
record("P3-ACT5-TASK-INDEX", task_index_ok, "activation task index includes TSK-P3-ACT-005")

posture_docs = {
    "ENVELOPE": envelope.read_text(encoding="utf-8") if envelope.exists() else "",
    "README": readme.read_text(encoding="utf-8") if readme.exists() else "",
    "SOURCE_PACK": source_pack.read_text(encoding="utf-8") if source_pack.exists() else "",
    "MASTER_PLAN": master_plan.read_text(encoding="utf-8") if master_plan.exists() else "",
    "OPENING_ACT": opening_act.read_text(encoding="utf-8") if opening_act.exists() else "",
}
required_posture = {
    "ENVELOPE": ["Phase-3 activation sequence is complete", "TSK-P3-WP-001", "runtime task creation may proceed"],
    "README": ["OPEN FOR PHASE 3 EXECUTION", "Activation complete; next runtime node is `TSK-P3-WP-001`"],
    "SOURCE_PACK": ["used to create atomic task packs", "DAG\ndependencies permit the node"],
    "MASTER_PLAN": ["activation\nsequence is complete", "runtime task creation may proceed"],
    "OPENING_ACT": ["activation sequence has completed", "runtime task creation may now proceed"],
}
missing_posture = []
for name, tokens in required_posture.items():
    for token in tokens:
        if token not in posture_docs[name]:
            missing_posture.append(f"{name}:{token}")
record("P3-ACT5-POSTURE-DOCS-COMPLETE", not missing_posture, "post-activation posture docs reflect completed activation and runtime task creation readiness" if not missing_posture else f"missing posture tokens: {missing_posture}")

forbidden_posture = [
    "Activation sequence incomplete",
    "Broader Runtime Work**: Remains gated until activation reconciliation completes",
    "Broader runtime implementation remains gated until the remaining activation tasks complete",
    "Create and execute `TSK-P3-ACT-004`",
]
present_forbidden = []
for name, text in posture_docs.items():
    for token in forbidden_posture:
        if token in text:
            present_forbidden.append(f"{name}:{token}")
record("P3-ACT5-POSTURE-DOCS-OLD-STATE-REMOVED", not present_forbidden, "completed-activation docs no longer claim activation is incomplete" if not present_forbidden else f"forbidden posture tokens present: {present_forbidden}")

for path in targets:
    if path.exists():
        observed_paths.append(str(path))
        observed_hashes[str(path)] = sha256(path)
for path in files:
    observed_paths.append(path)
    observed_hashes[path] = sha256(Path(path))

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

evidence_file.parent.mkdir(parents=True, exist_ok=True)
evidence_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(f"TSK-P3-ACT-005 artifact normalization verification: {status}")
for item in checks:
    print(f" - {item['id']}: {item['result']} ({item['detail']})")

if status != "PASS":
    sys.exit(1)
PY
