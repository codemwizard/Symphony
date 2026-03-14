#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-024"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_024_health_probe_parity.json}"
PROGRAM_FILE="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
K8S_FILE="$ROOT_DIR/infra/sandbox/k8s/ledger-api-deployment.yaml"

rg -Fq 'app.MapGet("/health", () => Results.Ok(new' "$PROGRAM_FILE" || { echo "missing_health_route" >&2; exit 1; }
rg -Fq 'app.MapGet("/healthz", () => Results.Ok(new' "$PROGRAM_FILE" || { echo "missing_healthz_route" >&2; exit 1; }
rg -Fq 'app.MapGet("/readyz", () => Results.Ok(new' "$PROGRAM_FILE" || { echo "missing_readyz_route" >&2; exit 1; }
rg -Fq 'path: /healthz' "$K8S_FILE" || { echo "missing_k8s_healthz_probe" >&2; exit 1; }
rg -Fq 'path: /readyz' "$K8S_FILE" || { echo "missing_k8s_readyz_probe" >&2; exit 1; }
GUIDE="$ROOT_DIR/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"
rg -Fq '/healthz' "$GUIDE" || { echo "guide_missing_healthz" >&2; exit 1; }
rg -Fq '/readyz' "$GUIDE" || { echo "guide_missing_readyz" >&2; exit 1; }

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path
task_id, evidence = sys.argv[1:]
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
Path(evidence).parent.mkdir(parents=True, exist_ok=True)
payload = {
    "check_id": "TSK-P1-DEMO-024-HEALTH-PROBE-PARITY",
    "task_id": task_id,
    "timestamp_utc": os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
    "git_sha": sha,
    "status": "PASS",
    "pass": True,
    "details": {
        "app_routes": ["/health", "/healthz", "/readyz"],
        "k8s_probe_paths": ["/healthz", "/readyz"],
        "parity_verified": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
