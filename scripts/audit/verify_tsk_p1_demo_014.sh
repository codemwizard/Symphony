#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-014"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_014_profile_wiring.json}"
LEDGER_PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"
DEMO_HOST="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

dotnet build "$LEDGER_PROJECT" -nologo -v minimal >/dev/null
dotnet build "$DEMO_HOST" -nologo -v minimal >/dev/null

set +e
SYMPHONY_RUNTIME_PROFILE=production dotnet run --no-launch-profile --project "$LEDGER_PROJECT" -- --self-test >/tmp/tsk_p1_demo_014_prod.log 2>&1
prod_rc=$?
set -e
if [[ "$prod_rc" -eq 0 ]]; then
  echo "production profile unexpectedly allowed self-test flag" >&2
  cat /tmp/tsk_p1_demo_014_prod.log >&2 || true
  exit 1
fi

dotnet run --no-launch-profile --project "$DEMO_HOST" -- --self-test-evidence-pack >/dev/null

python3 - <<'PY' "$EVIDENCE_PATH" "$TASK_ID" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$prod_rc"
import json, sys
from pathlib import Path

evidence, task_id, ts, sha, sfp, prod_rc = sys.argv[1:]
payload = {
    "check_id": "TSK-P1-DEMO-014-PROFILE-WIRING",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": sfp,
    "status": "PASS",
    "pass": True,
    "details": {
        "production_profile_rejected_demo_flag": True,
        "production_reject_exit_code": int(prod_rc),
        "pilot_demo_profile_executes_self_tests": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence}")
PY

