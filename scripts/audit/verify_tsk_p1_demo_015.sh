#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-015"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_015_pipeline_split.json}"
PRE_CI="$ROOT_DIR/scripts/dev/pre_ci.sh"
PRE_CI_DEMO="$ROOT_DIR/scripts/dev/pre_ci_demo.sh"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

[[ -x "$PRE_CI_DEMO" ]]
rg -n 'RUN_DEMO_GATES="\$\{RUN_DEMO_GATES:-0\}"' "$PRE_CI" >/dev/null
rg -n 'if \[\[ "\$\{RUN_DEMO_GATES\}" == "1" \]\]; then' "$PRE_CI" >/dev/null
rg -n 'RUN_DEMO_GATES=1' "$PRE_CI_DEMO" >/dev/null
bash -n "$PRE_CI"
bash -n "$PRE_CI_DEMO"

python3 - <<'PY' "$EVIDENCE_PATH" "$TASK_ID" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP"
import json, sys
from pathlib import Path

evidence, task_id, ts, sha, sfp = sys.argv[1:]
payload = {
    "check_id": "TSK-P1-DEMO-015-PIPELINE-SPLIT",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": sfp,
    "status": "PASS",
    "pass": True,
    "details": {
        "core_pre_ci_has_demo_gate_flag": True,
        "demo_pre_ci_entrypoint_exists": True,
        "shell_syntax_valid": True
    }
}
Path(evidence).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence}")
PY

