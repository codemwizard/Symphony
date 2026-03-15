#!/usr/bin/env bash
set -euo pipefail
CHECKLIST="docs/operations/SYMPHONY_DEMO_START_NOW_CHECKLIST.md"
EVIDENCE="evidence/phase1/tsk_p1_demo_023_start_now_checklist.json"
python3 - <<'PY' "$CHECKLIST" "$EVIDENCE"
import json, sys
from pathlib import Path
checklist, evidence = sys.argv[1:]
required = [
    "rehearsal-only",
    "full-demo",
    "ready to start end-to-end deployment and testing now",
    "Start Conditions",
    "Stop if:",
    "Continue if:",
    "tenant onboarding",
    "server-side API smoke",
    "Dell/browser smoke",
    "Do not classify the run as `full-demo` signoff",
    "Yes, start the end-to-end deployment and testing now in `rehearsal-only` mode.",
]
text = Path(checklist).read_text(encoding='utf-8') if Path(checklist).exists() else ''
missing = [p for p in required if p not in text]
payload = {
    "task_id": "TSK-P1-DEMO-023",
    "status": "PASS" if not missing else "FAIL",
    "pass": not missing,
    "checklist": checklist,
    "missing_sections": missing,
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding='utf-8')
if missing:
    raise SystemExit(1)
PY
