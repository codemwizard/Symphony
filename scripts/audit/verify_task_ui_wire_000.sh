#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-000"
DOC="$ROOT_DIR/docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_000_source_of_truth.json}"

[[ -f "$DOC" ]] || { echo "missing_doc:$DOC" >&2; exit 1; }

required_patterns=(
  "Canonical target shell"
  "GET /pilot-demo/supervisory"
  "GET /pilot-demo/supervisory-legacy"
  "| Programme summary | LIVE |"
  "| SIM-swap | DEMO_BACKED |"
  "| Pilot success panel | LIVE_FROM_EVIDENCE |"
  "must be revalidated against the new shell"
  "programme-summary-panel"
  "raw-artifact-drilldown"
)

for pattern in "${required_patterns[@]}"; do
  rg -Fq "$pattern" "$DOC" || { echo "missing_required_text:$pattern" >&2; exit 1; }
done

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
payload = {
  "check_id": "TASK-UI-WIRE-000-SOURCE-OF-TRUTH",
  "task_id": task_id,
  "timestamp_utc": os.popen("date -u +%Y-%m-%dT%H:%M:%SZ").read().strip(),
  "git_sha": sha,
  "status": "PASS",
  "pass": True,
  "details": {
    "canonical_shell_declared": True,
    "backing_modes_locked": True,
    "sim_swap_demo_backed": True,
    "legacy_shell_marked": True,
    "demo_prerequisites_revalidate_only": True
  }
}
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")
PY
