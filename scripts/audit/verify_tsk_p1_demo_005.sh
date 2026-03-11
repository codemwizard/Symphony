#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-005"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_005_signed_instruction_file_egress.json}"
SAMPLE_PATH="$ROOT_DIR/evidence/phase1/signed_instruction_file_sample.json"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-signed-egress >/dev/null

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$SAMPLE_PATH"
import json, sys
from pathlib import Path

task_id, evidence_path, sample_path = sys.argv[1:]
p = Path(evidence_path)
if not p.exists():
    raise SystemExit(f"missing_evidence:{p}")

d = json.loads(p.read_text(encoding="utf-8"))
if d.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if str(d.get("status", "")).upper() != "PASS" and d.get("pass") is not True:
    raise SystemExit("signed_egress_not_pass")

details = d.get("details") or {}
if details.get("tamper_error_code") != "CHECKSUM_BREAK":
    raise SystemExit("tamper_error_code_mismatch")

covered = set(details.get("critical_fields_covered") or [])
for key in ("amount_minor", "supplier_account", "reference"):
    if key not in covered:
        raise SystemExit(f"missing_critical_field:{key}")

tests = {t.get("name"): t.get("status") for t in (details.get("tests") or [])}
for name in ("generate_signed_instruction_file", "verify_untouched_file", "verify_tampered_file_fails"):
    if tests.get(name) != "PASS":
        raise SystemExit(f"test_failed:{name}:{tests.get(name)}")

sample = Path(sample_path)
if not sample.exists():
    raise SystemExit(f"missing_signed_instruction_file_sample:{sample}")
print(f"Evidence written: {p}")
PY
