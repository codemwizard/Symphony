#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-010"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_010_reveal_rehearsal.json}"
FALLBACK_DIR="$ROOT_DIR/evidence/phase1/demo_reveal_fallback_pack"

bash "$ROOT_DIR/scripts/dev/run_demo_rehearsal.sh" "$ROOT_DIR/evidence/phase1"

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$FALLBACK_DIR"
import json, sys
from pathlib import Path

task_id, evidence_path, fallback_dir = sys.argv[1:]
obj = json.loads(Path(evidence_path).read_text(encoding="utf-8"))
if obj.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if obj.get("details", {}).get("scripted_duration_leq_10_minutes") is not True:
    raise SystemExit("duration_check_failed")
steps = set(obj.get("details", {}).get("steps") or [])
required_steps = {
    "programme_overview",
    "settled_path_drilldown",
    "hold_path_drilldown",
    "export_step",
    "risk_triggered_hold_example_sim_swap",
}
missing = sorted(required_steps - steps)
if missing:
    raise SystemExit(f"missing_steps:{','.join(missing)}")
if obj.get("details", {}).get("executed_via_demo_runner") is not True:
    raise SystemExit("not_demo_runner")
for name in (
    "programme_overview.json",
    "settled_path.json",
    "hold_path.json",
    "export_step.json",
    "risk_hold_example.json",
):
    if not Path(fallback_dir, name).exists():
        raise SystemExit(f"missing_fallback:{name}")
print(f"Evidence written: {Path(evidence_path)}")
PY
