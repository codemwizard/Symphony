#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

JSON_OUT=0
TASK_IDS=()
ZIP_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      TASK_IDS+=("${2:-}")
      shift 2
      ;;
    --zip)
      ZIP_PATH="${2:-}"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ${#TASK_IDS[@]} -eq 0 && -z "$ZIP_PATH" ]]; then
  echo "ERROR: provide at least one --task or one --zip" >&2
  exit 2
fi

TASK_IDS_CSV=""
if [[ ${#TASK_IDS[@]} -gt 0 ]]; then
  TASK_IDS_CSV="$(IFS=,; echo "${TASK_IDS[*]}")"
fi

TASK_IDS_CSV="$TASK_IDS_CSV" ZIP_PATH="$ZIP_PATH" JSON_OUT="$JSON_OUT" python3 - <<'PY'
import csv
import io
import json
import os
from pathlib import Path
import zipfile
import yaml  # type: ignore


ROOT = Path.cwd()
task_ids_csv = os.environ.get("TASK_IDS_CSV", "")
zip_path = os.environ.get("ZIP_PATH", "")
json_out = os.environ.get("JSON_OUT") == "1"

task_ids = [x for x in task_ids_csv.split(",") if x]
phase_prefix = {
    "0": "docs/plans/phase0/",
    "1": "docs/plans/phase1/",
    "2": "docs/plans/phase2/",
    "3": "docs/plans/phase3/",
    "4": "docs/plans/phase4/",
}


def normalize_verification_commands(commands):
    if isinstance(commands, str):
        commands = [commands]
    if not isinstance(commands, list):
        return []
    normalized = []
    for item in commands:
        if isinstance(item, str):
            cmd = item.strip()
            if cmd:
                normalized.append(cmd)
        elif isinstance(item, dict):
            cmd = str(item.get("cmd", "")).strip()
            if cmd:
                normalized.append(cmd)
    return normalized


def verification_is_thin(commands, blast_radius):
    normalized_commands = normalize_verification_commands(commands)
    min_count = 2 if blast_radius == "DOCS_ONLY" else 3
    if len(normalized_commands) < min_count:
        return True
    if blast_radius != "DOCS_ONLY":
        has_task_verifier = any(
            (
                "bash scripts/" in cmd
                or "python3 scripts/" in cmd
                or cmd.startswith("scripts/")
            )
            and "validate_evidence.py" not in cmd
            for cmd in normalized_commands
        )
        if not has_task_verifier:
            return True
    return False


def inspect_meta(path_label, data, existing_paths=None):
    issues = []
    tid = str(data.get("task_id", "UNKNOWN"))
    phase = str(data.get("phase", ""))
    blast_radius = str(data.get("blast_radius", "DOCS_ONLY"))
    plan = str(data.get("implementation_plan", ""))
    log = str(data.get("implementation_log", ""))
    work = data.get("work", [])
    acceptance = data.get("acceptance_criteria", [])
    verification = data.get("verification", [])

    if phase not in phase_prefix:
        issues.append("invalid_lifecycle_phase")
    else:
        prefix = phase_prefix[phase]
        if not plan.startswith(prefix):
            issues.append(f"plan_phase_mismatch:{plan}")
        if not log.startswith(prefix):
            issues.append(f"log_phase_mismatch:{log}")

    def path_exists(candidate):
        if existing_paths is not None:
            return candidate in existing_paths
        return (ROOT / candidate).exists()

    if not plan or not path_exists(plan):
        issues.append(f"missing_plan:{plan}")
    if not log or not path_exists(log):
        issues.append(f"missing_log:{log}")

    if not isinstance(work, list) or len(work) == 0:
        issues.append("empty_work")
    else:
        for item in work:
            if isinstance(item, str) and item.strip().startswith("[INTENT-"):
                issues.append("intent_marker_in_work")
                break

    min_acceptance = 2 if blast_radius == "DOCS_ONLY" else 3
    if not isinstance(acceptance, list) or len(acceptance) < min_acceptance:
        issues.append(f"acceptance_too_shallow:{0 if not isinstance(acceptance, list) else len(acceptance)}")

    if verification_is_thin(verification, blast_radius):
        issues.append("verification_too_shallow")

    return {"task_id": tid, "path": path_label, "issues": issues}


task_reports = []
for tid in task_ids:
    meta_path = ROOT / "tasks" / tid / "meta.yml"
    if not meta_path.exists():
        task_reports.append({"task_id": tid, "path": str(meta_path), "issues": ["missing_meta"]})
        continue
    data = yaml.safe_load(meta_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        task_reports.append({"task_id": tid, "path": str(meta_path), "issues": ["meta_not_mapping"]})
        continue
    task_reports.append(inspect_meta(str(meta_path.relative_to(ROOT)), data))

zip_reports = []
if zip_path:
    zpath = ROOT / zip_path if not os.path.isabs(zip_path) else Path(zip_path)
    if not zpath.exists():
        zip_reports.append({"zip": str(zpath), "issues": ["missing_zip"]})
    else:
        with zipfile.ZipFile(zpath) as zf:
            names = [n for n in zf.namelist() if n and not n.startswith("__MACOSX")]
            top = sorted(set(n.split("/")[0] for n in names))
            expected = zpath.stem
            issues = []
            if top != [expected]:
                issues.append(f"zip_root_mismatch:{top}:{expected}")
            existing_paths = set()
            if top == [expected]:
                prefix = f"{expected}/"
                existing_paths = {
                    n[len(prefix):]
                    for n in names
                    if n.startswith(prefix)
                }

            for name in sorted(n for n in names if n.endswith("/meta.yml")):
                data = yaml.safe_load(io.TextIOWrapper(zf.open(name), encoding="utf-8").read())
                if not isinstance(data, dict):
                    issues.append(f"meta_not_mapping:{name}")
                    continue
                meta_report = inspect_meta(
                    f"{zpath.name}:{name}",
                    data,
                    existing_paths=existing_paths if existing_paths else None,
                )
                for issue in meta_report["issues"]:
                    issues.append(f"{data.get('task_id','UNKNOWN')}:{issue}")

            zip_reports.append({"zip": str(zpath), "issues": issues})

status = "PASS"
if any(r["issues"] for r in task_reports) or any(r["issues"] for r in zip_reports):
    status = "FAIL"

report = {
    "check_id": "TASK-PACK-READINESS",
    "status": status,
    "tasks": task_reports,
    "zips": zip_reports,
}

if json_out:
    print(json.dumps(report, indent=2, sort_keys=True))
else:
    print(f"Task pack readiness: {status}")
    for item in task_reports:
        if item["issues"]:
            print(f" - {item['task_id']}: {';'.join(item['issues'])}")
    for item in zip_reports:
        if item["issues"]:
            print(f" - {item['zip']}: {';'.join(item['issues'])}")

if status == "FAIL":
    raise SystemExit(1)
PY
