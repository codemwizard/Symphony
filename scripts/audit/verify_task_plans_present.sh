#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASKS_DIR="$ROOT_DIR/tasks"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/task_plans_present.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

TASKS_DIR="$TASKS_DIR" EVIDENCE_FILE="$EVIDENCE_FILE" ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
tasks_dir = Path(os.environ["TASKS_DIR"])
evidence_out = Path(os.environ["EVIDENCE_FILE"])

try:
    import yaml  # type: ignore
except Exception as e:
    out = {
        "check_id": "TASK-PLANS-PRESENT",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": [f"pyyaml_missing: {e}"],
    }
    evidence_out.write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

errors = []
checked = []

def include_meta(path: Path) -> bool:
    rel = path.relative_to(tasks_dir).as_posix()
    if "/_template/" in rel:
        return False
    # Existing Phase task packs
    if rel.startswith("TSK-P") and rel.endswith("/meta.yml"):
        return True
    # First-class checkpoint packs under tasks/checkpoint/<ID>/meta.yml
    if rel.startswith("checkpoint/") and rel.endswith("/meta.yml"):
        return True
    return False

for meta in sorted(tasks_dir.rglob("meta.yml")):
    if not include_meta(meta):
        continue
    data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
    if not isinstance(data, dict):
        errors.append(f"{meta}: meta_not_mapping")
        continue

    task_id = str(data.get("task_id", meta.parent.name))
    status = str(data.get("status", "")).lower()
    if status not in ("in_progress", "completed"):
        continue

    plan_path = data.get("implementation_plan")
    log_path = data.get("implementation_log")

    if not isinstance(plan_path, str) or not plan_path.strip():
        errors.append(f"{task_id}:missing_plan_path")
        continue
    if not isinstance(log_path, str) or not log_path.strip():
        errors.append(f"{task_id}:missing_log_path")
        continue

    plan_file = root / plan_path
    log_file = root / log_path

    if not plan_file.exists():
        errors.append(f"{task_id}:plan_missing:{plan_path}")
        continue
    if not log_file.exists():
        errors.append(f"{task_id}:log_missing:{log_path}")
        continue

    plan_text = plan_file.read_text(encoding="utf-8", errors="ignore")
    log_text = log_file.read_text(encoding="utf-8", errors="ignore")

    # Task ID must appear in both files
    if task_id not in plan_text:
        errors.append(f"{task_id}:plan_missing_task_id")
    if task_id not in log_text:
        errors.append(f"{task_id}:log_missing_task_id")

    # EXEC_LOG must reference PLAN
    if plan_path not in log_text and "Plan: PLAN.md" not in log_text:
        errors.append(f"{task_id}:log_missing_plan_reference")

    # Completed tasks require Final summary section
    if status == "completed":
        if "final summary" not in log_text.lower():
            errors.append(f"{task_id}:log_missing_final_summary")

    checked.append(task_id)

out = {
    "check_id": "TASK-PLANS-PRESENT",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "checked_tasks": checked,
    "errors": errors,
}

EVIDENCE_OUT = evidence_out
EVIDENCE_OUT.parent.mkdir(parents=True, exist_ok=True)
EVIDENCE_OUT.write_text(json.dumps(out, indent=2) + "\n")

if errors:
    print("Task plan/log verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print("Task plan/log verification passed")
PY

echo "Task plan/log verification evidence: $EVIDENCE_FILE"
