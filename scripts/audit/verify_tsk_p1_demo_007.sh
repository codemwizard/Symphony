#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-007"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_007_supervisory_read_models.json}"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-supervisory-read-models >/dev/null

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
    raise SystemExit("supervisory_read_models_not_pass")

details = d.get("details") or {}
if details.get("read_only") is not True:
    raise SystemExit("read_only_not_true")

tests = {t.get("name"): t.get("status") for t in (details.get("tests") or [])}
for name in ("reveal_read_model_components_present", "cross_tenant_denied_fail_closed"):
    if tests.get(name) != "PASS":
        raise SystemExit(f"test_failed:{name}:{tests.get(name)}")
print(f"Evidence written: {p}")
PY
