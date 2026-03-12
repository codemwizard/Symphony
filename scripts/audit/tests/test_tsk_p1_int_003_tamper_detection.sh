#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"
TMP_DIR="/tmp/symphony_int_002"
SIGNED="$TMP_DIR/signed_instruction_file_sample.json"
SIGNED_TAMPER="$TMP_DIR/signed_instruction_file_sample.tampered_chain.json"
SUBMISSIONS="$TMP_DIR/evidence_link_submissions.ndjson"
DISPATCH="$TMP_DIR/evidence_link_sms_dispatch.ndjson"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_003_tamper_detection.json"

dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-integrity-chain >/tmp/tsk_p1_int_003.log 2>&1 || {
  cat /tmp/tsk_p1_int_003.log >&2
  exit 1
}

python3 - <<'PY' "$SIGNED" "$SIGNED_TAMPER" "$SUBMISSIONS" "$DISPATCH" "$EVIDENCE"
import hashlib
import json
import os
import sys
from pathlib import Path

signed_path = Path(sys.argv[1])
signed_tamper_path = Path(sys.argv[2])
submissions_path = Path(sys.argv[3])
dispatch_path = Path(sys.argv[4])
evidence_path = Path(sys.argv[5])


def h(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def system_text_json_canonical(node: dict) -> str:
    return (
        json.dumps(node, separators=(",", ":"))
        .replace("+", "\\u002B")
        .replace("<", "\\u003C")
        .replace(">", "\\u003E")
        .replace("&", "\\u0026")
    )


def verify_obj(node: dict, domain: str, expected_previous: str | None):
    record = node.get("chain_record")
    if not isinstance(record, dict):
        return False, "CHAIN_RECORD_MISSING"
    if record.get("domain") != domain:
        return False, "CHAIN_DOMAIN_INVALID"
    if record.get("commit_boundary") != "single_write_envelope":
        return False, "CHAIN_BOUNDARY_INVALID"
    if record.get("previous_hash") != expected_previous:
        return False, "CHAIN_PREVIOUS_HASH_INVALID"
    clone = dict(node)
    clone.pop("chain_record", None)
    payload_hash = h(system_text_json_canonical(clone))
    if payload_hash != record.get("payload_hash"):
        return False, "CHAIN_PAYLOAD_HASH_INVALID"
    current = h(f"{domain}\n{expected_previous or ''}\n{payload_hash}")
    if current != record.get("current_hash"):
        return False, "CHAIN_CURRENT_HASH_INVALID"
    return True, None


def verify_json_file(path: Path, domain: str):
    return verify_obj(json.loads(path.read_text(encoding="utf-8")), domain, None)


def verify_ndjson_file(path: Path, domain: str):
    previous = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        node = json.loads(raw)
        ok, error = verify_obj(node, domain, previous)
        if not ok:
            return ok, error
        previous = node["chain_record"]["current_hash"]
    return True, None


def write_json(path: Path, node: dict):
    path.write_text(json.dumps(node, indent=2) + "\n", encoding="utf-8")


def write_ndjson(path: Path, rows: list[dict]):
    path.write_text("".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8")


tests = []

ok_signed, err_signed = verify_json_file(signed_path, "governed_instruction")
tests.append({"name": "baseline_signed_instruction_chain_valid", "status": "PASS" if ok_signed else "FAIL", "error": err_signed})

ok_dispatch, err_dispatch = verify_ndjson_file(dispatch_path, "evidence_event_sms_dispatch")
tests.append({"name": "baseline_dispatch_chain_valid", "status": "PASS" if ok_dispatch else "FAIL", "error": err_dispatch})

ok_sub, err_sub = verify_ndjson_file(submissions_path, "evidence_event_submission")
tests.append({"name": "baseline_submission_chain_valid", "status": "PASS" if ok_sub else "FAIL", "error": err_sub})

ok_tampered_signed, err_tampered_signed = verify_json_file(signed_tamper_path, "governed_instruction")
tests.append({"name": "signed_file_tamper_rejected", "status": "PASS" if not ok_tampered_signed else "FAIL", "error": err_tampered_signed})

chain_break_signed = signed_path.with_name("signed_instruction_file_sample.chain_break.json")
node = json.loads(signed_path.read_text(encoding="utf-8"))
node["chain_record"]["current_hash"] = "0" * 64
write_json(chain_break_signed, node)
ok_chain_break_signed, err_chain_break_signed = verify_json_file(chain_break_signed, "governed_instruction")
tests.append({"name": "instruction_chain_break_rejected", "status": "PASS" if not ok_chain_break_signed else "FAIL", "error": err_chain_break_signed})

metadata_divergence_signed = signed_path.with_name("signed_instruction_file_sample.metadata_divergence.json")
node = json.loads(signed_path.read_text(encoding="utf-8"))
node["timestamp_utc"] = "2099-01-01T00:00:00Z"
write_json(metadata_divergence_signed, node)
ok_metadata_divergence, err_metadata_divergence = verify_json_file(metadata_divergence_signed, "governed_instruction")
tests.append({"name": "metadata_divergence_rejected", "status": "PASS" if not ok_metadata_divergence else "FAIL", "error": err_metadata_divergence})

chain_break_submission = submissions_path.with_name("evidence_link_submissions.chain_break.ndjson")
rows = [json.loads(line) for line in submissions_path.read_text(encoding="utf-8").splitlines() if line.strip()]
rows[0]["chain_record"]["current_hash"] = "f" * 64
write_ndjson(chain_break_submission, rows)
ok_chain_break_event, err_chain_break_event = verify_ndjson_file(chain_break_submission, "evidence_event_submission")
tests.append({"name": "evidence_event_chain_break_rejected", "status": "PASS" if not ok_chain_break_event else "FAIL", "error": err_chain_break_event})

pass_all = all(t["status"] == "PASS" for t in tests)
payload = {
    "check_id": "TSK-P1-INT-003-TAMPER-DETECTION",
    "task_id": "TSK-P1-INT-003",
    "status": "PASS" if pass_all else "FAIL",
    "pass": pass_all,
    "tamper_detection_trigger_semantics": {
        "signed_file_tamper": err_tampered_signed,
        "instruction_chain_break": err_chain_break_signed,
        "evidence_event_chain_break": err_chain_break_event,
        "metadata_divergence": err_metadata_divergence,
    },
    "fixtures": {
        "signed_instruction_file": str(signed_path),
        "signed_instruction_tamper_fixture": str(signed_tamper_path),
        "instruction_chain_break_fixture": str(chain_break_signed),
        "metadata_divergence_fixture": str(metadata_divergence_signed),
        "evidence_submission_log": str(submissions_path),
        "evidence_event_chain_break_fixture": str(chain_break_submission),
    },
    "tests": tests,
}
evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
if not pass_all:
    raise SystemExit(1)
PY

echo "TSK-P1-INT-003 tamper detection tests passed. Evidence: $EVIDENCE"
