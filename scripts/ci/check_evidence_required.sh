#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASKS_DIR="$ROOT_DIR/tasks"

python3 - <<'PY'
import sys
from pathlib import Path
import glob
import yaml

root = Path("/home/mwiza/workspaces/Symphony")
tasks_dir = root / "tasks"

# pass CI_ONLY from env
import os
ci_only = os.environ.get("CI_ONLY", "0") == "1"

missing = []
checked = []

for meta in sorted(tasks_dir.glob("TSK-P0-*/meta.yml")):
    data = yaml.safe_load(meta.read_text()) or {}
    if str(data.get("phase")) != "0":
        continue
    if str(data.get("status", "")).lower() == "deferred":
        continue
    globs = data.get("evidence", []) or []
    for pattern in globs:
        pattern = str(pattern)
        if not pattern:
            continue
        # CI-only artifact name handling
        if pattern == "phase0-evidence":
            if ci_only:
                matches = glob.glob(str(root / "evidence" / "**"), recursive=True)
                count = len([m for m in matches if Path(m).is_file()])
                checked.append((meta.parent.name, pattern, count))
                if count == 0:
                    missing.append(f"{meta.parent.name}: {pattern} (no evidence files found)")
            else:
                # skip CI-only artifact in local mode
                continue
        else:
            # normalize to repo root
            if pattern.startswith("./"):
                pattern = pattern[2:]
            abs_pattern = str(root / pattern)
            matches = glob.glob(abs_pattern)
            checked.append((meta.parent.name, pattern, len(matches)))
            if len(matches) == 0:
                missing.append(f"{meta.parent.name}: {pattern}")

if missing:
    print("Missing evidence artifacts:")
    for m in missing:
        print(f" - {m}")
    sys.exit(1)

print("Evidence check passed. Checked:")
for task_id, pattern, count in checked:
    print(f" - {task_id}: {pattern} ({count})")
PY
