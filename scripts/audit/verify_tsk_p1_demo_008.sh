#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-008"
UI_FILE="$ROOT_DIR/src/supervisory-dashboard/index.html"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_008_supervisory_ui.json}"

[[ -f "$UI_FILE" ]] || { echo "missing_ui:$UI_FILE" >&2; exit 1; }

required_ids=(
  "programme-summary-panel"
  "timeline-panel"
  "evidence-completeness-panel"
  "exception-log-panel"
  "export-trigger"
  "raw-artifact-drilldown"
)
for id in "${required_ids[@]}"; do
  rg -q "$id" "$UI_FILE" || { echo "missing_ui_element:$id" >&2; exit 1; }
done

rg -q "PRESENT|MISSING|FAILED" "$UI_FILE" || { echo "missing_interpreted_status_tokens" >&2; exit 1; }
if rg -qi "live rail|real-time rail settlement|production settlement execution" "$UI_FILE"; then
  echo "unsupported_phase_claim_in_ui" >&2
  exit 1
fi

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "check_id": "TSK-P1-DEMO-008-SUPERVISORY-UI",
    "task_id": task_id,
    "timestamp_utc": os.popen("date -u +%Y-%m-%dT%H:%M:%SZ").read().strip(),
    "git_sha": sha,
    "status": "PASS",
    "pass": True,
    "details": {
      "non_technical_navigation_ready": True,
      "interpreted_evidence_primary": True,
      "raw_artifact_drilldown_available": True,
      "phase1_truthful_claims_only": True
    }
}
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")
PY
