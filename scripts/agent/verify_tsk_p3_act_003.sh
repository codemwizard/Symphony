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

task_id = "TSK-P3-ACT-003"
envelope = Path("docs/operations/PHASE_EXECUTION_ENVELOPE.md")
lifecycle = Path("docs/operations/PHASE_LIFECYCLE.md")
machine_contract = Path("docs/PHASE3/phase3_contract.yml")
human_contract = Path("docs/PHASE3/PHASE3_CONTRACT.md")
policy = Path("docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md")
opening_md = Path("approvals/2026-05-16/PHASE3-OPENING.md")
opening_json = Path("approvals/2026-05-16/PHASE3-OPENING.approval.json")
evidence_file = Path("evidence/phase3/tsk_p3_act_003_envelope_alignment.json")

checks = []
observed_paths = [
    str(envelope),
    str(lifecycle),
    str(machine_contract),
    str(human_contract),
    str(policy),
    str(opening_md),
    str(opening_json),
]
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

exists_ok = all(path.exists() for path in [envelope, lifecycle, machine_contract, human_contract, policy, opening_md, opening_json])
record("P3-ENV-FILES-EXIST", exists_ok, "envelope, lifecycle, contract, policy, and opening artifacts exist")

env_text = envelope.read_text(encoding="utf-8") if envelope.exists() else ""
required_tokens = [
    "| **Lifecycle phase key** | `3` |",
    "| **Phase name** | Constraint and Legitimacy Engine |",
    "| **Evidence namespace** | `evidence/phase3/**` |",
    "| **Gate flag** | `RUN_PHASE3_GATES=1` |",
    "`TSK-P3-ACT-003` is complete. The next governed activation node is",
    "`TSK-P3-ACT-004`",
    "Phase-3 activation governance is active; broader runtime implementation remains gated",
]
missing_tokens = [token for token in required_tokens if token not in env_text]
record("P3-ENV-ACTIVE-PHASE", not missing_tokens, "envelope names Phase 3 as active activation surface" if not missing_tokens else f"missing tokens: {missing_tokens}")

forbidden_tokens = [
    "Phase-2 execution is the only legal execution surface.",
    "Any evidence under `evidence/phase3/**` or `evidence/phase4/**`",
    "Phase-3 not open",
]
present_forbidden = [token for token in forbidden_tokens if token in env_text]
record("P3-ENV-OLD-BLOCKERS-REMOVED", not present_forbidden, "legacy unopened-phase blockers removed from envelope" if not present_forbidden else f"forbidden legacy tokens present: {present_forbidden}")

boundary_tokens = [
    "broader runtime implementation remains gated",
    "Do not implement broader Phase-3 runtime capability tasks outside the",
    "Any Phase-4 artifact or evidence surface | Future phase not open |",
]
missing_boundary = [token for token in boundary_tokens if token not in env_text]
record("P3-ENV-BOUNDARY-DISCIPLINE", not missing_boundary, "envelope preserves activation-only boundary discipline" if not missing_boundary else f"missing boundary tokens: {missing_boundary}")

contract_text = machine_contract.read_text(encoding="utf-8") if machine_contract.exists() else ""
contract_ok = 'phase: "3"' in contract_text and 'status: "open"' in contract_text and 'claimability: "claimable"' in contract_text
record("P3-CONTRACT-OPEN", contract_ok, "Phase 3 machine contract is open and claimable")

policy_text = policy.read_text(encoding="utf-8") if policy.exists() else ""
policy_ok = "Activation in progress" in policy_text and "evidence/phase3/**" in policy_text and "RUN_PHASE3_GATES=1" in policy_text
record("P3-POLICY-ALIGNMENT", policy_ok, "Phase 3 policy aligns to activation posture, evidence namespace, and gate flag")

opening_ok = False
opening_scope_ok = False
if opening_json.exists():
    opening_data = json.loads(opening_json.read_text(encoding="utf-8"))
    opening_ok = (
        opening_data.get("approval", {}).get("status") == "APPROVED"
        and opening_data.get("scope", {}).get("regulated_surfaces_touched") is True
    )
    record("P3-OPENING-APPROVED", opening_ok, "opening sidecar records approved activation state")
    scope_paths = set(opening_data.get("scope", {}).get("paths_changed", []))
    opening_scope_ok = "docs/operations/PHASE_EXECUTION_ENVELOPE.md" in scope_paths
    record("P3-OPENING-SCOPE", opening_scope_ok, "opening sidecar scope covers the envelope rewrite")
else:
    record("P3-OPENING-APPROVED", False, "opening sidecar missing")
    record("P3-OPENING-SCOPE", False, "opening sidecar missing")

for path in [envelope, lifecycle, machine_contract, human_contract, policy, opening_md, opening_json]:
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

print(f"TSK-P3-ACT-003 envelope verification: {status}")
for item in checks:
    print(f" - {item['id']}: {item['result']} ({item['detail']})")

if status != "PASS":
    sys.exit(1)
PY
