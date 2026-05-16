#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

HUMAN_CONTRACT="docs/PHASE3/PHASE3_CONTRACT.md"
MACHINE_CONTRACT="docs/PHASE3/phase3_contract.yml"
POLICY_FILE="docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md"
EVIDENCE_FILE="evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json"
TASK_ID="TSK-P3-ACT-001"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

python3 <<'PY'
import hashlib
import json
import subprocess
import sys
from pathlib import Path

import yaml  # type: ignore

task_id = "TSK-P3-ACT-001"
human_contract = Path("docs/PHASE3/PHASE3_CONTRACT.md")
machine_contract = Path("docs/PHASE3/phase3_contract.yml")
policy_file = Path("docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md")
evidence_file = Path("evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json")

checks = []
observed_paths = [
    str(human_contract),
    str(machine_contract),
    str(policy_file),
]
observed_hashes = {}
command_outputs = []
execution_trace = []

def record(check_id: str, passed: bool, detail: str) -> None:
    checks.append({
        "id": check_id,
        "result": "PASS" if passed else "FAIL",
        "detail": detail,
    })
    execution_trace.append(f"{check_id}:{'PASS' if passed else 'FAIL'}:{detail}")

def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()

git_sha = run(["git", "rev-parse", "HEAD"])
timestamp_utc = run(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"])

all_exist = all(p.exists() for p in [human_contract, machine_contract, policy_file])
record(
    "P3-CONTRACT-FILES-EXIST",
    all_exist,
    "required human contract, machine contract, and policy file exist",
)

machine_ok = False
phase_identity_ok = False
if machine_contract.exists():
    try:
        machine_data = yaml.safe_load(machine_contract.read_text(encoding="utf-8"))
        machine_ok = isinstance(machine_data, dict)
        record("P3-CONTRACT-YAML", machine_ok, "machine contract parses as YAML")
        if machine_ok:
            phase_identity_ok = (
                str(machine_data.get("phase")) == "3"
                and machine_data.get("phase_name") == "Constraint and Legitimacy Engine"
                and machine_data.get("status") == "open"
                and machine_data.get("claimability") == "claimable"
            )
            record(
                "P3-CONTRACT-IDENTITY",
                phase_identity_ok,
                "machine contract matches phase key, phase name, status, and claimability",
            )
    except Exception as ex:
        record("P3-CONTRACT-YAML", False, f"machine contract parse failed: {ex}")
        record("P3-CONTRACT-IDENTITY", False, "machine contract identity unavailable")
else:
    record("P3-CONTRACT-YAML", False, "machine contract file missing")
    record("P3-CONTRACT-IDENTITY", False, "machine contract file missing")

human_ok = False
human_claim_discipline_ok = False
if human_contract.exists():
    content = human_contract.read_text(encoding="utf-8")
    required_tokens = [
        "Constraint and Legitimacy Engine",
        "docs/PHASE3/phase3_contract.yml",
        "scripts/audit/verify_phase3_contract.sh",
        "evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json",
        "RUN_PHASE3_GATES=1",
    ]
    missing = [tok for tok in required_tokens if tok not in content]
    human_ok = not missing
    record(
        "P3-HUMAN-CONTRACT-CONTENT",
        human_ok,
        "human contract contains required phase, verifier, gate, and evidence references" if human_ok else f"missing tokens: {missing}",
    )
    forbidden = [
        "root execution envelope has already been updated",
        "Phase 3 is the active execution surface",
    ]
    found_forbidden = [tok for tok in forbidden if tok in content]
    human_claim_discipline_ok = not found_forbidden
    record(
        "P3-HUMAN-CONTRACT-CLAIM-DISCIPLINE",
        human_claim_discipline_ok,
        "human contract does not overclaim envelope state" if human_claim_discipline_ok else f"forbidden phrases present: {found_forbidden}",
    )
else:
    record("P3-HUMAN-CONTRACT-CONTENT", False, "human contract file missing")
    record("P3-HUMAN-CONTRACT-CLAIM-DISCIPLINE", False, "human contract file missing")

policy_ok = False
if policy_file.exists():
    content = policy_file.read_text(encoding="utf-8")
    required_tokens = [
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        "docs/operations/PHASE_LIFECYCLE.md",
        "docs/PHASE3/phase3_contract.yml",
        "scripts/audit/verify_phase3_contract.sh",
        "RUN_PHASE3_GATES=1",
        "evidence/phase3/**",
    ]
    missing = [tok for tok in required_tokens if tok not in content]
    policy_ok = not missing
    record(
        "P3-POLICY-CONTENT",
        policy_ok,
        "policy file contains required authority, verifier, gate, and evidence references" if policy_ok else f"missing tokens: {missing}",
    )
else:
    record("P3-POLICY-CONTENT", False, "policy file missing")

cross_alignment_ok = human_ok and policy_ok and phase_identity_ok
record(
    "P3-CROSS-ALIGNMENT",
    cross_alignment_ok,
    "human contract, machine contract, and policy align on phase identity and verification interface",
)

for path in [human_contract, machine_contract, policy_file]:
    if path.exists():
        observed_hashes[str(path)] = sha256(path)

status = "PASS" if all(item["result"] == "PASS" for item in checks) else "FAIL"
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

evidence_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(f"Phase-3 contract verification: {status}")
for item in checks:
    print(f" - {item['id']}: {item['result']} ({item['detail']})")

if status != "PASS":
    sys.exit(1)
PY
