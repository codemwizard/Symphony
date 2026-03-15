#!/usr/bin/env bash
set -euo pipefail
DOC="docs/security/SYMPHONY_DEMO_KEY_AND_ROTATION_POLICY.md"
EVIDENCE="evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json"
python3 - <<'PY' "$DOC" "$EVIDENCE"
import json, sys
from pathlib import Path
doc, evidence = sys.argv[1:]
required = [
    "OpenBao",
    "full-demo",
    "rehearsal-only",
    "non-signoff",
    "ADMIN_API_KEY",
    "rendered HTML",
    "bootstrap",
    "INF-006",
    "rotation closeout",
]
text = Path(doc).read_text(encoding='utf-8') if Path(doc).exists() else ''
missing = [p for p in required if p not in text]
payload = {"task_id": "TSK-P1-DEMO-021", "status": "PASS" if not missing else "FAIL", "document": doc, "missing_requirements": missing}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding='utf-8')
if missing:
    raise SystemExit(1)
PY
