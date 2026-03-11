#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/evidence/phase1}"
REPORT_JSON="$OUT_DIR/reporting_pack_sample.json"
REPORT_PDF="$OUT_DIR/reporting_pack_sample.pdf"
SOURCE_REVEAL="${2:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_007_supervisory_read_models.json}"

mkdir -p "$OUT_DIR"

python3 - <<'PY' "$SOURCE_REVEAL" "$REPORT_JSON" "$REPORT_PDF"
import json, sys, hashlib
from pathlib import Path

source_path = Path(sys.argv[1])
json_out = Path(sys.argv[2])
pdf_out = Path(sys.argv[3])

if not source_path.exists():
    raise SystemExit(f"missing_source_reveal:{source_path}")

source = json.loads(source_path.read_text(encoding="utf-8"))
details = source.get("details") or {}

tests = details.get("tests") or []
passed = sum(1 for t in tests if (t.get("status") or "").upper() == "PASS")
failed = sum(1 for t in tests if (t.get("status") or "").upper() != "PASS")

period = {"from": "2026-03-01", "to": "2026-03-31"}
payload = {
    "schema": "symphony.programme.reporting_pack.v1",
    "period": period,
    "totals": {
        "instruction_count": len(tests),
        "hold_count": failed,
        "pass_count": passed,
    },
    "evidence_summary": tests,
    "exception_log": [{"code": "SUPPLIER_NOT_ALLOWLISTED", "count": failed}],
    "deterministic_fingerprint": hashlib.sha256(json.dumps({"period": period, "tests": tests}, sort_keys=True).encode("utf-8")).hexdigest(),
}

json_out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

# Minimal PDF-compatible placeholder for demo export step.
pdf_text = (
    "%PDF-1.1\n"
    "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n"
    "2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n"
    "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R>>endobj\n"
    f"4 0 obj<</Length {len('Symphony Reporting Pack Export') + 35}>>stream\n"
    "BT /F1 18 Tf 72 720 Td (Symphony Reporting Pack Export) Tj ET\n"
    "endstream endobj\n"
    "xref\n0 5\n0000000000 65535 f \n"
    "trailer<</Size 5/Root 1 0 R>>\nstartxref\n0\n%%EOF\n"
)
pdf_out.write_text(pdf_text, encoding="utf-8")
print(f"generated:{json_out}")
print(f"generated:{pdf_out}")
PY
