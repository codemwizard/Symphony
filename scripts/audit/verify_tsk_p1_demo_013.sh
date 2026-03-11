#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-013"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_013_demo_host_extraction.json}"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
DEMO_HOST="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

[[ -f "$DEMO_HOST" ]]
! rg -n --fixed-strings -- '--self-test' "$PROGRAM" >/dev/null
rg -n 'LedgerApi\.DemoHost' "$ROOT_DIR/scripts/services/test_ingress_api_contract.sh" >/dev/null

dotnet build "$DEMO_HOST" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$DEMO_HOST" -- --self-test >/dev/null

python3 - <<'PY' "$EVIDENCE_PATH" "$TASK_ID" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP"
import json, sys
from pathlib import Path

evidence, task_id, ts, sha, sfp = sys.argv[1:]
payload = {
    "check_id": "TSK-P1-DEMO-013-DEMO-HOST-EXTRACTION",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": sfp,
    "status": "PASS",
    "pass": True,
    "details": {
        "program_bootstrap_selftest_dispatch_removed": True,
        "demo_host_project_present": True,
        "demo_runner_smoke_passed": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence}")
PY
