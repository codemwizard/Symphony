#!/usr/bin/env bash
set -euo pipefail
SCRIPT="scripts/dev/run_demo_e2e.sh"
RUNBOOK="docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md"
EVIDENCE="evidence/phase1/tsk_p1_demo_020_demo_runner.json"
python3 - <<'PY' "$SCRIPT" "$RUNBOOK" "$EVIDENCE"
import json, sys
from pathlib import Path
script, runbook, evidence = sys.argv[1:]
required = [
    "git fetch origin",
    "origin/main",
    "single active run",
    "manual-confirmed",
    "not-run",
    "waived",
    "run_summary.json",
    "verify_tsk_p1_inf_006.sh",
    "/health",
]
text = Path(script).read_text(encoding='utf-8') if Path(script).exists() else ''
runbook_text = Path(runbook).read_text(encoding='utf-8') if Path(runbook).exists() else ''
missing = [p for p in required if p not in text]
if 'Canonical host-run health contract on this branch' not in runbook_text or '/health' not in runbook_text:
    missing.append('health_endpoint_contract_mismatch')
if 'pre_ci_demo.sh' in text:
    missing.append('must_not_delegate_to_pre_ci_demo')
payload = {"task_id": "TSK-P1-DEMO-020", "status": "PASS" if not missing else "FAIL", "script": script, "missing_requirements": missing}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding='utf-8')
if missing:
    raise SystemExit(1)
PY
