#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-003"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_003_browser_geo_capture.json}"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-geo-capture >/dev/null

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
p = Path(evidence_path)
if not p.exists():
    raise SystemExit(f"missing_evidence:{p}")

d = json.loads(p.read_text(encoding="utf-8"))
if d.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if str(d.get("status", "")).upper() != "PASS" and d.get("pass") is not True:
    raise SystemExit("geo_capture_not_pass")

details = d.get("details") or {}
if details.get("capture_mode") != "submission_time_geolocation":
    raise SystemExit("capture_mode_mismatch")
if details.get("exif_dependency") is not False:
    raise SystemExit("exif_dependency_not_false")

tests = {t.get("name"): t.get("status") for t in (details.get("tests") or [])}
for name in ("geo_match_within_range", "geo_match_failed_out_of_range", "geo_required_missing_rejected"):
    if tests.get(name) != "PASS":
        raise SystemExit(f"test_failed:{name}:{tests.get(name)}")
print(f"Evidence written: {p}")
PY

