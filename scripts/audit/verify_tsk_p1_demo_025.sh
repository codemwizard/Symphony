#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-025"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_025_runtime_contract.json}"
GUIDE="$ROOT_DIR/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"

for required in \
  'SYMPHONY_RUNTIME_PROFILE=pilot-demo' \
  'ASPNETCORE_URLS=http://0.0.0.0:8080' \
  'DATABASE_URL=' \
  'INGRESS_STORAGE_MODE=db_psql' \
  'SYMPHONY_UI_TENANT_ID=' \
  'SYMPHONY_UI_API_KEY=' \
  'INGRESS_API_KEY=' \
  'ADMIN_API_KEY=' \
  'SYMPHONY_KNOWN_TENANTS=' \
  'psql' \
  'Kestrel'
do
  rg -Fq "$required" "$GUIDE" || { echo "guide_missing:$required" >&2; exit 1; }
done

rg -Fq 'SYMPHONY_UI_API_KEY' "$GUIDE" || { echo "guide_missing_ui_key_relation" >&2; exit 1; }
rg -Fq 'the backend accepts as `INGRESS_API_KEY`' "$GUIDE" || { echo "guide_missing_ui_key_ingress_key_relation" >&2; exit 1; }

! rg -n 'required deployment step.*nginx|required deployment step.*IIS' "$GUIDE" >/dev/null || { echo "guide_requires_proxy" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence = sys.argv[1:]
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
Path(evidence).parent.mkdir(parents=True, exist_ok=True)
payload = {
    "check_id": "TSK-P1-DEMO-025-RUNTIME-CONTRACT",
    "task_id": task_id,
    "timestamp_utc": os.popen('[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
    "git_sha": sha,
    "status": "PASS",
    "pass": True,
    "details": {
        "required_env_documented": True,
        "ui_key_ingress_key_relationship_documented": True,
        "psql_documented": True,
        "kestrel_documented": True,
        "proxy_not_required": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
