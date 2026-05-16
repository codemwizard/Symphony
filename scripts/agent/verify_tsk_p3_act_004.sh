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

task_id = "TSK-P3-ACT-004"
envelope = Path("docs/operations/PHASE_EXECUTION_ENVELOPE.md")
lifecycle = Path("docs/operations/PHASE_LIFECYCLE.md")
opening_json = Path("approvals/2026-05-16/PHASE3-OPENING.approval.json")
legality = Path("docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md")
readme = Path("docs/PHASE3/README.md")
source_pack = Path("docs/PHASE3/PHASE3_SOURCE_PACK.md")
master_plan = Path("docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md")
opening_act = Path("docs/PHASE3/PHASE3_OPENING_ACT.md")
evidence_file = Path("evidence/phase3/tsk_p3_act_004_legality_alignment.json")

targets = [envelope, lifecycle, opening_json, legality, readme, source_pack, master_plan, opening_act]
checks = []
observed_paths = [str(p) for p in targets]
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
record("P3-ACT4-FILES-EXIST", exists_ok, "legality, planning docs, envelope, lifecycle, and opening sidecar exist")

legality_text = legality.read_text(encoding="utf-8") if legality.exists() else ""
phase3_section = ""
if "### 3.4 Phase-3 (Scaled Runtime Assurance)" in legality_text and "### 3.4A Phase-3 Doctrine-Routed Task-Plan Legality" in legality_text:
    phase3_section = legality_text.split("### 3.4 Phase-3 (Scaled Runtime Assurance)", 1)[1].split("### 3.4A Phase-3 Doctrine-Routed Task-Plan Legality", 1)[0]
required_legality = [
    "OPEN FOR ACTIVATION GOVERNANCE, RUNTIME IMPLEMENTATION STILL GATED.",
    "| Phase-3 lifecycle artifact set | STATE-1 | REQUIRED and present for opened-phase activation claims |",
    "| Activation task metadata referencing `phase: '3'` | STATE-1 | LEGAL for opened-phase activation work when backed by approval and the active envelope |",
]
missing_legality = [token for token in required_legality if token not in legality_text]
record("P3-ACT4-LEGALITY-ACTIVE", not missing_legality, "legality matrix reflects active Phase 3 activation posture" if not missing_legality else f"missing legality tokens: {missing_legality}")

forbidden_legality = [
    "CONSTITUTIONALLY RESERVED, NOT OPENED.",
    "LEGAL to be absent — Phase-3 is not open",
    "VIOLATION — Phase-3 is not open; `verify_phase_claim_admissibility.sh` will reject",
]
present_forbidden_legality = [token for token in forbidden_legality if token in legality_text]
present_forbidden_legality = [token for token in forbidden_legality if token in phase3_section]
record("P3-ACT4-LEGALITY-OLD-POSTURE-REMOVED", not present_forbidden_legality, "old unopened Phase 3 legality posture removed" if not present_forbidden_legality else f"forbidden legality tokens present: {present_forbidden_legality}")

planning_docs = {
    "README": readme.read_text(encoding="utf-8") if readme.exists() else "",
    "SOURCE_PACK": source_pack.read_text(encoding="utf-8") if source_pack.exists() else "",
    "MASTER_PLAN": master_plan.read_text(encoding="utf-8") if master_plan.exists() else "",
    "OPENING_ACT": opening_act.read_text(encoding="utf-8") if opening_act.exists() else "",
}

required_doc_tokens = {
    "README": ["OPEN FOR ACTIVATION GOVERNANCE", "Current Sequence", "Broader Runtime Work"],
    "SOURCE_PACK": ["Activation sequence incomplete", "Historical posture drift"],
    "MASTER_PLAN": ["Activation\ngovernance work is executable", "Broader Phase 3 runtime implementation remains\ngated"],
    "OPENING_ACT": ["activation governance work is admissible and executable", "Phase 3 is open for activation governance"],
}
doc_missing = []
for name, tokens in required_doc_tokens.items():
    for token in tokens:
        if token not in planning_docs[name]:
            doc_missing.append(f"{name}:{token}")
record("P3-ACT4-PLANNING-DOCS-ACTIVE", not doc_missing, "planning docs reflect active Phase 3 activation posture" if not doc_missing else f"missing planning-doc tokens: {doc_missing}")

forbidden_doc_tokens = [
    "This phase is currently in a **planning-only posture**",
    "Phase 3 is not the active execution phase",
    "Execution-envelope conflict",
]
present_forbidden_docs = []
for name, text in planning_docs.items():
    for token in forbidden_doc_tokens:
        if token in text:
            present_forbidden_docs.append(f"{name}:{token}")
record("P3-ACT4-PLANNING-DOCS-OLD-POSTURE-REMOVED", not present_forbidden_docs, "stale planning-only and stale-envelope posture removed from dependent docs" if not present_forbidden_docs else f"forbidden planning-doc tokens present: {present_forbidden_docs}")

opening_ok = False
if opening_json.exists():
    data = json.loads(opening_json.read_text(encoding="utf-8"))
    opening_ok = data.get("approval", {}).get("status") == "APPROVED"
record("P3-ACT4-OPENING-APPROVED", opening_ok, "opening sidecar remains approved")

for path in targets:
    if path.exists():
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

evidence_file.parent.mkdir(parents=True, exist_ok=True)
evidence_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(f"TSK-P3-ACT-004 legality verification: {status}")
for item in checks:
    print(f" - {item['id']}: {item['result']} ({item['detail']})")

if status != "PASS":
    sys.exit(1)
PY
