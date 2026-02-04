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

evidence_root = root

# In CI, artifacts may be extracted under evidence/phase0 or nested paths.
ci_base = root / "evidence" / "phase0"
double_base = ci_base / "evidence" / "phase0"
if ci_only and double_base.exists():
    evidence_root = double_base
elif ci_only and ci_base.exists():
    evidence_root = ci_base
else:
    # search for a known marker file
    marker_names = {"evidence.json", "baseline_drift.json", "repo_structure.json"}
    for p in (root / "evidence").rglob("*.json"):
        if p.name in marker_names:
            evidence_root = p.parent
            break

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
    status = str(data.get("status", "")).lower()
    if status != "completed":
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
            if ci_only and pattern.startswith("evidence/phase0/"):
                pattern = pattern[len("evidence/phase0/"):]
                abs_pattern = str(evidence_root / pattern)
            else:
                abs_pattern = str(root / pattern)
            if ci_only and pattern == "evidence/phase0/local_ci_parity.json":
                # local-only evidence; skip in CI gate
                continue
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
