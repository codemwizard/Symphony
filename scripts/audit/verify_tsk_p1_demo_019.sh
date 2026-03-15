#!/usr/bin/env bash
set -euo pipefail
SCRIPT="scripts/dev/capture_demo_server_snapshot.sh"
EVIDENCE="evidence/phase1/tsk_p1_demo_019_server_snapshot.json"
python3 - <<'PY' "$SCRIPT" "$EVIDENCE"
import json, sys
from pathlib import Path
script, evidence = sys.argv[1:]
required = [
    "--run-id",
    "HMAC-SHA256",
    "SYMPHONY_SNAPSHOT_HMAC_KEY",
    "output_path_outside_bundle_root",
    "symlink_output_target_forbidden",
    "server_snapshot.json",
    "env_contract_snapshot.json",
    "process_snapshot.txt",
    "system_resources.txt",
    "network_identity.txt",
]
text = Path(script).read_text(encoding='utf-8') if Path(script).exists() else ''
missing = [p for p in required if p not in text]
payload = {"task_id": "TSK-P1-DEMO-019", "status": "PASS" if not missing else "FAIL", "script": script, "missing_requirements": missing}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding='utf-8')
if missing:
    raise SystemExit(1)
PY
