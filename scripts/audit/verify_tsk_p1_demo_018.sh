#!/usr/bin/env bash
set -euo pipefail
RUNBOOK="docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md"
EVIDENCE="evidence/phase1/tsk_p1_demo_018_e2e_runbook.json"
python3 - <<'PY' "$RUNBOOK" "$EVIDENCE"
import json, sys
runbook, evidence = sys.argv[1:]
required = [
    "clean deployment checkout",
    "task evidence",
    "run evidence",
    "server-side API smoke",
    "Dell/browser",
    "Pass condition:",
    "Fail condition:",
    "Operator action:",
    "Evidence emitted:",
    "Kubernetes Appendix",
]
text = open(runbook, encoding='utf-8').read() if __import__('pathlib').Path(runbook).exists() else ''
missing = [p for p in required if p not in text]
payload = {"task_id": "TSK-P1-DEMO-018", "status": "PASS" if not missing else "FAIL", "runbook": runbook, "missing_sections": missing}
open(evidence, 'w', encoding='utf-8').write(json.dumps(payload, indent=2) + "\n")
if missing:
    raise SystemExit(1)
PY
