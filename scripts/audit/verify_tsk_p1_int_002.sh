#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"
TASK_ID="TSK-P1-INT-002"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json"

dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-integrity-chain >/tmp/tsk_p1_int_002.log 2>&1 || {
  cat /tmp/tsk_p1_int_002.log >&2
  exit 1
}

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

hardware = payload.get("declared_reference_hardware")
method = payload.get("measurement_method")
latency = payload.get("latency_ms") or {}
tests = payload.get("tests") or []

if not hardware or not isinstance(hardware, str):
    raise SystemExit("reference_hardware_missing")
if not method or "p95 wall-clock transaction delta over 100 runs" not in method:
    raise SystemExit("measurement_method_invalid")
if payload.get("runs") != 100:
    raise SystemExit("runs_not_100")

delta = latency.get("chain_population_delta")
threshold = latency.get("threshold")
if delta is None or threshold is None:
    raise SystemExit("latency_fields_missing")
if float(delta) > float(threshold):
    raise SystemExit("latency_threshold_exceeded")

domains = payload.get("domains") or {}
governed = domains.get("governed_instruction") or {}
events = domains.get("evidence_events") or {}

if governed.get("chain_record_present") is not True:
    raise SystemExit("governed_instruction_chain_missing")
if governed.get("tamper_fixture_rejected") is not True:
    raise SystemExit("governed_instruction_tamper_not_rejected")
if events.get("dispatch_chain_present") is not True or events.get("submission_chain_present") is not True:
    raise SystemExit("evidence_event_chain_missing")
if events.get("tamper_fixture_rejected") is not True:
    raise SystemExit("evidence_event_tamper_not_rejected")

bad = [t["name"] for t in tests if t.get("status") != "PASS"]
if bad:
    raise SystemExit("failing_tests:" + ",".join(bad))

print("PASS")
PY

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
