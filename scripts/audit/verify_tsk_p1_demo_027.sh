#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-027"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_027_demo_gate_split.json}"
DEMO_GATE="$ROOT_DIR/scripts/dev/pre_ci_demo.sh"
CHECKLIST="$ROOT_DIR/docs/operations/PHASE1_DEMO_DEPLOY_AND_TEST_CHECKLIST.md"
GUIDE="$ROOT_DIR/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"

for required in \
  'verify_tsk_p1_demo_014.sh' \
  'verify_tsk_p1_demo_008.sh' \
  'verify_tsk_p1_demo_009.sh' \
  'verify_tsk_p1_demo_010.sh' \
  'verify_tsk_p1_demo_011.sh' \
  'verify_tsk_p1_demo_017.sh' \
  'verify_tsk_p1_demo_026.sh' \
  'verify_task_ui_wire_007.sh' \
  'verify_task_ui_wire_010.sh' \
  'verify_task_ui_wire_011.sh' \
  'psql' \
  '/pilot-demo/supervisory'
do
  rg -Fq "$required" "$DEMO_GATE" "$CHECKLIST" "$GUIDE" || { echo "missing_demo_gate_requirement:$required" >&2; exit 1; }
done

! rg -Fq 'exec scripts/dev/pre_ci.sh' "$DEMO_GATE" || { echo "demo_gate_still_execs_pre_ci" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence = sys.argv[1:]
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
Path(evidence).parent.mkdir(parents=True, exist_ok=True)
payload = {
    "check_id": "TSK-P1-DEMO-027-DEMO-GATE-SPLIT",
    "task_id": task_id,
    "timestamp_utc": os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
    "git_sha": sha,
    "status": "PASS",
    "pass": True,
    "details": {
        "demo_gate_script": "scripts/dev/pre_ci_demo.sh",
        "pre_ci_reserved_for_engineering": True,
        "enumerated_verifier_set_fixed": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
