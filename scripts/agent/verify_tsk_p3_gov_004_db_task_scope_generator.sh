#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CONFIG="$TMPDIR/task.json"
cat > "$CONFIG" <<'JSON'
{
  "task_id": "TSK-P3-WP-901",
  "title": "Representative DB task-pack scope generation probe",
  "owner": "DB_FOUNDATION",
  "phase": "3",
  "wave": "WP",
  "blast_radius": "DB_SCHEMA",
  "work": [
    "[ID tsk_p3_wp_901_w01] Generate a representative Phase 3 DB task pack and prove canonical DB governance closure surfaces are emitted mechanically."
  ],
  "acceptance_criteria": [
    "[ID tsk_p3_wp_901_w01] The generated pack includes migration-head, baseline, ADR-0010, registry, and runtime task-index closure surfaces without manual repair."
  ],
  "verifiers": [
    "scripts/db/verify_p3_wp_901_scope_probe.sh"
  ],
  "evidence": {
    "path": "evidence/phase3/tsk_p3_wp_901_scope_probe.json",
    "must_include": [
      "task_id",
      "git_sha",
      "timestamp_utc",
      "status",
      "checks",
      "observed_paths",
      "observed_hashes"
    ]
  }
}
JSON

python3 "$ROOT/scripts/agent/generate_task_pack.py" --config "$CONFIG" --base-dir "$TMPDIR" --phase3 >/dev/null

META="$TMPDIR/tasks/TSK-P3-WP-901/meta.yml"
PLAN="$TMPDIR/docs/plans/phase3/TSK-P3-WP-901/PLAN.md"
LOG="$TMPDIR/docs/plans/phase3/TSK-P3-WP-901/EXEC_LOG.md"

python3 - "$ROOT" "$META" "$PLAN" "$LOG" <<'PY'
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

root, meta_path, plan_path, log_path = sys.argv[1:]

required_meta_paths = [
    "schema/migrations/MIGRATION_HEAD",
    "schema/baseline.sql",
    "schema/baselines/current/0001_baseline.sql",
    "schema/baselines/current/baseline.cutoff",
    "schema/baselines/current/baseline.meta.json",
    "schema/baselines/2026-05-17/0001_baseline.sql",
    "schema/baselines/2026-05-17/baseline.normalized.sql",
    "schema/baselines/2026-05-17/baseline.cutoff",
    "schema/baselines/2026-05-17/baseline.meta.json",
    "docs/decisions/ADR-0010-baseline-policy.md",
    "docs/PHASE3/phase3_task_registry.yml",
    "docs/tasks/PHASE3_RUNTIME_TASKS.md"
]

required_plan_refs = [
    "schema/migrations/MIGRATION_HEAD",
    "schema/baseline.sql",
    "schema/baselines/current/0001_baseline.sql",
    "schema/baselines/2026-05-17/0001_baseline.sql",
    "schema/baselines/2026-05-17/baseline.normalized.sql",
    "docs/decisions/ADR-0010-baseline-policy.md",
    "docs/PHASE3/phase3_task_registry.yml",
    "docs/tasks/PHASE3_RUNTIME_TASKS.md"
]

checks = []

def sha256(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()

with open(meta_path, "r", encoding="utf-8") as fh:
    meta_text = fh.read()
with open(plan_path, "r", encoding="utf-8") as fh:
    plan_text = fh.read()
with open(log_path, "r", encoding="utf-8") as fh:
    log_text = fh.read()

for path in required_meta_paths:
    checks.append({"check": f"meta_contains::{path}", "pass": path in meta_text})

for path in required_plan_refs:
    checks.append({"check": f"plan_contains::{path}", "pass": path in plan_text})

checks.append({"check": "meta_omits_pre_ci", "pass": "scripts/dev/pre_ci.sh" not in meta_text})
checks.append({"check": "plan_omits_pre_ci", "pass": "scripts/dev/pre_ci.sh" not in plan_text})
checks.append({"check": "meta_contains_task_pack_readiness", "pass": "verify_task_pack_readiness.sh --task TSK-P3-WP-901" in meta_text})
checks.append({"check": "plan_contains_task_pack_readiness", "pass": "verify_task_pack_readiness.sh --task TSK-P3-WP-901" in plan_text})
checks.append({"check": "exec_log_has_plan_reference", "pass": "Plan: docs/plans/phase3/TSK-P3-WP-901/PLAN.md" in log_text})
checks.append({"check": "exec_log_has_final_summary", "pass": "## final summary" in log_text})

status = "PASS" if all(item["pass"] for item in checks) else "FAIL"
git_sha = subprocess.check_output(["git", "-C", root, "rev-parse", "HEAD"], text=True).strip()

observed = [
    meta_path,
    plan_path,
    log_path,
    os.path.join(root, "scripts/agent/generate_task_pack.py"),
    os.path.join(root, "docs/operations/TASK_CREATION_PROCESS.md"),
    os.path.join(root, "docs/operations/AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md"),
]

payload = {
    "task_id": "TSK-P3-GOV-004",
    "git_sha": git_sha,
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "status": status,
    "checks": checks,
    "observed_paths": observed,
    "observed_hashes": {path: sha256(path) for path in observed},
    "command_outputs": [
        {
            "command": "python3 scripts/agent/generate_task_pack.py --config <temp> --base-dir <temp> --phase3",
            "status": "PASS"
        }
    ],
    "execution_trace": [
        "Generated a representative Phase 3 DB task pack in a temporary sandbox.",
        "Verified canonical DB governance closure surfaces in meta and plan outputs.",
        "Verified readiness-based verification wiring and exec-log structural markers."
    ]
}

json.dump(payload, sys.stdout, indent=2)
if status != "PASS":
    sys.exit(1)
PY
