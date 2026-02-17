#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASKS_DOC="$ROOT_DIR/docs/tasks/PHASE0_TASKS.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/task_evidence_contract.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$TASKS_DOC" ]]; then
  echo "Missing tasks doc: $TASKS_DOC" >&2
  exit 1
fi

TASKS_DOC="$TASKS_DOC" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

tasks_doc = Path(os.environ.get("TASKS_DOC", "/home/mwiza/workspaces/Symphony/docs/tasks/PHASE0_TASKS.md"))
text = tasks_doc.read_text(encoding="utf-8", errors="ignore")

blocks = text.split("TASK ID: ")[1:]
issues = []
checked = []

for block in blocks:
    header, *rest = block.splitlines()
    task_id = header.strip()
    body = "\n".join(rest)
    has_evidence = "Evidence Artifact(s):" in body
    has_failure_modes = "Failure Modes:" in body
    evidence_missing_flag = "Evidence file missing" in body
    has_verification = "Verification Commands:" in body

    # Track tasks with evidence
    if has_evidence:
        checked.append(task_id)
        if not has_failure_modes:
            issues.append(f"{task_id}: missing Failure Modes section")
        elif not evidence_missing_flag:
            issues.append(f"{task_id}: Failure Modes missing 'Evidence file missing'")

        # Require verification commands to reference scripts (not just rg/grep)
        if has_verification:
            # Extract verification block (rough heuristic)
            v_start = body.find("Verification Commands:")
            v_block = body[v_start:v_start + 800] if v_start >= 0 else ""
            if "scripts/" not in v_block:
                issues.append(f"{task_id}: Verification Commands do not reference a script")
        else:
            issues.append(f"{task_id}: missing Verification Commands section")

out = {
    "check_id": "TASK-EVIDENCE-CONTRACT",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "FAIL" if issues else "PASS",
    "checked_tasks": checked,
    "issues": issues,
}

Path(os.environ.get("EVIDENCE_FILE", "/home/mwiza/workspaces/Symphony/evidence/phase0/task_evidence_contract.json")).write_text(
    json.dumps(out, indent=2) + "\n",
    encoding="utf-8",
)

if issues:
    print("Task evidence contract violations:")
    for i in issues:
        print(f" - {i}")
    raise SystemExit(1)

print("Task evidence contract OK")
PY
