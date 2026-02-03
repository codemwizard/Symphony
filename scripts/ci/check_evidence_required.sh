#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASKS_DIR="$ROOT_DIR/tasks"

ROOT_DIR="$ROOT_DIR" TASKS_DIR="$TASKS_DIR" python3 - <<'PY'
import sys
from pathlib import Path
import glob
import os

root = Path(os.environ["ROOT_DIR"])
tasks_dir = Path(os.environ["TASKS_DIR"])

ci_only = os.environ.get("CI_ONLY", "0") == "1"

missing = []
checked = []

def parse_meta(path: Path) -> dict:
    data = {"phase": None, "status": None, "evidence": []}
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    in_evidence = False
    for line in lines:
        if not line.strip():
            continue
        if line.startswith("phase:"):
            data["phase"] = line.split(":", 1)[1].strip().strip('"')
            in_evidence = False
            continue
        if line.startswith("status:"):
            data["status"] = line.split(":", 1)[1].strip().strip('"')
            in_evidence = False
            continue
        if line.startswith("evidence:"):
            in_evidence = True
            continue
        if in_evidence:
            if line.lstrip().startswith("- "):
                data["evidence"].append(line.split("- ", 1)[1].strip().strip('"'))
                continue
            # end of evidence block on next top-level key
            if not line.startswith("  "):
                in_evidence = False
    return data

for meta in sorted(tasks_dir.glob("TSK-P0-*/meta.yml")):
    data = parse_meta(meta)
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
