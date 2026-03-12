#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_003_tamper_detection.json"

bash "$ROOT_DIR/scripts/audit/tests/test_tsk_p1_int_003_tamper_detection.sh"

python3 - <<'PY' "$EVIDENCE"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(f"missing_evidence:{path}")

payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("status") != "PASS" or payload.get("pass") is not True:
    raise SystemExit("evidence_status_not_pass")

required = {
    "signed_file_tamper": "CHAIN_PAYLOAD_HASH_INVALID",
    "instruction_chain_break": "CHAIN_CURRENT_HASH_INVALID",
    "evidence_event_chain_break": "CHAIN_CURRENT_HASH_INVALID",
    "metadata_divergence": "CHAIN_PAYLOAD_HASH_INVALID",
}
actual = payload.get("tamper_detection_trigger_semantics") or {}
for key, expected in required.items():
    if actual.get(key) != expected:
        raise SystemExit(f"unexpected_trigger:{key}:{actual.get(key)}:{expected}")

bad = [t["name"] for t in (payload.get("tests") or []) if t.get("status") != "PASS"]
if bad:
    raise SystemExit("failing_tests:" + ",".join(bad))

print("PASS")
PY

echo "TSK-P1-INT-003 verification passed. Evidence: $EVIDENCE"
