#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
REPLAY_EVIDENCE="$EVIDENCE_DIR/pilot_harness_replay.json"
ONBOARD_EVIDENCE="$EVIDENCE_DIR/pilot_onboarding_readiness.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP REPLAY_EVIDENCE ONBOARD_EVIDENCE

python3 <<'PY'
import json
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
replay_path = Path(os.environ["REPLAY_EVIDENCE"])
onboarding_path = Path(os.environ["ONBOARD_EVIDENCE"])

def load_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

checks = {
    "ingress_contract": root / "evidence/phase1/ingress_api_contract_tests.json",
    "executor_runtime": root / "evidence/phase1/executor_worker_runtime.json",
    "evidence_pack_contract": root / "evidence/phase1/evidence_pack_api_contract.json",
    "exception_case_pack": root / "evidence/phase1/exception_case_pack_generation.json",
}

required_docs = [
    root / "docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md",
    root / "docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md",
    root / "scripts/dev/run_phase1_pilot_harness.sh",
]

failures = []
component_status = {}

for name, path in checks.items():
    data = load_json(path)
    if data is None:
        failures.append(f"missing_or_invalid_json:{name}:{path}")
        component_status[name] = "FAIL"
        continue
    status = str(data.get("status", "")).upper()
    if status != "PASS":
        failures.append(f"component_not_pass:{name}:{status}")
        component_status[name] = "FAIL"
    else:
        component_status[name] = "PASS"

ingress = load_json(checks["ingress_contract"])
malformed_guardrail = False
if isinstance(ingress, dict):
    for row in ingress.get("results", []):
        row_name = row.get("name") or row.get("Name")
        row_status = row.get("status") or row.get("Status")
        if row_name == "invalid_payload_fail_closed" and row_status == "PASS":
            malformed_guardrail = True
            break
if not malformed_guardrail:
    failures.append("missing_malformed_payload_fail_closed_proof")

for doc in required_docs:
    if not doc.exists() or not doc.read_text(encoding="utf-8").strip():
        failures.append(f"missing_or_empty_artifact:{doc}")

status = "PASS" if not failures else "FAIL"

replay = {
    "check_id": "PHASE1-PILOT-HARNESS-REPLAY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "deterministic_replay": status == "PASS",
    "components": component_status,
    "malformed_payload_fail_closed": malformed_guardrail,
    "replay_command": "scripts/dev/run_phase1_pilot_harness.sh",
    "failures": failures,
}

onboarding = {
    "check_id": "PHASE1-PILOT-ONBOARDING-READINESS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "contract_doc": "docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md",
    "onboarding_checklist_doc": "docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md",
    "ready_for_pilot_handoff": status == "PASS",
    "failures": failures,
}

replay_path.write_text(json.dumps(replay, indent=2) + "\n", encoding="utf-8")
onboarding_path.write_text(json.dumps(onboarding, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Pilot harness readiness verification failed", file=sys.stderr)
    for item in failures:
        print(f" - {item}", file=sys.stderr)
    sys.exit(1)

print(f"Pilot harness readiness verification passed. Evidence: {replay_path}")
print(f"Pilot onboarding readiness verification passed. Evidence: {onboarding_path}")
PY
