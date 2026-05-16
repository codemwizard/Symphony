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

opening_md = Path("approvals/2026-05-16/PHASE3-OPENING.md")
opening_json = Path("approvals/2026-05-16/PHASE3-OPENING.approval.json")
evidence_file = Path("evidence/phase3/tsk_p3_act_002_opening_approval.json")
task_id = "TSK-P3-ACT-002"

checks = []
observed_paths = [str(opening_md), str(opening_json)]
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

exists_ok = opening_md.exists() and opening_json.exists()
record("P3-OPENING-FILES-EXIST", exists_ok, "opening markdown and sidecar exist")

md_ok = False
md_boundary_ok = False
if opening_md.exists():
    content = opening_md.read_text(encoding="utf-8")
    required = [
        "**Status**: APPROVED",
        "Phase-3 Opening Approval",
        "PHASE3-OPENING.approval.json",
        "This approval does **not**:",
        "claim that Phase 3 runtime implementation is complete"
    ]
    missing = [tok for tok in required if tok not in content]
    md_ok = not missing
    record("P3-OPENING-MD-CONTENT", md_ok, "opening markdown contains required status and boundary sections" if md_ok else f"missing tokens: {missing}")
    bad = [tok for tok in [
        "Phase 3 runtime implementation is complete.",
        "all Phase 3 execution surfaces are already reconciled."
    ] if tok in content and "does **not**" not in content]
    md_boundary_ok = not bad
    record("P3-OPENING-MD-BOUNDARY", md_boundary_ok, "opening markdown does not overclaim runtime completion" if md_boundary_ok else f"forbidden claims present: {bad}")
else:
    record("P3-OPENING-MD-CONTENT", False, "opening markdown missing")
    record("P3-OPENING-MD-BOUNDARY", False, "opening markdown missing")

json_ok = False
json_scope_ok = False
if opening_json.exists():
    data = json.loads(opening_json.read_text(encoding="utf-8"))
    json_ok = (
        data.get("schema_version") == "1.0"
        and data.get("approval", {}).get("status") == "APPROVED"
        and data.get("approval", {}).get("approver_id") == "mwiza"
        and data.get("ai", {}).get("session_id") == "phase3-opening-approval"
    )
    record("P3-OPENING-JSON-CONTENT", json_ok, "opening sidecar contains required approval and ai fields")
    paths_changed = set(data.get("scope", {}).get("paths_changed", []))
    needed_paths = {
        "approvals/2026-05-16/PHASE3-OPENING.md",
        "approvals/2026-05-16/PHASE3-OPENING.approval.json",
        "docs/operations/PHASE_EXECUTION_ENVELOPE.md"
    }
    json_scope_ok = needed_paths.issubset(paths_changed)
    record("P3-OPENING-JSON-SCOPE", json_scope_ok, "opening sidecar scope includes opening artifacts and envelope reconciliation surface")
else:
    record("P3-OPENING-JSON-CONTENT", False, "opening sidecar missing")
    record("P3-OPENING-JSON-SCOPE", False, "opening sidecar missing")

alignment_ok = md_ok and json_ok
record("P3-OPENING-CROSS-ALIGNMENT", alignment_ok, "opening markdown and sidecar align on approved opening state")

for path in [opening_md, opening_json]:
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
    "execution_trace": execution_trace
}

evidence_file.parent.mkdir(parents=True, exist_ok=True)
evidence_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(f"TSK-P3-ACT-002 opening approval verification: {status}")
for item in checks:
    print(f" - {item['id']}: {item['result']} ({item['detail']})")

if status != "PASS":
    sys.exit(1)
PY
