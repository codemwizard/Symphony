#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-009"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_009_reporting_pack_export.json}"
REPORT_JSON="$ROOT_DIR/evidence/phase1/reporting_pack_sample.json"
REPORT_PDF="$ROOT_DIR/evidence/phase1/reporting_pack_sample.pdf"

bash "$ROOT_DIR/scripts/dev/generate_programme_reporting_pack.sh" "$ROOT_DIR/evidence/phase1"
sha_a_json="$(sha256sum "$REPORT_JSON" | awk '{print $1}')"
sha_a_pdf="$(sha256sum "$REPORT_PDF" | awk '{print $1}')"
bash "$ROOT_DIR/scripts/dev/generate_programme_reporting_pack.sh" "$ROOT_DIR/evidence/phase1"
sha_b_json="$(sha256sum "$REPORT_JSON" | awk '{print $1}')"
sha_b_pdf="$(sha256sum "$REPORT_PDF" | awk '{print $1}')"
[[ "$sha_a_json" == "$sha_b_json" ]] || { echo "non_deterministic_json_export" >&2; exit 1; }
[[ "$sha_a_pdf" == "$sha_b_pdf" ]] || { echo "non_deterministic_pdf_export" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$REPORT_JSON" "$REPORT_PDF" "$sha_a_json" "$sha_a_pdf"
import json, subprocess, sys
from pathlib import Path

task_id, evidence_path, report_json, report_pdf, json_sha, pdf_sha = sys.argv[1:]
r = json.loads(Path(report_json).read_text(encoding="utf-8"))
for key in ("totals", "evidence_summary", "exception_log"):
    if key not in r:
        raise SystemExit(f"missing_reporting_key:{key}")
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({
    "check_id": "TSK-P1-DEMO-009-REPORTING-EXPORT",
    "task_id": task_id,
    "timestamp_utc": subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], text=True).strip(),
    "git_sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
    "status": "PASS",
    "pass": True,
    "details": {
        "json_export": report_json,
        "pdf_export": report_pdf,
        "deterministic_json_sha256": json_sha,
        "deterministic_pdf_sha256": pdf_sha,
        "includes_required_sections": True,
    },
}, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")
PY
