#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/security/SOVEREIGN_VPC_POSTURE.md"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_005_restricted_posture.json"
SOURCE_EVIDENCE="$ROOT_DIR/evidence/phase1/led_004_kyc_hash_bridge_endpoint.json"

bash "$ROOT_DIR/scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh"
cp "$SOURCE_EVIDENCE" "$EVIDENCE"

rg -n "Phase-1 Restricted Path Proof" "$DOC" >/dev/null
rg -n "does not require a live DB connection" "$DOC" >/dev/null
rg -n "does not require an external network call" "$DOC" >/dev/null
rg -n "must not be emitted into the proof artifact" "$DOC" >/dev/null
rg -n "TryRejectPiiFields|full_name is rejected" "$DOC" >/dev/null
rg -n "must not be generalized to unimplemented endpoints" "$DOC" >/dev/null

python3 - <<'PY' "$EVIDENCE"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
if payload.get("status") != "PASS" and payload.get("pass") is not True:
    raise SystemExit("restricted_posture_evidence_not_pass")

details = payload.get("details") or {}
tests = {}
for t in details.get("tests") or []:
    name = t.get("name", t.get("Name"))
    status = t.get("status", t.get("Status"))
    if name is not None:
        tests[name] = status

for case in ("valid_hash_accepted", "unknown_provider_rejected", "pii_field_rejected"):
    if tests.get(case) != "PASS":
        raise SystemExit(f"case_failed:{case}:{tests.get(case)}")

if details.get("retention_class") != "FIC_AML_CUSTOMER_ID":
    raise SystemExit("retention_class_mismatch")
if details.get("retention_class_confirmed") is not True:
    raise SystemExit("retention_class_not_confirmed")

print("PASS")
PY

echo "TSK-P1-INT-005 verification passed. Evidence: $EVIDENCE"
