#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/native_aot_compilation_report.json"

python3 - <<PY
import json
from pathlib import Path

p = Path(r"$EVIDENCE_FILE")
if not p.exists():
    raise SystemExit("missing_evidence:native_aot_compilation_report.json")

data = json.loads(p.read_text())
for key in ("check_id", "timestamp_utc", "git_sha", "status", "details"):
    if key not in data:
        raise SystemExit(f"missing_top_field:{key}")

details = data["details"]
for key in ("publish_exit_code", "success", "binary_size_bytes", "warnings_count"):
    if key not in details:
        raise SystemExit(f"missing_detail_field:{key}")

if details.get("publish_exit_code") == 0 and data.get("status") != "PASS":
    raise SystemExit("aot_success_but_status_not_pass")
if details.get("publish_exit_code") != 0 and data.get("status") != "FAIL":
    raise SystemExit("aot_failure_but_status_not_fail")
if details.get("publish_exit_code") != 0:
    raise SystemExit("native_aot_publish_failed")
if int(details.get("binary_size_bytes", 0)) <= 0:
    raise SystemExit("missing_aot_binary_size")

print("native aot compilation report verification passed")
PY
